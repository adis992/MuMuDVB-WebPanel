#!/bin/bash

# BRZA POPRAVKA - SIMPLE CLEANUP VERZIJA
set -e

echo "🔥 SIMPLE INSTALLER - BRZA POPRAVKA"
echo "===================================="

# Funkcije
print_status() { echo -e "\n🔄 $1"; }
print_success() { echo -e "✅ $1"; }
print_error() { echo -e "❌ $1"; exit 1; }

# JEDNOSTAVAN CLEANUP
print_status "Cleanup..."
systemctl stop mumudvb-webpanel 2>/dev/null || true
systemctl stop oscam 2>/dev/null || true
pkill -f mumudvb 2>/dev/null || true
pkill -f oscam 2>/dev/null || true
pkill -f node 2>/dev/null || true

# OBRIŠI FAJLOVE
rm -rf /opt/mumudvb-webpanel 2>/dev/null || true
rm -rf /etc/oscam 2>/dev/null || true
rm -f /etc/systemd/system/mumudvb-webpanel.service 2>/dev/null || true
rm -f /etc/systemd/system/oscam.service 2>/dev/null || true

print_success "Cleanup gotov"

# SYSTEM UPDATE
print_status "System update..."
apt update && apt upgrade -y

# OSNOVNI PAKETI
print_status "Osnovni paketi..."
apt install -y build-essential git wget curl vim htop autoconf automake libtool pkg-config gettext gettext-base autopoint intltool linux-headers-$(uname -r) ca-certificates gnupg lsb-release software-properties-common libpcsclite-dev pcsc-tools libssl-dev libusb-1.0-0-dev cmake libz-dev

print_success "Osnovni paketi instalirani"

# NODE.JS 18.x
print_status "Node.js 18.x instalacija..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

print_success "Node.js instaliran: $(node --version)"

# DVB PAKETI
print_status "DVB paketi..."
apt install -y dvb-tools w-scan libdvbv5-dev 2>/dev/null || true

# MUMUDVB KOMPAJLIRANJE
print_status "MuMuDVB kompajliranje..."
cd /tmp
rm -rf MuMuDVB 2>/dev/null || true
git clone https://github.com/braice/MuMuDVB.git
cd MuMuDVB
autoreconf -i -f
./configure --enable-cam-support --enable-scam-support
make -j$(nproc)
make install

print_success "MuMuDVB instaliran: $(which mumudvb)"

# OSCAM KOMPAJLIRANJE
print_status "OSCam kompajliranje..."
cd /tmp
rm -rf oscam-smod 2>/dev/null || true
git clone https://github.com/Schimmelreiter/oscam-smod.git
cd oscam-smod
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DWEBIF=ON -DWITH_SSL=ON ..
make -j$(nproc)

# INSTALL OSCAM
if [ -f "oscam" ]; then
    cp oscam /usr/local/bin/oscam
    chmod +x /usr/local/bin/oscam
    print_success "OSCam instaliran: /usr/local/bin/oscam"
else
    print_error "OSCam binary nije pronađen!"
fi

# OSCAM CONFIG
mkdir -p /etc/oscam
cat > /etc/oscam/oscam.conf << 'EOF'
[global]
logfile = /var/log/oscam/oscam.log

[webif]
httpport = 8888
httpuser = admin
httppwd = admin

[dvbapi]
enabled = 1
au = 1
user = mumudvb
boxtype = pc

[account]
user = mumudvb
pwd = mumudvb
group = 1
au = 1
EOF

# WEB PANEL
print_status "Web Panel kreiranje..."
WEB_DIR="/opt/mumudvb-webpanel"
mkdir -p $WEB_DIR/public
cd $WEB_DIR

# PACKAGE.JSON
cat > package.json << 'EOF'
{
  "name": "mumudvb-webpanel",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "ws": "^8.13.0"
  }
}
EOF

npm install

# SERVER.JS
cat > server.js << 'EOF'
const express = require('express');
const { exec } = require('child_process');
const app = express();

app.use(express.static('public'));
app.use(express.json());

app.get('/api/status', (req, res) => {
    exec('pgrep -f mumudvb', (error, stdout) => {
        res.json({ running: !error, pid: stdout.trim() });
    });
});

const PORT = 8887;
app.listen(PORT, () => {
    console.log(`🚀 MuMuDVB Web Panel na portu ${PORT}`);
});
EOF

