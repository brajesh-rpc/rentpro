# Module 1.4 - Device Live Tracking System
**Date:** February 18, 2026  
**Status:** 📋 PLANNING COMPLETE — Ready for Implementation  
**Priority:** 🔴 HIGH — Core fraud prevention feature

---

## 🎯 Module Objective

Real-time tracking of all rented computers with two operating modes:
- **NORMAL Mode:** Lightweight monitoring, minimal system impact
- **SUPERWATCH Mode:** Deep surveillance when fraud suspected

**Target Hardware:** i5 2nd Gen, 4GB RAM, 256GB SSD (low-end systems)  
**Core Constraint:** NORMAL mode must be invisible to end users — no lag, no slowdown

---

## 🏗️ Architecture Overview

```
[Client Machine]                    [Cloud]                    [Dashboard]
     │                                 │                            │
Windows Agent                  Cloudflare Workers           rentpro.pages.dev
     │                                 │                            │
NORMAL mode ──── every 5 min ───► /api/devices/stats ──────► Device Monitor
SUPERWATCH ──── every 30 sec ───► /api/devices/stats ──────► Alert Panel
Screenshot ────── on trigger ───► /api/devices/screenshot ─► Evidence Viewer
Events ─────────── realtime ────► /api/devices/events ─────► Event Log
```

---

## 📊 Two Tracking Modes

### 🟢 NORMAL Mode (Default)
**Goal:** Maximum info, minimum CPU/RAM usage

| Property | Value |
|----------|-------|
| Report Interval | 5 minutes |
| CPU Impact | < 1% |
| RAM Usage | < 15 MB |
| Screenshot | ❌ No |
| Network calls | 1 per 5 min |

**Data Collected:**
- Online/Offline status
- CPU usage % (single reading, no loop)
- RAM used/total
- Disk used/total
- Current logged-in user
- IP address
- Active MAC address
- Last boot time
- Uptime in minutes

**Performance Rules for NORMAL Mode:**
1. `ManagementObjectSearcher` — use ONLY once per cycle, cache results
2. `PerformanceCounter` — read once, no sleep/loop
3. No `Thread.Sleep()` in main thread
4. No WMI queries in loop
5. Network check = simple TCP ping (not HTTP request to Google)
6. All work in background thread, never block main thread

---

### 🔴 SUPERWATCH Mode
**Goal:** Deep surveillance when fraud or misuse suspected

| Property | Value |
|----------|-------|
| Report Interval | 30 seconds |
| Screenshot | ✅ Every 5 minutes |
| CPU Impact | 3-5% (acceptable) |
| Trigger | Manual by admin OR auto by heuristic |

**Additional Data Collected:**
- Screenshot (compressed, < 100KB)
- System temperature (CPU + HDD if available)
- Restart count in last 24 hours
- Abrupt shutdown events
- Active window title (what app is running)
- USB device connect/disconnect events

**Who can activate SUPERWATCH Mode:**
- Super Admin manually from dashboard
- Auto-triggered by heuristic engine

---

## 🧠 Heuristic Engine (Auto SUPERWATCH Detection)

Auto-triggers SUPERWATCH Mode when suspicious patterns detected:

### Trigger Rules:

| Rule | Condition | Severity |
|------|-----------|----------|
| Payment Overdue | Invoice overdue > 5 days | 🟡 MEDIUM |
| Location Change | IP changes to different city | 🔴 HIGH |
| MAC Change | Active MAC changed (dongle replaced?) | 🔴 HIGH |
| Offline Spike | Device offline > 8 hours during business hours | 🟡 MEDIUM |
| Frequent Restart | > 5 restarts in 24 hours | 🟡 MEDIUM |
| Abrupt Shutdown | > 3 abrupt shutdowns in 24 hours | 🔴 HIGH |
| Night Activity | System active 11 PM - 6 AM consistently | 🟡 MEDIUM |
| New User Login | Unknown username detected | 🔴 HIGH |

### Alert Severity Levels:
- 🟢 **INFO** — Normal activity, just log
- 🟡 **WARNING** — Watch closely, notify admin
- 🔴 **CRITICAL** — Immediate action needed, SMS alert

---

## 💾 Database Changes Required

