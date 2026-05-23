# ngrok Setup Guide

## Prerequisites
1. Install ngrok from https://ngrok.com/download
2. Create a free ngrok account at https://dashboard.ngrok.com/signup
3. Get your authtoken from https://dashboard.ngrok.com/get-started/your-authtoken

## Configuration

1. Open `ngrok.yml` in the root directory
2. Replace `YOUR_NGROK_AUTH_TOKEN_HERE` with your actual ngrok authtoken

Example:
```yaml
authtoken: 2abc123def456ghi789jkl0mno1pqr2stuvwxyz
```

## Usage

### Option 1: Quick Start (Recommended for Local Development)
Simply run:
```bash
start-all.bat
```
This will start:
- Backend server (http://localhost:3000)
- Frontend server (http://localhost:3001)
- **Note:** ngrok is NOT started automatically to speed up startup

### Option 2: Start Everything Including ngrok
If you need external access, run:
```bash
start-all-with-ngrok.bat
```
This will start:
- Backend server (http://localhost:3000)
- Frontend server (http://localhost:3001)
- ngrok tunnel (public HTTPS URL)
- **Note:** This takes longer to start (waits for services to fully initialize)

### Option 3: Start Services Individually
```bash
start-backend.bat   # Start only backend
start-frontend.bat  # Start only frontend
start-ngrok.bat     # Start only ngrok tunnel (run this AFTER frontend is ready)
```

## Access Your Application

### Local Development (start-all.bat)
- Local frontend: http://localhost:3001
- Local backend: http://localhost:3000

### With ngrok (start-all-with-ngrok.bat or start-ngrok.bat)
- Local frontend: http://localhost:3001
- Local backend: http://localhost:3000
- Public URL: Check the ngrok window for your public HTTPS URL (e.g., https://xxxx-xx-xx-xxx-xxx.ngrok-free.app)

## Notes

- **For faster startup:** Use `start-all.bat` which skips ngrok (only starts backend + frontend)
- **For external access:** Use `start-all-with-ngrok.bat` or manually run `start-ngrok.bat` after services are ready
- The ngrok tunnel URL changes every time you restart ngrok (unless you have a paid plan)
- The frontend is configured to allow ngrok hosts (`.ngrok-free.dev` domain)
- All services run in separate command windows, so you can monitor their logs individually
- To stop a service, close its command window or press Ctrl+C in that window
- If ngrok shows errors, make sure the frontend is fully loaded on http://localhost:3001 first
