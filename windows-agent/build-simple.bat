@echo off
echo =========================================
echo   RentComPro Agent - Build Script
echo =========================================
echo.

REM Check if .NET SDK is installed
dotnet --version >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: .NET SDK not found!
    echo.
    echo Please install .NET 8 SDK from:
    echo https://dotnet.microsoft.com/download/dotnet/8.0
    echo.
    echo Look for: ".NET 8.0 SDK (recommended)"
    echo Download and install, then run this script again.
    echo.
    pause
    exit /b 1
)

echo ✓ .NET SDK found
dotnet --version
echo.

echo Building RentComPro Agent...
echo.

cd RentComProAgent

REM Clean previous builds
echo Cleaning previous builds...
dotnet clean >nul 2>&1

REM Restore packages
echo Restoring packages...
dotnet restore

REM Build the project
echo Building project...
dotnet build -c Release

if %errorLevel% neq 0 (
    echo.
    echo ❌ Build failed! Check errors above.
    pause
    exit /b 1
)

REM Publish as single executable
echo Publishing as single file...
dotnet publish -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true -o ..\publish

if %errorLevel% neq 0 (
    echo.
    echo ❌ Publish failed! Check errors above.
    pause
    exit /b 1
)

cd ..

echo.
echo =========================================
echo   Build Successful! ✓
echo =========================================
echo.
echo EXE Location: publish\RentComProAgent.exe
echo Size: Checking...
dir publish\RentComProAgent.exe | find "RentComProAgent.exe"
echo.
echo Next steps:
echo 1. Test the agent locally
echo 2. Copy to installer folder
echo 3. Deploy to client machines
echo.
pause
