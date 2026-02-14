import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// Get all items
export async function getItems(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('item_master')
      .select('*')
      .order('category', { ascending: true })
      .order('item_name', { ascending: true });

    if (error) throw error;

    return c.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Get items error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch items'
    }, 500);
  }
}

// Get active items only (for dropdowns)
export async function getActiveItems(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('item_master')
      .select('*')
      .eq('is_active', true)
      .order('category', { ascending: true })
      .order('item_name', { ascending: true });

    if (error) throw error;

    return c.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Get active items error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch active items'
    }, 500);
  }
}

// Get single item
export async function getItem(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('item_master')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) {
      return c.json({
        success: false,
        message: 'Item not found'
      }, 404);
    }

    return c.json({
      success: true,
      data
    });
  } catch (error) {
    console.error('Get item error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch item'
    }, 500);
  }
}

// Create new item
export async function createItem(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();
    
    const {
      itemCode,
      itemName,
      category,
      itemType,
      description,
      defaultRate,
      hsnSacCode
    } = body;

    if (!itemCode || !itemName || !category || !itemType || !defaultRate) {
      return c.json({
        success: false,
        message: 'Missing required fields'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Check if item code already exists
    const { data: existing } = await supabase
      .from('item_master')
      .select('id')
      .eq('item_code', itemCode)
      .single();

    if (existing) {
      return c.json({
        success: false,
        message: 'Item code already exists'
      }, 400);
    }

    const { data, error } = await supabase
      .from('item_master')
      .insert({
        item_code: itemCode,
        item_name: itemName,
        category,
        item_type: itemType,
        description,
        default_rate: defaultRate,
        hsn_sac_code: hsnSacCode
      })
      .select()
      .single();

    if (error) throw error;

    return c.json({
      success: true,
      message: 'Item created successfully',
      data
    });
  } catch (error) {
    console.error('Create item error:', error);
    return c.json({
      success: false,
      message: 'Failed to create item'
    }, 500);
  }
}

// Update item
export async function updateItem(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const body = await c.req.json();
    
    const {
      itemName,
      category,
      itemType,
      description,
      defaultRate,
      hsnSacCode
    } = body;

    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('item_master')
      .update({
        item_name: itemName,
        category,
        item_type: itemType,
        description,
        default_rate: defaultRate,
        hsn_sac_code: hsnSacCode,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return c.json({
      success: true,
      message: 'Item updated successfully',
      data
    });
  } catch (error) {
    console.error('Update item error:', error);
    return c.json({
      success: false,
      message: 'Failed to update item'
    }, 500);
  }
}

// Toggle item active status
export async function toggleItemActive(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const body = await c.req.json();
    const { is_active } = body;

    const supabase = getSupabaseClient(c.env);

    const { error } = await supabase
      .from('item_master')
      .update({
        is_active,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (error) throw error;

    return c.json({
      success: true,
      message: `Item ${is_active ? 'enabled' : 'disabled'} successfully`
    });
  } catch (error) {
    console.error('Toggle item error:', error);
    return c.json({
      success: false,
      message: 'Failed to update item status'
    }, 500);
  }
}

// Delete item (soft delete - set inactive)
export async function deleteItem(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    // Soft delete - just set is_active to false
    const { error } = await supabase
      .from('item_master')
      .update({
        is_active: false,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (error) throw error;

    return c.json({
      success: true,
      message: 'Item deleted successfully'
    });
  } catch (error) {
    console.error('Delete item error:', error);
    return c.json({
      success: false,
      message: 'Failed to delete item'
    }, 500);
  }
}
