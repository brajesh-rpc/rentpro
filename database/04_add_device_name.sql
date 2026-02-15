-- ============================================
-- Human-Friendly Device Names
-- Version: 1.3.0
-- Status: PENDING - Run in Supabase
-- ============================================

-- Add device_name column to devices table
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS device_name VARCHAR(100) UNIQUE;

-- Add comment
COMMENT ON COLUMN devices.device_name IS 'Human-friendly name like Sonu-Desktop, Rahul-Laptop';

-- Update existing devices with default names (optional)
-- UPDATE devices SET device_name = 'Device-' || SUBSTRING(serial_number, 1, 6) WHERE device_name IS NULL;

-- Create index for faster search
CREATE INDEX IF NOT EXISTS idx_devices_name ON devices(device_name);

-- Verification query
SELECT 
    device_name,
    serial_number,
    mac_address,
    device_type,
    status
FROM devices
ORDER BY device_name;

-- ============================================
-- END
-- ============================================