### New Table: `device_events`
```sql
CREATE TABLE device_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,   -- RESTART, SHUTDOWN, USER_CHANGE, MAC_CHANGE, etc.
    event_data JSONB,                   -- flexible extra data
    severity VARCHAR(20) DEFAULT 'INFO',
    is_resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT check_severity CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL'))
);
```

### New Table: `device_screenshots`
```sql
CREATE TABLE device_screenshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    screenshot_url TEXT NOT NULL,       -- Cloudflare R2 or base64
    file_size_kb INTEGER,
    triggered_by VARCHAR(50),           -- 'MANUAL', 'AUTO_SUPERWATCH', 'SCHEDULE'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Modify: `hardware_stats` table
```sql
-- Add new columns to existing hardware_stats
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS cpu_temp DECIMAL(5,1);
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS hdd_temp DECIMAL(5,1);
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS uptime_minutes INTEGER;
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS restart_count_24h INTEGER DEFAULT 0;
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS active_window TEXT;
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS tracking_mode VARCHAR(15) DEFAULT 'NORMAL'; -- NORMAL or SUPERWATCH
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS ram_usage DECIMAL(5,2);
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS disk_usage DECIMAL(5,2);
ALTER TABLE hardware_stats ADD COLUMN IF NOT EXISTS last_boot TIMESTAMP WITH TIME ZONE;
```

### Modify: `devices` table
```sql
-- Add tracking mode column
ALTER TABLE devices ADD COLUMN IF NOT EXISTS tracking_mode VARCHAR(15) DEFAULT 'NORMAL'; -- NORMAL or SUPERWATCH
ALTER TABLE devices ADD COLUMN IF NOT EXISTS superwatch_reason TEXT;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS superwatch_activated_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS alert_count INTEGER DEFAULT 0;
```

---

## 🔧 Windows Agent Changes

### File Structure (New/Modified):

```
RentComProAgent/
├── AgentConfig.cs              ← MODIFY: add tracking mode fields (NORMAL/SUPERWATCH)
├── AgentWorker.cs              ← MODIFY: dual-mode loop (NORMAL/SUPERWATCH)
├── Models/
│   ├── HardwareStats.cs        ← MODIFY: add new fields
│   ├── ServerResponse.cs       ← MODIFY: add trackingMode in response
│   └── DeviceEvent.cs          ← NEW: event model
├── Services/
│   ├── HardwareMonitorService.cs   ← MODIFY: optimized + new fields
│   ├── ApiCommunicationService.cs  ← MODIFY: new endpoints
│   ├── NetworkDetectionService.cs  ← NO CHANGE (already good)
│   ├── LockService.cs              ← NO CHANGE
│   ├── TemperatureService.cs       ← NEW: CPU/HDD temp
│   ├── ScreenshotService.cs        ← NEW: compressed screenshot
│   ├── EventDetectionService.cs    ← NEW: restart/shutdown/USB events
│   └── SystemInfoService.cs        ← MODIFY: uptime, last boot, active window
```

---

## ⚡ Performance Optimization Plan (Critical)

### Problem with Current Code:
```csharp
// CURRENT - SLOW (WMI queries are expensive)
private long GetTotalRam() {
    using var searcher = new ManagementObjectSearcher(
        "SELECT TotalVisibleMemorySize FROM Win32_OperatingSystem");
    // This WMI query takes 200-500ms!
}
// Called 4 times separately = 800ms-2sec of WMI overhead per cycle
```

### Solution - Cache + Single WMI Call:
```csharp
// NEW - FAST: One WMI call, cache for 5 minutes
private OsStats? _cachedOsStats;
private DateTime _cacheExpiry = DateTime.MinValue;

private OsStats GetOsStats() {
    if (DateTime.Now < _cacheExpiry && _cachedOsStats != null)
        return _cachedOsStats;  // Return cached, no WMI call
    
    // Single WMI call for ALL OS data
    using var searcher = new ManagementObjectSearcher(
        "SELECT TotalVisibleMemorySize, FreePhysicalMemory, LastBootUpTime 
         FROM Win32_OperatingSystem");
    
    _cachedOsStats = ParseOsStats(searcher);
    _cacheExpiry = DateTime.Now.AddMinutes(5);
    return _cachedOsStats;
}
```

### Network Check Optimization:
```csharp
// CURRENT - SLOW: HTTP request to Google (1-3 sec timeout possible)
using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(5) };
var response = client.GetAsync("https://www.google.com")...

