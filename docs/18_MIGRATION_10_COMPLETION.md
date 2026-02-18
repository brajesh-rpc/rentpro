# Migration #10 - Device Live Tracking Database
**Date:** February 18, 2026  
**Status:** ✅ COMPLETE — Successfully deployed to Supabase  
**Migration File:** `database/migrations/10_device_tracking_tables.sql`

---

## 📋 What Was Done

Database foundation for the complete Device Live Tracking module (Module 1.4).  
Includes SUPERWATCH mode, event tracking, screenshots, configurable settings, and audit trail.

---

## 🗄️ Tables Created / Modified

### 1. MODIFIED: `devices` table
New columns added:

| Column | Type | Default | Purpose |
|--------|------|---------|---------|
| `client_id` | UUID (FK → clients) | NULL | Which client has this device |
| `tracking_mode` | VARCHAR(15) | NORMAL | NORMAL or SUPERWATCH |
| `superwatch_reason` | TEXT | NULL | Why SUPERWATCH was activated |
| `superwatch_activated_at` | TIMESTAMPTZ | NULL | When SUPERWATCH was activated |
| `alert_count` | INTEGER | 0 | Total unresolved alerts |

**Constraint:** `tracking_mode` only allows `NORMAL` or `SUPERWATCH`

---

### 2. MODIFIED: `hardware_stats` table
New columns added:

| Column | Type | Purpose |
|--------|------|---------|
| `cpu_temp` | DECIMAL(5,1) | CPU temperature in °C |
| `hdd_temp` | DECIMAL(5,1) | HDD temperature in °C |
| `uptime_minutes` | INTEGER | System uptime in minutes |
| `restart_count_24h` | INTEGER | Restarts in last 24 hours |
| `active_window` | TEXT | Currently open application title |
| `tracking_mode` | VARCHAR(15) | NORMAL or SUPERWATCH at time of record |
| `ram_usage` | DECIMAL(5,2) | RAM usage percentage |
| `disk_usage` | DECIMAL(5,2) | Disk usage percentage |
| `last_boot` | TIMESTAMPTZ | Last system boot time |
| `connection_type` | VARCHAR(20) | LAN / WIFI / DONGLE |
| `computer_name` | VARCHAR(100) | Windows computer name |
| `logged_in_user` | VARCHAR(100) | Currently logged in Windows user |
| `lan_mac_address` | VARCHAR(20) | Motherboard LAN MAC (permanent ID) |
| `active_mac_address` | VARCHAR(20) | Currently active MAC |
| `is_online` | BOOLEAN | Internet connectivity status |

**Note:** `current_user` renamed to `logged_in_user` — `current_user` is a reserved keyword in PostgreSQL.

**Retention Policy (via trigger):**
- NORMAL mode: 24 hours (configurable)
- SUPERWATCH mode: 48 hours (fixed — more data needed for investigation)

---

### 3. NEW: `device_events` table
Stores all suspicious and notable device events.

```
id, device_id, event_type, event_data (JSONB), severity, 
is_resolved, resolved_by, resolved_at, resolve_note, created_at
```

**Event Types:**

| Event | Severity | Trigger |
|-------|----------|---------|
| RESTART | WARNING | > N restarts in 24h |
| ABRUPT_SHUTDOWN | WARNING/CRITICAL | > N abrupt shutdowns in 24h |
| USER_CHANGE | CRITICAL | Unknown username detected |
| MAC_CHANGE | CRITICAL | Active MAC changed (dongle swap?) |
| IP_CHANGE | INFO/WARNING | IP address changed |
| LOCATION_CHANGE | CRITICAL | IP suggests different city |
| OFFLINE_SPIKE | WARNING | Offline during business hours |
| NIGHT_ACTIVITY | WARNING | Active between night hours |
| USB_CONNECT | INFO | USB device plugged in |
| SUPERWATCH_ON | INFO | SUPERWATCH mode activated |
| SUPERWATCH_OFF | INFO | SUPERWATCH mode deactivated |
| PAYMENT_OVERDUE | WARNING/CRITICAL | Invoice overdue threshold crossed |

