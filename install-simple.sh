#!/bin/bash

# JEDNOSTAVAN Ubuntu 20.04 MuMuDVB installer  
# Preskače sve problematične pakete

echo "🚀 JEDNOSTAVAN MuMuDVB Installer za Ubuntu 20.04"
echo "==============================================="

print_status() { echo -e "🔄 \e[34m$1\e[0m"; }
print_success() { echo -e "✅ \e[32m$1\e[0m"; }
print_error() { echo -e "❌ \e[31m$1\e[0m"; }

# Update sistema
print_status "Ažuriranje sistema..."
sudo apt update && sudo apt upgrade -y

# Osnovni paketi
print_status "Instaliranje osnovnih paketa..."
sudo apt install -y \
    build-essential \
    git \
    wget \
    curl \
    vim \
    htop \
    linux-headers-$(uname -r)

# Samo sigurni DVB paketi
print_status "Instaliranje DVB paketa (samo oni koji postoje)..."
sudo apt install -y dvb-tools 2>/dev/null || true
sudo apt install -y w-scan 2>/dev/null || true  
sudo apt install -y libdvbv5-dev 2>/dev/null || true

print_success "Osnovni paketi instalirani!"

# Node.js 18
print_status "Instaliranje Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Provera Node.js
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    print_success "Node.js: $(node --version)"
    print_success "npm: $(npm --version)"
else
    print_error "Node.js instalacija neuspešna!"
    exit 1
fi

# Skidanje MuMuDVB
print_status "Skidanje MuMuDVB source koda..."
cd /tmp
rm -rf MuMuDVB 2>/dev/null || true
git clone https://github.com/braice/MuMuDVB.git

# Kompajliranje MuMuDVB
print_status "Kompajliranje MuMuDVB..."
cd MuMuDVB

# Configure with CAM support
if ./configure --enable-cam-support --enable-scam-support; then
    print_success "Configure uspešan!"
else
    print_error "Configure neuspešan!"
    exit 1
fi

# Make
if make; then
    print_success "Kompajliranje uspešno!"
else
    print_error "Kompajliranje neuspešno!"
    exit 1  
fi

# Install
if sudo make install; then
    print_success "MuMuDVB instaliran!"
else
    print_error "Instalacija neuspešna!"
    exit 1
fi

# Kreiranje web panel foldera
print_status "Kreiranje web panel strukture..."
cd /opt
sudo mkdir -p mumudvb-webpanel
sudo chown $USER:$USER mumudvb-webpanel
cd mumudvb-webpanel

# Web Panel files
print_status "Kreiranje web panel fajlova..."

# Package.json
cat > package.json << 'EOF'
{
  "name": "mumudvb-webpanel",
  "version": "1.0.0",
  "description": "MuMuDVB Web Management Panel",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "ws": "^8.13.0",
    "multer": "^1.4.5-lts.1"
  }
}
EOF

# Instaliranje npm paketa
print_status "Instaliranje web panel zavistnosti..."
npm install

# Server.js (jednostavan)
cat > server.js << 'EOF'
const express = require('express');
const path = require('path');
const { exec } = require('child_process');
const WebSocket = require('ws');
const fs = require('fs');

const app = express();
const port = 8080;

// Static files
app.use(express.static('public'));
app.use(express.json());

// Basic routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start MuMuDVB
app.post('/api/start-mumudvb', (req, res) => {
    exec('mumudvb -d -c /etc/mumudvb/mumudvb.conf', (error, stdout, stderr) => {
        if (error) {
            res.json({ success: false, error: error.message });
        } else {
            res.json({ success: true, output: stdout });
        }
    });
});

// Stop MuMuDVB  
app.post('/api/stop-mumudvb', (req, res) => {
    exec('pkill mumudvb', (error, stdout, stderr) => {
        res.json({ success: true });
    });
});

