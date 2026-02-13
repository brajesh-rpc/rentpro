import { Context, Next } from 'hono';
import type { Env, JWTPayload, ApiResponse } from '../types';
import { extractToken, verifyToken } from '../utils/jwt';

// Extend context to include user info
export interface AuthContext {
  user: JWTPayload;
}

// Authentication middleware
export async function authMiddleware(
  c: Context<{ Bindings: Env }>,
  next: Next
): Promise<Response | void> {
  try {
    // Get Authorization header
    const authHeader = c.req.header('Authorization');
    
    // Extract token
    const token = extractToken(authHeader);
    
    if (!token) {
      return c.json<ApiResponse>({
        success: false,
        message: 'Authentication required. Please provide a valid token.',
        error: 'MISSING_TOKEN',
      }, 401);
    }

    // Verify token
    const payload = await verifyToken(token, c.env.JWT_SECRET);
    
    if (!payload) {
      return c.json<ApiResponse>({
        success: false,
        message: 'Invalid or expired token',
        error: 'INVALID_TOKEN',
      }, 401);
    }

    // Attach user info to context
    c.set('user', payload);

    // Continue to next handler
    await next();

  } catch (error) {
    console.error('Auth middleware error:', error);
    return c.json<ApiResponse>({
      success: false,
      message: 'Authentication failed',
      error: 'AUTH_ERROR',
    }, 401);
  }
}

// Role-based authorization middleware
export function requireRole(...allowedRoles: string[]) {
  return async (c: Context<{ Bindings: Env }>, next: Next): Promise<Response | void> => {
    const user = c.get('user') as JWTPayload;
    
    if (!user) {
      return c.json<ApiResponse>({
        success: false,
        message: 'Authentication required',
        error: 'MISSING_USER',
      }, 401);
    }

    if (!allowedRoles.includes(user.role)) {
      return c.json<ApiResponse>({
        success: false,
        message: 'Access denied. Insufficient permissions.',
        error: 'FORBIDDEN',
      }, 403);
    }

    await next();
  };
}