**event_data JSONB examples:**
```json
MAC_CHANGE:      {"old_mac": "AA:BB:CC", "new_mac": "DD:EE:FF"}
IP_CHANGE:       {"old_ip": "192.168.1.5", "new_ip": "10.0.0.2"}
USER_CHANGE:     {"old_user": "rahul", "new_user": "unknown_user"}
PAYMENT_OVERDUE: {"invoice_number": "RENT/FEB/001", "overdue_days": 7}
RESTART:         {"restart_count_24h": 6}
```

**Important:** Unresolved events are NEVER auto-deleted regardless of retention settings.

---

### 4. NEW: `device_screenshots` table
Stores compressed screenshots taken in SUPERWATCH mode.

```
id, device_id, screenshot_data (base64 JPEG), file_size_kb,
width, height, triggered_by, active_window, created_at
```

**triggered_by values:**
- `AUTO_SUPERWATCH` — taken automatically on schedule
- `MANUAL` — admin requested from dashboard

**Storage Strategy:**
- Compressed JPEG, quality 30 (default) = ~50-80KB per screenshot
- Max width 1024px (default)
- Auto-cleanup: max 10 per device (configurable)
- Auto-cleanup: older than 30 days (configurable)

---

### 5. NEW: `system_settings` table
All configurable settings — editable from dashboard without code changes.

```
id, setting_key, setting_value, setting_type, category,
label, description, min_value, max_value,
updated_by, updated_at, created_at
```

**22 default settings inserted across 5 categories:**

#### SUPERWATCH (6 settings)
| Key | Default | Range |
|-----|---------|-------|
| superwatch_report_interval_seconds | 30 | 10–300 |
| superwatch_screenshot_interval_minutes | 5 | 1–60 |
| superwatch_screenshot_quality | 30 | 10–80 |
| superwatch_screenshot_max_width | 1024 | 640–1920 |
| superwatch_max_screenshots_per_device | 10 | 5–100 |
| superwatch_screenshot_retention_days | 30 | 7–365 |

#### NORMAL (2 settings)
| Key | Default | Range |
|-----|---------|-------|
| normal_report_interval_seconds | 300 | 60–1800 |
| normal_stats_retention_hours | 24 | 6–168 |

#### BUSINESS_HOURS (3 settings)
| Key | Default | Notes |
|-----|---------|-------|
| business_hours_start | 9 | 9 AM |
| business_hours_end | 19 | 7 PM |
| business_days | 1,2,3,4,5,6 | Mon–Sat |

#### HEURISTIC (7 settings)
| Key | Default | Range |
|-----|---------|-------|
| heuristic_enabled | true | — |
| heuristic_payment_overdue_days | 5 | 1–30 |
| heuristic_offline_hours_trigger | 4 | 1–24 |
| heuristic_restart_count_trigger | 5 | 2–20 |
| heuristic_abrupt_shutdown_trigger | 3 | 1–10 |
| heuristic_night_start_hour | 23 | 20–23 |
| heuristic_night_end_hour | 6 | 4–9 |

#### ALERTS (4 settings)
| Key | Default | Notes |
|-----|---------|-------|
| alert_sms_enabled | false | Phase 2 |
| alert_whatsapp_enabled | false | Phase 2 |
| alert_admin_phone | 0000000000 | Update this! |
| alert_events_retention_days | 90 | 30–365 |

---

### 6. NEW: `settings_history` table
Audit trail — automatically logs every setting change.

```
id, setting_key, old_value, new_value, changed_by, changed_at, change_note
```

**Auto-populated via trigger** — no manual inserts needed.  
Every time a setting is updated, old and new values are automatically recorded.

---

## 🔄 Triggers Created

| Trigger | Table | Purpose |
|---------|-------|---------|
| `trigger_log_setting_change` | system_settings | Auto-logs every setting change to settings_history |
| `trigger_cleanup_screenshots` | device_screenshots | Keeps max N screenshots per device + deletes old ones |
| `trigger_cleanup_hardware_stats` | hardware_stats | Time-based cleanup (24h NORMAL, 48h SUPERWATCH) |
| `trigger_cleanup_device_events` | device_events | Deletes resolved events beyond retention period |

---

## 👁️ View Created: `device_live_status`

Dashboard-ready view combining devices + latest hardware stats + client info + alert counts.

**Key computed fields:**

