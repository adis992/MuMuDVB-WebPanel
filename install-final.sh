#!/bin/bash

# KONAČAN MUMUDVB + WEB PANEL INSTALLER ZA UBUNTU 20.04
# Ovaj script MORA da radi bez greške!

set -e  # Exit on any error

echo "🚀 KONAČAN MuMuDVB + Web Panel Installer"
echo "======================================"
echo "Ubuntu $(lsb_release -rs) - $(date)"
echo ""

# Funkcije za output
print_status() { echo -e "\n🔄 \e[34m$1\e[0m"; }
print_success() { echo -e "✅ \e[32m$1\e[0m"; }
print_error() { echo -e "❌ \e[31m$1\e[0m"; exit 1; }
print_warning() { echo -e "⚠️  \e[33m$1\e[0m"; }

# Čistimo staro
print_status "Čišćenje starih instalacija..."
sudo pkill -f mumudvb 2>/dev/null || true
sudo pkill -f node 2>/dev/null || true
sudo pkill -f npm 2>/dev/null || true
rm -rf /tmp/MuMuDVB 2>/dev/null || true

# ==============================================
# FAZA 1: OSNOVNI SISTEM I PAKETI
# ==============================================

print_status "FAZA 1: Ažuriranje sistema i osnovni paketi"
sudo apt update && sudo apt upgrade -y

print_status "Instaliranje build tools..."
sudo apt install -y \
    build-essential \
    git \
    wget \
    curl \
    vim \
    htop \
    autoconf \
    automake \
    libtool \
    pkg-config \
    gettext \
    linux-headers-$(uname -r) \
    ca-certificates \
    gnupg \
    lsb-release

print_success "Osnovi paketi instalirani"

# ==============================================
# FAZA 2: KOMPLETNO ČIŠĆENJE I INSTALACIJA NODE.JS
# ==============================================

print_status "FAZA 2: Node.js - kompletno čišćenje i reinstalacija"

# Kompletno uklanjanje SVEGA vezano za Node.js
print_status "Uklanjanje svih postojećih Node.js instalacija..."
sudo apt remove --purge -y nodejs npm nodejs-doc libnode-dev node-gyp 2>/dev/null || true
sudo snap remove node 2>/dev/null || true
sudo apt autoremove -y
sudo apt autoclean

# Brisanje fajlova
sudo rm -rf /usr/local/bin/node* /usr/local/bin/npm* 2>/dev/null || true
sudo rm -rf /usr/local/lib/node_modules 2>/dev/null || true  
sudo rm -rf /usr/bin/node* /usr/bin/npm* 2>/dev/null || true
sudo rm -rf ~/.npm ~/.node-gyp /tmp/.npm* 2>/dev/null || true
sudo rm -rf /etc/apt/sources.list.d/nodesource.list* 2>/dev/null || true

# Čišćenje PATH i environment
unset NODE_PATH
unset NPM_CONFIG_PREFIX

print_status "Instaliranje čiste Node.js 18.x verzije..."

# NodeSource setup
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt update
sudo apt install -y nodejs

# Čekamo da se instaliraju
sleep 5

# Testiranje instalacije
print_status "Testiranje Node.js instalacije..."

NODE_CMD=""
NPM_CMD=""

# Pronađi radnu komandu
if [ -x "/usr/bin/node" ] && /usr/bin/node --version &>/dev/null; then
    NODE_CMD="/usr/bin/node"
    print_success "Node.js pronađen: /usr/bin/node"
elif command -v node &>/dev/null && node --version &>/dev/null; then
    NODE_CMD="node"
    print_success "Node.js pronađen u PATH"
else
    print_error "Node.js instalacija neuspešna!"
fi

if [ -x "/usr/bin/npm" ] && /usr/bin/npm --version &>/dev/null; then
    NPM_CMD="/usr/bin/npm"
    print_success "npm pronađen: /usr/bin/npm"
elif command -v npm &>/dev/null && npm --version &>/dev/null; then
    NPM_CMD="npm"
    print_success "npm pronađen u PATH"
else
    print_error "npm instalacija neuspešna!"
fi

# Finalni test
NODE_VERSION=$($NODE_CMD --version)
NPM_VERSION=$($NPM_CMD --version)

