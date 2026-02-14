import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// Get last invoice for auto-increment
export async function getLastInvoice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('invoices')
      .select('invoice_number, invoice_date, period_to')
      .order('created_at', { ascending: false })
      .limit(1);

    if (error) throw error;

    // Generate next invoice number
    let nextInvoiceNumber = 'RENT/JAN/001';
    let suggestedPeriodFrom = null;

    if (data && data.length > 0) {
      const lastInvoice = data[0];
      const parts = lastInvoice.invoice_number.split('/');
      const lastNumber = parseInt(parts[2]) || 0;
      const currentMonth = new Date().toLocaleString('en-US', { month: 'short' }).toUpperCase();
      
      nextInvoiceNumber = `RENT/${currentMonth}/${String(lastNumber + 1).padStart(3, '0')}`;
      
      // Suggest period from as last period_to + 1 day
      if (lastInvoice.period_to) {
        const lastPeriodTo = new Date(lastInvoice.period_to);
        lastPeriodTo.setDate(lastPeriodTo.getDate() + 1);
        suggestedPeriodFrom = lastPeriodTo.toISOString().split('T')[0];
      }
    }

    return c.json({
      success: true,
      data: {
        lastInvoice: data?.[0] || null,
        suggestedInvoiceNumber: nextInvoiceNumber,
        suggestedPeriodFrom
      }
    });
  } catch (error) {
    console.error('Get last invoice error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch last invoice'
    }, 500);
  }
}

// Create invoice
export async function createInvoice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const body = await c.req.json();
    
    const {
      invoiceNumber,
      referenceNumber,
      clientId,
      invoiceDate,
      periodFrom,
      periodTo,
      dueDate,
      hasGst,
      items,
      previousOutstanding,
      notes
    } = body;

    if (!invoiceNumber || !clientId || !invoiceDate || !periodFrom || !periodTo) {
      return c.json({
        success: false,
        message: 'Missing required fields'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Check if invoice number already exists
    const { data: existing } = await supabase
      .from('invoices')
      .select('id')
      .eq('invoice_number', invoiceNumber)
      .single();

    if (existing) {
      return c.json({
        success: false,
        message: 'Invoice number already exists'
      }, 400);
    }

    // Calculate totals
    let subtotal = 0;
    items.forEach((item: any) => {
      subtotal += parseFloat(item.amount);
    });

    const gstAmount = hasGst ? (subtotal + (previousOutstanding || 0)) * 0.18 : 0;
    const totalAmount = subtotal + (previousOutstanding || 0) + gstAmount;

    // Create invoice
    const { data: invoice, error: invoiceError } = await supabase
      .from('invoices')
      .insert({
        invoice_number: invoiceNumber,
        reference_number: referenceNumber,
        client_id: clientId,
        invoice_date: invoiceDate,
        period_from: periodFrom,
        period_to: periodTo,
        due_date: dueDate,
        has_gst: hasGst,
        subtotal,
        previous_outstanding: previousOutstanding || 0,
        gst_amount: gstAmount,
        total_amount: totalAmount,
        notes
      })
      .select()
      .single();

    if (invoiceError) throw invoiceError;

    // Insert invoice items
    const itemsToInsert = items.map((item: any) => ({
      invoice_id: invoice.id,
      item_type: item.itemType,
      description: item.description,
      quantity: item.quantity,
      rate: item.rate,
      amount: item.amount,
      hsn_sac_code: item.hsnSacCode
    }));

    const { error: itemsError } = await supabase
      .from('invoice_items')
      .insert(itemsToInsert);

    if (itemsError) throw itemsError;

    return c.json({
      success: true,
      message: 'Invoice created successfully',
      data: invoice
    });
  } catch (error) {
    console.error('Create invoice error:', error);
    return c.json({
      success: false,
      message: 'Failed to create invoice'
    }, 500);
  }
}

// Get all invoices
export async function getInvoices(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('invoices')
      .select(`
        *,
        clients(company_name, owner_name, phone)
      `)
      .order('invoice_date', { ascending: false });

    if (error) throw error;

    return c.json({
      success: true,
      data: data || []
    });
  } catch (error) {
    console.error('Get invoices error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch invoices'
    }, 500);
  }
}

// Get single invoice with items
export async function getInvoice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    const { data: invoice, error: invoiceError } = await supabase
      .from('invoices')
      .select(`
        *,
        clients(*)
      `)
      .eq('id', id)
      .single();

    if (invoiceError || !invoice) {
      return c.json({
        success: false,
        message: 'Invoice not found'
      }, 404);
    }

    const { data: items, error: itemsError } = await supabase
      .from('invoice_items')
      .select('*')
      .eq('invoice_id', id);

    if (itemsError) throw itemsError;

    return c.json({
      success: true,
      data: {
        ...invoice,
        items: items || []
      }
    });
  } catch (error) {
    console.error('Get invoice error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch invoice'
    }, 500);
  }
}

// Mark invoice as paid
export async function markInvoicePaid(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { id } = c.req.param();
    const body = await c.req.json();
    
    const { paymentDate, amountPaid, paymentMode, paymentReference, paymentRemarks } = body;

    if (!paymentDate || !amountPaid) {
      return c.json({
        success: false,
        message: 'Missing required fields'
      }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Get invoice
    const { data: invoice, error: fetchError } = await supabase
      .from('invoices')
      .select('total_amount, amount_paid')
      .eq('id', id)
      .single();

    if (fetchError || !invoice) {
      return c.json({
        success: false,
        message: 'Invoice not found'
      }, 404);
    }

    const totalPaid = (invoice.amount_paid || 0) + parseFloat(amountPaid);
    const status = totalPaid >= invoice.total_amount ? 'PAID' : 'PARTIAL';

    const { error: updateError } = await supabase
      .from('invoices')
      .update({
        amount_paid: totalPaid,
        status,
        payment_date: paymentDate,
        payment_mode: paymentMode,
        payment_reference: paymentReference,
        payment_remarks: paymentRemarks,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (updateError) throw updateError;

    return c.json({
      success: true,
      message: `Invoice marked as ${status.toLowerCase()}`
    });
  } catch (error) {
    console.error('Mark paid error:', error);
    return c.json({
      success: false,
      message: 'Failed to update payment'
    }, 500);
  }
}

// Get client's last invoice
export async function getClientLastInvoice(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const { clientId } = c.req.param();
    const supabase = getSupabaseClient(c.env);

    const { data, error } = await supabase
      .from('invoices')
      .select('invoice_date, invoice_number, status')
      .eq('client_id', clientId)
      .order('invoice_date', { ascending: false })
      .limit(1);

    if (error) throw error;

    return c.json({
      success: true,
      data: data?.[0] || null
    });
  } catch (error) {
    console.error('Get client last invoice error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch last invoice'
    }, 500);
  }
}
