# RentComPro Windows Agent

Windows Service that runs on rented devices to monitor hardware and enable remote management.

## Features

- ✅ Hardware monitoring (CPU, RAM, Disk)
- ✅ Remote lock/unlock capability
- ✅ Automatic stats reporting to server
- ✅ Runs as Windows Service
- ✅ Auto-start on boot

## Requirements

- Windows 10/11
- .NET 8.0 Runtime (included in installer)
- Administrator privileges for installation

## Project Structure

```
windows-agent/
├── RentComProAgent/
│   ├── Program.cs                    # Main entry point
│   ├── AgentWorker.cs                # Background worker service
│   ├── AgentConfig.cs                # Configuration model
│   ├── Services/
│   │   ├── HardwareMonitorService.cs # Hardware stats collection
│   │   ├── ApiCommunicationService.cs# API communication
│   │   └── LockService.cs            # Device lock/unlock
│   ├── Models/
│   │   └── HardwareStats.cs          # Stats data model
│   └── RentComProAgent.csproj        # Project file
├── Installer/
│   ├── setup.iss                     # Inno Setup script
│   └── README.md                     # Installer instructions
└── README.md                         # This file
```

## Building the Agent

### Prerequisites

1. Install Visual Studio 2022 or .NET 8.0 SDK
2. Clone the repository

### Build Steps

```bash
cd windows-agent/RentComProAgent
dotnet restore
dotnet build --configuration Release
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Output will be in: `bin/Release/net8.0-windows/win-x64/publish/`

## Installation (Manual)

### 1. Copy Files

Copy the published folder to: `C:\Program Files\RentComPro\`

### 2. Configure

Edit `appsettings.json`:

```json
{
  "Agent": {
    "ApiBaseUrl": "https://rentcompro-backend.brajesh-jimmc.workers.dev",
    "DeviceId": "your-device-id",
    "DeviceToken": "your-device-token",
    "ReportingIntervalSeconds": 300,
    "EnableLocking": true,
    "EnableHardwareMonitoring": true
  }
}
```

### 3. Install as Windows Service

Run PowerShell as Administrator:

```powershell
sc.exe create "RentComProAgent" binPath= "C:\Program Files\RentComPro\RentComProAgent.exe"
sc.exe description "RentComProAgent" "RentComPro Device Monitoring Agent"
sc.exe start "RentComProAgent"

# Set to auto-start on boot
sc.exe config "RentComProAgent" start= auto
```

### 4. Verify Service

```powershell
Get-Service RentComProAgent
```

## Uninstallation

```powershell
sc.exe stop "RentComProAgent"
sc.exe delete "RentComProAgent"
```

Then delete: `C:\Program Files\RentComPro\`

## Building Installer (Advanced)

### Using Inno Setup

1. Install Inno Setup: https://jrsoftware.org/isdl.php
2. Open `Installer/setup.iss`
3. Compile

This creates: `RentComProAgent-Setup.exe`

## Features Detail

### Hardware Monitoring

Collects every 5 minutes (configurable):
- CPU usage percentage
- RAM usage (used/total)
- Disk usage (used/total)
- Network status
- Current logged-in user

### Remote Lock/Unlock

When server sends lock command:
- Blocks keyboard and mouse input
- Shows full-screen lock message
- Cannot be closed by Task Manager
- Only unlocks when server sends unlock command

### Security

- Device ID and token are encrypted locally
- Communication uses HTTPS
- Token expires after 24 hours
- Service runs under LocalSystem account

## API Integration

The agent communicates with backend via:

**POST** `/api/devices/stats`
```json
{
  "deviceId": "xxx",
  "cpuUsage": 45.5,
  "ramUsage": 60.2,
  "diskUsage": 75.0,
  "isOnline": true
}
```

**Response:**
```json
{
  "success": true,
  "lockStatus": false
}
```

## Troubleshooting

### Service won't start

Check Event Viewer:
- Windows Logs → Application
- Look for RentComProAgent errors

### Stats not reporting

1. Check internet connection
2. Verify API URL in config
3. Check device ID and token

### Lock not working

1. Verify `EnableLocking` is `true` in config
2. Check service is running as LocalSystem
3. Restart service

## Development

### Running in Debug Mode

```bash
dotnet run --configuration Debug
```

Press `Ctrl+C` to stop.

### Testing Lock Feature

The lock can be tested without server by directly calling:

```csharp
var lockService = new LockService();
lockService.LockDevice();
// Wait...
lockService.UnlockDevice();
```

## Logs

Logs are written to:
- Event Viewer (Application Log)
- File: `C:\ProgramData\RentComPro\logs\agent.log`

## Support

For issues, contact: brajesh.jimmc@gmail.com

---

**Version:** 1.0.0  
**Last Updated:** February 13, 2026  
**License:** Proprietary
