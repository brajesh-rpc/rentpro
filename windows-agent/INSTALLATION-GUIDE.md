# RentComPro Agent - Quick Installation Guide

## For Device Installation Technicians

### Option 1: Fully Automated (Recommended)

**Step 1:** Run registration script
```powershell
Right-click: register-device.ps1
Select: "Run with PowerShell"
```

**Step 2:** Enter device information
- Device Name: e.g., "Rajesh-i5", "Office-PC-1"
- Admin Email: Your RentComPro admin email
- Admin Password: Your admin password

**Step 3:** Automatic installation
- Script will automatically register device
- Get Device ID and Token from server
- Install and start the service

**Done!** ✅

---

### Option 2: Manual Steps

**Step 1: Build the agent**
```bash
Double-click: build.bat
Wait for build to complete
```

**Step 2: Register device**
```powershell
Right-click: register-device.ps1
Run with PowerShell
```

**Step 3: Install service**
```powershell
Right-click: install.ps1
Run as Administrator
Enter Device ID and Token when prompted
```

---

### Option 3: Command Line (Batch File)

**Easy for non-technical users:**
```bash
Double-click: register-device.bat
Follow on-screen instructions
```

---

## Verification

**Check if service is running:**
```powershell
Get-Service RentComProAgent
```

**Expected output:**
```
Status   Name               DisplayName
------   ----               -----------
Running  RentComProAgent    RentComPro Device Agent
```

---

## Uninstallation

**To remove the agent:**
```powershell
Right-click: uninstall.ps1
Run as Administrator
Confirm: yes
```

---

## Troubleshooting

### Service won't start
1. Check Event Viewer → Application logs
2. Verify Device ID and Token in `C:\Program Files\RentComPro\appsettings.json`
3. Ensure internet connection

### Registration fails
1. Check admin credentials
2. Verify backend server is running
3. Check internet connection

### Device not showing in dashboard
1. Wait 5 minutes for first stats report
2. Check service is running
3. Verify API URL in config

---

## Files Generated

After registration, you'll get:
- `device-credentials.txt` - Contains Device ID and Token (SAVE THIS!)

After installation, service files are in:
- `C:\Program Files\RentComPro\`

---

## Support

For technical support:
- Email: support@rentcompro.com
- Phone: +91 9876543210

---

**Last Updated:** February 13, 2026
