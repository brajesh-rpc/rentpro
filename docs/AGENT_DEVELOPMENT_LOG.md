# RentComPro — Windows Agent & Dashboard Development Log

**Date:** 2026-02-20  
**Session:** Installer + Agent + Dashboard Integration

---

## 1. Kya Achieve Kiya

Agent system end-to-end kaam kar raha hai:
- Windows machine par installer chalao
- Device automatically server pe register hota hai (PENDING status)
- Admin dashboard pe approve karo
- Agent service hardware stats bhejta rehta hai (CPU, RAM, Disk)
- Device Monitor dashboard pe Live/Offline dikhta hai

---

## 2. Architecture Overview

```
[Windows Machine]                    [Cloudflare Workers]         [Supabase DB]
RentComProInstaller.exe
  └── Register Device          →     POST /api/devices/register → devices table (PENDING)
  └── Install Agent Service

[RentComProAgent.exe Service]
  └── Every 60s sends stats    →     POST /api/devices/stats    → hardware_stats table
                               ←     Returns: lockStatus, trackingMode

[Dashboard - Cloudflare Pages]
  └── manage-devices.html      →     GET /api/devices           → Shows PENDING devices
  └── device-monitor.html      →     GET /api/devices/monitor   → Live/Offline status
```

---

## 3. File Structure

```
windows-agent/
├── publish/
│   └── RentComProAgent.exe          ← Actual agent binary (built from RentComProAgent project)
├── installer/
│   └── RentComProInstaller/
│       ├── Program.cs               ← UAC Admin elevation
│       ├── MainWizard.cs            ← 4-step wizard flow
│       ├── InstallData.cs           ← Shared data between steps
│       ├── app.manifest             ← requireAdministrator
│       ├── RentComProInstaller.csproj
│       └── Forms/
│           ├── WelcomePanel.cs
│           ├── ServerPanel.cs       ← Server URL test
│           ├── RegisterPanel.cs     ← MAC-based device registration
│           ├── ConfigPanel.cs       ← Install folder, interval
│           ├── InstallingPanel.cs   ← Actual install logic
│           └── SuccessPanel.cs
├── RentComProAgent/
│   ├── AgentWorker.cs               ← Background service loop
│   ├── AgentConfig.cs               ← Config model
│   └── Program.cs
└── Installer/
    └── build-and-run.bat            ← Build + launch installer

Frontend/
├── manage-devices.html              ← PENDING device approval UI
└── device-monitor.html              ← Live/Offline monitoring

backend/src/devices/
├── management.ts                    ← selfRegisterDevice(), getDeviceCount()
└── monitoring.ts                    ← getDeviceMonitor(), receiveDeviceStats()
```

---

## 4. Database Changes (Supabase)

### New Columns Added to `devices` table:
```sql
ALTER TABLE devices ADD COLUMN IF NOT EXISTS roll_number INTEGER;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS client_name TEXT;
```

### Status Constraint Updated:
```sql
ALTER TABLE devices DROP CONSTRAINT IF EXISTS devices_status_check;
ALTER TABLE devices ADD CONSTRAINT devices_status_check 
CHECK (status IN ('AVAILABLE','DEPLOYED','MAINTENANCE','RETIRED','PENDING','LOCKED','STOLEN'));
```

### New Status: `PENDING`
- Installer se aaya device pehle PENDING hota hai
- Admin manage-devices.html pe "Approve" karta hai → AVAILABLE ho jaata hai

---

## 5. Installer Flow (Step by Step)

### Step 1 — Welcome Screen
- Basic intro

### Step 2 — Server Connection (ServerPanel.cs)
- Server URL enter karo
- "Test Connection" button — GET /api/health check

### Step 3 — Device Registration (RegisterPanel.cs)
- Auto-fetch LAN MAC address (Ethernet adapters only, WiFi/Bluetooth exclude)
- Multiple NICs listbox mein dikhte hain
- Roll Number auto-fetch from `/api/devices/count + 1`
- "Register Device" → POST `/api/devices/register` (public endpoint, no auth)
- Response mein `deviceId` milta hai → `InstallData.RegisteredDeviceId` mein save
- **Success tabhi dikhao jab server se confirmation aaye**

### Step 4 — Configuration (ConfigPanel.cs)
- Install folder (default: C:\RentComPro)
- Reporting interval slider (1-10 min)
- Auto-start with Windows checkbox

### Step 5 — Installing (InstallingPanel.cs)
```
1. Stop old service (if exists)
2. Verify DeviceId (agar missing → offline MAC-based ID)
3. Create C:\RentComPro\ and logs\ folder
4. Write appsettings.json WITH DeviceId (PEHLE config save karo)
5. Find agent exe from: windows-agent/publish/RentComProAgent.exe
6. Copy all files (appsettings.json SKIP — already saved)
7. sc.exe delete old service
8. sc.exe create "RentComPro Agent" binPath= "C:\RentComPro\RentComProAgent.exe"
9. sc.exe start "RentComPro Agent"
10. Verify service status
11. Registry auto-start entry
12. Create uninstall.bat
```

