import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// Add rental item to client
export async function addRentalItem(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();
    const { clientId, itemType, quantity, monthlyRent, effectiveDate, action } = body;

    if (!clientId || !itemType || !quantity || !monthlyRent || !effectiveDate) {
      return c.json({
        success: false,
        message: 'Missing required fields'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Check if item already exists for this client
    const { data: existing } = await supabase
      .from('rental_items')
      .select('*')
      .eq('client_id', clientId)
      .eq('item_type', itemType)
      .single();

    if (existing) {
      // Update existing item quantity
      const newQuantity = existing.quantity + quantity;
      
      const { data, error } = await supabase
        .from('rental_items')
        .update({ 
          quantity: newQuantity,
          monthly_rent: monthlyRent,
          updated_at: new Date().toISOString()
        })
        .eq('id', existing.id)
        .select()
        .single();

      if (error) throw error;

      // Record history
      await supabase.from('rental_item_history').insert({
        client_id: clientId,
        item_type: itemType,
        action: 'ADDED',
        quantity,
        monthly_rent: monthlyRent,
        effective_date: effectiveDate,
        notes: `Added ${quantity} items. New total: ${newQuantity}`
      });

      return c.json({
        success: true,
        message: 'Rental item updated successfully',
        data
      });
    } else {
      // Create new rental item
      const { data, error } = await supabase
        .from('rental_items')
        .insert({
          client_id: clientId,
          item_type: itemType,
          quantity,
          monthly_rent: monthlyRent
        })
        .select()
        .single();

      if (error) throw error;

      // Record history
      await supabase.from('rental_item_history').insert({
        client_id: clientId,
        item_type: itemType,
        action: 'ADDED',
        quantity,
        monthly_rent: monthlyRent,
        effective_date: effectiveDate,
        notes: `Initial addition of ${quantity} items`
      });

      return c.json({
        success: true,
        message: 'Rental item added successfully',
        data
      });
    }
  } catch (error) {
    console.error('Add rental item error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}

// Get rental items for a client
export async function getClientRentalItems(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { clientId } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('rental_items')
      .select('*')
      .eq('client_id', clientId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return c.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Get rental items error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch rental items'
    }, 500);
  }
}

// Get rental item history
export async function getRentalItemHistory(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { clientId } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('rental_item_history')
      .select('*')
      .eq('client_id', clientId)
      .order('effective_date', { ascending: false })
      .limit(50);

    if (error) throw error;

    return c.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Get rental history error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch history'
    }, 500);
  }
}

// Remove/reduce rental item
export async function removeRentalItem(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const body = await c.req.json();
    const { quantity, effectiveDate } = body;

    if (!quantity || !effectiveDate) {
      return c.json({
        success: false,
        message: 'Missing required fields'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Get current item
    const { data: item, error: fetchError } = await supabase
      .from('rental_items')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !item) {
      return c.json({
        success: false,
        message: 'Rental item not found'
      }, 404);
    }

    if (quantity > item.quantity) {
      return c.json({
        success: false,
        message: 'Cannot remove more than current quantity'
      }, 400);
    }

    const newQuantity = item.quantity - quantity;

    if (newQuantity === 0) {
      // Remove item completely
      const { error: deleteError } = await supabase
        .from('rental_items')
        .delete()
        .eq('id', id);

      if (deleteError) throw deleteError;
    } else {
      // Update quantity
      const { error: updateError } = await supabase
        .from('rental_items')
        .update({ 
          quantity: newQuantity,
          updated_at: new Date().toISOString()
        })
        .eq('id', id);

      if (updateError) throw updateError;
    }

    // Record history
    await supabase.from('rental_item_history').insert({
      client_id: item.client_id,
      item_type: item.item_type,
      action: 'REMOVED',
      quantity,
      monthly_rent: item.monthly_rent,
      effective_date: effectiveDate,
      notes: `Removed ${quantity} items. ${newQuantity === 0 ? 'Item fully removed' : `New total: ${newQuantity}`}`
    });

    return c.json({
      success: true,
      message: 'Rental item updated successfully'
    });
  } catch (error) {
    console.error('Remove rental item error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}
