-- Create Test Users for RentComPro
-- Run this in Supabase SQL Editor

-- Note: Password hashing is done using SHA-256 in our backend
-- For testing, we'll create users with pre-hashed passwords

-- Password for all test users: "password123"
-- SHA-256 hash of "password123": ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f

-- 1. Super Admin User
INSERT INTO users (
  email,
  password_hash,
  name,
  role,
  phone,
  is_active
) VALUES (
  'admin@rentcompro.com',
  'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
  'Super Admin',
  'SUPER_ADMIN',
  '9876543210',
  true
);

-- 2. Staff User
INSERT INTO users (
  email,
  password_hash,
  name,
  role,
  phone,
  is_active
) VALUES (
  'staff@rentcompro.com',
  'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f',
  'Staff Member',
  'STAFF',
  '9876543212',
  true
);

-- Verify users created
SELECT 
  id,
  email,
  name,
  role,
  is_active,
  created_at
FROM users
ORDER BY created_at DESC;
