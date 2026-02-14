-- Fix: Add device_name column properly
-- Run this in Supabase SQL Editor

-- Step 1: Add column WITHOUT unique constraint first
ALTER TABLE devices 
ADD COLUMN device_name VARCHAR(100);

-- Step 2: Update existing devices with unique names
UPDATE devices 
SET device_name = CASE
  WHEN serial_number = 'DEV001' THEN 'Rajesh-i5'
  WHEN serial_number = 'DEV002' THEN 'Suresh-i5'  
  WHEN serial_number = 'DEV003' THEN 'Priya-i5'
  ELSE CONCAT('Device-', SUBSTRING(id::text, 1, 8))  -- Temporary unique name
END;

-- Step 3: Now add UNIQUE constraint
ALTER TABLE devices 
ADD CONSTRAINT devices_device_name_unique UNIQUE (device_name);

-- Step 4: Make it NOT NULL
ALTER TABLE devices 
ALTER COLUMN device_name SET NOT NULL;

-- Step 5: Create index for faster search
CREATE INDEX idx_devices_name ON devices(device_name);

-- Step 6: Verify the changes
SELECT serial_number, device_name, brand, processor, status FROM devices;