| Field | Values | Logic |
|-------|--------|-------|
| `online_status` | NEVER_SEEN / ONLINE / RECENTLY_ONLINE / OFFLINE / LONG_OFFLINE | Based on last_seen timestamp |
| `offline_minutes` | NULL or number | Minutes since last seen (null if online) |
| `unresolved_alerts` | 0, 1, 2... | Count of WARNING + CRITICAL unresolved events |
| `latest_critical_event` | event_type or NULL | Most recent unresolved CRITICAL event type |

**Usage:**
```sql
-- Dashboard: all devices with status
SELECT * FROM device_live_status;

-- Only online devices
SELECT * FROM device_live_status WHERE online_status = 'ONLINE';

-- Devices needing attention
SELECT * FROM device_live_status WHERE unresolved_alerts > 0;

-- SUPERWATCH devices
SELECT * FROM device_live_status WHERE tracking_mode = 'SUPERWATCH';
```

---

## 📊 Indexes Created

| Index | Table | Columns | Purpose |
|-------|-------|---------|---------|
| idx_devices_client_id | devices | client_id | Fast client→device lookup |
| idx_devices_tracking_mode | devices | tracking_mode | Filter by NORMAL/SUPERWATCH |
| idx_hardware_stats_mode | hardware_stats | tracking_mode | Filter stats by mode |
| idx_hardware_stats_online | hardware_stats | is_online | Filter online/offline |
| idx_device_events_device | device_events | device_id | Events per device |
| idx_device_events_severity | device_events | severity | Filter by severity |
| idx_device_events_resolved | device_events | is_resolved | Filter unresolved |
| idx_device_events_created | device_events | created_at DESC | Latest events first |
| idx_device_events_type | device_events | event_type | Filter by type |
| idx_device_events_unresolved_critical | device_events | device_id, is_resolved, severity | Dashboard query (partial index) |
| idx_screenshots_device | device_screenshots | device_id | Screenshots per device |
| idx_screenshots_created | device_screenshots | created_at DESC | Latest first |
| idx_system_settings_category | system_settings | category | Settings by category |
| idx_settings_history_key | settings_history | setting_key | History per setting |
| idx_settings_history_changed_at | settings_history | changed_at DESC | Latest changes first |

---

## ⚠️ Known Issues / Fixes Applied

### Issue 1: `current_user` reserved keyword
PostgreSQL reserves `current_user` — renamed to `logged_in_user` in hardware_stats.  
Windows Agent code must send field as `loggedInUser` (camelCase).

### Issue 2: `schema_version` table missing
`schema_version` table did not exist in this Supabase instance.  
Migration version record was skipped — not critical.

### Issue 3: Empty string in NOT NULL column
`alert_admin_phone` uses `'0000000000'` as placeholder instead of empty string.  
Update this to actual phone number from dashboard settings.

---

## ✅ Verification Results (Confirmed Working)

```
Settings by category:
  ALERTS         → 4 settings ✅
  BUSINESS_HOURS → 3 settings ✅
  HEURISTIC      → 7 settings ✅
  NORMAL         → 2 settings ✅
  SUPERWATCH     → 6 settings ✅

Tables created:
  device_events      ✅
  device_screenshots ✅
  settings_history   ✅
  system_settings    ✅

View working:
  DEV001 → NEVER_SEEN (agent not connected yet) ✅
  DEV002 → NEVER_SEEN ✅
  DEV003 → NEVER_SEEN ✅
  5LD9152 → NEVER_SEEN ✅
```

---

## 🚀 Next Step: Backend APIs (Step 2)

APIs to build in `backend/src/devices/monitoring.ts`:

```
PUT  /api/devices/:id/mode           ← Switch NORMAL/SUPERWATCH
GET  /api/devices/monitor            ← Live status (uses device_live_status view)
POST /api/devices/event              ← Agent reports event
GET  /api/devices/alerts             ← All unresolved alerts
PUT  /api/devices/alerts/:id/resolve ← Mark alert resolved
POST /api/devices/screenshot         ← Agent uploads screenshot
GET  /api/devices/:id/screenshots    ← View screenshots
GET  /api/settings                   ← Get all settings
PUT  /api/settings/:key              ← Update a setting
```

---

**Completed By:** Brajesh Kumar + Claude AI  
**Date:** February 18, 2026  
**Time Taken:** ~45 minutes (including debugging)  
**Status:** 🟢 Production Ready
