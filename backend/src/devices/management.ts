import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// Add new device
export async function addDevice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();
    
    const {
      deviceName,
      serialNumber,
      lanMacAddress,        // NEW: LAN MAC (permanent ID)
      activeMacAddress,     // NEW: Active connection MAC  
      activeConnectionType, // NEW: LAN/WIFI/DONGLE
      deviceType,
      brand,
      model,
      processor,
      ramGb,
      storageGb,
      storageType,
      monitorSize,
      purchaseDate,
      purchasePrice,
      monthlyRent,
      securityDeposit,
      condition,
      status
    } = body;

    // Validation - deviceName and MAC can be optional for manual entry
    if (!serialNumber || !deviceType || !processor || !ramGb || !storageGb || !monthlyRent) {
      return c.json({
        success: false,
        message: 'Missing required fields'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Check if serial number already exists
    const { data: existing } = await supabase
      .from('devices')
      .select('id')
      .eq('serial_number', serialNumber)
      .single();

    if (existing) {
      return c.json({
        success: false,
        message: 'Device with this serial number already exists'
      }, 400);
    }

    // Insert device with new MAC fields
    const { data, error } = await supabase
      .from('devices')
      .insert({
        device_name: deviceName,                    // NEW
        serial_number: serialNumber,
        lan_mac_address: lanMacAddress,             // NEW
        active_mac_address: activeMacAddress,       // NEW
        active_connection_type: activeConnectionType, // NEW
        device_type: deviceType,
        brand: brand || 'Generic',
        model: model || 'Unknown',
        processor,
        ram_gb: ramGb,
        storage_gb: storageGb,
        storage_type: storageType,
        monitor_size: monitorSize,
        purchase_date: purchaseDate,
        purchase_price: purchasePrice,
        monthly_rent: monthlyRent,
        security_deposit: securityDeposit,
        condition: condition || 'GOOD',
        status: status || 'AVAILABLE'
      })
      .select()
      .single();

    if (error) {
      console.error('Insert device error:', error);
      return c.json({
        success: false,
        message: 'Failed to add device',
        error: error.message
      }, 500);
    }

    return c.json({
      success: true,
      message: 'Device added successfully',
      data
    });

  } catch (error) {
    console.error('Add device error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}

// Get all devices
export async function getDevices(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('devices')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    return c.json({
      success: true,
      data
    });

  } catch (error) {
    console.error('Get devices error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch devices'
    }, 500);
  }
}

// Get single device
export async function getDevice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('devices')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) {
      return c.json({
        success: false,
        message: 'Device not found'
      }, 404);
    }

    return c.json({
      success: true,
      data
    });

  } catch (error) {
    console.error('Get device error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}

// Update device
export async function updateDevice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const body = await c.req.json();
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('devices')
      .update({
        ...body,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return c.json({
        success: false,
        message: 'Failed to update device'
      }, 500);
    }

    return c.json({
      success: true,
      message: 'Device updated successfully',
      data
    });

  } catch (error) {
    console.error('Update device error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}

// ============================================
// PUBLIC: Self-register from installer (no auth)
// ============================================
export async function selfRegisterDevice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();
    const { deviceName, clientName, lanMacAddress, deviceType, rollNumber, serialNumber, brand, model, processor, ramGb, storageGb, storageType, monthlyRent } = body;

    if (!lanMacAddress) {
      return c.json({ success: false, message: 'LAN MAC address zaroori hai' }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Check if MAC already registered
    const { data: existing } = await supabase
      .from('devices')
      .select('id, device_name, status')
      .eq('lan_mac_address', lanMacAddress)
      .single();

    if (existing) {
      return c.json({
        success: true,
        message: 'Device already registered',
        data: existing,
        alreadyExists: true
      });
    }

    // Check roll number uniqueness
    const { data: rollExists } = await supabase
      .from('devices')
      .select('id')
      .eq('roll_number', rollNumber)
      .single();

    const finalRollNumber = rollExists ? null : rollNumber;

    // Insert as PENDING
    const { data, error } = await supabase
      .from('devices')
      .insert({
        device_name:    deviceName || model,
        client_name:    clientName || null,
        lan_mac_address: lanMacAddress,
        serial_number:  serialNumber || lanMacAddress.replace(/:/g, ''),
        device_type:    deviceType || 'DESKTOP',
        roll_number:    finalRollNumber,
        brand:          brand || 'Generic',
        model:          model || 'Unknown',
        processor:      processor || null,
        ram_gb:         ramGb || null,
        storage_gb:     storageGb || null,
        storage_type:   storageType || 'HDD',
        monthly_rent:   monthlyRent || 0,
        status:         'PENDING',
        condition:      'GOOD'
      })
      .select()
      .single();

    if (error) {
      console.error('Self-register error:', error);
      return c.json({ success: false, message: 'Registration failed', error: error.message }, 500);
    }

    return c.json({ success: true, message: 'Device registered as PENDING', data });

  } catch (error) {
    console.error('Self-register error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}

// PUBLIC: Get device count (for roll number)
export async function getDeviceCount(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);
    const { count, error } = await supabase
      .from('devices')
      .select('*', { count: 'exact', head: true });

    if (error) throw error;
    return c.json({ success: true, count: count || 0 });
  } catch (error) {
    return c.json({ success: false, count: 0 });
  }
}

// Delete device
export async function deleteDevice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    const { error } = await supabase
      .from('devices')
      .delete()
      .eq('id', id);

    if (error) {
      return c.json({
        success: false,
        message: 'Failed to delete device'
      }, 500);
    }

    return c.json({
      success: true,
      message: 'Device deleted successfully'
    });

  } catch (error) {
    console.error('Delete device error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}
