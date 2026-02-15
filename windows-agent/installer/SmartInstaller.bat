@echo off
title RentComPro - Smart Installer
color 0A

echo ========================================
echo   RentComPro Smart Installation
echo ========================================
echo.

REM Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Run as Administrator!
    pause
    exit /b 1
)

echo [1/4] Detecting Device Serial Number...
echo.

REM Auto-detect serial using WMIC
for /f "tokens=2 delims==" %%i in ('wmic bios get serialnumber /value ^| find "="') do set AUTO_SERIAL=%%i

REM Clean whitespace
set AUTO_SERIAL=%AUTO_SERIAL: =%

if "%AUTO_SERIAL%"=="" (
    echo Could not auto-detect serial number
    echo.
    goto MANUAL_SERIAL
)

if "%AUTO_SERIAL%"=="To Be Filled By O.E.M." (
    echo Generic serial detected, need custom number
    echo.
    goto MANUAL_SERIAL
)

echo Detected Serial: %AUTO_SERIAL%
echo.
choice /C YN /M "Use this serial number"
if errorlevel 2 goto MANUAL_SERIAL

set SERIAL_NUMBER=%AUTO_SERIAL%
goto INSTALL

:MANUAL_SERIAL
echo.
set /p SERIAL_NUMBER="Enter Serial Number (or custom ID like RENT-001): "

if "%SERIAL_NUMBER%"=="" (
    echo Serial number required!
    goto MANUAL_SERIAL
)

:INSTALL
echo.
echo ========================================
echo   Installing with Serial: %SERIAL_NUMBER%
echo ========================================
echo.

REM Check existing
sc query RentComProAgent >nul 2>&1
if %errorLevel% equ 0 (
    echo Removing existing installation...
    net stop RentComProAgent >nul 2>&1
    sc delete RentComProAgent >nul 2>&1
    timeout /t 2 >nul
)

echo [2/4] Installing files...

set INSTALL_DIR=C:\Program Files\RentComProAgent
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy /Y "RentComProAgent.exe" "%INSTALL_DIR%\" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy agent files!
    echo Make sure RentComProAgent.exe is in same folder
    pause
    exit /b 1
)

REM Create config
(
echo {
echo   "ApiUrl": "https://rentcompro-backend.brajesh-jimmc.workers.dev",
echo   "SerialNumber": "%SERIAL_NUMBER%",
echo   "UpdateIntervalMinutes": 5
echo }
) > "%INSTALL_DIR%\appsettings.json"

echo [3/4] Registering service...
sc create RentComProAgent binPath= "%INSTALL_DIR%\RentComProAgent.exe" start= auto DisplayName= "RentComPro Agent"
if errorlevel 1 (
    echo ERROR: Failed to register service!
    pause
    exit /b 1
)

echo [4/4] Starting service...
net start RentComProAgent
if errorlevel 1 (
    echo WARNING: Service started but may have issues
    echo Check Event Viewer for details
)

echo.
echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo Serial Number: %SERIAL_NUMBER%
echo Service: RentComPro Agent
echo Status: Running
echo.
echo The device will now:
echo - Register with backend
echo - Send hardware info
echo - Monitor system every 5 minutes
echo.
echo NEXT STEPS:
echo 1. Check dashboard - device should appear online
echo 2. Assign device to client
echo 3. Verify monitoring working
echo.

pause
