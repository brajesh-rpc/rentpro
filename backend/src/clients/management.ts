import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// Register new client
export async function registerClient(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();
    
    const {
      companyName,
      ownerName,
      phone,
      alternatePhone,
      email,
      whatsapp,
      businessType,
      gstNumber,
      panNumber,
      officeAddress,
      landmark,
      city,
      state,
      pincode,
      landlordContact,
      creditLimit,
      securityDeposit,
      latePenaltyPercent,
      status
    } = body;

    // Validation
    if (!companyName || !ownerName || !phone || !officeAddress || !city || !state || !pincode) {
      return c.json({
        success: false,
        message: 'Missing required fields'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Check if company already exists
    const { data: existing } = await supabase
      .from('clients')
      .select('id')
      .eq('company_name', companyName)
      .single();

    if (existing) {
      return c.json({
        success: false,
        message: 'Client with this company name already exists'
      }, 400);
    }

    // Insert client
    const { data, error } = await supabase
      .from('clients')
      .insert({
        company_name: companyName,
        owner_name: ownerName,
        phone,
        alternate_phone: alternatePhone,
        email,
        whatsapp,
        business_type: businessType,
        gst_number: gstNumber,
        pan_number: panNumber,
        office_address: officeAddress,
        landmark,
        city,
        state,
        pincode,
        landlord_contact: landlordContact,
        credit_limit: creditLimit || 0,
        security_deposit: securityDeposit || 0,
        late_penalty_percent: latePenaltyPercent || 0,
        status: status || 'ACTIVE'
      })
      .select()
      .single();

    if (error) {
      console.error('Insert client error:', error);
      return c.json({
        success: false,
        message: 'Failed to register client',
        error: error.message
      }, 500);
    }

    return c.json({
      success: true,
      message: 'Client registered successfully',
      data
    });

  } catch (error) {
    console.error('Register client error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}

// Get all clients
export async function getClients(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    return c.json({
      success: true,
      data
    });

  } catch (error) {
    console.error('Get clients error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch clients'
    }, 500);
  }
}

// Get single client
export async function getClient(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) {
      return c.json({
        success: false,
        message: 'Client not found'
      }, 404);
    }

    return c.json({
      success: true,
      data
    });

  } catch (error) {
    console.error('Get client error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}

// Update client
export async function updateClient(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const body = await c.req.json();
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('clients')
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
        message: 'Failed to update client'
      }, 500);
    }

    return c.json({
      success: true,
      message: 'Client updated successfully',
      data
    });

  } catch (error) {
    console.error('Update client error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}

// Delete client
export async function deleteClient(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    // Check if client exists
    const { data: client, error: fetchError } = await supabase
      .from('clients')
      .select('company_name')
      .eq('id', id)
      .single();

    if (fetchError || !client) {
      return c.json({
        success: false,
        message: 'Client not found'
      }, 404);
    }

    // Delete client (CASCADE will handle related records)
    const { error: deleteError } = await supabase
      .from('clients')
      .delete()
      .eq('id', id);

    if (deleteError) {
      console.error('Delete client error:', deleteError);
      return c.json({
        success: false,
        message: 'Failed to delete client'
      }, 500);
    }

    return c.json({
      success: true,
      message: `Client "${client.company_name}" deleted successfully`
    });

  } catch (error) {
    console.error('Delete client error:', error);
    return c.json({
      success: false,
      message: 'Internal server error'
    }, 500);
  }
}
