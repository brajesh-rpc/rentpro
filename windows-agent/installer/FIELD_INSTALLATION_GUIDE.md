# Field Installation Guide

## Equipment Checklist
- [ ] USB drive with installer
- [ ] Internet-connected laptop (for dashboard access)
- [ ] Client computer (device to install agent on)

---

## Installation Process

### Pre-Installation (Office)

**Step 1: Register Device in System**
```
1. Login to https://rentpro.pages.dev
2. Dashboard → Add Device
3. Fill details:
   - Serial Number: [Physical serial from laptop/desktop]
   - Device Type: Desktop/Laptop
   - Specs: Processor, RAM, Storage
   - Monthly Rent: Amount
   - Status: AVAILABLE
4. Click "Save Device"
5. Note down Serial Number for field installation
```

---

### Field Installation (Client Site)

**Step 2: Physical Setup**
```
1. Unbox and connect computer
2. Power on
3. Complete Windows setup (if new)
4. Connect to internet (WiFi/LAN)
5. Verify internet connection working
```

**Step 3: Install RentComPro Agent**
```
1. Insert USB drive
2. Copy "installer" folder to Desktop
3. Right-click "FieldInstaller.bat"
4. Select "Run as Administrator"
5. Enter Serial Number when prompted
6. Verify installation completes successfully
```

**Step 4: Verification**
```
1. Check Windows Services:
   - Press Win+R → services.msc
   - Find "RentComPro Monitoring Agent"
   - Status should be "Running"

2. Check Dashboard:
   - Refresh device list
   - Device should show:
     ✅ Status: ONLINE
     ✅ MAC Address: populated
     ✅ Computer Name: populated
     ✅ Last Seen: few seconds ago
```

**Step 5: Assign to Client**
```
1. Dashboard → Manage Devices
2. Find the device
3. Click "Assign"
4. Select client from dropdown
5. Status changes: AVAILABLE → DEPLOYED
```

---

## What Details Are Auto-Detected?

### ✅ Automatically Collected:
- Computer Name
- MAC Address (all adapters)
- Local IP Address
- Processor details
- RAM size
- Disk size & usage
- OS version
- Last seen timestamp

### ❌ Manual Input Required:
- Serial Number (during installation)
- Device Type (Desktop/Laptop)
- Monthly Rent amount
- Client assignment

---

## Troubleshooting

### Agent Not Starting?
```bash
# Check logs
notepad "C:\Program Files\RentComProAgent\logs\agent.log"

# Restart service
net stop RentComProAgent
net start RentComProAgent
```

### Device Not Showing Online?
```
1. Check internet connection
2. Verify serial number matches
3. Check firewall (allow port 443 outbound)
4. Restart agent service
```

### Wrong Serial Number Entered?
```
1. Uninstall:
   sc stop RentComProAgent
   sc delete RentComProAgent

2. Reinstall with correct serial
```

---

## Installation Time

| Step | Duration |
|------|----------|
| Physical setup | 5-10 min |
| Windows setup (if new) | 15-20 min |
| Agent installation | 2-3 min |
| Verification | 2-3 min |
| **Total** | **25-35 min** |

---

## USB Drive Contents

```
installer/
├── FieldInstaller.bat          ← Run this
├── RentComProAgent.exe         ← Windows service
└── README.txt                  ← This guide
```

---

## Support

Issues during installation?
- Call: [Support Number]
- WhatsApp: [Support WhatsApp]
- Dashboard: Raise ticket

---

**Last Updated:** February 15, 2026
