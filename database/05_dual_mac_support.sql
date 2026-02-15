-- ============================================
-- Dual MAC Address Support
-- Version: 1.3.1
-- Status: PENDING - Run in Supabase
-- ============================================

-- Add columns for multiple network adapters
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS mac_address_primary VARCHAR(17),
ADD COLUMN IF NOT EXISTS mac_address_secondary VARCHAR(17),
ADD COLUMN IF NOT EXISTS mac_address_all TEXT;

-- Drop old unique constraint on mac_address if exists
ALTER TABLE devices DROP CONSTRAINT IF EXISTS devices_mac_address_key;

-- Add comments
COMMENT ON COLUMN devices.mac_address_primary IS 'Currently active MAC (LAN or WiFi dongle)';
COMMENT ON COLUMN devices.mac_address_secondary IS 'Secondary MAC (backup - usually integrated LAN)';
COMMENT ON COLUMN devices.mac_address_all IS 'All detected MACs (JSON array)';

-- Create index for searching by any MAC
CREATE INDEX IF NOT EXISTS idx_devices_mac_primary ON devices(mac_address_primary);
CREATE INDEX IF NOT EXISTS idx_devices_mac_secondary ON devices(mac_address_secondary);

-- Example data structure:
-- mac_address_primary: "00:1B:63:84:45:E6" (Active WiFi dongle)
-- mac_address_secondary: "00:1C:42:12:34:AB" (Motherboard LAN - backup)
-- mac_address_all: '["00:1B:63:84:45:E6","00:1C:42:12:34:AB","00:1D:73:45:67:CD"]'

-- Verification
SELECT 
    device_name,
    mac_address_primary AS active_mac,
    mac_address_secondary AS backup_mac,
    status
FROM devices
WHERE mac_address_primary IS NOT NULL;

-- ============================================
-- END
-- ============================================
