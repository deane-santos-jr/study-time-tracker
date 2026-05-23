@echo off
echo Starting TimeTracker Application with ngrok...
echo.

REM Start Backend Server
echo Starting Backend Server...
start "TimeTracker Backend" cmd /k "cd /d %~dp0backend && npm run dev"

REM Wait for backend to initialize
timeout /t 5 /nobreak >nul

REM Start Frontend Server
echo Starting Frontend Server...
start "TimeTracker Frontend" cmd /k "cd /d %~dp0frontend && npm run dev"

REM Wait for frontend to fully initialize (longer wait for Vite)
echo Waiting for frontend to start...
timeout /t 10 /nobreak >nul

REM Start ngrok tunnel
echo Starting ngrok tunnel...
start "ngrok Tunnel" cmd /k "cd /d %~dp0 && ngrok start --config ngrok.yml frontend"

echo.
echo All services started including ngrok!
echo - Backend: http://localhost:3000
echo - Frontend: http://localhost:3001
echo - ngrok: Check the ngrok window for your public URL
echo.
echo Press any key to exit this window (services will continue running)
pause >nul
