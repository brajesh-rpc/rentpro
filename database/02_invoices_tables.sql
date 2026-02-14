-- ============================================
-- RentComPro - Invoice Tables
-- File: 02_invoices_tables.sql
-- Status: ⚠️ PENDING - RUN THIS IN SUPABASE
-- ============================================

-- ============================================
-- INVOICES TABLE
-- ============================================
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
    status VARCHAR(20) DEFAULT 'UNPAID',
    payment_date DATE,
    payment_mode VARCHAR(50),
    payment_reference VARCHAR(100),
    payment_remarks TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_invoice_status CHECK (status IN ('UNPAID', 'PAID', 'PARTIAL', 'OVERDUE', 'CANCELLED'))
);

-- ============================================
-- INVOICE ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL,
    description TEXT NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 1,
    rate DECIMAL(10,2) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    hsn_sac_code VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_item_type CHECK (item_type IN ('RENTAL', 'SALE', 'CHARGE', 'ADJUSTMENT'))
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_invoices_client ON invoices(client_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_date ON invoices(invoice_date);
CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE invoices IS 'Invoice records for client billing';
COMMENT ON TABLE invoice_items IS 'Line items for each invoice';

-- ============================================
-- VERIFICATION QUERY (Run after executing above)
-- ============================================
/*
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('invoices', 'invoice_items');

Expected: 2 rows (invoices, invoice_items)
*/

-- ============================================
-- END
-- ============================================