### Step 6 — Success
- Device ID, folder, interval display

### Log File
- Desktop pe `RentComPro_Install_Log.txt` banta hai
- Har step ka output capture hota hai
- Errors clearly marked

---

## 6. Critical Fix: Admin Rights

**Problem:** `[SC] OpenSCManager FAILED 5: Access is denied`

**Root Cause:** Installer admin rights ke bina chal raha tha, Windows service install/start ke liye admin chahiye.

**Fix:**
1. `app.manifest` mein `requireAdministrator` set kiya
2. `Program.cs` mein runtime admin check + UAC elevation
3. `.csproj` mein `<ApplicationManifest>app.manifest</ApplicationManifest>`

Ab installer chalate hi Windows UAC popup aata hai — "Yes" karo.

---

## 7. Critical Fix: Agent Exe Path

**Problem:** Installer galat path pe exe dhundh raha tha

**Root Cause:** baseDir = `installer\RentComProInstaller\bin\Release\net8.0-windows\`  
Actual exe = `windows-agent\publish\RentComProAgent.exe` (5 levels up)

**Fix:** `FindAgentExe()` mein correct relative path:
```csharp
Path.Combine(baseDir, @"..\..\..\..\..\publish\RentComProAgent.exe")
```

---

## 8. Critical Fix: Config Save Order

**Problem:** Agent service chal rahi thi lekin `appsettings.json` mein `DeviceId` blank tha → agent "Device not registered" error de raha tha

**Root Cause:** Pehle files copy hoti thi (blank appsettings), phir config likhta tha — overwrite ho jaata tha

**Fix:** Config **pehle** save karo (Step 3), phir agent files copy karo (Step 4), aur copy mein `appsettings.json` skip karo

---

## 9. Backend API Endpoints

### Public (No Auth)
```
POST /api/devices/register    ← Installer se device register
GET  /api/devices/count       ← Roll number auto-increment ke liye
```

### Authenticated
```
GET  /api/devices/monitor     ← Dashboard live status
POST /api/devices/stats       ← Agent heartbeat (hardware stats)
PUT  /api/devices/:id         ← Approve PENDING device
```

---

## 10. Dashboard Changes

### manage-devices.html
- **PENDING stat card** — purple color, sirf tab dikhta hai jab pending devices hain
- **Pending filter button** — filter bar mein
- **Pending device card** — purple banner + "Approve" button directly on card
- "Reject" = Delete
- PENDING devices hamesha list mein pehle dikhte hain

### device-monitor.html
- PENDING devices approve hone se pehle alag purple section mein dikhte hain
- "→ Approve in Devices" link
- Approved hone ke baad automatically Live/Offline section mein aa jaate hain
- Summary cards mein PENDING count exclude (sirf approved devices count hote hain)

---

## 11. Agent Config (C:\RentComPro\appsettings.json)

```json
{
  "Agent": {
    "ApiBaseUrl": "https://rentcompro-backend.brajesh-jimmc.workers.dev",
    "DeviceId": "<registered-device-uuid>",
    "DeviceToken": "",
    "ReportingIntervalSeconds": 60,
    "EnableLocking": true,
    "EnableHardwareMonitoring": true,
    "ScreenshotMaxWidth": 1024,
    "ScreenshotQuality": 30
  }
}
```

---

## 12. Deployment Commands

```powershell
# Frontend (auto-deploy via git push)
cd C:\Users\HP\Desktop\RentComPro
git add -A
git commit -m "message"
git push

# Backend (manual deploy)
cd C:\Users\HP\Desktop\RentComPro\backend
npx wrangler deploy

# Installer rebuild
C:\Users\HP\Desktop\RentComPro\windows-agent\Installer\build-and-run.bat
```

---

## 13. Pending / Future Work

- [ ] Agent ko PENDING status mein heartbeat band karna (approve ke baad hi start kare)
- [ ] Agent stealth mode — console window hide karo, background mein silently chale (user ko koi popup na dikhe)
- [ ] Device naam installer mein editable banana (abhi computer name auto-aata hai)
- [ ] Multiple devices ek client ko assign karna
- [ ] Payment overdue alert → auto SUPERWATCH
- [ ] BIOS password lock feature
- [ ] Screenshot capture in SUPERWATCH mode
- [ ] SMS/WhatsApp notification on critical alerts
- [ ] Installer `.exe` properly sign karna (code signing certificate)

---

## 14. Known Issues

| Issue | Status |
|-------|--------|
| Har install pe naya DeviceId banta hai (MAC same hai) | Pending fix — duplicate check improve karna |
| Device naam `DESKTOP-UD6NUM7` — human friendly nahi | Future: installer mein editable field |
| Agent logs `C:\RentComPro\logs\` mein nahi aa rahe | Agent logging configure karna baaki |
| `gitignore` mein `windows-agent/` add kiya | Done ✅ |

