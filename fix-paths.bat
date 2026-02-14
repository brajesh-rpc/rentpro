@echo off
echo Fixing paths in Frontend files...
echo.

cd Frontend

REM Fix paths using PowerShell
powershell -Command "(Get-Content 'index.html') -replace \"window.location.href = '/dashboard.html'\", \"window.location.href = '/Frontend/dashboard.html'\" | Set-Content 'index.html'"

powershell -Command "(Get-Content 'dashboard.html') -replace \"window.location.href = '/index.html'\", \"window.location.href = '/Frontend/index.html'\" | Set-Content 'dashboard.html'"

powershell -Command "(Get-Content 'dashboard.html') -replace \"href='/manage-clients.html'\", \"href='/Frontend/manage-clients.html'\" | Set-Content 'dashboard.html'"

powershell -Command "(Get-Content 'dashboard.html') -replace \"href='/add-device.html'\", \"href='/Frontend/add-device.html'\" | Set-Content 'dashboard.html'"

powershell -Command "(Get-Content 'dashboard.html') -replace \"href='/register-client.html'\", \"href='/Frontend/register-client.html'\" | Set-Content 'dashboard.html'"

powershell -Command "(Get-Content 'dashboard.html') -replace \"href='/invoices.html'\", \"href='/Frontend/invoices.html'\" | Set-Content 'dashboard.html'"

echo.
echo Done! Paths fixed.
echo.
echo Now:
echo 1. git add .
echo 2. git commit -m "Fix: Update paths for Frontend folder"
echo 3. git push origin main
echo.
pause
