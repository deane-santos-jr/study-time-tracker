# 🌐 External Access Setup - Quick Start Guide

Share your TimeTracker app with anyone, anywhere!

## 📋 Prerequisites

- ✅ Backend running on port 3000
- ✅ Frontend running (usually port 3004)
- ✅ MySQL/XAMPP running
- ⬜ ngrok installed

## 🚀 Quick Setup (5 minutes)

### Step 1: Install ngrok

Choose ONE method:

**Option A - Using Chocolatey (easiest for Windows):**
```bash
choco install ngrok
```

**Option B - Using npm:**
```bash
npm install -g ngrok
```

**Option C - Manual Download:**
1. Visit https://ngrok.com/download
2. Download & extract
3. Move `ngrok.exe` to `C:\Windows\System32`

### Step 2: Create ngrok Account (Free)

1. Sign up at https://dashboard.ngrok.com/signup
2. Get your authtoken from https://dashboard.ngrok.com/get-started/your-authtoken
3. Run this command with YOUR token:
   ```bash
   ngrok config add-authtoken YOUR_TOKEN_HERE
   ```

### Step 3: Start Everything

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
```

**Terminal 3 - Run the helper script:**
```bash
# Double-click: start-ngrok.bat
# Or run from command line:
start-ngrok.bat
```

This will open TWO new windows showing your ngrok URLs!

### Step 4: Copy Your URLs

Look for lines like this in the ngrok windows:

```
Forwarding    https://abc123.ngrok.io -> http://localhost:3000
```

You'll have TWO URLs:
- **Backend URL**: `https://abc123.ngrok.io` (from port 3000)
- **Frontend URL**: `https://xyz789.ngrok.io` (from port 3004)

### Step 5: Update Configuration

**Create `backend/.env` file** (copy from `.env.example`):
```env
PORT=3000
NODE_ENV=development

CORS_ORIGIN=https://xyz789.ngrok.io

DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=
DB_DATABASE=timetracker

JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production
JWT_REFRESH_EXPIRES_IN=30d
```

**Create `frontend/.env` file:**
```env
VITE_API_URL=https://abc123.ngrok.io/api/v1
```

### Step 6: Restart Servers

Press `Ctrl+C` in both server terminals, then restart:

```bash
# Terminal 1
cd backend
npm run dev

# Terminal 2
cd frontend
npm run dev
```

### Step 7: Share with Your Friend! 🎉

Send them your **frontend URL**:
```
https://xyz789.ngrok.io
```

They can now access your TimeTracker app from anywhere in the world!

---

## 🔄 Every Time You Start

Since free ngrok URLs change each session:

1. Run `start-ngrok.bat`
2. Copy the new URLs
3. Update both `.env` files
4. Restart both servers

**💡 Tip:** Upgrade to ngrok Pro ($8/month) for permanent URLs!

---

## ⚠️ Important Notes

### Keep Running
All of these must stay open:
- ✅ Backend server (Terminal 1)
- ✅ Frontend server (Terminal 2)
- ✅ ngrok backend tunnel (Window 1)
- ✅ ngrok frontend tunnel (Window 2)

### Security
- ✅ ngrok provides HTTPS automatically
- ✅ Your JWT tokens keep the API secure
- ✅ CORS protects against unauthorized domains

### Free Tier Limits
- URLs change every restart
- 40 connections/minute limit
- Tunnels timeout after 2 hours of inactivity

---

## 🐛 Troubleshooting

### "ngrok command not found"
➡️ ngrok isn't installed or not in PATH
- Try: `npm install -g ngrok`
- Or reinstall following Step 1

### "ERR_NGROK_108" or "tunnel not found"
➡️ You need to authenticate ngrok
- Get authtoken from https://dashboard.ngrok.com
- Run: `ngrok config add-authtoken YOUR_TOKEN`

### CORS errors in browser
➡️ Check backend `.env` CORS_ORIGIN
- Must EXACTLY match your frontend ngrok URL
- Include `https://` and no trailing slash
- Restart backend after changing

### Frontend can't reach backend
➡️ Check frontend `.env` VITE_API_URL
- Must EXACTLY match your backend ngrok URL
- Include `/api/v1` at the end
- Restart frontend after changing

### "Cannot connect to database"
➡️ Make sure XAMPP/MySQL is running
- Check database name in backend `.env`
- Verify credentials are correct

---

## 📞 Need Help?

Check the detailed guide: `setup-ngrok.md`

Happy studying! 📚✨
