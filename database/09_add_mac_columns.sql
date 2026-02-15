-- ============================================
-- Add MAC Address Tracking to Devices
-- Version: 2.0.2
-- Date: February 15, 2026
-- Status: READY - Run in Supabase
-- ============================================

-- Add MAC address columns to existing devices table
-- Note: device_name already exists, so we skip it

-- ============================================
-- Step 1: Add MAC address columns
-- ============================================

ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS lan_mac_address VARCHAR(17);

ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS active_mac_address VARCHAR(17);

ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS active_connection_type VARCHAR(20);

-- ============================================
-- Step 2: Add unique constraint on LAN MAC
-- ============================================

-- Make lan_mac_address unique (primary device identifier)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'devices_lan_mac_address_key'
    ) THEN
        ALTER TABLE devices 
        ADD CONSTRAINT devices_lan_mac_address_key 
        UNIQUE (lan_mac_address);
    END IF;
END $$;

-- Make device_name unique (if not already)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'devices_device_name_key'
    ) THEN
        ALTER TABLE devices 
        ADD CONSTRAINT devices_device_name_key 
        UNIQUE (device_name);
    END IF;
END $$;

-- ============================================
-- Step 3: Add check constraint
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
-- Step 4: Add column comments
-- ============================================

COMMENT ON COLUMN devices.device_name IS 
'Human-friendly name: Sonu-Desktop, Rahul-Laptop (unique)';

COMMENT ON COLUMN devices.lan_mac_address IS 
'Integrated LAN port MAC - PERMANENT device identifier (never changes)';

COMMENT ON COLUMN devices.active_mac_address IS 
'Currently active connection MAC (LAN/WiFi/Dongle)';

COMMENT ON COLUMN devices.active_connection_type IS 
'Current connection type: LAN, WIFI, DONGLE, OTHER';

-- ============================================
-- Step 5: Create indexes for performance
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

-- Show updated schema
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'devices'
  AND column_name IN (
    'device_name',
    'lan_mac_address', 
    'active_mac_address',
    'active_connection_type',
    'serial_number'
  )
ORDER BY column_name;

-- Show constraints
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint 
WHERE conrelid = 'devices'::regclass
  AND conname IN (
    'devices_device_name_key',
    'devices_lan_mac_address_key',
    'check_connection_type'
  );

-- Show indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'devices'
  AND indexname LIKE 'idx_devices_%';

-- ============================================
-- Success Message
-- ============================================

DO $$ 
BEGIN
    RAISE NOTICE '✅ Device schema updated successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Added columns:';
    RAISE NOTICE '  - lan_mac_address (UNIQUE) - Permanent device ID';
    RAISE NOTICE '  - active_mac_address - Current connection MAC';
    RAISE NOTICE '  - active_connection_type - LAN/WIFI/DONGLE';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Deploy updated Windows Agent';
    RAISE NOTICE '  2. Test device registration';
    RAISE NOTICE '  3. Verify MAC addresses populate correctly';
END $$;

-- ============================================
-- END
-- ============================================
