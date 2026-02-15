@echo off
title RentComPro Agent - Test Installation
color 0A

echo =========================================
echo   RentComPro Agent - Test Install
echo =========================================
echo.

REM Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Run as Administrator!
    echo Right-click and select "Run as Administrator"
    pause
    exit /b 1
)

echo Checking if agent already installed...
sc query RentComProAgent >nul 2>&1
if %errorLevel% equ 0 (
    echo Removing existing installation...
    net stop RentComProAgent
    sc delete RentComProAgent
    timeout /t 2 >nul
)

echo.
echo Installing to: C:\Program Files\RentComProAgent
echo.

set INSTALL_DIR=C:\Program Files\RentComProAgent
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Copying files...
copy /Y "RentComProAgent.exe" "%INSTALL_DIR%\" >nul

REM Create test config
(
echo {
echo   "ApiUrl": "https://rentcompro-backend.brajesh-jimmc.workers.dev",
echo   "SerialNumber": "TEST-DEVICE",
echo   "UpdateIntervalMinutes": 5
echo }
) > "%INSTALL_DIR%\appsettings.json"

echo Registering Windows Service...
sc create RentComProAgent binPath= "%INSTALL_DIR%\RentComProAgent.exe" start= auto DisplayName= "RentComPro Agent"

echo Starting service...
net start RentComProAgent

echo.
echo =========================================
echo   Installation Complete!
echo =========================================
echo.
echo Testing MAC detection...
echo Check output below:
echo.

REM Wait for service to start
timeout /t 3 >nul

REM Check service status
sc query RentComProAgent

echo.
echo Check Windows Services:
echo Press Win+R, type: services.msc
echo Find: RentComPro Agent
echo Status should be: Running
echo.
pause
