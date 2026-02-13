import { Context } from 'hono';
import type { Env, ApiResponse } from '../types';

export async function logoutHandler(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    // Since we're using stateless JWT, logout is handled on client-side
    // by removing the token from storage
    
    // We can optionally log the logout action or blacklist the token
    // For now, just return success
    
    return c.json<ApiResponse>({
      success: true,
      message: 'Logout successful',
    });

  } catch (error) {
    console.error('Logout error:', error);
    return c.json<ApiResponse>({
      success: false,
      message: 'Internal server error',
    }, 500);
  }
}
