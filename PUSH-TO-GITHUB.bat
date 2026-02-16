@echo off
echo ========================================
echo Git Push Helper Script
echo ========================================
echo.
echo Current repository: suraj-learning3427/GCP-VPN-Project
echo.
echo Step 1: Clearing old Git credentials...
cmdkey /delete:LegacyGeneric:target=git:https://github.com 2>nul
echo Done!
echo.
echo Step 2: Attempting to push...
echo You will be prompted to sign in with GitHub account: suraj-learning3427
echo.
pause
git push -u origin main
echo.
echo ========================================
if %errorlevel% equ 0 (
    echo SUCCESS! Project pushed to GitHub!
    echo Visit: https://github.com/suraj-learning3427/GCP-VPN-Project
) else (
    echo FAILED! Please check the error above.
    echo.
    echo Alternative: Use GitHub Desktop
    echo 1. Open GitHub Desktop
    echo 2. Sign in with suraj-learning3427 account
    echo 3. Add this repository
    echo 4. Click "Push origin"
)
echo ========================================
pause
