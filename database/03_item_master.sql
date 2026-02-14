-- ============================================
-- Item Master Table
-- Version: 1.2.0
-- Status: PENDING - Run in Supabase
-- ============================================

CREATE TABLE IF NOT EXISTS item_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_code VARCHAR(50) UNIQUE NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    item_type VARCHAR(20) NOT NULL,
    description TEXT,
    default_rate DECIMAL(10,2) NOT NULL,
    hsn_sac_code VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_item_type CHECK (item_type IN ('RENTAL', 'SALE')),
    CONSTRAINT check_category CHECK (category IN ('COMPUTER', 'PERIPHERAL', 'ACCESSORY', 'OTHER'))
);

-- Indexes
CREATE INDEX idx_item_master_category ON item_master(category);
CREATE INDEX idx_item_master_type ON item_master(item_type);
CREATE INDEX idx_item_master_active ON item_master(is_active);

-- Comments
COMMENT ON TABLE item_master IS 'Master list of rental and sale items with standard rates';
COMMENT ON COLUMN item_master.item_code IS 'Unique code like DT-I5-8GB, UPS-600VA';
COMMENT ON COLUMN item_master.item_type IS 'RENTAL for recurring items, SALE for one-time items';

-- ============================================
-- Seed Data - Standard Items
-- ============================================

INSERT INTO item_master (item_code, item_name, category, item_type, description, default_rate, hsn_sac_code) VALUES
-- Desktop Computers
('DT-I3-4GB', 'Desktop i3 4GB 500GB', 'COMPUTER', 'RENTAL', 'Desktop Computer - i3 2nd Gen, 4GB RAM, 500GB HDD, 19" Monitor', 750.00, '997212'),
('DT-I5-8GB', 'Desktop i5 8GB 1TB', 'COMPUTER', 'RENTAL', 'Desktop Computer - i5 4th Gen, 8GB RAM, 1TB HDD, 19" Monitor', 1200.00, '997212'),
('DT-I5-4GB', 'Desktop i5 4GB 500GB', 'COMPUTER', 'RENTAL', 'Desktop Computer - i5 2nd Gen, 4GB RAM, 500GB HDD, 19" Monitor', 1000.00, '997212'),

-- Laptops
('LP-I3-4GB', 'Laptop i3 4GB', 'COMPUTER', 'RENTAL', 'Laptop - i3, 4GB RAM, 500GB HDD', 1000.00, '997212'),
('LP-I5-8GB', 'Laptop i5 8GB', 'COMPUTER', 'RENTAL', 'Laptop - i5, 8GB RAM, 1TB HDD', 1500.00, '997212'),

-- UPS
('UPS-600VA', 'UPS 600VA', 'PERIPHERAL', 'RENTAL', 'UPS 600VA with Battery Backup', 150.00, '997212'),
('UPS-1KVA', 'UPS 1KVA', 'PERIPHERAL', 'RENTAL', 'UPS 1KVA with Battery Backup', 250.00, '997212'),

-- Monitors
('MON-19', 'Monitor 19 inch', 'PERIPHERAL', 'RENTAL', '19 inch LED Monitor', 200.00, '997212'),
('MON-22', 'Monitor 22 inch', 'PERIPHERAL', 'RENTAL', '22 inch LED Monitor', 300.00, '997212'),

-- Accessories (Rental)
('KB-MOUSE', 'Keyboard + Mouse Set', 'ACCESSORY', 'RENTAL', 'Standard Keyboard and Mouse Combo', 50.00, '997212'),
('HEADSET', 'Headset with Mic', 'ACCESSORY', 'RENTAL', 'USB Headset with Microphone', 100.00, '997212'),

-- Sale Items
('HEADPHONE-SALE', 'Headphone (Sale)', 'ACCESSORY', 'SALE', 'Headphone for permanent sale', 500.00, '8518'),
('MOUSE-SALE', 'Mouse (Sale)', 'ACCESSORY', 'SALE', 'Wired Mouse for sale', 200.00, '8471'),
('KEYBOARD-SALE', 'Keyboard (Sale)', 'ACCESSORY', 'SALE', 'Standard Keyboard for sale', 300.00, '8471'),
('WEBCAM-SALE', 'Webcam (Sale)', 'ACCESSORY', 'SALE', 'HD Webcam for sale', 1000.00, '8525')

ON CONFLICT (item_code) DO NOTHING;

-- ============================================
-- Verification Query
-- ============================================
/*
SELECT 
    category,
    item_type,
    COUNT(*) as item_count,
    AVG(default_rate) as avg_rate
FROM item_master
WHERE is_active = true
GROUP BY category, item_type
ORDER BY category, item_type;
*/

-- ============================================
-- END
-- ============================================
