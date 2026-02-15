@echo off
title RentComPro - Field Installer
color 0A

echo ========================================
echo   RentComPro Device Installation
echo ========================================
echo.

REM Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This installer requires Administrator privileges!
    echo.
    echo Right-click this file and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo [1/5] Checking system...
echo.

REM Check if service already installed
sc query RentComProAgent >nul 2>&1
if %errorLevel% equ 0 (
    echo WARNING: RentComPro Agent is already installed!
    echo.
    choice /C YN /M "Do you want to reinstall"
    if errorlevel 2 goto :END
    
    echo Stopping existing service...
    net stop RentComProAgent
    sc delete RentComProAgent
    timeout /t 2 >nul
)

echo.
echo [2/5] Device Registration
echo ========================================
echo.

REM Get serial number
:GET_SERIAL
set /p SERIAL_NUMBER="Enter Device Serial Number: "

if "%SERIAL_NUMBER%"=="" (
    echo ERROR: Serial number required!
    goto :GET_SERIAL
)

echo.
echo Serial: %SERIAL_NUMBER%
choice /C YN /M "Correct"
if errorlevel 2 goto :GET_SERIAL

echo.
echo [3/5] Installing Agent...

REM Install directory
set INSTALL_DIR=C:\Program Files\RentComProAgent
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy /Y "RentComProAgent.exe" "%INSTALL_DIR%\" >nul

REM Config
(
echo {
echo   "ApiUrl": "https://rentcompro-backend.brajesh-jimmc.workers.dev",
echo   "SerialNumber": "%SERIAL_NUMBER%",
echo   "UpdateIntervalMinutes": 5
echo }
) > "%INSTALL_DIR%\appsettings.json"

echo.
echo [4/5] Register Service...
sc create RentComProAgent binPath= "%INSTALL_DIR%\RentComProAgent.exe" start= auto

echo.
echo [5/5] Start Service...
net start RentComProAgent

echo.
echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo Device: %SERIAL_NUMBER%
echo Status: Running
echo.
pause

:END
