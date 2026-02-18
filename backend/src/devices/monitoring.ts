import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// ============================================
// HELPER: Get setting value from system_settings
// ============================================
async function getSetting(supabase: any, key: string, defaultValue: any) {
  const { data } = await supabase
    .from('system_settings')
    .select('setting_value, setting_type')
    .eq('setting_key', key)
    .single();

  if (!data) return defaultValue;

  switch (data.setting_type) {
    case 'INTEGER': return parseInt(data.setting_value) || defaultValue;
    case 'BOOLEAN': return data.setting_value === 'true';
    case 'DECIMAL': return parseFloat(data.setting_value) || defaultValue;
    default: return data.setting_value || defaultValue;
  }
}

// ============================================
// HELPER: Find device by deviceId or serial_number
// ============================================
async function findDevice(supabase: any, deviceId: string) {
  const { data, error } = await supabase
    .from('devices')
    .select('id, status, tracking_mode, lan_mac_address, active_mac_address, client_id')
    .or(`serial_number.eq.${deviceId},id.eq.${deviceId}`)
    .single();

  return { device: data, error };
}

// ============================================
// HELPER: Run heuristic checks and create events
// ============================================
async function runHeuristicChecks(supabase: any, deviceId: string, stats: any, previousStats: any) {
  const heuristicEnabled = await getSetting(supabase, 'heuristic_enabled', true);
  if (!heuristicEnabled) return;

  const events = [];

  // Check 1: MAC address changed (dongle swap?)
  if (previousStats?.active_mac_address &&
    stats.activeMacAddress &&
    previousStats.active_mac_address !== stats.activeMacAddress) {
    events.push({
      device_id: deviceId,
      event_type: 'MAC_CHANGE',
      severity: 'CRITICAL',
      event_data: {
        old_mac: previousStats.active_mac_address,
        new_mac: stats.activeMacAddress
      }
    });
  }

  // Check 2: IP address changed
  if (previousStats?.ip_address &&
    stats.ipAddress &&
    previousStats.ip_address !== stats.ipAddress) {
    events.push({
      device_id: deviceId,
      event_type: 'IP_CHANGE',
      severity: 'WARNING',
      event_data: {
        old_ip: previousStats.ip_address,
        new_ip: stats.ipAddress
      }
    });
  }

  // Check 3: User changed
  if (previousStats?.logged_in_user &&
    stats.loggedInUser &&
    previousStats.logged_in_user !== stats.loggedInUser) {
    events.push({
      device_id: deviceId,
      event_type: 'USER_CHANGE',
      severity: 'CRITICAL',
      event_data: {
        old_user: previousStats.logged_in_user,
        new_user: stats.loggedInUser
      }
    });
  }

  // Check 4: Too many restarts
  const restartTrigger = await getSetting(supabase, 'heuristic_restart_count_trigger', 5);
  if (stats.restartCount24h && stats.restartCount24h >= restartTrigger) {
    events.push({
      device_id: deviceId,
      event_type: 'RESTART',
      severity: 'WARNING',
      event_data: { restart_count_24h: stats.restartCount24h }
    });
  }

  // Check 5: Abrupt shutdown count
  const abruptTrigger = await getSetting(supabase, 'heuristic_abrupt_shutdown_trigger', 3);
  if (stats.abruptShutdownCount24h && stats.abruptShutdownCount24h >= abruptTrigger) {
    events.push({
      device_id: deviceId,
      event_type: 'ABRUPT_SHUTDOWN',
      severity: 'CRITICAL',
      event_data: { abrupt_shutdown_count_24h: stats.abruptShutdownCount24h }
    });
  }

  // Check 6: Night activity
  const nightStart = await getSetting(supabase, 'heuristic_night_start_hour', 23);
  const nightEnd = await getSetting(supabase, 'heuristic_night_end_hour', 6);
  const currentHour = new Date().getHours();
  const isNightTime = currentHour >= nightStart || currentHour < nightEnd;
  if (isNightTime && stats.isOnline) {
    events.push({
      device_id: deviceId,
      event_type: 'NIGHT_ACTIVITY',
      severity: 'WARNING',
      event_data: { hour: currentHour, night_start: nightStart, night_end: nightEnd }
    });
  }

  // Insert all events
  if (events.length > 0) {
    await supabase.from('device_events').insert(events);

    // Auto-activate SUPERWATCH if any CRITICAL event
    const hasCritical = events.some(e => e.severity === 'CRITICAL');
    if (hasCritical) {
      const criticalEvent = events.find(e => e.severity === 'CRITICAL');
      await supabase
        .from('devices')
        .update({
          tracking_mode: 'SUPERWATCH',
          superwatch_reason: `Auto: ${criticalEvent?.event_type}`,
          superwatch_activated_at: new Date().toISOString()
        })
        .eq('id', deviceId);
    }

    // Update alert_count on device
    await supabase.rpc('increment_alert_count', { device_id_param: deviceId, increment_by: events.length });
  }
}

