import { Context } from 'hono';
import type { Env, JWTPayload } from '../types';
import { getSupabaseClient } from '../utils/supabase';
import { verifyPassword, hashPassword } from '../utils/password';

export async function changePasswordHandler(c: Context<{ Bindings: Env }>): Promise<Response> {
  try {
    const user = c.get('user') as JWTPayload;
    const body = await c.req.json<{ currentPassword: string; newPassword: string }>();
    const { currentPassword, newPassword } = body;

    // Validation
    if (!currentPassword || !newPassword) {
      return c.json({ success: false, message: 'Current password and new password are required' }, 400);
    }

    if (newPassword.length < 6) {
      return c.json({ success: false, message: 'New password must be at least 6 characters' }, 400);
    }

    const supabase = getSupabaseClient(c.env);

    // Fetch user from DB to get current password hash
    const { data: users, error } = await supabase
      .from('users')
      .select('id, password_hash, is_active')
      .eq('id', user.userId)
      .limit(1);

    if (error || !users || users.length === 0) {
      return c.json({ success: false, message: 'User not found' }, 404);
    }

    const dbUser = users[0];

    if (!dbUser.is_active) {
      return c.json({ success: false, message: 'Account is deactivated' }, 403);
    }

    // Verify current password
    const isCurrentValid = await verifyPassword(currentPassword, dbUser.password_hash);
    if (!isCurrentValid) {
      return c.json({ success: false, message: 'Current password is incorrect' }, 401);
    }

    // Hash new password
    const newHash = await hashPassword(newPassword);

    // Update in DB
    const { error: updateError } = await supabase
      .from('users')
      .update({ password_hash: newHash, updated_at: new Date().toISOString() })
      .eq('id', user.userId);

    if (updateError) {
      return c.json({ success: false, message: 'Failed to update password' }, 500);
    }

    return c.json({ success: true, message: 'Password updated successfully' });

  } catch (error) {
    console.error('Change password error:', error);
    return c.json({ success: false, message: 'Internal server error' }, 500);
  }
}
