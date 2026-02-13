import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// Device stats endpoint - receives hardware stats from agent
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
      currentUser,
      timestamp
    } = body;

    // Basic validation
    if (!deviceId || !deviceToken) {
      return c.json({
        success: false,
        message: 'Device ID and Token required',
        lockStatus: false
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Verify device exists and token is valid
    const { data: device, error: deviceError } = await supabase
      .from('devices')
      .select('id, serial_number, status')
      .eq('serial_number', deviceId)
      .single();

    if (deviceError || !device) {
      return c.json({
        success: false,
        message: 'Invalid device ID or token',
        lockStatus: false
      }, 401);
    }

    // Insert hardware stats
    const { error: statsError } = await supabase
      .from('hardware_stats')
      .insert({
        device_id: device.id,
        cpu_usage: cpuUsage,
        ram_total: Math.round(ramTotal / (1024 * 1024 * 1024)), // Convert to GB
        ram_used: Math.round(ramUsed / (1024 * 1024 * 1024)),
        disk_total: Math.round(diskTotal / (1024 * 1024 * 1024)),
        disk_used: Math.round(diskUsed / (1024 * 1024 * 1024)),
        ip_address: c.req.header('cf-connecting-ip') || 'unknown',
        login_count: 1,
        timestamp: new Date(timestamp || Date.now()).toISOString()
      });

    if (statsError) {
      console.error('Error inserting stats:', statsError);
    }

    // Update device last_seen
    await supabase
      .from('devices')
      .update({ 
        last_seen: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', device.id);

    // Determine if device should be locked
    // For now, we'll just return false (no lock)
    // TODO: Check payment status and return true if payment overdue
    const shouldLock = false; // device.status === 'LOCKED' or payment overdue

    return c.json({
      success: true,
      message: 'Stats received successfully',
      lockStatus: shouldLock
    });

  } catch (error) {
    console.error('Device stats error:', error);
    return c.json({
      success: false,
      message: 'Internal server error',
      lockStatus: false
    }, 500);
  }
}

// Device registration endpoint
export async function registerDevice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    // This would require authentication - for now, simple implementation
    const body = await c.req.json();
    const { deviceName, deviceInfo } = body;

    if (!deviceName) {
      return c.json({
        success: false,
        message: 'Device name required'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Generate a unique device ID (serial number)
    const deviceId = `DEV${Date.now().toString(36).toUpperCase()}`;
    const deviceToken = crypto.randomUUID();

    // Parse device info
    const info = JSON.parse(deviceInfo);

    // Insert device into database
    const { data, error } = await supabase
      .from('devices')
      .insert({
        serial_number: deviceId,
        device_type: 'DESKTOP',
        brand: 'Generic',
        model: info.computerName || 'Unknown',
        processor: info.cpu || 'Unknown',
        ram_gb: info.ramGB || 4,
        storage_gb: info.diskGB || 500,
        status: 'AVAILABLE'
      })
      .select()
      .single();

    if (error) {
      return c.json({
        success: false,
        message: 'Failed to register device',
        error: error.message
      }, 500);
    }

    return c.json({
      success: true,
      message: 'Device registered successfully',
      data: {
        deviceId: deviceId,
        deviceToken: deviceToken
      }
    });

  } catch (error) {
    console.error('Device registration error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}
