-- ============================================
-- RentComPro Device Schema - Final Consolidated
-- Version: 2.0.0
-- Date: February 15, 2026
-- Status: PENDING - Run in Supabase
-- ============================================

-- This script consolidates all device management improvements:
-- 1. Human-friendly device names (Sonu-Desktop, Rahul-Laptop)
-- 2. LAN MAC as permanent primary identifier
-- 3. Active connection tracking (WiFi/LAN/Dongle)
-- 4. Full backward compatibility

-- ============================================
-- Step 1: Add new columns
-- ============================================

-- Human-friendly device name
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS device_name VARCHAR(100) UNIQUE;

-- LAN MAC address (permanent identifier)
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS lan_mac_address VARCHAR(17) UNIQUE;

-- Active connection tracking
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS active_mac_address VARCHAR(17);

ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS active_connection_type VARCHAR(20);

-- Add constraints
ALTER TABLE devices 
ADD CONSTRAINT check_connection_type 
CHECK (active_connection_type IN ('LAN', 'WIFI', 'DONGLE', 'OTHER', NULL));

-- ============================================
-- Step 2: Add comments for documentation
-- ============================================

COMMENT ON COLUMN devices.device_name IS 
'Human-friendly name like Sonu-Desktop, Rahul-Laptop (unique across system)';

COMMENT ON COLUMN devices.lan_mac_address IS 
'Integrated LAN port MAC address - PERMANENT device identifier (never changes)';

COMMENT ON COLUMN devices.active_mac_address IS 
'Currently active connection MAC (could be LAN, WiFi, or WiFi dongle)';

COMMENT ON COLUMN devices.active_connection_type IS 
'Type of active connection: LAN, WIFI, DONGLE, OTHER';

COMMENT ON COLUMN devices.mac_address IS 
'Legacy field - migrate data to lan_mac_address';

-- ============================================
-- Step 3: Migrate existing data (if any)
-- ============================================

-- Copy existing mac_address to lan_mac_address for devices that don't have it
UPDATE devices 
SET lan_mac_address = mac_address 
WHERE lan_mac_address IS NULL 
  AND mac_address IS NOT NULL;

-- Set active MAC same as LAN MAC for existing devices (assuming LAN connection)
UPDATE devices 
SET active_mac_address = lan_mac_address,
    active_connection_type = 'LAN'
WHERE active_mac_address IS NULL 
  AND lan_mac_address IS NOT NULL;

-- Generate default device names for existing devices without names
UPDATE devices 
SET device_name = 'Device-' || SUBSTRING(serial_number, 1, 8)
WHERE device_name IS NULL 
  AND serial_number IS NOT NULL;

-- ============================================
-- Step 4: Create indexes for performance
-- ============================================

-- Fast lookup by device name
CREATE INDEX IF NOT EXISTS idx_devices_name ON devices(device_name);

-- Fast lookup by LAN MAC (primary identifier)
CREATE INDEX IF NOT EXISTS idx_devices_lan_mac ON devices(lan_mac_address);

-- Fast lookup by active MAC (for connection tracking)
CREATE INDEX IF NOT EXISTS idx_devices_active_mac ON devices(active_mac_address);

-- Fast lookup by connection type
CREATE INDEX IF NOT EXISTS idx_devices_connection_type ON devices(active_connection_type);

-- Combined index for common queries
CREATE INDEX IF NOT EXISTS idx_devices_status_type 
ON devices(status, device_type);

-- ============================================
-- Step 5: Verification queries
-- ============================================

-- Show current schema
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'devices'
  AND column_name IN (
    'device_name', 
    'lan_mac_address', 
    'active_mac_address', 
    'active_connection_type',
    'mac_address',
    'serial_number'
  )
ORDER BY ordinal_position;

-- Show sample data
SELECT 
    device_name AS name,
    lan_mac_address AS permanent_id,
    active_mac_address AS current_mac,
    active_connection_type AS connection,
    device_type,
    status,
    serial_number
FROM devices
ORDER BY device_name
LIMIT 10;

-- Count devices by connection type
SELECT 
    active_connection_type AS connection,
    COUNT(*) as device_count
FROM devices
GROUP BY active_connection_type
ORDER BY device_count DESC;

-- ============================================
-- Step 6: Future migration note
-- ============================================

-- OPTIONAL: Remove old mac_address column after confirming all data migrated
-- WARNING: Only run this after verifying lan_mac_address is populated for all devices
-- ALTER TABLE devices DROP COLUMN IF EXISTS mac_address;

-- ============================================
-- END
-- ============================================

-- Summary of changes:
-- ✅ Added device_name for human-friendly names
-- ✅ Added lan_mac_address as permanent device identifier
-- ✅ Added active_mac_address for current connection tracking
-- ✅ Added active_connection_type (LAN/WIFI/DONGLE)
-- ✅ Migrated existing data from mac_address
-- ✅ Created performance indexes
-- ✅ Maintained backward compatibility

-- Next steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Verify all devices have lan_mac_address populated
-- 3. Deploy updated Windows Agent
-- 4. Test device registration with new fields
