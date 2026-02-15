@echo off
echo ========================================
echo Jenkins Documentation Website Setup
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed!
    echo.
    echo Please install Python from: https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo [1/3] Python found!
echo.

REM Install MkDocs Material
echo [2/3] Installing MkDocs Material...
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install MkDocs Material
    pause
    exit /b 1
)

echo.
echo [3/3] Installation complete!
echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo To start the documentation website:
echo   mkdocs serve
echo.
echo Then open your browser to:
echo   http://127.0.0.1:8000
echo.
echo To build for production:
echo   mkdocs build
echo.
echo To deploy to GitHub Pages:
echo   mkdocs gh-deploy
echo.
pause
