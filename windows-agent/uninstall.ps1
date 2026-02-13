# RentComPro Agent - Uninstallation Script
# Run as Administrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RentComPro Agent - Uninstallation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    pause
    exit
}

$serviceName = "RentComProAgent"
$installPath = "C:\Program Files\RentComPro"

# Confirm uninstallation
Write-Host "WARNING: This will remove RentComPro Agent from this device" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Uninstallation cancelled" -ForegroundColor Yellow
    pause
    exit
}

Write-Host ""

# Stop service
Write-Host "Stopping service..." -ForegroundColor Yellow
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    if ($service.Status -eq 'Running') {
        Stop-Service -Name $serviceName -Force
        Start-Sleep -Seconds 2
    }
    
    # Remove service
    Write-Host "Removing service..." -ForegroundColor Yellow
    sc.exe delete $serviceName
    Start-Sleep -Seconds 2
}

# Delete installation folder
if (Test-Path $installPath) {
    Write-Host "Removing installation files..." -ForegroundColor Yellow
    Remove-Item -Path $installPath -Recurse -Force
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Uninstallation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "RentComPro Agent has been removed from this device" -ForegroundColor Green
Write-Host ""

pause
