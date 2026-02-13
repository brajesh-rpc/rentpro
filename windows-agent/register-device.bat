@echo off
title RentComPro Device Registration
color 0A
cls

echo ========================================
echo   RentComPro - Device Registration
echo ========================================
echo.

REM Collect device info
echo Collecting device information...
echo.

set DEVICE_NAME=
set /p DEVICE_NAME="Enter device name (e.g., Rajesh-i5): "

if "%DEVICE_NAME%"=="" (
    set DEVICE_NAME=%COMPUTERNAME%
    echo Using computer name: %DEVICE_NAME%
)

echo.
echo ========================================
echo   Admin Authentication Required
echo ========================================
echo.

set ADMIN_EMAIL=
set ADMIN_PASSWORD=

set /p ADMIN_EMAIL="Admin Email: "
set /p ADMIN_PASSWORD="Admin Password: "

echo.
echo Registering device with server...
echo.

REM Create temporary VBScript to call PowerShell and get output
echo Set objShell = CreateObject("WScript.Shell") > %TEMP%\register.vbs
echo objShell.Run "powershell -ExecutionPolicy Bypass -File ""%~dp0register-device.ps1"" -DeviceName ""%DEVICE_NAME%"" -AdminEmail ""%ADMIN_EMAIL%"" -AdminPassword ""%ADMIN_PASSWORD%""", 1, True >> %TEMP%\register.vbs

cscript //nologo %TEMP%\register.vbs
del %TEMP%\register.vbs

echo.
echo ========================================
echo   Check device-credentials.txt
echo   for your Device ID and Token
echo ========================================
echo.

pause