// ============================================
// POST /api/devices/stats
// Agent sends hardware stats (replaces old stats.ts)
// ============================================
export async function receiveDeviceStats(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();

    const {
      deviceId,
      deviceToken,
      cpuUsage,
      ramUsage,
      ramTotal,
      ramUsed,
      diskUsage,
      diskTotal,
      diskUsed,
      isOnline,
      loggedInUser,
      timestamp,
      lanMacAddress,
      activeMacAddress,
      connectionType,
      ipAddress,
      computerName,
      // New SUPERWATCH fields
      cpuTemp,
      hddTemp,
      uptimeMinutes,
      restartCount24h,
      abruptShutdownCount24h,
      activeWindow,
      lastBoot,
      trackingMode
    } = body;

    if (!deviceId) {
      return c.json({ success: false, message: 'Missing deviceId', lockStatus: false }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Find device
    const { device, error: findError } = await findDevice(supabase, deviceId);
    if (findError || !device) {
      return c.json({ success: false, message: 'Device not found', lockStatus: false }, 404);
    }

    // Get previous stats for comparison (heuristic checks)
    const { data: previousStats } = await supabase
      .from('hardware_stats')
      .select('ip_address, active_mac_address, logged_in_user')
      .eq('device_id', device.id)
      .order('timestamp', { ascending: false })
      .limit(1)
      .single();

    // Get current tracking mode from DB (server is source of truth)
    const currentMode = device.tracking_mode || 'NORMAL';

    // Insert hardware stats
    const { error: statsError } = await supabase
      .from('hardware_stats')
      .insert({
        device_id: device.id,
        cpu_usage: cpuUsage,
        ram_usage: ramUsage,
        disk_usage: diskUsage,
        is_online: isOnline,
        logged_in_user: loggedInUser,
        timestamp: timestamp || new Date().toISOString(),
        lan_mac_address: lanMacAddress,
        active_mac_address: activeMacAddress,
        connection_type: connectionType,
        ip_address: ipAddress,
        computer_name: computerName,
        tracking_mode: currentMode,
        // SUPERWATCH fields (null if NORMAL mode)
        cpu_temp: cpuTemp || null,
        hdd_temp: hddTemp || null,
        uptime_minutes: uptimeMinutes || null,
        restart_count_24h: restartCount24h || 0,
        active_window: activeWindow || null,
        last_boot: lastBoot || null
      });

    if (statsError) {
      console.error('Stats insert error:', statsError);
    }

    // Update device last_seen and MAC addresses
    await supabase
      .from('devices')
      .update({
        last_seen: new Date().toISOString(),
        ...(lanMacAddress && { lan_mac_address: lanMacAddress }),
        ...(activeMacAddress && { active_mac_address: activeMacAddress }),
        updated_at: new Date().toISOString()
      })
      .eq('id', device.id);

    // Run heuristic checks
    await runHeuristicChecks(supabase, device.id, body, previousStats);

    // Check lock status
    const shouldLock = device.status === 'LOCKED' || device.status === 'STOLEN';

    // Get report interval based on current mode
    const reportInterval = currentMode === 'SUPERWATCH'
      ? await getSetting(supabase, 'superwatch_report_interval_seconds', 30)
      : await getSetting(supabase, 'normal_report_interval_seconds', 300);

    // Get screenshot interval if SUPERWATCH
    const screenshotInterval = currentMode === 'SUPERWATCH'
      ? await getSetting(supabase, 'superwatch_screenshot_interval_minutes', 5)
      : null;

    return c.json({
      success: true,
      message: 'Stats received',
      lockStatus: shouldLock,
      deviceStatus: device.status,
      trackingMode: currentMode,          // Server tells agent which mode to run
      reportIntervalSeconds: reportInterval,
      screenshotIntervalMinutes: screenshotInterval
    });

  } catch (error) {
    console.error('Receive stats error:', error);
    return c.json({ success: false, message: 'Internal server error', lockStatus: false }, 500);
  }
}

// ============================================
// GET /api/devices/monitor
// Dashboard: live status of all devices
// ============================================
export async function getDeviceMonitor(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('device_live_status')
      .select('*')
      .order('online_status', { ascending: true }); // ONLINE first

    if (error) throw error;

    // Summary counts
    const summary = {
      total: data?.length || 0,
      online: data?.filter(d => d.online_status === 'ONLINE').length || 0,
      offline: data?.filter(d => ['OFFLINE', 'LONG_OFFLINE'].includes(d.online_status)).length || 0,
      superwatch: data?.filter(d => d.tracking_mode === 'SUPERWATCH').length || 0,
      alerts: data?.reduce((sum: number, d: any) => sum + (d.unresolved_alerts || 0), 0) || 0,
      neverSeen: data?.filter(d => d.online_status === 'NEVER_SEEN').length || 0
    };

    return c.json({ success: true, summary, data });

  } catch (error) {
    console.error('Monitor error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// PUT /api/devices/:id/mode
// Admin switches device NORMAL/SUPERWATCH mode
// ============================================
export async function switchDeviceMode(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const deviceId = c.req.param('id');
    const { mode, reason } = await c.req.json();

    if (!['NORMAL', 'SUPERWATCH'].includes(mode)) {
      return c.json({ success: false, message: 'Mode must be NORMAL or SUPERWATCH' }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    const updateData: any = {
      tracking_mode: mode,
      updated_at: new Date().toISOString()
    };

    if (mode === 'SUPERWATCH') {
      updateData.superwatch_reason = reason || 'Manual activation by admin';
      updateData.superwatch_activated_at = new Date().toISOString();
    } else {
      // Clearing SUPERWATCH
      updateData.superwatch_reason = null;
      updateData.superwatch_activated_at = null;
    }

    const { error } = await supabase
      .from('devices')
      .update(updateData)
      .eq('id', deviceId);

    if (error) throw error;

    // Log the mode change as event
    await supabase.from('device_events').insert({
      device_id: deviceId,
      event_type: mode === 'SUPERWATCH' ? 'SUPERWATCH_ON' : 'SUPERWATCH_OFF',
      severity: 'INFO',
      event_data: {
        mode,
        reason: reason || 'Manual by admin',
        activated_by: 'admin'
      }
    });

    return c.json({
      success: true,
      message: `Device switched to ${mode} mode`,
      data: { deviceId, mode, reason }
    });

  } catch (error) {
    console.error('Switch mode error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// POST /api/devices/event
// Agent reports an event (restart, shutdown, USB, etc.)
// ============================================
export async function receiveDeviceEvent(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();
    const { deviceId, deviceToken, eventType, eventData, severity } = body;

    if (!deviceId || !eventType) {
      return c.json({ success: false, message: 'Missing deviceId or eventType' }, 400);
    }

    const validEvents = [
      'RESTART', 'ABRUPT_SHUTDOWN', 'USER_CHANGE', 'MAC_CHANGE',
      'IP_CHANGE', 'LOCATION_CHANGE', 'OFFLINE_SPIKE', 'NIGHT_ACTIVITY',
      'USB_CONNECT', 'SUPERWATCH_ON', 'SUPERWATCH_OFF', 'PAYMENT_OVERDUE'
    ];

    if (!validEvents.includes(eventType)) {
      return c.json({ success: false, message: 'Invalid event type' }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Find device
    const { device, error: findError } = await findDevice(supabase, deviceId);
    if (findError || !device) {
      return c.json({ success: false, message: 'Device not found' }, 404);
    }

    // Determine severity if not provided
    const eventSeverity = severity || (() => {
      const criticalEvents = ['MAC_CHANGE', 'LOCATION_CHANGE', 'USER_CHANGE', 'ABRUPT_SHUTDOWN'];
      const warningEvents = ['RESTART', 'OFFLINE_SPIKE', 'NIGHT_ACTIVITY', 'PAYMENT_OVERDUE'];
      if (criticalEvents.includes(eventType)) return 'CRITICAL';
      if (warningEvents.includes(eventType)) return 'WARNING';
      return 'INFO';
    })();

    // Insert event
    const { error } = await supabase.from('device_events').insert({
      device_id: device.id,
      event_type: eventType,
      event_data: eventData || {},
      severity: eventSeverity
    });

    if (error) throw error;

    // Auto-activate SUPERWATCH for CRITICAL events
    if (eventSeverity === 'CRITICAL' && device.tracking_mode !== 'SUPERWATCH') {
      await supabase.from('devices').update({
        tracking_mode: 'SUPERWATCH',
        superwatch_reason: `Auto: ${eventType}`,
        superwatch_activated_at: new Date().toISOString()
      }).eq('id', device.id);
    }

    return c.json({ success: true, message: 'Event recorded', severity: eventSeverity });

  } catch (error) {
    console.error('Event receive error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// GET /api/devices/alerts
// Get all unresolved alerts
// ============================================
export async function getAlerts(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    const severityFilter = c.req.query('severity');
    const deviceId = c.req.query('deviceId');

    let query = supabase
      .from('device_events')
      .select(`
        *,
        devices (
          id, serial_number, tracking_mode,
          clients ( company_name, owner_name, phone )
        )
      `)
      .eq('is_resolved', false)
      .order('created_at', { ascending: false })
      .limit(100);

    if (severityFilter) query = query.eq('severity', severityFilter);
    if (deviceId) query = query.eq('device_id', deviceId);

    const { data, error } = await query;
    if (error) throw error;

    return c.json({
      success: true,
      total: data?.length || 0,
      data
    });

  } catch (error) {
    console.error('Get alerts error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// PUT /api/devices/alerts/:id/resolve
// Mark alert as resolved
// ============================================
export async function resolveAlert(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const alertId = c.req.param('id');
    const { resolveNote } = await c.req.json();
    const user = c.get('user') as any;

    const supabase = getSupabaseClient(c.env);

    const { error } = await supabase
      .from('device_events')
      .update({
        is_resolved: true,
        resolved_by: user.userId,
        resolved_at: new Date().toISOString(),
        resolve_note: resolveNote || null
      })
      .eq('id', alertId);

    if (error) throw error;

    return c.json({ success: true, message: 'Alert resolved' });

  } catch (error) {
    console.error('Resolve alert error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// POST /api/devices/screenshot
// Agent uploads screenshot (SUPERWATCH mode only)
// ============================================
export async function receiveScreenshot(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();
    const { deviceId, deviceToken, screenshotData, fileSizeKb, width, height, activeWindow, triggeredBy } = body;

    if (!deviceId || !screenshotData) {
      return c.json({ success: false, message: 'Missing deviceId or screenshotData' }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Find device and verify it's in SUPERWATCH mode
    const { device, error: findError } = await findDevice(supabase, deviceId);
    if (findError || !device) {
      return c.json({ success: false, message: 'Device not found' }, 404);
    }

    if (device.tracking_mode !== 'SUPERWATCH') {
      return c.json({ success: false, message: 'Screenshots only allowed in SUPERWATCH mode' }, 403);
    }

    const { error } = await supabase.from('device_screenshots').insert({
      device_id: device.id,
      screenshot_data: screenshotData,
      file_size_kb: fileSizeKb || null,
      width: width || 1024,
      height: height || 768,
      active_window: activeWindow || null,
      triggered_by: triggeredBy || 'AUTO_SUPERWATCH'
    });

    if (error) throw error;

    return c.json({ success: true, message: 'Screenshot saved' });

  } catch (error) {
    console.error('Screenshot receive error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// GET /api/devices/:id/screenshots
// View screenshots for a device
// ============================================
export async function getScreenshots(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const deviceId = c.req.param('id');
    const limit = parseInt(c.req.query('limit') || '10');

    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('device_screenshots')
      .select('id, file_size_kb, width, height, triggered_by, active_window, created_at')
      // Note: screenshot_data excluded by default (too large)
      .eq('device_id', deviceId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    return c.json({ success: true, total: data?.length || 0, data });

  } catch (error) {
    console.error('Get screenshots error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// GET /api/devices/:id/screenshot/:screenshotId
// Get single screenshot with image data
// ============================================
export async function getScreenshot(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const screenshotId = c.req.param('screenshotId');
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('device_screenshots')
      .select('*')
      .eq('id', screenshotId)
      .single();

    if (error || !data) {
      return c.json({ success: false, message: 'Screenshot not found' }, 404);
    }

    return c.json({ success: true, data });

  } catch (error) {
    console.error('Get screenshot error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// GET /api/settings
// Get all settings (grouped by category)
// ============================================
export async function getSettings(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);
    const category = c.req.query('category');

    let query = supabase
      .from('system_settings')
      .select('setting_key, setting_value, setting_type, category, label, description, min_value, max_value, updated_at')
      .order('category')
      .order('setting_key');

    if (category) query = query.eq('category', category);

    const { data, error } = await query;
    if (error) throw error;

    // Group by category
    const grouped = data?.reduce((acc: any, setting: any) => {
      if (!acc[setting.category]) acc[setting.category] = [];
      acc[setting.category].push(setting);
      return acc;
    }, {});

    return c.json({ success: true, data: grouped });

  } catch (error) {
    console.error('Get settings error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// PUT /api/settings/:key
// Update a setting value
// ============================================
export async function updateSetting(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const key = c.req.param('key');
    const { value } = await c.req.json();
    const user = c.get('user') as any;

    if (value === undefined || value === null) {
      return c.json({ success: false, message: 'Missing value' }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Get setting to validate
    const { data: setting, error: findError } = await supabase
      .from('system_settings')
      .select('*')
      .eq('setting_key', key)
      .single();

    if (findError || !setting) {
      return c.json({ success: false, message: 'Setting not found' }, 404);
    }

    // Validate range if INTEGER
    if (setting.setting_type === 'INTEGER') {
      const numVal = parseInt(value);
      if (isNaN(numVal)) {
        return c.json({ success: false, message: 'Value must be a number' }, 400);
      }
      if (setting.min_value && numVal < parseInt(setting.min_value)) {
        return c.json({ success: false, message: `Minimum value is ${setting.min_value}` }, 400);
      }
      if (setting.max_value && numVal > parseInt(setting.max_value)) {
        return c.json({ success: false, message: `Maximum value is ${setting.max_value}` }, 400);
      }
    }

    // Validate BOOLEAN
    if (setting.setting_type === 'BOOLEAN' && !['true', 'false'].includes(String(value))) {
      return c.json({ success: false, message: 'Value must be true or false' }, 400);
    }

    // Update setting (trigger will auto-log to settings_history)
    const { error } = await supabase
      .from('system_settings')
      .update({
        setting_value: String(value),
        updated_by: user.userId
      })
      .eq('setting_key', key);

    if (error) throw error;

    return c.json({
      success: true,
      message: `Setting '${key}' updated to '${value}'`,
      data: { key, value }
    });

  } catch (error) {
    console.error('Update setting error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// ============================================
// GET /api/devices/:id/events
// Get event history for a device
// ============================================
export async function getDeviceEvents(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const deviceId = c.req.param('id');
    const limit = parseInt(c.req.query('limit') || '50');
    const onlyUnresolved = c.req.query('unresolved') === 'true';

    const supabase = getSupabaseClient(c.env);

    let query = supabase
      .from('device_events')
      .select('*')
      .eq('device_id', deviceId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (onlyUnresolved) query = query.eq('is_resolved', false);

    const { data, error } = await query;
    if (error) throw error;

    return c.json({ success: true, total: data?.length || 0, data });

  } catch (error) {
    console.error('Get device events error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}