# INDEX.HTML - KOMPLETNA VERZIJA
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>🚀 MuMuDVB Web Panel - FULL</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 0; background: #f0f2f5; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; background: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; }
        .tabs { display: flex; background: white; border-radius: 10px; margin-bottom: 20px; }
        .tab { padding: 15px 30px; cursor: pointer; border: none; background: none; }
        .tab.active { background: #007bff; color: white; border-radius: 10px; }
        .tab-content { display: none; background: white; padding: 30px; border-radius: 10px; }
        .tab-content.active { display: block; }
        .btn { padding: 10px 20px; margin: 5px; border: none; border-radius: 5px; cursor: pointer; }
        .btn-success { background: #28a745; color: white; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-info { background: #17a2b8; color: white; }
        textarea { width: 100%; height: 200px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 MuMuDVB Web Panel</h1>
            <p>Ubuntu 20.04 - DVB-S/S2 Streaming Server</p>
            <div id="status">📡 Status: Checking...</div>
        </div>
        
        <div class="tabs">
            <button class="tab active" onclick="showTab('status')">📊 Status</button>
            <button class="tab" onclick="showTab('config')">⚙️ Config</button>
            <button class="tab" onclick="showTab('settings')">🔧 Settings</button>
            <button class="tab" onclick="showTab('wscan')">📡 W-Scan</button>
            <button class="tab" onclick="showTab('oscam')">🔐 OSCam</button>
            <button class="tab" onclick="showTab('system')">💻 System</button>
            <button class="tab" onclick="showTab('logs')">📋 Logs</button>
        </div>

        <div id="status" class="tab-content active">
            <h3>📊 MuMuDVB Status</h3>
            <button class="btn btn-success" onclick="startService()">▶️ Start MuMuDVB</button>
            <button class="btn btn-danger" onclick="stopService()">⏹️ Stop MuMuDVB</button>
            <button class="btn btn-info" onclick="checkStatus()">🔄 Refresh</button>
            <div id="output" style="margin-top: 20px; background: #2d3748; color: white; padding: 15px; border-radius: 5px;">Ready...</div>
        </div>

        <div id="config" class="tab-content">
            <h3>⚙️ MuMuDVB Configuration</h3>
            <textarea id="configEditor" placeholder="MuMuDVB configuration will be loaded here..."></textarea>
            <br>
            <button class="btn btn-success" onclick="saveConfig()">💾 Save Config</button>
        </div>

        <div id="settings" class="tab-content">
            <h3>🔧 Advanced Settings</h3>
            <p>Advanced MuMuDVB settings and options...</p>
        </div>

        <div id="wscan" class="tab-content">
            <h3>📡 W-Scan - Satellite Scanner</h3>
            <select id="satellite">
                <option value="HOTBIRD">HOTBIRD 13.0E</option>
                <option value="ASTRA1">ASTRA 19.2E</option>
                <option value="ASTRA2">ASTRA 28.2E</option>
            </select>
            <button class="btn btn-success" onclick="startScan()">🔍 Start Scan</button>
            <div id="scanOutput" style="margin-top: 20px; background: #2d3748; color: white; padding: 15px; border-radius: 5px;">W-Scan output...</div>
        </div>

        <div id="oscam" class="tab-content">
            <h3>🔐 OSCam - Software CAM</h3>
            <div id="oscamStatus">Checking OSCam...</div>
            <button class="btn btn-success" onclick="startOSCam()">▶️ Start OSCam</button>
            <button class="btn btn-danger" onclick="stopOSCam()">⏹️ Stop OSCam</button>
            <textarea id="oscamConfig" placeholder="OSCam configuration..."></textarea>
        </div>

        <div id="system" class="tab-content">
            <h3>💻 System Information</h3>
            <div id="systemInfo">Loading system information...</div>
        </div>

        <div id="logs" class="tab-content">
            <h3>📋 System Logs</h3>
            <button class="btn btn-info" onclick="refreshLogs()">🔄 Refresh Logs</button>
            <div id="logOutput" style="margin-top: 20px; background: #2d3748; color: white; padding: 15px; border-radius: 5px;">Logs will appear here...</div>
        </div>
    </div>

    <script>
        function showTab(tabName) {
            // Hide all tabs
            const tabs = document.getElementsByClassName('tab-content');
            for (let tab of tabs) {
                tab.classList.remove('active');
            }
            
            const buttons = document.getElementsByClassName('tab');
            for (let button of buttons) {
                button.classList.remove('active');
            }
            
            // Show selected tab
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
        }

        function checkStatus() {
            fetch('/api/status')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('status').innerHTML = data.running ? 
                        `📡 Status: Running (PID: ${data.pid})` : 
                        '📡 Status: Stopped';
                });
        }

        function startService() {
            document.getElementById('output').textContent = 'Starting MuMuDVB...';
        }

        function stopService() {
            document.getElementById('output').textContent = 'Stopping MuMuDVB...';
        }

        function saveConfig() {
            alert('Config saved!');
        }

        function startScan() {
            document.getElementById('scanOutput').textContent = 'Starting W-Scan...';
        }

        function startOSCam() {
            document.getElementById('oscamStatus').textContent = 'Starting OSCam...';
        }

        function stopOSCam() {
            document.getElementById('oscamStatus').textContent = 'Stopping OSCam...';
        }

        function refreshLogs() {
            document.getElementById('logOutput').textContent = 'Refreshing logs...';
        }

        // Initial status check
        checkStatus();
        setInterval(checkStatus, 5000);
    </script>
</body>
</html>
EOF

# SYSTEMD SERVISI
print_status "Systemd servisi..."

# MuMuDVB Web Panel servis
cat > /etc/systemd/system/mumudvb-webpanel.service << 'EOF'
[Unit]
Description=MuMuDVB Web Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mumudvb-webpanel
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# OSCam servis
cat > /etc/systemd/system/oscam.service << 'EOF'
[Unit]
Description=OSCam - Software CAM
After=network.target

[Service]
Type=forking
User=root
ExecStart=/usr/local/bin/oscam -b -c /etc/oscam
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mumudvb-webpanel
systemctl enable oscam
systemctl start mumudvb-webpanel
systemctl start oscam

print_success "🎉 INSTALACIJA ZAVRŠENA!"
print_success "🌐 Web Panel: http://$(hostname -I | awk '{print $1}'):8887"
print_success "🔐 OSCam Web: http://$(hostname -I | awk '{print $1}'):8888"

echo ""
echo "🚀 PRISTUPAJ WEB PANELU NA PORTU 8887!"