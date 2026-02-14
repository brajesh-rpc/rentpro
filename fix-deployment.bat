@echo off
echo Fixing Cloudflare Pages deployment issue...
echo.

REM Backup and delete wrangler.toml from root
echo Backing up wrangler.toml...
copy wrangler.toml wrangler.toml.backup >nul 2>&1
del wrangler.toml

echo.
echo ✓ wrangler.toml removed from root
echo ✓ Backup saved as wrangler.toml.backup
echo.
echo Now committing changes...

git add .
git commit -m "Fix: Remove wrangler.toml from root to fix Pages deployment"
git push origin main

echo.
echo ========================================
echo   Done!
echo ========================================
echo.
echo Cloudflare Pages will now deploy correctly.
echo.
echo Wait 2 minutes, then test:
echo   https://rentpro.pages.dev/
echo.
pause
