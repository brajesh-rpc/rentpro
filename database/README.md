# 🗄️ Database Structure

Complete database schema and SQL scripts for RentComPro.

---

## 📊 Database Provider

**Supabase (PostgreSQL)**
- Project: RentComPro
- Credentials: See `docs/setup-guides/SUPABASE_CREDENTIALS.md`

---

## 📁 Files Structure

```
database/
├── README.md                           (This file)
├── 00_complete_schema.sql             (Complete database - ALL tables)
├── 01_rental_items_tables.sql         (✅ Already executed)
└── 02_invoices_tables.sql             (⚠️ PENDING - Run this next)
```

---

## 🗂️ Database Tables

### Core Tables
1. **users** - System users (SUPER_ADMIN, STAFF, FIELD_AGENT)
2. **clients** - Telecalling companies
3. **devices** - Desktop/Laptop inventory
4. **hardware_stats** - Device monitoring data

### Rental Management
5. **rental_items** - Current items assigned to clients
6. **rental_item_history** - Audit trail of changes

### Billing
7. **invoices** - Invoice records ⚠️ **PENDING**
8. **invoice_items** - Invoice line items ⚠️ **PENDING**

---

## 🚀 How to Execute SQL Scripts

### Step 1: Access Supabase
1. Go to: https://supabase.com
2. Login and select **RentComPro** project
3. Go to **SQL Editor** (left sidebar)

### Step 2: Run Pending Script
```sql
-- Open file: 02_invoices_tables.sql
-- Copy entire content
-- Paste in Supabase SQL Editor
-- Click "Run"
```

### Step 3: Verify Tables Created
```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('invoices', 'invoice_items');
```

Should return 2 rows ✅

---

## 📋 Execution Status

| File | Status | Description |
|------|--------|-------------|
| `00_complete_schema.sql` | ✅ Reference | Complete schema (use for fresh setup) |
| `01_rental_items_tables.sql` | ✅ EXECUTED | Rental items tables created |
| `02_invoices_tables.sql` | ⚠️ PENDING | **Run this next!** |

---

## 🔧 Common Operations

### Fresh Database Setup
```sql
-- Run only: 00_complete_schema.sql
-- This creates ALL tables at once
```

### Incremental Setup (Current Approach)
```sql
-- Step 1: Basic tables already exist
-- Step 2: Run 01_rental_items_tables.sql ✅
-- Step 3: Run 02_invoices_tables.sql ⚠️
```

### Reset Database (⚠️ DANGER - Development Only)
```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
-- Then run: 00_complete_schema.sql
```

---

## 📊 Table Relationships

```
users
  (no relationships)

clients
  ├── rental_items (many)
  ├── rental_item_history (many)
  └── invoices (many)

devices
  └── hardware_stats (many)

invoices
  └── invoice_items (many)
```

---

## 🔐 Performance Indexes

**Indexes created on:**
- users: email, role
- clients: status, city
- devices: status, serial_number
- invoices: client_id, status, date
- rental_items: client_id

---

**Last Updated:** February 14, 2026