// Check status
app.get('/api/status', (req, res) => {
    exec('pgrep mumudvb', (error, stdout, stderr) => {
        const running = !error && stdout.trim() !== '';
        res.json({ running: running, pid: stdout.trim() });
    });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 MuMuDVB Web Panel running at http://localhost:${port}`);
    console.log(`📡 Access from network: http://YOUR_SERVER_IP:${port}`);
});
EOF

# Public folder
mkdir -p public

# HTML
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>MuMuDVB Web Panel</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .running { background: #d4edda; color: #155724; }
        .stopped { background: #f8d7da; color: #721c24; }
        button { padding: 10px 20px; margin: 5px; cursor: pointer; }
        .start { background: #28a745; color: white; border: none; }
        .stop { background: #dc3545; color: white; border: none; }
        .info { background: #17a2b8; color: white; border: none; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 MuMuDVB Web Panel</h1>
        
        <div id="status" class="status stopped">
            📡 MuMuDVB Status: Checking...
        </div>
        
        <div>
            <button class="start" onclick="startMuMuDVB()">▶️ Start MuMuDVB</button>
            <button class="stop" onclick="stopMuMuDVB()">⏹️ Stop MuMuDVB</button>
            <button class="info" onclick="checkStatus()">🔄 Refresh Status</button>
        </div>
        
        <div id="output" style="margin-top: 20px; padding: 10px; background: #f8f9fa; border-radius: 5px; white-space: pre-wrap; font-family: monospace;"></div>
    </div>

    <script>
        function updateStatus(running, pid) {
            const statusDiv = document.getElementById('status');
            if (running) {
                statusDiv.className = 'status running';
                statusDiv.innerHTML = `📡 MuMuDVB Status: Running (PID: ${pid})`;
            } else {
                statusDiv.className = 'status stopped';
                statusDiv.innerHTML = '📡 MuMuDVB Status: Stopped';
            }
        }

        function checkStatus() {
            fetch('/api/status')
                .then(r => r.json())
                .then(data => updateStatus(data.running, data.pid));
        }

        function startMuMuDVB() {
            fetch('/api/start-mumudvb', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    document.getElementById('output').textContent = 
                        data.success ? data.output : data.error;
                    setTimeout(checkStatus, 1000);
                });
        }

        function stopMuMuDVB() {
            fetch('/api/stop-mumudvb', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    document.getElementById('output').textContent = 'MuMuDVB stopped';
                    setTimeout(checkStatus, 1000);
                });
        }

        // Check status on load
        checkStatus();
        setInterval(checkStatus, 5000);
    </script>
</body>
</html>
EOF

# MuMuDVB config folder
print_status "Kreiranje MuMuDVB konfiguracije..."
sudo mkdir -p /etc/mumudvb
sudo tee /etc/mumudvb/mumudvb.conf > /dev/null << 'EOF'
# MuMuDVB osnovni config
freq=11538000
pol=h
srate=22000000
card=0
tuner=0

autoconfiguration=full
autoconf_unicast_start_port=8100
autoconf_multicast_port=1234

common_port=8080
cam_support=1
scam_support=1
EOF

# Systemd service
print_status "Kreiranje systemd servisa..."
sudo tee /etc/systemd/system/mumudvb-webpanel.service > /dev/null << EOF
[Unit]
Description=MuMuDVB Web Panel
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/mumudvb-webpanel
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable service
sudo systemctl daemon-reload
sudo systemctl enable mumudvb-webpanel

print_success "🎯 INSTALACIJA ZAVRŠENA!"
echo ""
echo "📋 REZULTATI:"
echo "   ✅ MuMuDVB instaliran: $(which mumudvb || echo 'GREŠKA')"
echo "   ✅ Web panel: /opt/mumudvb-webpanel"
echo "   ✅ Servis: mumudvb-webpanel"
echo ""
echo "🚀 POKRETANJE:"
echo "   sudo systemctl start mumudvb-webpanel"
echo "   http://localhost:8080"
echo ""
echo "📡 Za DVB-S karticu edituj:"
echo "   sudo nano /etc/mumudvb/mumudvb.conf"
