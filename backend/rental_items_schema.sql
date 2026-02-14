-- Rental Items Table (Current active rentals)
CREATE TABLE IF NOT EXISTS rental_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL, -- DESKTOP, LAPTOP, UPS, MONITOR, etc.
    quantity INTEGER NOT NULL DEFAULT 1,
    monthly_rent DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Rental Item History Table (Track all changes)
CREATE TABLE IF NOT EXISTS rental_item_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL, -- ADDED, REMOVED
    quantity INTEGER NOT NULL,
    monthly_rent DECIMAL(10,2) NOT NULL,
    effective_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_rental_items_client ON rental_items(client_id);
CREATE INDEX idx_rental_history_client ON rental_item_history(client_id);
CREATE INDEX idx_rental_history_date ON rental_item_history(effective_date);

-- Comments
COMMENT ON TABLE rental_items IS 'Current rental items assigned to clients';
COMMENT ON TABLE rental_item_history IS 'Historical record of all rental item changes including mid-month additions/removals';
COMMENT ON COLUMN rental_item_history.action IS 'Type of change: ADDED or REMOVED';
COMMENT ON COLUMN rental_item_history.effective_date IS 'Date when this change became effective for billing purposes';
