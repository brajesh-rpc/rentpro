import { Hono } from 'hono';
import { cors } from 'hono/cors';
import type { Env, JWTPayload } from './types';
import { testDatabaseConnection } from './utils/supabase';
import { loginHandler } from './auth/login';
import { logoutHandler } from './auth/logout';
import { authMiddleware, requireRole } from './middleware/auth';
import { getDashboardStats, getRecentActivity } from './dashboard/stats';

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
