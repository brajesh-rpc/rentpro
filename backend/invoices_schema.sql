-- Invoices Table
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    reference_number VARCHAR(50),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    invoice_date DATE NOT NULL,
    period_from DATE NOT NULL,
    period_to DATE NOT NULL,
    due_date DATE NOT NULL,
    has_gst BOOLEAN DEFAULT false,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
    previous_outstanding DECIMAL(10,2) DEFAULT 0,
    gst_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    amount_paid DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'UNPAID', -- UNPAID, PAID, PARTIAL, OVERDUE, CANCELLED
    payment_date DATE,
    payment_mode VARCHAR(50),
    payment_reference VARCHAR(100),
    payment_remarks TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Invoice Items Table
CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL, -- RENTAL, SALE, CHARGE, ADJUSTMENT
    description TEXT NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 1,
    rate DECIMAL(10,2) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    hsn_sac_code VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_invoices_client ON invoices(client_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_date ON invoices(invoice_date);
CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);

-- Comments
COMMENT ON TABLE invoices IS 'Invoice records for client billing';
COMMENT ON COLUMN invoices.has_gst IS 'Whether GST is included in this invoice';
COMMENT ON COLUMN invoices.status IS 'Payment status: UNPAID, PAID, PARTIAL, OVERDUE, CANCELLED';
COMMENT ON TABLE invoice_items IS 'Line items for each invoice';
COMMENT ON COLUMN invoice_items.item_type IS 'Type: RENTAL (recurring), SALE (one-time), CHARGE (additional), ADJUSTMENT (negative)';
