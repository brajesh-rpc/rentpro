# RentComPro Agent - Installation Script
# Run as Administrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RentComPro Agent - Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit
}

# Installation directory
$installPath = "C:\Program Files\RentComPro"
$serviceName = "RentComProAgent"

Write-Host "Installation Path: $installPath" -ForegroundColor Green
Write-Host ""

# Stop and remove existing service if exists
Write-Host "Checking for existing service..." -ForegroundColor Yellow
$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($existingService) {
    Write-Host "Stopping existing service..." -ForegroundColor Yellow
    Stop-Service -Name $serviceName -Force
    
    Write-Host "Removing existing service..." -ForegroundColor Yellow
    sc.exe delete $serviceName
    Start-Sleep -Seconds 2
}

# Create installation directory
if (-not (Test-Path $installPath)) {
    Write-Host "Creating installation directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}

# Copy files from publish folder
$publishPath = Join-Path $PSScriptRoot "publish"

if (-not (Test-Path $publishPath)) {
    Write-Host "ERROR: Publish folder not found!" -ForegroundColor Red
    Write-Host "Please run build.bat first to create the publish folder" -ForegroundColor Yellow
    pause
    exit
}

Write-Host "Copying files to installation directory..." -ForegroundColor Yellow
Copy-Item -Path "$publishPath\*" -Destination $installPath -Recurse -Force

# Prompt for Device ID and Token
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Device Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please enter device information from the admin panel:" -ForegroundColor Yellow
Write-Host ""

$deviceId = Read-Host "Device ID"
$deviceToken = Read-Host "Device Token"

# Update appsettings.json
$configPath = Join-Path $installPath "appsettings.json"
$config = Get-Content $configPath | ConvertFrom-Json
$config.Agent.DeviceId = $deviceId
$config.Agent.DeviceToken = $deviceToken
$config | ConvertTo-Json -Depth 10 | Set-Content $configPath

Write-Host ""
Write-Host "Configuration updated successfully!" -ForegroundColor Green
Write-Host ""

# Create and start Windows Service
Write-Host "Creating Windows Service..." -ForegroundColor Yellow
$exePath = Join-Path $installPath "RentComProAgent.exe"

sc.exe create $serviceName binPath= "`"$exePath`"" start= auto DisplayName= "RentComPro Device Agent"
sc.exe description $serviceName "Monitors device hardware and enables remote management for RentComPro"

Write-Host "Starting service..." -ForegroundColor Yellow
Start-Service -Name $serviceName

# Verify service status
Start-Sleep -Seconds 2
$service = Get-Service -Name $serviceName

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service Name: $serviceName" -ForegroundColor White
Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq 'Running') { 'Green' } else { 'Red' })
Write-Host "Installed Path: $installPath" -ForegroundColor White
Write-Host ""
Write-Host "The agent will now run automatically in the background" -ForegroundColor Green
Write-Host "and report hardware stats every 5 minutes." -ForegroundColor Green
Write-Host ""
Write-Host "To view service status: Get-Service $serviceName" -ForegroundColor Yellow
Write-Host "To stop service: Stop-Service $serviceName" -ForegroundColor Yellow
Write-Host "To start service: Start-Service $serviceName" -ForegroundColor Yellow
Write-Host ""

pause
