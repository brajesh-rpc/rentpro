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

    // Validation
    if (!deviceName || !serialNumber || !deviceType || !processor || !ramGb || !storageGb || !monthlyRent) {
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

    // Insert device
    const { data, error } = await supabase
      .from('devices')
      .insert({
        serial_number: serialNumber,
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