// NEW - FAST: TCP ping (< 100ms)
private bool CheckInternetFast() {
    try {
        using var tcp = new TcpClient();
        tcp.Connect("8.8.8.8", 53); // DNS port — always open
        return true;
    } catch { return false; }
}
```

### NORMAL Mode Total Impact Target:
```
WMI queries:      1 batch call  (~200ms, once per 5 min)
CPU counter:      1 reading     (~50ms)
Network check:    TCP ping      (~50ms)
Screenshot:       NONE
Total CPU time:   < 300ms per 5 min cycle = < 0.1% CPU average
RAM:              ~12-15 MB process size
```

---

## 🌐 Backend API Changes

### New Endpoints Required:

```
EXISTING (already works):
POST /api/devices/stats               ← stats data from agent

NEW ENDPOINTS NEEDED:
PUT  /api/devices/:id/mode            ← Admin switches NORMAL/SUPERWATCH mode
GET  /api/devices/monitor             ← Dashboard: all devices live status
GET  /api/devices/:id/events          ← Device event history
POST /api/devices/screenshot          ← Agent uploads screenshot
GET  /api/devices/:id/screenshots     ← View device screenshots
POST /api/devices/event               ← Agent reports event (restart, shutdown, etc.)
GET  /api/devices/alerts              ← All unresolved alerts
PUT  /api/devices/alerts/:id/resolve  ← Mark alert as resolved
```

---

## 🖥️ Frontend Dashboard Section

### Location: `dashboard-new.html` — New "Device Monitor" section

### Layout:
```
┌─────────────────────────────────────────────────────┐
│  📡 DEVICE MONITOR                    🔄 Auto-refresh│
├──────────┬──────────┬──────────┬───────────────────┤
│ Total    │ 🟢 Online│ 🔴 Offline│ ⚠️ Alerts        │
│ 12       │ 9        │ 3        │ 2                  │
├─────────────────────────────────────────────────────┤
│ DEVICE CARDS (grid)                                 │
│ ┌─────────────────┐  ┌─────────────────┐           │
│ │ 🟢 Sonu-Desktop │  │ 🔴 Ramesh-i5    │           │
│ │ Client: ABC Call│  │ OFFLINE 2h ago  │           │
│ │ CPU ████░ 40%   │  │ Last: 10:30 AM  │           │
│ │ RAM █████ 62%   │  │ [📍 Last Known] │           │
│ │ User: rahul     │  │ [🔴 SUPERWATCH] │           │
│ │ IP: 192.168.1.5 │  └─────────────────┘           │
│ │ [👁️ Details]   │                                 │
│ └─────────────────┘                                 │
├─────────────────────────────────────────────────────┤
│ ⚠️ RECENT ALERTS                                    │
│ 🔴 Sonu-Desktop — IP changed (Delhi→Noida) 2h ago  │
│ 🟡 Ramesh-i5 — Offline during business hours       │
│ [View All Alerts]                                   │
└─────────────────────────────────────────────────────┘
```

### Auto-refresh:
- Normal: Every 30 seconds (page refresh of data)
- If any device in SUPERWATCH mode: Every 10 seconds

---

## 📱 Alert Notifications (Future - Phase 2)

When CRITICAL alert triggers:
- SMS to Brajesh via Textlocal/Fast2SMS API
- WhatsApp message via Twilio/WATI

Format:
```
🔴 RentComPro Alert
Device: Sonu-Desktop
Client: ABC Calling Co.
Issue: Location changed (Delhi→Noida)
Time: 18 Feb 2026, 2:45 PM
Action: Device switched to SUPERWATCH mode
Login: rentpro.pages.dev
```

---

## 📋 Implementation Order

### Step 1: Database (30 min)
- [ ] Create `device_events` table
- [ ] Create `device_screenshots` table  
- [ ] Alter `hardware_stats` — add new columns
- [ ] Alter `devices` — add tracking_mode column (NORMAL/SUPERWATCH)
- [ ] Run migrations on Supabase

### Step 2: Backend APIs (2-3 hours)
- [ ] `PUT /api/devices/:id/mode` — switch NORMAL/SUPERWATCH mode
- [ ] `GET /api/devices/monitor` — live status for all devices
- [ ] `POST /api/devices/event` — receive events from agent
- [ ] `GET /api/devices/alerts` — get unresolved alerts
- [ ] `POST /api/devices/screenshot` — receive screenshot
- [ ] Deploy to Cloudflare Workers

### Step 3: Windows Agent (3-4 hours)
- [ ] Optimize `HardwareMonitorService` — cache WMI, fast network check
- [ ] Update `AgentConfig` — add trackingMode (NORMAL/SUPERWATCH), screenshotInterval
- [ ] Update `AgentWorker` — dual-mode loop (NORMAL/SUPERWATCH)
- [ ] Create `TemperatureService` — CPU/HDD temp
- [ ] Create `EventDetectionService` — restart/shutdown detection
- [ ] Create `ScreenshotService` — compressed capture
- [ ] Update `ApiCommunicationService` — new endpoints
- [ ] Update `HardwareStats` model — new fields
- [ ] Rebuild EXE

### Step 4: Frontend Dashboard (2 hours)
- [ ] Add Device Monitor section to `dashboard-new.html`
- [ ] Summary cards (Total/Online/Offline/Alerts)
- [ ] Device grid with live stats
- [ ] Alert panel
- [ ] Auto-refresh logic
- [ ] NORMAL/SUPERWATCH toggle button per device

---

## ⚠️ Important Technical Notes

### Screenshot Strategy (lightweight):
```csharp
// Capture → Resize to 1024x768 → Compress JPEG quality 30%
// Target: < 100KB per screenshot
// Upload: Base64 in JSON payload (no separate file upload needed)
// Storage: Store only last 10 screenshots per device in DB
// Older ones auto-delete (DB trigger or cron)
// SUPERWATCH mode only — never in NORMAL mode
```

### Temperature Reading:
```csharp
// WMI temperature is often unreliable on budget hardware
// Use OpenHardwareMonitor library OR
// Read from MSAcpi_ThermalZoneTemperature WMI class
// If unavailable → send null (don't crash)
// Never block the main loop for temperature
// SUPERWATCH mode only
```

### Abrupt Shutdown Detection:
```csharp
// On startup: Check Windows Event Log
// Event ID 6006 = Clean shutdown
// Event ID 6008 = Unexpected/abrupt shutdown
// Count last 24 hours and report
// No realtime hook needed — just check on next startup
```

### Restart Count:
```csharp
// On startup: Check Event ID 6005 (EventLog service started = system started)
// Count occurrences in last 24 hours from System event log
// > 5 in 24h = suspicious → auto-trigger SUPERWATCH
```

---

## 🔒 Security Notes

- Screenshots stored ONLY when SUPERWATCH mode active
- Screenshot access: Super Admin only
- Device cannot self-activate SUPERWATCH (server decides)
- Agent token required for all API calls
- Screenshots auto-purge after 30 days

---

## 📁 Files to Create/Modify

### New Files:
- `docs/17_DEVICE_LIVE_TRACKING_MODULE.md` ← THIS FILE
- `database/migrations/10_device_tracking_tables.sql`
- `backend/src/devices/monitoring.ts`
- `windows-agent/RentComProAgent/Services/TemperatureService.cs`
- `windows-agent/RentComProAgent/Services/ScreenshotService.cs`
- `windows-agent/RentComProAgent/Services/EventDetectionService.cs`
- `windows-agent/RentComProAgent/Models/DeviceEvent.cs`

### Modified Files:
- `backend/src/index.ts` ← new routes
- `database/complete_schema.sql` ← updated schema
- `windows-agent/RentComProAgent/AgentConfig.cs`
- `windows-agent/RentComProAgent/AgentWorker.cs`
- `windows-agent/RentComProAgent/Models/HardwareStats.cs`
- `windows-agent/RentComProAgent/Models/ServerResponse.cs`
- `windows-agent/RentComProAgent/Services/HardwareMonitorService.cs`
- `windows-agent/RentComProAgent/Services/ApiCommunicationService.cs`
- `Frontend/dashboard-new.html`

---

**Planned By:** Brajesh Kumar + Claude AI  
**Date:** February 18, 2026  
**Estimated Total Time:** 8-10 hours  
**Status:** 📋 Ready to implement — Start with Step 1 (Database)
