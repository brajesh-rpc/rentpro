-- ============================================
-- RentComPro Database Schema
-- Complete schema for all tables
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL DEFAULT 'STAFF',
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_role CHECK (role IN ('SUPER_ADMIN', 'STAFF', 'FIELD_AGENT'))
);

-- ============================================
-- CLIENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    alternate_phone VARCHAR(20),
    email VARCHAR(255),
    whatsapp VARCHAR(20),
    business_type VARCHAR(50),
    gst_number VARCHAR(50),
    pan_number VARCHAR(50),
    office_address TEXT NOT NULL,
    landmark VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    landlord_contact VARCHAR(20),
    credit_limit DECIMAL(10,2) DEFAULT 0,
    security_deposit DECIMAL(10,2) DEFAULT 0,
    late_penalty_percent DECIMAL(5,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_client_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'OVERDUE'))
);

-- ============================================
-- DEVICES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    device_type VARCHAR(20) NOT NULL,
    brand VARCHAR(100),
    model VARCHAR(100),
    processor VARCHAR(255),
    ram_gb INTEGER,
    storage_gb INTEGER,
    storage_type VARCHAR(20),
    monitor_size INTEGER,
    purchase_date DATE,
    purchase_price DECIMAL(10,2),
    monthly_rent DECIMAL(10,2) NOT NULL,
    security_deposit DECIMAL(10,2),
    condition VARCHAR(20) DEFAULT 'GOOD',
    status VARCHAR(20) DEFAULT 'AVAILABLE',
    last_seen TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_device_type CHECK (device_type IN ('DESKTOP', 'LAPTOP')),
    CONSTRAINT check_device_status CHECK (status IN ('AVAILABLE', 'DEPLOYED', 'MAINTENANCE', 'RETIRED')),
    CONSTRAINT check_condition CHECK (condition IN ('EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'NEW'))
);

-- ============================================
-- HARDWARE STATS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS hardware_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    cpu_usage DECIMAL(5,2),
    ram_total INTEGER,
    ram_used INTEGER,
    disk_total INTEGER,
    disk_used INTEGER,
    ip_address VARCHAR(50),
    login_count INTEGER DEFAULT 0,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- RENTAL ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS rental_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    monthly_rent DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- RENTAL ITEM HISTORY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS rental_item_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL,
    monthly_rent DECIMAL(10,2) NOT NULL,
    effective_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_action CHECK (action IN ('ADDED', 'REMOVED'))
);

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
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Clients
CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_clients_city ON clients(city);

-- Devices
CREATE INDEX idx_devices_status ON devices(status);
CREATE INDEX idx_devices_serial ON devices(serial_number);

-- Hardware Stats
CREATE INDEX idx_hardware_stats_device ON hardware_stats(device_id);
CREATE INDEX idx_hardware_stats_timestamp ON hardware_stats(timestamp);

-- Rental Items
CREATE INDEX idx_rental_items_client ON rental_items(client_id);
CREATE INDEX idx_rental_history_client ON rental_item_history(client_id);
CREATE INDEX idx_rental_history_date ON rental_item_history(effective_date);

-- Invoices
CREATE INDEX idx_invoices_client ON invoices(client_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_date ON invoices(invoice_date);
CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE users IS 'System users with role-based access';
COMMENT ON TABLE clients IS 'Telecalling companies renting systems';
COMMENT ON TABLE devices IS 'Desktop and laptop inventory';
COMMENT ON TABLE hardware_stats IS 'Device monitoring statistics';
COMMENT ON TABLE rental_items IS 'Current rental items assigned to clients';
COMMENT ON TABLE rental_item_history IS 'Historical record of rental changes';
COMMENT ON TABLE invoices IS 'Invoice records for billing';
COMMENT ON TABLE invoice_items IS 'Line items for each invoice';

-- ============================================
-- SEED DATA (Optional - for testing)
-- ============================================

-- Insert default admin user (password: password123)
-- Password hash for 'password123' using bcrypt
INSERT INTO users (email, password_hash, full_name, role) 
VALUES (
    'admin@rentcompro.com',
    '$2a$10$rZ0K8qH6qQxJ9Y.tYv0R0OqKZF8xVxN8bYxN8xVxN8xVxN8xVxN8x',
    'Super Admin',
    'SUPER_ADMIN'
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- SCHEMA VERSION
-- ============================================
CREATE TABLE IF NOT EXISTS schema_version (
    version VARCHAR(20) PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    description TEXT
);

INSERT INTO schema_version (version, description)
VALUES ('1.0.0', 'Initial schema with all core tables')
ON CONFLICT (version) DO NOTHING;

-- ============================================
-- END OF SCHEMA
-- ============================================
