import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// Receive hardware stats from agent
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
      timestamp,
      // NEW: Network information
      lanMacAddress,
      activeMacAddress,
      connectionType,
      ipAddress,
      computerName
    } = body;

    console.log('Received stats from device:', deviceId);
    console.log('MAC addresses - LAN:', lanMacAddress, 'Active:', activeMacAddress);

    // Validation
    if (!deviceId) {
      return c.json({
        success: false,
        message: 'Missing deviceId'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Find device by device_name or serial_number
    const { data: device, error: findError } = await supabase
      .from('devices')
      .select('id, status')
      .or(`device_name.eq.${deviceId},serial_number.eq.${deviceId}`)
      .single();

    if (findError || !device) {
      console.log('Device not found:', deviceId);
      return c.json({
        success: false,
        message: 'Device not found',
        lockStatus: false
      }, 404);
    }

    // Update device with latest stats and MAC addresses
    const updateData: any = {
      is_online: true,
      last_seen: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // Update MAC addresses if provided
    if (lanMacAddress) {
      updateData.lan_mac_address = lanMacAddress;
    }
    if (activeMacAddress) {
      updateData.active_mac_address = activeMacAddress;
    }
    if (connectionType) {
      updateData.active_connection_type = connectionType;
    }

    const { error: updateError } = await supabase
      .from('devices')
      .update(updateData)
      .eq('id', device.id);

    if (updateError) {
      console.error('Error updating device:', updateError);
    } else {
      console.log('Device updated with MAC addresses:', lanMacAddress);
    }

    // Insert hardware stats
    const { error: statsError } = await supabase
      .from('hardware_stats')
      .insert({
        device_id: device.id,
        cpu_usage: cpuUsage,
        ram_usage: ramUsage,
        ram_total_gb: ramTotal,
        ram_used_gb: ramUsed,
        disk_usage: diskUsage,
        disk_total_gb: diskTotal,
        disk_used_gb: diskUsed,
        is_online: isOnline,
        current_user: currentUser,
        recorded_at: timestamp || new Date().toISOString()
      });

    if (statsError) {
      console.error('Error inserting stats:', statsError);
    }

    // Check if device should be locked
    const shouldLock = device.status === 'LOCKED' || device.status === 'STOLEN';

    return c.json({
      success: true,
      message: 'Stats received',
      lockStatus: shouldLock,
      deviceStatus: device.status
    });

  } catch (error) {
    console.error('Receive stats error:', error);
    return c.json({
      success: false,
      message: 'Internal server error',
      lockStatus: false
    }, 500);
  }
}