print_success "Node.js: $NODE_VERSION"
print_success "npm: $NPM_VERSION"

# Kreiraj linkove ako treba
sudo ln -sf $NODE_CMD /usr/local/bin/node 2>/dev/null || true
sudo ln -sf $NPM_CMD /usr/local/bin/npm 2>/dev/null || true

# ==============================================
# FAZA 3: DVB PAKETI (SAMO ONI KOJI POSTOJE)
# ==============================================

print_status "FAZA 3: DVB paketi za Ubuntu 20.04"

DVB_PACKAGES=("dvb-tools" "w-scan" "libdvbv5-dev")
INSTALLED_DVB=0

for pkg in "${DVB_PACKAGES[@]}"; do
    if apt-cache show "$pkg" &>/dev/null; then
        print_status "Instaliram $pkg..."
        if sudo apt install -y "$pkg"; then
            print_success "$pkg ✅"
            INSTALLED_DVB=$((INSTALLED_DVB + 1))
        fi
    else
        print_warning "$pkg ne postoji u Ubuntu 20.04"
    fi
done

print_success "DVB paketi: $INSTALLED_DVB od ${#DVB_PACKAGES[@]} instaliran"

# ==============================================
# FAZA 4: MUMUDVB KOMPAJLIRANJE
# ==============================================

print_status "FAZA 4: MuMuDVB kompajliranje"

cd /tmp
rm -rf MuMuDVB 2>/dev/null || true

print_status "Kloniranje MuMuDVB repozitorijuma..."
if ! git clone https://github.com/braice/MuMuDVB.git; then
    print_error "Neuspešno kloniranje MuMuDVB repozitorijuma!"
fi

cd MuMuDVB
print_success "MuMuDVB kod skinut"

# Generiši configure script ako ne postoji
if [ ! -f "./configure" ]; then
    print_status "Generiram configure script..."
    
    if [ -f "./autogen.sh" ]; then
        print_status "Pokrećem autogen.sh..."
        chmod +x autogen.sh
        ./autogen.sh
    else
        print_status "Pokrećem autoreconf..."
        autoreconf -fiv
    fi
    
    if [ ! -f "./configure" ]; then
        print_error "Ne mogu da generiram configure script!"
    fi
fi

print_success "Configure script spreman"

# Configure
print_status "Konfigurišem MuMuDVB sa CAM podrškom..."
if ! ./configure --enable-cam-support --enable-scam-support --prefix=/usr/local; then
    print_error "Configure neuspešan!"
fi

print_success "Configure uspešan"

# Make
print_status "Kompajliram MuMuDVB..."
if ! make -j$(nproc); then
    print_error "Kompajliranje neuspešno!"
fi

print_success "Kompajliranje uspešno"

# Install
print_status "Instaliram MuMuDVB..."
if ! sudo make install; then
    print_error "Instalacija neuspešna!"
fi

# Update library cache
sudo ldconfig

MUMUDVB_PATH=$(which mumudvb 2>/dev/null || echo "/usr/local/bin/mumudvb")
print_success "MuMuDVB instaliran: $MUMUDVB_PATH"

# ==============================================
# FAZA 5: WEB PANEL SETUP
# ==============================================

print_status "FAZA 5: Web Panel setup"

# Kreiraj direktorijum
WEB_DIR="/opt/mumudvb-webpanel"
sudo rm -rf $WEB_DIR 2>/dev/null || true
sudo mkdir -p $WEB_DIR
sudo chown $USER:$USER $WEB_DIR
cd $WEB_DIR

print_status "Kreiranje web panel fajlova..."

