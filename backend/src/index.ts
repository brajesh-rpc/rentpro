import { Hono } from 'hono';
import { cors } from 'hono/cors';
import type { Env, JWTPayload } from './types';
import { testDatabaseConnection } from './utils/supabase';
import { loginHandler } from './auth/login';
import { logoutHandler } from './auth/logout';
import { authMiddleware, requireRole } from './middleware/auth';
import { getDashboardStats, getRecentActivity } from './dashboard/stats';
import { receiveDeviceStats } from './devices/stats';
import { addDevice, getDevices } from './devices/management';
import { registerClient, getClients, getClient, updateClient } from './clients/management';
import { addRentalItem, getClientRentalItems, getRentalItemHistory, removeRentalItem } from './rental-items/management';
import { getLastInvoice, createInvoice, getInvoices, getInvoice, markInvoicePaid, getClientLastInvoice } from './invoices/management';
import { getItems, getActiveItems, getItem, createItem, updateItem, toggleItemActive, deleteItem } from './items/management';

const app = new Hono<{ Bindings: Env }>();

// Enable CORS for all routes
app.use('/*', cors());

// ============================================
// PUBLIC ROUTES (No authentication required)
// ============================================

// Health check endpoint
app.get('/', (c) => {
  return c.json({
    success: true,
    message: 'RentComPro Backend API is running!',
    version: '1.0.0',
    endpoints: {
      health: 'GET /',
      testConnection: 'GET /api/test-connection',
      login: 'POST /api/auth/login',
      logout: 'POST /api/auth/logout',
      profile: 'GET /api/auth/profile (protected)',
      dashboard: 'GET /api/dashboard (protected)',
    },
  });
});

// Test Supabase connection
app.get('/api/test-connection', async (c) => {
  try {
    const isConnected = await testDatabaseConnection(c.env);
    
    if (isConnected) {
      return c.json({
        success: true,
        message: 'Supabase connection successful!',
        supabase_url: c.env.SUPABASE_URL,
      });
    } else {
      return c.json({
        success: false,
        message: 'Supabase connection failed',
      }, 500);
    }
  } catch (error) {
    return c.json({
      success: false,
      message: 'Error testing connection',
      error: error instanceof Error ? error.message : 'Unknown error',
    }, 500);
  }
});

// ============================================
// AUTH ROUTES
// ============================================

// Login endpoint
app.post('/api/auth/login', loginHandler);

// Device Stats endpoint (Public - no auth required for agents)
app.post('/api/devices/stats', receiveDeviceStats);

// Device Management (Protected - Admin only)
app.post('/api/devices', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), addDevice);
app.get('/api/devices', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getDevices);

// Client Management (Protected - Admin only)
app.post('/api/clients', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), registerClient);
app.get('/api/clients', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getClients);
app.get('/api/clients/:id', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getClient);
app.put('/api/clients/:id', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), updateClient);

// Rental Items Management (Protected - Admin only)
app.post('/api/rental-items', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), addRentalItem);
app.get('/api/rental-items/client/:clientId', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getClientRentalItems);
app.get('/api/rental-items/history/:clientId', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getRentalItemHistory);
app.delete('/api/rental-items/:id', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), removeRentalItem);

// Invoice Management (Protected - Admin only)
app.get('/api/invoices/last', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getLastInvoice);
app.post('/api/invoices', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), createInvoice);
app.get('/api/invoices', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getInvoices);
app.get('/api/invoices/:id', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getInvoice);
app.post('/api/invoices/:id/pay', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), markInvoicePaid);
app.get('/api/invoices/client/:clientId/last', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getClientLastInvoice);

// Item Master Management (Protected - Admin only)
app.get('/api/items', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getItems);
app.get('/api/items/active', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getActiveItems);
app.get('/api/items/:id', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getItem);
app.post('/api/items', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), createItem);
app.put('/api/items/:id', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), updateItem);
app.put('/api/items/:id/toggle', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), toggleItemActive);
app.delete('/api/items/:id', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), deleteItem);

// Logout endpoint
app.post('/api/auth/logout', logoutHandler);

// ============================================
// PROTECTED ROUTES (Authentication required)
// ============================================

// Get current user profile
app.get('/api/auth/profile', authMiddleware, (c) => {
  const user = c.get('user') as JWTPayload;
  
  return c.json({
    success: true,
    message: 'Profile retrieved successfully',
    data: {
      userId: user.userId,
      email: user.email,
      role: user.role,
    },
  });
});

// Dashboard stats - Real data from Supabase (Only for SUPER_ADMIN and STAFF)
app.get('/api/dashboard/stats', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getDashboardStats);

// Recent activity feed (Only for SUPER_ADMIN and STAFF)
app.get('/api/dashboard/activity', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), getRecentActivity);

// Legacy dashboard endpoint (kept for backwards compatibility)
app.get('/api/dashboard', authMiddleware, requireRole('SUPER_ADMIN', 'STAFF'), (c) => {
  const user = c.get('user') as JWTPayload;
  
  return c.json({
    success: true,
    message: 'Dashboard data retrieved',
    data: {
      message: `Welcome ${user.email}!`,
      role: user.role,
      note: 'Use /api/dashboard/stats for real statistics',
    },
  });
});

// Test protected route for all authenticated users
app.get('/api/test-protected', authMiddleware, (c) => {
  const user = c.get('user') as JWTPayload;
  
  return c.json({
    success: true,
    message: 'You are authenticated!',
    data: {
      user: {
        userId: user.userId,
        email: user.email,
        role: user.role,
      },
    },
  });
});

// ============================================
// 404 Handler
// ============================================

app.notFound((c) => {
  return c.json({
    success: false,
    message: 'Endpoint not found',
    error: '404_NOT_FOUND',
  }, 404);
});

// ============================================
// Error Handler
// ============================================

app.onError((err, c) => {
  console.error('Global error:', err);
  return c.json({
    success: false,
    message: 'Internal server error',
    error: err.message,
  }, 500);
});

export default app;
