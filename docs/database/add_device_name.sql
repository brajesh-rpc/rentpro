-- Add device_name column to devices table
-- Run this in Supabase SQL Editor

-- Add the column
ALTER TABLE devices 
ADD COLUMN device_name VARCHAR(100) UNIQUE;

-- Update existing devices with friendly names
UPDATE devices 
SET device_name = CASE
  WHEN serial_number = 'DEV001' THEN 'Dell-Office-01'
  WHEN serial_number = 'DEV002' THEN 'HP-Desk-02'
  WHEN serial_number = 'DEV003' THEN 'Lenovo-Laptop-03'
  ELSE NULL
END;

-- Create index for faster search
CREATE INDEX idx_devices_name ON devices(device_name);

-- Verify the changes
SELECT serial_number, device_name, brand, model, status FROM devices;
