import { Context } from 'hono';
import type { Env, LoginRequest, LoginResponse, User } from '../types';
import { getSupabaseClient } from '../utils/supabase';
import { verifyPassword } from '../utils/password';
import { generateToken } from '../utils/jwt';

export async function loginHandler(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    // Parse request body
    const body = await c.req.json<LoginRequest>();
    const { email, password } = body;

    // Validation
    if (!email || !password) {
      return c.json<LoginResponse>({
        success: false,
        message: 'Email and password are required',
      }, 400);
    }

    // Get Supabase client
    const supabase = getSupabaseClient(c.env);

    // Find user by email
    const { data: users, error } = await supabase
      .from('users')
      .select('*')
      .eq('email', email.toLowerCase())
      .limit(1);

    if (error || !users || users.length === 0) {
      return c.json<LoginResponse>({
        success: false,
        message: 'Invalid email or password',
      }, 401);
    }

    const user = users[0] as User;

    // Check if user is active
    if (!user.is_active) {
      return c.json<LoginResponse>({
        success: false,
        message: 'Account is deactivated. Please contact administrator.',
      }, 403);
    }

    // Verify password
    const isPasswordValid = await verifyPassword(password, user.password_hash);

    if (!isPasswordValid) {
      return c.json<LoginResponse>({
        success: false,
        message: 'Invalid email or password',
      }, 401);
    }

    // Generate JWT token
    const token = await generateToken(
      {
        userId: user.id,
        email: user.email,
        role: user.role,
      },
      c.env.JWT_SECRET
    );

    // Update last login timestamp
    await supabase
      .from('users')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', user.id);

    // Return success response
    return c.json<LoginResponse>({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          full_name: user.full_name,
          role: user.role,
        },
      },
    });

  } catch (error) {
    console.error('Login error:', error);
    return c.json<LoginResponse>({
      success: false,
      message: 'Internal server error',
    }, 500);
  }
}
