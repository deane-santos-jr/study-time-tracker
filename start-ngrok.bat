@echo off
echo Starting ngrok tunnel for TimeTracker Frontend...
echo.
echo IMPORTANT: Make sure the frontend is running on http://localhost:3001
echo           before ngrok can tunnel to it!
echo.
echo Frontend URL: http://localhost:3001
echo.
ngrok start --config ngrok.yml frontend
