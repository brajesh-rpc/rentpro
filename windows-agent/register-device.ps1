# RentComPro Agent - Device Registration Tool
# This tool registers the device with the server and gets Device ID & Token

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RentComPro - Device Registration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# API Configuration
$apiBaseUrl = "https://rentcompro-backend.brajesh-jimmc.workers.dev"

Write-Host "This tool will register this device with RentComPro server" -ForegroundColor Yellow
Write-Host ""

# Collect device information
Write-Host "Step 1: Collecting device information..." -ForegroundColor Green
Write-Host ""

$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME
$osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Caption

# Get hardware info
$cpu = (Get-WmiObject -Class Win32_Processor).Name
$ramGB = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$diskGB = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB, 2)

Write-Host "Computer Name: $computerName" -ForegroundColor White
Write-Host "Current User: $userName" -ForegroundColor White
Write-Host "OS: $osVersion" -ForegroundColor White
Write-Host "CPU: $cpu" -ForegroundColor White
Write-Host "RAM: $ramGB GB" -ForegroundColor White
Write-Host "Disk: $diskGB GB" -ForegroundColor White
Write-Host ""

# Ask for human-friendly device name
Write-Host "Step 2: Device Name" -ForegroundColor Green
Write-Host ""
Write-Host "Enter a friendly name for this device (e.g., 'Rajesh-i5', 'Office-1'):" -ForegroundColor Yellow
$deviceName = Read-Host "Device Name"

if ([string]::IsNullOrWhiteSpace($deviceName)) {
    $deviceName = $computerName
    Write-Host "Using computer name: $deviceName" -ForegroundColor Yellow
}

Write-Host ""

# Ask for admin credentials for registration
Write-Host "Step 3: Admin Authentication" -ForegroundColor Green
Write-Host ""
Write-Host "Enter admin credentials to register this device:" -ForegroundColor Yellow
$adminEmail = Read-Host "Admin Email"
$adminPassword = Read-Host "Admin Password" -AsSecureString

# Convert secure string to plain text for API call
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host ""
Write-Host "Step 4: Registering device with server..." -ForegroundColor Green
Write-Host ""

try {
    # Step 1: Login to get admin token
    Write-Host "Authenticating admin..." -ForegroundColor Yellow
    
    $loginBody = @{
        email = $adminEmail
        password = $plainPassword
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$apiBaseUrl/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"

    if (-not $loginResponse.success) {
        Write-Host "ERROR: Authentication failed - $($loginResponse.message)" -ForegroundColor Red
        pause
        exit
    }

    $adminToken = $loginResponse.data.token
    Write-Host "Admin authenticated successfully!" -ForegroundColor Green
    Write-Host ""

    # Step 2: Register device
    Write-Host "Registering device..." -ForegroundColor Yellow
    
    $deviceInfo = @{
        computerName = $computerName
        userName = $userName
        osVersion = $osVersion
        cpu = $cpu
        ramGB = $ramGB
        diskGB = $diskGB
    } | ConvertTo-Json

    $registerBody = @{
        deviceName = $deviceName
        deviceInfo = $deviceInfo
    } | ConvertTo-Json

    $headers = @{
        "Authorization" = "Bearer $adminToken"
        "Content-Type" = "application/json"
    }

    $registerResponse = Invoke-RestMethod -Uri "$apiBaseUrl/api/devices/register" -Method Post -Body $registerBody -Headers $headers

    if (-not $registerResponse.success) {
        Write-Host "ERROR: Device registration failed - $($registerResponse.message)" -ForegroundColor Red
        pause
        exit
    }

    # Success!
    $deviceId = $registerResponse.data.deviceId
    $deviceToken = $registerResponse.data.deviceToken

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Registration Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Device Name: $deviceName" -ForegroundColor White
    Write-Host "Device ID: $deviceId" -ForegroundColor Yellow
    Write-Host "Device Token: $deviceToken" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "IMPORTANT: Save these credentials!" -ForegroundColor Red
    Write-Host ""

    # Save to file
    $credFile = "device-credentials.txt"
    $credContent = @"
RentComPro Device Credentials
==============================

Device Name: $deviceName
Device ID: $deviceId
Device Token: $deviceToken

Computer: $computerName
Registered: $(Get-Date)

KEEP THIS FILE SAFE!
"@

    $credContent | Out-File -FilePath $credFile -Encoding UTF8
    Write-Host "Credentials saved to: $credFile" -ForegroundColor Green
    Write-Host ""

    # Ask if user wants to install agent now
    Write-Host "Do you want to install the RentComPro Agent now? (yes/no)" -ForegroundColor Yellow
    $installNow = Read-Host

    if ($installNow -eq "yes") {
        Write-Host ""
        Write-Host "Starting installation..." -ForegroundColor Green
        
        # Update appsettings.json if it exists
        $publishPath = Join-Path $PSScriptRoot "publish"
        $configPath = Join-Path $publishPath "appsettings.json"
        
        if (Test-Path $configPath) {
            $config = Get-Content $configPath | ConvertFrom-Json
            $config.Agent.DeviceId = $deviceId
            $config.Agent.DeviceToken = $deviceToken
            $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
            Write-Host "Configuration file updated" -ForegroundColor Green
        }

        # Run install script
        $installScript = Join-Path $PSScriptRoot "install.ps1"
        if (Test-Path $installScript) {
            & $installScript
        } else {
            Write-Host "ERROR: install.ps1 not found!" -ForegroundColor Red
            Write-Host "Please run install.ps1 manually with these credentials" -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "Installation skipped" -ForegroundColor Yellow
        Write-Host "To install later, run: install.ps1" -ForegroundColor Yellow
        Write-Host "Use the Device ID and Token from $credFile" -ForegroundColor Yellow
    }

} catch {
    Write-Host ""
    Write-Host "ERROR: Registration failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "1. Check internet connection" -ForegroundColor White
    Write-Host "2. Verify admin email and password" -ForegroundColor White
    Write-Host "3. Ensure backend server is running" -ForegroundColor White
    Write-Host ""
}

Write-Host ""
pause