# Package.json
cat > package.json << 'EOF'
{
  "name": "mumudvb-webpanel",
  "version": "2.0.0",
  "description": "MuMuDVB Web Management Panel - Ubuntu 20.04",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "ws": "^8.13.0",
    "multer": "^1.4.5",
    "body-parser": "^1.20.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# Instaliraj npm pakete
print_status "Instaliram npm pakete..."
$NPM_CMD install --production

print_success "npm paketi instalirani"

# Server.js
cat > server.js << 'EOF'
const express = require('express');
const path = require('path');
const { exec, spawn } = require('child_process');
const WebSocket = require('ws');
const fs = require('fs');
const bodyParser = require('body-parser');

const app = express();
const port = 8080;

// Middleware
app.use(express.static('public'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// WebSocket server for real-time updates
const wss = new WebSocket.Server({ port: 8081 });

// Broadcast to all connected clients
function broadcast(data) {
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Get MuMuDVB status
app.get('/api/status', (req, res) => {
    exec('pgrep -f mumudvb', (error, stdout) => {
        const running = !error && stdout.trim() !== '';
        const pid = running ? stdout.trim().split('\n')[0] : null;
        res.json({ 
            running: running, 
            pid: pid,
            timestamp: new Date().toISOString()
        });
    });
});

// Start MuMuDVB
app.post('/api/start', (req, res) => {
    const configFile = req.body.config || '/etc/mumudvb/mumudvb.conf';
    
    exec(`mumudvb -d -c ${configFile}`, (error, stdout, stderr) => {
        const success = !error;
        res.json({
            success: success,
            message: success ? 'MuMuDVB started successfully' : error.message,
            output: stdout,
            error: stderr
        });
        
        // Broadcast status change
        setTimeout(() => {
            exec('pgrep -f mumudvb', (err, out) => {
                broadcast({
                    type: 'status',
                    running: !err && out.trim() !== '',
                    pid: !err ? out.trim().split('\n')[0] : null
                });
            });
        }, 1000);
    });
});

// Stop MuMuDVB
app.post('/api/stop', (req, res) => {
    exec('pkill -f mumudvb', (error) => {
        res.json({
            success: true,
            message: 'MuMuDVB stop signal sent'
        });
        
        // Broadcast status change
        setTimeout(() => {
            broadcast({
                type: 'status',
                running: false,
                pid: null
            });
        }, 1000);
    });
});

// Get DVB adapters
app.get('/api/adapters', (req, res) => {
    exec('ls -1 /dev/dvb/adapter* 2>/dev/null || echo "no_adapters"', (error, stdout) => {
        const adapters = stdout.trim() === 'no_adapters' ? [] : 
                        stdout.trim().split('\n').filter(line => line.trim());
        res.json({ adapters: adapters });
    });
});

// Get configuration
app.get('/api/config', (req, res) => {
    const configPath = '/etc/mumudvb/mumudvb.conf';
    fs.readFile(configPath, 'utf8', (err, data) => {
        if (err) {
            res.json({ success: false, error: 'Config file not found' });
        } else {
            res.json({ success: true, config: data });
        }
    });
});

// Save configuration
app.post('/api/config', (req, res) => {
    const configPath = '/etc/mumudvb/mumudvb.conf';
    const configData = req.body.config;
    
    fs.writeFile(configPath, configData, 'utf8', (err) => {
        if (err) {
            res.json({ success: false, error: err.message });
        } else {
            res.json({ success: true, message: 'Configuration saved' });
        }
    });
});

// WebSocket connection handling
wss.on('connection', (ws) => {
    console.log('Client connected to WebSocket');
    
    // Send initial status
    exec('pgrep -f mumudvb', (error, stdout) => {
        const running = !error && stdout.trim() !== '';
        ws.send(JSON.stringify({
            type: 'status',
            running: running,
            pid: running ? stdout.trim().split('\n')[0] : null
        }));
    });
    
    ws.on('close', () => {
        console.log('Client disconnected from WebSocket');
    });
});

// Start server
app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 MuMuDVB Web Panel running on port ${port}`);
    console.log(`📡 Local access: http://localhost:${port}`);
    console.log(`🌐 Network access: http://YOUR_SERVER_IP:${port}`);
    console.log(`🔌 WebSocket server on port 8081`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n👋 Shutting down MuMuDVB Web Panel...');
    wss.close();
    process.exit(0);
});
EOF

# Public folder
mkdir -p public

# HTML
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MuMuDVB Web Panel v2.0</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { opacity: 0.9; font-size: 1.1em; }
        
        .content { padding: 30px; }
        
        .tabs {
            display: flex;
            background: #f8f9fa;
            border-radius: 10px;
            padding: 5px;
            margin-bottom: 30px;
            overflow-x: auto;
        }
        
        .tab {
            flex: 1;
            padding: 15px 20px;
            text-align: center;
            background: transparent;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.3s;
            white-space: nowrap;
            font-weight: 500;
        }
        
        .tab.active {
            background: #007bff;
            color: white;
            box-shadow: 0 2px 10px rgba(0,123,255,0.3);
        }
        
        .tab-content {
            display: none;
            animation: fadeIn 0.3s;
        }
        
        .tab-content.active { display: block; }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .status-card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            border-left: 5px solid #ddd;
        }
        
        .status-card.running { border-left-color: #28a745; }
        .status-card.stopped { border-left-color: #dc3545; }
        
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 10px;
        }
        
        .status-indicator.running { background: #28a745; }
        .status-indicator.stopped { background: #dc3545; }
        
        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 500;
            transition: all 0.3s;
            margin: 5px;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
        
        .btn-success { background: #28a745; color: white; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-info { background: #17a2b8; color: white; }
        .btn-primary { background: #007bff; color: white; }
        
        .output-box {
            background: #2d3748;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            line-height: 1.5;
            max-height: 300px;
            overflow-y: auto;
            white-space: pre-wrap;
            margin-top: 20px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: #495057;
        }
        
        .form-control {
            width: 100%;
            padding: 12px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        
        .form-control:focus {
            border-color: #007bff;
            outline: none;
            box-shadow: 0 0 0 3px rgba(0,123,255,0.1);
        }
        
        textarea.form-control {
            min-height: 200px;
            resize: vertical;
            font-family: 'Courier New', monospace;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
        }
        
        .card h3 {
            color: #2c3e50;
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        
        @media (max-width: 768px) {
            .tabs { flex-direction: column; }
            .tab { margin-bottom: 5px; }
            .header h1 { font-size: 2em; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 MuMuDVB Web Panel</h1>
            <p>Ubuntu 20.04 - DVB-S/S2 Streaming Server Management</p>
        </div>
        
        <div class="content">
            <div class="tabs">
                <button class="tab active" onclick="showTab('status')">📊 Status</button>
                <button class="tab" onclick="showTab('config')">⚙️ Configuration</button>
                <button class="tab" onclick="showTab('adapters')">📡 DVB Adapters</button>
                <button class="tab" onclick="showTab('logs')">📋 Logs</button>
                <button class="tab" onclick="showTab('help')">❓ Help</button>
            </div>
            
            <!-- Status Tab -->
            <div id="status" class="tab-content active">
                <div id="statusCard" class="status-card">
                    <h3><span class="status-indicator" id="statusIndicator"></span>MuMuDVB Service Status</h3>
                    <p id="statusText">Checking status...</p>
                    <p id="statusDetails"></p>
                </div>
                
                <div class="grid">
                    <div class="card">
                        <h3>🎛️ Service Control</h3>
                        <button class="btn btn-success" onclick="startMuMuDVB()">
                            ▶️ Start MuMuDVB
                        </button>
                        <button class="btn btn-danger" onclick="stopMuMuDVB()">
                            ⏹️ Stop MuMuDVB
                        </button>
                        <button class="btn btn-info" onclick="refreshStatus()">
                            🔄 Refresh Status
                        </button>
                    </div>
                    
                    <div class="card">
                        <h3>📈 Quick Stats</h3>
                        <p><strong>Server:</strong> <span id="serverInfo">Ubuntu 20.04</span></p>
                        <p><strong>Panel Version:</strong> v2.0.0</p>
                        <p><strong>Last Update:</strong> <span id="lastUpdate">-</span></p>
                    </div>
                </div>
            </div>
            
            <!-- Configuration Tab -->
            <div id="config" class="tab-content">
                <div class="card">
                    <h3>⚙️ MuMuDVB Configuration</h3>
                    <div class="form-group">
                        <label for="configEditor">Edit Configuration File (/etc/mumudvb/mumudvb.conf):</label>
                        <textarea id="configEditor" class="form-control" placeholder="Loading configuration..."></textarea>
                    </div>
                    <button class="btn btn-primary" onclick="saveConfig()">💾 Save Configuration</button>
                    <button class="btn btn-info" onclick="loadConfig()">🔄 Reload Configuration</button>
                </div>
            </div>
            
            <!-- DVB Adapters Tab -->
            <div id="adapters" class="tab-content">
                <div class="card">
                    <h3>📡 DVB Adapters Detection</h3>
                    <div id="adaptersInfo">Loading adapter information...</div>
                    <button class="btn btn-info" onclick="refreshAdapters()">🔄 Refresh Adapters</button>
                </div>
            </div>
            
            <!-- Logs Tab -->
            <div id="logs" class="tab-content">
                <div class="card">
                    <h3>📋 System Output</h3>
                    <div id="outputBox" class="output-box">Ready for system output...</div>
                    <button class="btn btn-info" onclick="clearOutput()">🗑️ Clear Output</button>
                </div>
            </div>
            
            <!-- Help Tab -->
            <div id="help" class="tab-content">
                <div class="card">
                    <h3>❓ Help & Documentation</h3>
                    <h4>🚀 Quick Start:</h4>
                    <ol>
                        <li>Configure your DVB-S/S2 card parameters in the Configuration tab</li>
                        <li>Set frequency, polarization, symbol rate for your satellite</li>
                        <li>Start MuMuDVB service from the Status tab</li>
                        <li>Access streams at http://YOUR_SERVER_IP:8100+</li>
                    </ol>
                    
                    <h4>🔧 Configuration Tips:</h4>
                    <ul>
                        <li><strong>freq:</strong> Transponder frequency in Hz (e.g., 11538000)</li>
                        <li><strong>pol:</strong> Polarization (h for horizontal, v for vertical)</li>
                        <li><strong>srate:</strong> Symbol rate (e.g., 22000000)</li>
                        <li><strong>card:</strong> DVB adapter number (usually 0)</li>
                        <li><strong>tuner:</strong> Tuner number (usually 0)</li>
                    </ul>
                    
                    <h4>📡 Stream Access:</h4>
                    <p>After starting MuMuDVB, streams will be available at:</p>
                    <ul>
                        <li>HTTP: http://YOUR_SERVER_IP:8100/</li>
                        <li>Multicast: 239.100.x.x:1234</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <script>
        let ws;
        let isConnected = false;

        // Initialize WebSocket connection
        function initWebSocket() {
            const wsUrl = `ws://${window.location.hostname}:8081`;
            ws = new WebSocket(wsUrl);
            
            ws.onopen = () => {
                isConnected = true;
                console.log('WebSocket connected');
            };
            
            ws.onmessage = (event) => {
                const data = JSON.parse(event.data);
                if (data.type === 'status') {
                    updateStatusDisplay(data.running, data.pid);
                }
            };
            
            ws.onclose = () => {
                isConnected = false;
                console.log('WebSocket disconnected');
                setTimeout(initWebSocket, 3000); // Reconnect after 3 seconds
            };
            
            ws.onerror = (error) => {
                console.error('WebSocket error:', error);
            };
        }

        // Tab management
        function showTab(tabName) {
            // Hide all tabs
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.classList.remove('active');
            });
            document.querySelectorAll('.tab').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // Show selected tab
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
            
            // Load tab-specific data
            if (tabName === 'config') loadConfig();
            if (tabName === 'adapters') refreshAdapters();
        }

        // Status management
        function updateStatusDisplay(running, pid) {
            const statusCard = document.getElementById('statusCard');
            const statusIndicator = document.getElementById('statusIndicator');
            const statusText = document.getElementById('statusText');
            const statusDetails = document.getElementById('statusDetails');
            const lastUpdate = document.getElementById('lastUpdate');
            
            if (running) {
                statusCard.className = 'status-card running';
                statusIndicator.className = 'status-indicator running';
                statusText.textContent = 'MuMuDVB is running';
                statusDetails.textContent = `Process ID: ${pid}`;
            } else {
                statusCard.className = 'status-card stopped';
                statusIndicator.className = 'status-indicator stopped';
                statusText.textContent = 'MuMuDVB is stopped';
                statusDetails.textContent = 'Service is not running';
            }
            
            lastUpdate.textContent = new Date().toLocaleString();
        }

        function refreshStatus() {
            fetch('/api/status')
                .then(r => r.json())
                .then(data => updateStatusDisplay(data.running, data.pid))
                .catch(err => addOutput('Error checking status: ' + err.message));
        }

        function startMuMuDVB() {
            addOutput('Starting MuMuDVB service...');
            fetch('/api/start', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    addOutput(data.success ? 
                        'MuMuDVB started successfully!' : 
                        'Error starting MuMuDVB: ' + data.message);
                    if (data.output) addOutput('Output: ' + data.output);
                    if (data.error) addOutput('Error: ' + data.error);
                    setTimeout(refreshStatus, 1000);
                })
                .catch(err => addOutput('Error: ' + err.message));
        }

        function stopMuMuDVB() {
            addOutput('Stopping MuMuDVB service...');
            fetch('/api/stop', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    addOutput(data.message);
                    setTimeout(refreshStatus, 1000);
                })
                .catch(err => addOutput('Error: ' + err.message));
        }

        // Configuration management
        function loadConfig() {
            fetch('/api/config')
                .then(r => r.json())
                .then(data => {
                    const editor = document.getElementById('configEditor');
                    if (data.success) {
                        editor.value = data.config;
                    } else {
                        editor.value = `# MuMuDVB Configuration File
# Basic DVB-S/S2 configuration

# Frequency in Hz (example: 11538 MHz = 11538000000 Hz)
freq=11538000

# Polarization: h (horizontal) or v (vertical)
pol=h

# Symbol rate (example: 22000 kSyms/s = 22000000)
srate=22000000

# DVB adapter and tuner
card=0
tuner=0

# Autoconfiguration
autoconfiguration=full
autoconf_unicast_start_port=8100
autoconf_multicast_port=1234

# Web interface port
common_port=8080

# CAM support for encrypted channels
cam_support=1
scam_support=1

# Logging
log_type=syslog
log_header=1
`;
                        addOutput('Default configuration loaded - please edit as needed');
                    }
                })
                .catch(err => addOutput('Error loading config: ' + err.message));
        }

        function saveConfig() {
            const config = document.getElementById('configEditor').value;
            fetch('/api/config', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ config: config })
            })
                .then(r => r.json())
                .then(data => {
                    addOutput(data.success ? 
                        'Configuration saved successfully!' : 
                        'Error saving configuration: ' + data.error);
                })
                .catch(err => addOutput('Error: ' + err.message));
        }

        // DVB Adapters
        function refreshAdapters() {
            const adaptersInfo = document.getElementById('adaptersInfo');
            adaptersInfo.innerHTML = 'Scanning for DVB adapters...';
            
            fetch('/api/adapters')
                .then(r => r.json())
                .then(data => {
                    if (data.adapters.length > 0) {
                        adaptersInfo.innerHTML = `
                            <h4>Found ${data.adapters.length} DVB adapter(s):</h4>
                            <ul>
                                ${data.adapters.map(adapter => `<li>${adapter}</li>`).join('')}
                            </ul>
                            <p><strong>Status:</strong> ✅ DVB hardware detected</p>
                        `;
                    } else {
                        adaptersInfo.innerHTML = `
                            <p><strong>Status:</strong> ❌ No DVB adapters found</p>
                            <p>Please check:</p>
                            <ul>
                                <li>DVB-S/S2 card is properly installed</li>
                                <li>Drivers are loaded (check with: lsmod | grep dvb)</li>
                                <li>Device permissions are correct</li>
                            </ul>
                        `;
                    }
                })
                .catch(err => {
                    adaptersInfo.innerHTML = `<p>Error scanning adapters: ${err.message}</p>`;
                });
        }

        // Output management
        function addOutput(message) {
            const outputBox = document.getElementById('outputBox');
            const timestamp = new Date().toLocaleTimeString();
            outputBox.textContent += `[${timestamp}] ${message}\n`;
            outputBox.scrollTop = outputBox.scrollHeight;
        }

        function clearOutput() {
            document.getElementById('outputBox').textContent = 'Output cleared.\n';
        }

        // Initialize everything
        document.addEventListener('DOMContentLoaded', () => {
            initWebSocket();
            refreshStatus();
            
            // Set server info
            document.getElementById('serverInfo').textContent = 
                `${navigator.platform} - ${navigator.userAgent.includes('Chrome') ? 'Chrome' : 'Browser'}`;
        });
    </script>
</body>
</html>
EOF

print_success "Web panel fajlovi kreiran"

# ==============================================
# FAZA 6: KONFIGURACIJA I SERVISI
# ==============================================

print_status "FAZA 6: Kreiranje konfiguracija i servisa"

# MuMuDVB config
sudo mkdir -p /etc/mumudvb
sudo tee /etc/mumudvb/mumudvb.conf > /dev/null << 'EOF'
# MuMuDVB Configuration for DVB-S/S2
# Edit this file according to your satellite and transponder

# Basic DVB-S/S2 configuration
freq=11538000
pol=h
srate=22000000

# DVB adapter
card=0
tuner=0

# Autoconfiguration
autoconfiguration=full
autoconf_unicast_start_port=8100
autoconf_multicast_port=1234

# Web interface
common_port=8080

# CAM/SCAM support for encrypted channels
cam_support=1
scam_support=1

# Logging
log_type=syslog
log_header=1
EOF

# Systemd service
sudo tee /etc/systemd/system/mumudvb-webpanel.service > /dev/null << EOF
[Unit]
Description=MuMuDVB Web Panel v2.0
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$WEB_DIR
ExecStart=$NODE_CMD server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload and enable
sudo systemctl daemon-reload
sudo systemctl enable mumudvb-webpanel

print_success "Servis konfigurisan"

# ==============================================
# FINALNO TESTIRANJE
# ==============================================

print_status "FINALNO TESTIRANJE"

# Test MuMuDVB
if command -v mumudvb &>/dev/null; then
    MUMUDVB_VERSION=$(mumudvb --version 2>&1 | head -1 || echo "Version check failed")
    print_success "MuMuDVB test: $MUMUDVB_VERSION"
else
    print_error "MuMuDVB nije dostupan u PATH!"
fi

# Test Node.js
if $NODE_CMD --version &>/dev/null && $NPM_CMD --version &>/dev/null; then
    print_success "Node.js test: $($NODE_CMD --version)"
    print_success "npm test: $($NPM_CMD --version)"
else
    print_error "Node.js ili npm test neuspešan!"
fi

# Test web panel dependencies
cd $WEB_DIR
if $NODE_CMD -e "require('express'); require('ws'); console.log('Dependencies OK')" 2>/dev/null; then
    print_success "Web panel dependencies test: OK"
else
    print_error "Web panel dependencies test neuspešan!"
fi

# ==============================================
# REZULTATI
# ==============================================

echo ""
echo "🎉 ======================================"
echo "🎉     INSTALACIJA USPEŠNO ZAVRŠENA!"
echo "🎉 ======================================"
echo ""
echo "📋 INSTALIRANO:"
echo "   ✅ MuMuDVB: $(which mumudvb 2>/dev/null || echo '/usr/local/bin/mumudvb')"
echo "   ✅ Node.js: $NODE_VERSION"
echo "   ✅ npm: $NPM_VERSION"
echo "   ✅ Web Panel: $WEB_DIR"
echo "   ✅ Systemd servis: mumudvb-webpanel"
echo ""
echo "🚀 POKRETANJE:"
echo "   sudo systemctl start mumudvb-webpanel"
echo "   sudo systemctl status mumudvb-webpanel"
echo ""
echo "🌐 PRISTUP WEB PANELU:"
echo "   Lokalno:  http://localhost:8080"
echo "   Mreža:    http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "⚙️  KONFIGURACIJA:"
echo "   Config fajl: /etc/mumudvb/mumudvb.conf"
echo "   Edituj frekvenciju, polarizaciju i ostale DVB-S parametre"
echo ""
echo "📡 DVB-S KARTICU KONFIGURIŠI PREKO WEB PANELA!"
echo ""
echo "🎯 Instalacija gotova - pokretaj web panel!"

# Auto-start the web panel service
print_status "Automatski pokretam web panel..."
if sudo systemctl start mumudvb-webpanel; then
    print_success "Web panel pokrenut!"
    echo ""
    echo "🔗 Pristup: http://$(hostname -I | awk '{print $1}'):8080"
else
    print_warning "Web panel se nije pokrenuo automatski. Pokreni ručno:"
    echo "   sudo systemctl start mumudvb-webpanel"
fi