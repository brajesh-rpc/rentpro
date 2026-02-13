import { createClient, SupabaseClient } from '@supabase/supabase-js';
import type { Env } from '../types';

// Initialize Supabase client
export function getSupabaseClient(env: Env): SupabaseClient {
  return createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
    auth: {
      persistSession: false, // No session persistence in Workers
      autoRefreshToken: false,
    },
  });
}

// Test database connection
export async function testDatabaseConnection(env: Env): Promise<boolean> {
  try {
    const supabase = getSupabaseClient(env);
    const { error } = await supabase.from('users').select('count').limit(1);
    return !error;
  } catch (error) {
    console.error('Database connection failed:', error);
    return false;
  }
}
