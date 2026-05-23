@echo off
echo Starting TimeTracker Application...
echo.

REM Start Backend Server
echo Starting Backend Server...
start "TimeTracker Backend" cmd /k "cd /d %~dp0backend && npm run dev"

REM Wait a moment for backend to initialize
timeout /t 3 /nobreak >nul

REM Start Frontend Server
echo Starting Frontend Server...
start "TimeTracker Frontend" cmd /k "cd /d %~dp0frontend && npm run dev"

echo.
echo All services started!
echo - Backend: http://localhost:3000
echo - Frontend: http://localhost:3001
echo.
echo NOTE: ngrok is NOT started automatically.
echo To expose your app externally, run: start-ngrok.bat
echo.
echo Press any key to exit this window (services will continue running)
pause >nul
