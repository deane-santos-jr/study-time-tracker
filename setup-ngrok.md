# TimeTracker - External Access Setup with ngrok

## Step 1: Install ngrok

### Option A: Using Chocolatey (Recommended for Windows)
```bash
choco install ngrok
```

### Option B: Manual Download
1. Visit https://ngrok.com/download
2. Download the Windows version
3. Extract ngrok.exe to a folder
4. Add the folder to your PATH or move ngrok.exe to C:\Windows\System32

### Option C: Using npm
```bash
npm install -g ngrok
```

## Step 2: Sign up for ngrok (Free)
1. Visit https://dashboard.ngrok.com/signup
2. Sign up for a free account
3. Copy your authtoken from https://dashboard.ngrok.com/get-started/your-authtoken
4. Run: `ngrok config add-authtoken YOUR_TOKEN_HERE`

## Step 3: Start the Application

Run the provided start script:

```bash
# From the TimeTracker root directory
./start-with-ngrok.sh
```

Or manually:

### Terminal 1 - Backend
```bash
cd backend
npm run dev
```

### Terminal 2 - Frontend
```bash
cd frontend
npm run dev
```

### Terminal 3 - ngrok Backend Tunnel
```bash
ngrok http 3000
```

### Terminal 4 - ngrok Frontend Tunnel
```bash
ngrok http 3004  # Use the port shown in your frontend terminal
```

## Step 4: Configure Environment Variables

After starting ngrok, you'll see URLs like:
- Backend: `https://abc123.ngrok.io`
- Frontend: `https://xyz789.ngrok.io`

### Update backend/.env:
```env
CORS_ORIGIN=https://xyz789.ngrok.io
```

### Update frontend/.env:
```env
VITE_API_URL=https://abc123.ngrok.io/api/v1
```

### Restart both servers after updating .env files

## Step 5: Share with Your Friend

Send them the frontend ngrok URL:
```
https://xyz789.ngrok.io
```

## Important Notes

⚠️ **Free ngrok URLs change every time you restart ngrok**
- You'll need to update the .env files each time
- Consider upgrading to ngrok paid plan for static domains

⚠️ **Keep all terminals running**
- Backend server
- Frontend server
- Both ngrok tunnels

⚠️ **Firewall**
- ngrok handles this automatically
- No need to configure your router

## Troubleshooting

### "tunnel not found" error
- Make sure you've authenticated ngrok with your authtoken

### CORS errors
- Double-check CORS_ORIGIN matches your frontend ngrok URL exactly
- Restart the backend after changing .env

### Can't connect to database
- Make sure MySQL/XAMPP is running
- Check database credentials in backend/.env

### Frontend can't reach backend
- Verify VITE_API_URL in frontend/.env matches backend ngrok URL
- Restart frontend after changing .env
