import { Context } from 'hono';
import type { Env } from '../types';
import { getSupabaseClient } from '../utils/supabase';

// Dashboard stats interface
export interface DashboardStats {
  totalDevices: number;
  activeDevices: number;
  availableDevices: number;
  maintenanceDevices: number;
  totalClients: number;
  activeClients: number;
  overdueClients: number;
  totalRevenue: number;
  pendingPayments: number;
  paymentsThisMonth: number;
  devicesDeployed: number;
}

// Recent activity interface
export interface RecentActivity {
  id: string;
  type: string;
  message: string;
  timestamp: string;
  user?: string;
}

export async function getDashboardStats(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    // Fetch devices statistics
    const { data: devices, error: devicesError } = await supabase
      .from('devices')
      .select('status');

    if (devicesError) throw devicesError;

    // Fetch clients statistics
    const { data: clients, error: clientsError } = await supabase
      .from('clients')
      .select('status');

    if (clientsError) throw clientsError;

    // Fetch payments statistics
    const { data: payments, error: paymentsError } = await supabase
      .from('payments')
      .select('amount, payment_date, status');

    if (paymentsError) throw paymentsError;

    // Calculate device stats
    const totalDevices = devices?.length || 0;
    const activeDevices = devices?.filter(d => d.status === 'DEPLOYED').length || 0;
    const availableDevices = devices?.filter(d => d.status === 'AVAILABLE').length || 0;
    const maintenanceDevices = devices?.filter(d => d.status === 'MAINTENANCE').length || 0;

    // Calculate client stats
    const totalClients = clients?.length || 0;
    const activeClients = clients?.filter(c => c.status === 'ACTIVE').length || 0;
    const overdueClients = clients?.filter(c => c.status === 'OVERDUE').length || 0;

    // Calculate payment stats
    const totalRevenue = payments?.reduce((sum, p) => sum + (parseFloat(p.amount) || 0), 0) || 0;
    const pendingPayments = payments?.filter(p => p.status === 'PENDING' || p.status === 'OVERDUE')
      .reduce((sum, p) => sum + (parseFloat(p.amount) || 0), 0) || 0;

    // Payments this month
    const currentMonth = new Date().toISOString().substring(0, 7); // YYYY-MM format
    const paymentsThisMonth = payments?.filter(p => p.payment_date?.startsWith(currentMonth))
      .reduce((sum, p) => sum + (parseFloat(p.amount) || 0), 0) || 0;

    const stats: DashboardStats = {
      totalDevices,
      activeDevices,
      availableDevices,
      maintenanceDevices,
      totalClients,
      activeClients,
      overdueClients,
      totalRevenue,
      pendingPayments,
      paymentsThisMonth,
      devicesDeployed: activeDevices,
    };

    return c.json({
      success: true,
      message: 'Dashboard stats retrieved successfully',
      data: {
        stats,
        lastUpdated: new Date().toISOString(),
      },
    });

  } catch (error) {
    console.error('Dashboard stats error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch dashboard stats',
      error: error instanceof Error ? error.message : 'Unknown error',
    }, 500);
  }
}

export async function getRecentActivity(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const supabase = getSupabaseClient(c.env);

    // Fetch recent payments
    const { data: recentPayments, error: paymentsError } = await supabase
      .from('payments')
      .select('id, amount, payment_date, client_id, clients(company_name)')
      .order('payment_date', { ascending: false })
      .limit(5);

    if (paymentsError) throw paymentsError;

    // Fetch recent devices
    const { data: recentDevices, error: devicesError } = await supabase
      .from('devices')
      .select('id, serial_number, status, updated_at')
      .order('updated_at', { ascending: false })
      .limit(5);

    if (devicesError) throw devicesError;

    // Combine and format activities
    const activities: RecentActivity[] = [];

    // Add payment activities
    recentPayments?.forEach(payment => {
      activities.push({
        id: payment.id,
        type: 'payment',
        message: `Payment of ₹${payment.amount} received from ${payment.clients?.company_name || 'Unknown'}`,
        timestamp: payment.payment_date,
      });
    });

    // Add device activities
    recentDevices?.forEach(device => {
      let action = 'updated';
      if (device.status === 'DEPLOYED') action = 'deployed';
      if (device.status === 'AVAILABLE') action = 'made available';
      if (device.status === 'MAINTENANCE') action = 'sent for maintenance';

      activities.push({
        id: device.id,
        type: 'device',
        message: `Device ${device.serial_number} ${action}`,
        timestamp: device.updated_at,
      });
    });

    // Sort by timestamp and take top 10
    activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
    const recentActivities = activities.slice(0, 10);

    return c.json({
      success: true,
      message: 'Recent activities retrieved successfully',
      data: {
        activities: recentActivities,
      },
    });

  } catch (error) {
    console.error('Recent activity error:', error);
    return c.json({
      success: false,
      message: 'Failed to fetch recent activities',
      error: error instanceof Error ? error.message : 'Unknown error',
    }, 500);
  }
}
