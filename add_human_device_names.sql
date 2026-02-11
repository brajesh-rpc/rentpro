-- Add Human-like Device Names
-- Run this in Supabase SQL Editor

-- Add the device_name column
ALTER TABLE devices 
ADD COLUMN device_name VARCHAR(100) UNIQUE NOT NULL DEFAULT 'Unnamed-Device';

-- Update existing test devices with human names
UPDATE devices 
SET device_name = CASE
  WHEN serial_number = 'DEV001' THEN 'Rajesh-i5'
  WHEN serial_number = 'DEV002' THEN 'Suresh-i5'  
  WHEN serial_number = 'DEV003' THEN 'Priya-i5'
  ELSE 'Unnamed-Device'
END;

-- Create index for faster search
CREATE INDEX idx_devices_name ON devices(device_name);

-- Verify the changes
SELECT serial_number, device_name, brand, processor, status FROM devices;

-- ============================================
-- Example: Adding new devices with human names
-- ============================================

-- You can insert like this:
/*
INSERT INTO devices (
  serial_number,
  device_name,
  device_type,
  brand,
  model,
  processor,
  ram_gb,
  storage_gb,
  storage_type,
  monthly_rent,
  security_deposit,
  status
) VALUES
  ('DEV004', 'Amit-i3', 'DESKTOP', 'Dell', 'OptiPlex 3010', 'Intel i3-3220', 4, 500, 'HDD', 800, 4000, 'AVAILABLE'),
  ('DEV005', 'Neha-i7', 'LAPTOP', 'HP', 'EliteBook 840', 'Intel i7-6600U', 8, 256, 'SSD', 1500, 7000, 'AVAILABLE'),
  ('DEV006', 'Deepak-i5', 'DESKTOP', 'Lenovo', 'ThinkCentre M93p', 'Intel i5-4590', 8, 1000, 'HDD', 1200, 6000, 'AVAILABLE'),
  ('DEV007', 'Pooja-i3', 'DESKTOP', 'HP', 'ProDesk 400', 'Intel i3-4150', 4, 500, 'HDD', 800, 4000, 'AVAILABLE'),
  ('DEV008', 'Vikram-i7', 'DESKTOP', 'Dell', 'OptiPlex 9020', 'Intel i7-4790', 16, 512, 'SSD', 1800, 9000, 'AVAILABLE'),
  ('DEV009', 'Kavita-Ryzen5', 'DESKTOP', 'HP', 'EliteDesk 705', 'AMD Ryzen 5 2400G', 8, 256, 'SSD', 1300, 6500, 'AVAILABLE'),
  ('DEV010', 'Sanjay-MacMini', 'DESKTOP', 'Apple', 'Mac Mini', 'Apple M1', 8, 256, 'SSD', 2500, 12000, 'AVAILABLE');
*/
