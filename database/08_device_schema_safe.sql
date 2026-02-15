-- ============================================
-- RentComPro Device Schema - Safe Migration
-- Version: 2.0.1
-- Date: February 15, 2026
-- Status: PENDING - Run in Supabase
-- ============================================

-- This is a SAFE migration that doesn't assume existing columns
-- It only ADDS new columns without touching existing ones

-- ============================================
-- Step 1: Add new columns (safe - won't fail if already exist)
-- ============================================

-- Human-friendly device name
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS device_name VARCHAR(100);

-- LAN MAC address (permanent identifier)
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS lan_mac_address VARCHAR(17);

-- Active connection tracking
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS active_mac_address VARCHAR(17);

-- Connection type
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS active_connection_type VARCHAR(20);

-- ============================================
-- Step 2: Add unique constraints
-- ============================================

-- Make device_name unique (if constraint doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'devices_device_name_key'
    ) THEN
        ALTER TABLE devices ADD CONSTRAINT devices_device_name_key UNIQUE (device_name);
    END IF;
END $$;

-- Make lan_mac_address unique (if constraint doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'devices_lan_mac_address_key'
    ) THEN
        ALTER TABLE devices ADD CONSTRAINT devices_lan_mac_address_key UNIQUE (lan_mac_address);
    END IF;
END $$;

-- ============================================
-- Step 3: Add check constraint for connection type
-- ============================================

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'check_connection_type'
    ) THEN
        ALTER TABLE devices 
        ADD CONSTRAINT check_connection_type 
        CHECK (active_connection_type IN ('LAN', 'WIFI', 'DONGLE', 'OTHER', NULL));
    END IF;
END $$;

-- ============================================
-- Step 4: Add comments
-- ============================================

COMMENT ON COLUMN devices.device_name IS 
'Human-friendly name like Sonu-Desktop, Rahul-Laptop';

COMMENT ON COLUMN devices.lan_mac_address IS 
'Integrated LAN port MAC - permanent device ID';

COMMENT ON COLUMN devices.active_mac_address IS 
'Currently active connection MAC';

COMMENT ON COLUMN devices.active_connection_type IS 
'Connection type: LAN, WIFI, DONGLE, OTHER';

-- ============================================
-- Step 5: Create indexes
-- ============================================

CREATE INDEX IF NOT EXISTS idx_devices_name 
ON devices(device_name);

CREATE INDEX IF NOT EXISTS idx_devices_lan_mac 
ON devices(lan_mac_address);

CREATE INDEX IF NOT EXISTS idx_devices_active_mac 
ON devices(active_mac_address);

CREATE INDEX IF NOT EXISTS idx_devices_connection_type 
ON devices(active_connection_type);

-- ============================================
-- Step 6: Verification
-- ============================================

-- Show current schema
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'devices'
ORDER BY ordinal_position;

-- Show constraints
SELECT 
    conname AS constraint_name,
    contype AS constraint_type
FROM pg_constraint 
WHERE conrelid = 'devices'::regclass;

-- Count current devices
SELECT COUNT(*) as total_devices FROM devices;

-- ============================================
-- END
-- ============================================

-- ✅ Safe to run multiple times
-- ✅ Won't fail if columns already exist
-- ✅ Won't touch existing data
-- ✅ Only adds new functionality
