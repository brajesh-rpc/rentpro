# ⚠️ IMPORTANT: Database Schema Location

## ✅ Correct Location for Database Files

**USE THIS FOLDER:**
```
C:\Users\HP\Desktop\RentComPro\database\
```

**NOT THIS:**
```
C:\Users\HP\Desktop\RentComPro\docs\database\  ❌ WRONG!
```

---

## 📁 Correct Folder Structure

```
RentComPro/
├── database/                    ← ✅ CORRECT - Use this!
│   ├── migrations/
│   │   ├── 000_add_rental_items.sql
│   │   └── 001_add_invoices_tables.sql
│   ├── 01_rental_items_tables.sql
│   ├── 02_invoices_tables.sql
│   ├── 03_item_master.sql
│   ├── complete_schema.sql
│   └── README.md
│
└── docs/                        ← Documentation only
    ├── 01_BUSINESS_OVERVIEW.md
    ├── 02_USER_TYPES_AND_ROLES.md
    └── [other .md files]
    └── database/               ← ❌ DELETE THIS FOLDER!
        └── [duplicate SQL files - NOT NEEDED]
```

---

## 🗑️ Action Required

**DELETE this folder:**
```
C:\Users\HP\Desktop\RentComPro\docs\database\
```

**Why?**
- Duplicate files create confusion
- Real database files are in `/database/`
- docs/ folder should only have .md documentation

---

## ✅ Use These Files for Database

### **Main Schema Files:**
```
database/complete_schema.sql           - Complete database schema
database/02_invoices_tables.sql        - Invoice tables (standalone)
```

### **Migration Files (Ordered):**
```
database/migrations/000_add_rental_items.sql    - Rental items
database/migrations/001_add_invoices_tables.sql - Invoice tables
```

**Run migrations in order:** 000 → 001

---

## 📋 To Add New Database Changes

1. Create migration file: `database/migrations/00X_description.sql`
2. Use sequential numbering: 000, 001, 002, etc.
3. Include rollback queries in comments
4. Update `database/complete_schema.sql` if needed

---

**Created:** February 16, 2026  
**Purpose:** Prevent confusion about database file locations
