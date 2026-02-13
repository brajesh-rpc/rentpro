@echo off
echo ========================================
echo RentComPro Agent - Build Script
echo ========================================
echo.

cd /d "%~dp0RentComProAgent"

echo Cleaning previous build...
dotnet clean

echo.
echo Restoring packages...
dotnet restore

echo.
echo Building Release version...
dotnet build --configuration Release

echo.
echo Publishing self-contained executable...
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output "..\publish"

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo Output folder: %~dp0publish
echo.
pause
