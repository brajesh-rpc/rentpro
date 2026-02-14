# Device Naming Convention Guide

## 🎯 Device Name Format

**Format:** `[Brand]-[Type]-[Number]`

**Examples:**
- `Dell-Desktop-01`
- `HP-Laptop-05`
- `Lenovo-Desktop-12`
- `Dell-Gaming-03`

---

## 📝 Naming Rules:

### 1. Brand (Capitalize first letter)
- Dell
- HP
- Lenovo
- Asus
- Acer

### 2. Type (Describe usage or type)
- Desktop
- Laptop
- Gaming
- Office
- Premium
- Basic

### 3. Number (Sequential 01, 02, 03...)
- 01, 02, 03... 10, 11, 12...
- Always 2 digits
- Unique per brand-type combination

---

## ✅ Good Examples:

```
Dell-Office-01      (Dell desktop for office work, #1)
HP-Desktop-02       (HP desktop, #2)
Lenovo-Laptop-03    (Lenovo laptop, #3)
Dell-Gaming-04      (Dell gaming PC, #4)
Asus-Premium-05     (Asus premium desktop, #5)
HP-Basic-06         (HP basic system, #6)
```

---

## ❌ Bad Examples:

```
DEV001              (Not human-readable)
dell desktop 1      (No proper format, spaces)
DELL-DESKTOP-1      (All caps, single digit)
Dell_Desktop_01     (Underscores instead of hyphens)
MyComputer          (Not descriptive)
```

---

## 🎨 Category-based Naming (Alternative):

If you want to categorize by client type:

```
LoanRecovery-Dell-01    (For loan recovery company)
Insurance-HP-02         (For insurance sales)
Medicine-Lenovo-03      (For medicine sales)
CallCenter-Dell-04      (Generic call center)
```

---

## 💡 Location-based Naming (Alternative):

If you have multiple offices:

```
BLR-Dell-01    (Bangalore office)
MUM-HP-02      (Mumbai office)
DEL-Lenovo-03  (Delhi office)
```

---

## 🔧 Implementation in Database:

### Current Schema:
```sql
devices table:
- id (UUID - auto)
- serial_number (DEV001 - unique)
- device_name (Dell-Office-01 - NEW, unique, human-readable)
- brand, model, etc.
```

### Adding New Device:
```sql
INSERT INTO devices (
  serial_number,
  device_name,
  device_type,
  brand,
  model,
  ...
) VALUES (
  'DEV004',              -- System generated
  'Dell-Premium-04',     -- Human-friendly name
  'DESKTOP',
  'Dell',
  'OptiPlex 7050',
  ...
);
```

---

## 🎯 Dashboard Display:

Users will see:
```
Device Name: Dell-Office-01
Serial Number: DEV001
Brand: Dell
Model: OptiPlex 3020
Status: Available
```

Much better than just seeing "DEV001"! 👍

---

## 📋 Next Steps:

1. Run `add_device_name.sql` to add column
2. Decide your naming convention
3. Update existing devices
4. Use device_name in frontend (easier for users)
5. Keep serial_number for internal tracking

---

**Which naming format do you prefer?**

1. Brand-Type-Number (Dell-Desktop-01) ⭐ Recommended
2. Category-Brand-Number (LoanRecovery-Dell-01)
3. Location-Brand-Number (BLR-Dell-01)
4. Custom format?
