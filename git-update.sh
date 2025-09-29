#!/bin/bash

echo "🚀 GIT UPDATE REPO SA SVIM DODACIMA"
echo "==================================="

# Check git status
echo "1. Git status:"
git status

echo ""
echo "2. Add all changes:"
git add .

echo ""
echo "3. Commit changes:"
git commit -m "🚀 MASTER INSTALLER - Complete MuMuDVB + OSCam + Web Panel solution

✅ Features:
- Auto MuMuDVB compilation from local folder
- Auto OSCam Schimmelreiter smod compilation 
- Master Web Panel on port 8887
- Complete systemd service management
- Fixed all JavaScript template literal issues
- CORS support with full configuration
- Health check endpoints
- Auto cleanup old installations
- One installer for everything

✅ Fixed Issues:
- Template literal escaping in server.js
- Node.js path auto-detection  
- npm install sequencing
- CORS configuration
- Service restart logic
- Syntax validation

✅ Usage:
chmod +x master-panel-install.sh
sudo ./master-panel-install.sh

Web Panel: http://IP:8887
OSCam Web: http://IP:8888
MuMuDVB HTTP: http://IP:4242"

echo ""
echo "4. Push to GitHub:"
git push origin main

echo ""
echo "✅ REPO UPDATED!"
echo "🌐 GitHub: https://github.com/adis992/MuMuDVB-WebPanel"