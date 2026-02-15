-- ============================================
-- Simplified MAC Strategy - LAN as Primary Key
-- Version: 1.4.0
-- Status: PENDING - Run in Supabase
-- ============================================

-- Use integrated LAN MAC as primary unique identifier
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS lan_mac_address VARCHAR(17) UNIQUE NOT NULL,
ADD COLUMN IF NOT EXISTS active_mac_address VARCHAR(17),
ADD COLUMN IF NOT EXISTS active_connection_type VARCHAR(20);

-- Drop old MAC columns (if migration needed)
-- ALTER TABLE devices DROP COLUMN IF EXISTS mac_address;
-- ALTER TABLE devices DROP COLUMN IF EXISTS mac_address_primary;
-- ALTER TABLE devices DROP COLUMN IF EXISTS mac_address_secondary;

-- Comments
COMMENT ON COLUMN devices.lan_mac_address IS 'Integrated LAN port MAC (PERMANENT - used as unique ID)';
COMMENT ON COLUMN devices.active_mac_address IS 'Currently active connection MAC (WiFi/LAN/Dongle)';
COMMENT ON COLUMN devices.active_connection_type IS 'LAN, WIFI, DONGLE';

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_devices_lan_mac ON devices(lan_mac_address);
CREATE INDEX IF NOT EXISTS idx_devices_active_mac ON devices(active_mac_address);

-- Example data:
/*
Device: Sonu-Desktop
lan_mac_address: 00:1B:63:84:45:E6 (Motherboard LAN - PERMANENT ID)
active_mac_address: 00:1B:63:84:45:E6 (Currently using LAN)
active_connection_type: LAN

Device: Priya-Desktop (WiFi Dongle)
lan_mac_address: 00:1C:42:12:34:AB (Motherboard LAN - PERMANENT ID)
active_mac_address: 00:2A:10:88:99:FF (Currently using WiFi dongle)
active_connection_type: DONGLE

Device: Rahul-Laptop
lan_mac_address: A0:36:9F:12:34:56 (Built-in LAN port - PERMANENT ID)
active_mac_address: A4:5E:60:D2:3F:1A (Currently using WiFi)
active_connection_type: WIFI
*/

-- Verification
SELECT 
    device_name,
    lan_mac_address AS permanent_id,
    active_mac_address AS current_connection,
    active_connection_type AS connection_type,
    status
FROM devices
ORDER BY device_name;

-- ============================================
-- END
-- ============================================
