@echo off
echo ========================================
echo TimeTracker - ngrok Setup Helper
echo ========================================
echo.

REM Check if ngrok is installed
where ngrok >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ngrok is not installed!
    echo.
    echo Please install ngrok using one of these methods:
    echo 1. choco install ngrok
    echo 2. npm install -g ngrok
    echo 3. Download from https://ngrok.com/download
    echo.
    pause
    exit /b 1
)

echo ngrok is installed!
echo.
echo INSTRUCTIONS:
echo 1. Make sure your backend is running on port 3000
echo 2. Make sure your frontend is running (check the port)
echo 3. This script will start TWO ngrok tunnels
echo.
echo Press any key to start ngrok tunnels...
pause >nul

echo.
echo Starting ngrok for BACKEND (port 3000)...
echo.
start "ngrok-backend" cmd /k "ngrok http 3000"

timeout /t 3 >nul

echo.
echo Starting ngrok for FRONTEND (port 3004)...
echo NOTE: Change the port if your frontend is running on a different port!
echo.
start "ngrok-frontend" cmd /k "ngrok http 3004"

echo.
echo ========================================
echo ngrok tunnels started!
echo ========================================
echo.
echo NEXT STEPS:
echo.
echo 1. Copy the ngrok URLs from both windows
echo    - Backend URL (from port 3000 window)
echo    - Frontend URL (from port 3004 window)
echo.
echo 2. Update backend/.env:
echo    CORS_ORIGIN=your-frontend-ngrok-url
echo.
echo 3. Update frontend/.env:
echo    VITE_API_URL=your-backend-ngrok-url/api/v1
echo.
echo 4. Restart both backend and frontend servers
echo.
echo 5. Share the frontend ngrok URL with your friend!
echo.
echo ========================================
echo.
pause
