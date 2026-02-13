// Environment variables type definition
export interface Env {
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  JWT_SECRET: string;
}

// User type from database
export interface User {
  id: string;
  email: string;
  password_hash: string;
  full_name: string;
  role: 'super_admin' | 'admin' | 'staff' | 'end_user';
  phone?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// Login request body
export interface LoginRequest {
  email: string;
  password: string;
}

// Login response
export interface LoginResponse {
  success: boolean;
  message: string;
  data?: {
    token: string;
    user: {
      id: string;
      email: string;
      full_name: string;
      role: string;
    };
  };
}

// JWT payload
export interface JWTPayload {
  userId: string;
  email: string;
  role: string;
  iat?: number;
  exp?: number;
}

// API Response wrapper
export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: string;
}
