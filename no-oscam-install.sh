#!/bin/bash

# NO-OSCAM INSTALLER - SAMO MUMUDVB + WEB PANEL
# ZA KADA OSCam REPOZITORIJUMI JEBU
set -e

echo "🚀 NO-OSCAM INSTALLER - SAMO MUMUDVB + WEB PANEL"
echo "================================================="

# Funkcije
print_status() { echo -e "\n🔄 $1"; }
print_success() { echo -e "✅ $1"; }
print_error() { echo -e "❌ $1"; exit 1; }

# CLEANUP
print_status "Cleanup..."
systemctl stop mumudvb-webpanel 2>/dev/null || true
pkill -f mumudvb 2>/dev/null || true
pkill -f node 2>/dev/null || true
rm -rf /opt/mumudvb-webpanel 2>/dev/null || true
rm -f /etc/systemd/system/mumudvb-webpanel.service 2>/dev/null || true

# SYSTEM UPDATE
print_status "System update..."
apt update && apt upgrade -y

# OSNOVNI PAKETI
print_status "Osnovni paketi..."
apt install -y build-essential git wget curl vim htop autoconf automake libtool pkg-config gettext gettext-base autopoint intltool linux-headers-$(uname -r) ca-certificates gnupg lsb-release software-properties-common

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

# SERVER.JS - SA SVIM API ENDPOINTIMA
cat > server.js << 'EOF'
const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const app = express();

app.use(express.static('public'));
app.use(express.json());

// MuMuDVB Status
app.get('/api/status', (req, res) => {
    exec('pgrep -f mumudvb', (error, stdout) => {
        res.json({ 
            running: !error, 
            pid: stdout.trim() || null 
        });
    });
});

// Start MuMuDVB
app.post('/api/start', (req, res) => {
    exec('mumudvb -d -c /etc/mumudvb/mumudvb.conf', (error, stdout, stderr) => {
        res.json({
            success: !error,
            message: error ? error.message : 'MuMuDVB started',
            output: stdout || stderr
        });
    });
});

// Stop MuMuDVB
app.post('/api/stop', (req, res) => {
    exec('pkill -f mumudvb', (error) => {
        res.json({
            success: true,
            message: 'MuMuDVB stop signal sent'
        });
    });
});

// Config Load
app.get('/api/config', (req, res) => {
    try {
        const config = fs.readFileSync('/etc/mumudvb/mumudvb.conf', 'utf8');
        res.json({ success: true, config: config });
    } catch (error) {
        res.json({ success: false, error: 'Config file not found' });
    }
});

// Config Save
app.post('/api/config', (req, res) => {
    try {
        fs.writeFileSync('/etc/mumudvb/mumudvb.conf', req.body.config);
        res.json({ success: true });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

// W-Scan
app.post('/api/wscan', (req, res) => {
    const satellite = req.body.satellite || 'HOTBIRD';
    exec(`w-scan -f s -s ${satellite} -o 7 -t 3`, (error, stdout, stderr) => {
        res.json({
            success: !error,
            output: stdout || stderr || 'W-scan completed',
            error: error ? error.message : null
        });
    });
});

// System Info
app.get('/api/system', (req, res) => {
    exec('uname -a && free -h && df -h', (error, stdout) => {
        res.json({
            success: !error,
            info: stdout || 'System info not available'
        });
    });
});

// Logs
app.get('/api/logs', (req, res) => {
    exec('journalctl -u mumudvb-webpanel -n 100 --no-pager', (error, stdout) => {
        res.json({
            success: !error,
            logs: stdout || 'No logs available'
        });
    });
});

const PORT = 8887;
app.listen(PORT, () => {
    console.log(`🚀 MuMuDVB Web Panel na portu ${PORT}`);
    console.log(`🌐 Pristup: http://localhost:${PORT}`);
});
EOF

# INDEX.HTML - KOMPLETNA VERZIJA SA SVIM TABOVIMA
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>🚀 MuMuDVB Web Panel - KOMPLETNA</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            min-height: 100vh;
            padding: 20px;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 15px; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header { 
            background: linear-gradient(45deg, #007bff, #0056b3);
            color: white;
            text-align: center; 
            padding: 30px; 
        }
        .header h1 { margin: 0; font-size: 2.5em; }
        .header p { margin: 10px 0 0 0; opacity: 0.9; }
        
        .tabs {
            display: flex;
            background: #f8f9fa;
            border-bottom: 2px solid #dee2e6;
            overflow-x: auto;
        }
        .tab {
            padding: 15px 25px;
            cursor: pointer;
            border: none;
            background: none;
            white-space: nowrap;
            transition: all 0.3s;
            border-bottom: 3px solid transparent;
        }
        .tab:hover {
            background: #e9ecef;
        }
        .tab.active {
            background: #007bff;
            color: white;
            border-bottom-color: #0056b3;
        }
        
        .tab-content {
            display: none;
            padding: 30px;
            min-height: 500px;
        }
        .tab-content.active {
            display: block;
        }
        
        .btn {
            padding: 12px 24px;
            margin: 5px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s;
        }
        .btn:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.2); }
        .btn-success { background: #28a745; color: white; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-info { background: #17a2b8; color: white; }
        .btn-warning { background: #ffc107; color: #212529; }
        .btn-primary { background: #007bff; color: white; }
        
        .status {
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            font-weight: 500;
        }
        .status.running { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .status.stopped { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        
        textarea, select, input {
            width: 100%;
            padding: 12px;
            border: 2px solid #dee2e6;
            border-radius: 8px;
            font-size: 14px;
            margin: 10px 0;
        }
        
        .config-editor {
            height: 400px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
        }
        
        .output {
            background: #2d3748;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            max-height: 400px;
            overflow-y: auto;
            margin: 20px 0;
            white-space: pre-wrap;
            line-height: 1.5;
        }
        
        .card {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        
        .form-group {
            margin: 15px 0;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 500;
        }
        
        .spinner {
            width: 20px;
            height: 20px;
            border: 2px solid #f3f3f3;
            border-top: 2px solid #007bff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            display: inline-block;
            margin-right: 10px;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 MuMuDVB Web Panel</h1>
            <p>Ubuntu 20.04 - DVB-S/S2 Streaming Server - KOMPLETNA VERZIJA</p>
        </div>
        
        <div class="tabs">
            <button class="tab active" onclick="showTab('status')">📊 Status</button>
            <button class="tab" onclick="showTab('config')">⚙️ Config</button>
            <button class="tab" onclick="showTab('settings')">🔧 Settings</button>
            <button class="tab" onclick="showTab('wscan')">📡 W-Scan</button>
            <button class="tab" onclick="showTab('system')">💻 System</button>
            <button class="tab" onclick="showTab('logs')">📋 Logs</button>
        </div>

        <!-- Status Tab -->
        <div id="status" class="tab-content active">
            <h2>📊 MuMuDVB Status & Control</h2>
            
            <div id="statusDisplay" class="status stopped">
                📡 MuMuDVB Status: Checking...
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <button class="btn btn-success" onclick="startMuMuDVB()">
                    ▶️ Start MuMuDVB
                </button>
                <button class="btn btn-danger" onclick="stopMuMuDVB()">
                    ⏹️ Stop MuMuDVB
                </button>
                <button class="btn btn-info" onclick="checkStatus()">
                    🔄 Refresh Status
                </button>
            </div>
            
            <div id="output" class="output">Ready to control MuMuDVB service...</div>
        </div>

        <!-- Config Tab -->
        <div id="config" class="tab-content">
            <h2>⚙️ MuMuDVB Configuration</h2>
            
            <div class="card">
                <h3>📝 Configuration Editor</h3>
                <p>Edit your MuMuDVB configuration file:</p>
                <textarea id="configEditor" class="config-editor" placeholder="Loading MuMuDVB configuration..."></textarea>
                <div style="text-align: center; margin-top: 15px;">
                    <button class="btn btn-primary" onclick="loadConfig()">🔄 Reload Config</button>
                    <button class="btn btn-success" onclick="saveConfig()">💾 Save Config</button>
                    <button class="btn btn-warning" onclick="generateSampleConfig()">📄 Generate Sample</button>
                </div>
            </div>
        </div>

        <!-- Settings Tab -->
        <div id="settings" class="tab-content">
            <h2>🔧 Advanced Settings</h2>
            
            <div class="card">
                <h3>🛠️ MuMuDVB Advanced Options</h3>
                
                <div class="form-group">
                    <label>DVB Adapter:</label>
                    <select id="dvbAdapter">
                        <option value="0">Adapter 0 (/dev/dvb/adapter0)</option>
                        <option value="1">Adapter 1 (/dev/dvb/adapter1)</option>
                        <option value="2">Adapter 2 (/dev/dvb/adapter2)</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label>Multicast IP Range:</label>
                    <input type="text" id="multicastIP" value="239.100.0.0" placeholder="239.100.0.0">
                </div>
                
                <div class="form-group">
                    <label>Port Range Start:</label>
                    <input type="number" id="portStart" value="1234" min="1000" max="65000">
                </div>
                
                <div class="form-group">
                    <label>
                        <input type="checkbox" id="enableSAP"> Enable SAP Announces
                    </label>
                </div>
                
                <div class="form-group">
                    <label>
                        <input type="checkbox" id="enableHTTP"> Enable HTTP Unicast
                    </label>
                </div>
                
                <button class="btn btn-primary" onclick="applySettings()">✅ Apply Settings</button>
            </div>
        </div>

        <!-- W-Scan Tab -->
        <div id="wscan" class="tab-content">
            <h2>📡 W-Scan - Satellite Channel Scanner</h2>
            
            <div class="card">
                <h3>🛰️ Satellite Selection</h3>
                <div class="form-group">
                    <label>Select Satellite:</label>
                    <select id="satelliteSelect">
                        <option value="HOTBIRD">HOTBIRD 13.0E</option>
                        <option value="ASTRA1">ASTRA 19.2E</option>
                        <option value="ASTRA2">ASTRA 28.2E</option>
                        <option value="EUTELSAT16E">EUTELSAT 16.0E</option>
                        <option value="TURKSAT">TURKSAT 42.0E</option>
                    </select>
                </div>
            </div>
            
            <div style="text-align: center; margin: 20px 0;">
                <button class="btn btn-success" onclick="startWScan()">🔍 Start W-Scan</button>
                <button class="btn btn-warning" onclick="stopWScan()">⏹️ Stop Scan</button>
            </div>
            
            <div id="wscanOutput" class="output" style="display:none;">W-Scan output will appear here...</div>
        </div>

        <!-- System Tab -->
        <div id="system" class="tab-content">
            <h2>💻 System Information</h2>
            
            <div class="card">
                <h3>🖥️ System Status</h3>
                <div id="systemInfo" class="output">Loading system information...</div>
                <button class="btn btn-info" onclick="refreshSystemInfo()">🔄 Refresh System Info</button>
            </div>
        </div>

        <!-- Logs Tab -->
        <div id="logs" class="tab-content">
            <h2>📋 System Logs</h2>
            
            <div style="text-align: center; margin: 20px 0;">
                <button class="btn btn-info" onclick="refreshLogs()">🔄 Refresh Logs</button>
                <button class="btn btn-warning" onclick="clearLogs()">🗑️ Clear Display</button>
            </div>
            
            <div id="logOutput" class="output">Click 'Refresh Logs' to load system logs...</div>
        </div>
    </div>

    <script>
        // Tab Management
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
            
            // Load tab-specific data
            if (tabName === 'config') loadConfig();
            if (tabName === 'system') refreshSystemInfo();
        }

        // Status functions
        function checkStatus() {
            fetch('/api/status')
                .then(r => r.json())
                .then(data => {
                    const statusDiv = document.getElementById('statusDisplay');
                    if (data.running) {
                        statusDiv.className = 'status running';
                        statusDiv.innerHTML = `📡 MuMuDVB Status: <strong>Running</strong> (PID: ${data.pid})`;
                    } else {
                        statusDiv.className = 'status stopped';
                        statusDiv.innerHTML = '📡 MuMuDVB Status: <strong>Stopped</strong>';
                    }
                })
                .catch(err => addOutput('Status check error: ' + err));
        }

        function startMuMuDVB() {
            addOutput('Starting MuMuDVB...');
            fetch('/api/start', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    addOutput(data.success ? 
                        `✅ MuMuDVB started successfully!\\n${data.output}` : 
                        `❌ Failed to start MuMuDVB: ${data.message}`);
                    setTimeout(checkStatus, 2000);
                })
                .catch(err => addOutput('Start error: ' + err));
        }

        function stopMuMuDVB() {
            addOutput('Stopping MuMuDVB...');
            fetch('/api/stop', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    addOutput('🛑 MuMuDVB stop signal sent');
                    setTimeout(checkStatus, 2000);
                })
                .catch(err => addOutput('Stop error: ' + err));
        }

        function addOutput(message) {
            const output = document.getElementById('output');
            const timestamp = new Date().toLocaleTimeString();
            output.textContent += `[${timestamp}] ${message}\\n`;
            output.scrollTop = output.scrollHeight;
        }

        // Config functions
        function loadConfig() {
            fetch('/api/config')
                .then(r => r.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('configEditor').value = data.config;
                    } else {
                        document.getElementById('configEditor').value = '# MuMuDVB config not found - will be created when saved';
                    }
                });
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
                alert(data.success ? '✅ Config saved successfully!' : '❌ Error: ' + data.error);
            });
        }

        function generateSampleConfig() {
            const sampleConfig = \`# MuMuDVB Sample Configuration
# DVB-S/S2 Configuration
adapter=0
freq=12422
pol=h
srate=27500
delivery_system=DVBS2

# Multicast Configuration
multicast=1
multicast_iface=eth0
ip_multicast=239.100.0.0
port_multicast=1234
ttl_multicast=2

# Channel Configuration
autoconfiguration=full
autoconf_radios=1
autoconf_scrambled=1

# SAP announces
sap=1
sap_group=239.255.255.255

# HTTP Unicast
unicast=1
ip_http=0.0.0.0
port_http=4242

# Logging
log_type=console
log_header=1
show_traffic=1\`;
            
            document.getElementById('configEditor').value = sampleConfig;
            alert('📄 Sample configuration generated!');
        }

        // W-Scan functions
        function startWScan() {
            const satellite = document.getElementById('satelliteSelect').value;
            const output = document.getElementById('wscanOutput');
            output.style.display = 'block';
            output.innerHTML = '<div class="spinner"></div>Starting W-Scan for ' + satellite + '...\\nThis may take several minutes...';
            
            fetch('/api/wscan', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ satellite: satellite })
            })
            .then(r => r.json())
            .then(data => {
                output.textContent = data.success ? 
                    \`W-Scan completed for \${satellite}:\\n\\n\${data.output}\` :
                    \`W-Scan failed: \${data.error}\\n\\n\${data.output}\`;
            })
            .catch(err => {
                output.textContent = \`W-Scan error: \${err.message}\`;
            });
        }

        function stopWScan() {
            document.getElementById('wscanOutput').textContent = 'W-Scan stopped.';
        }

        // System functions
        function refreshSystemInfo() {
            const output = document.getElementById('systemInfo');
            output.innerHTML = '<div class="spinner"></div>Loading system information...';
            
            fetch('/api/system')
                .then(r => r.json())
                .then(data => {
                    output.textContent = data.success ? data.info : 'System info not available';
                });
        }

        // Logs functions
        function refreshLogs() {
            const output = document.getElementById('logOutput');
            output.innerHTML = '<div class="spinner"></div>Loading logs...';
            
            fetch('/api/logs')
                .then(r => r.json())
                .then(data => {
                    output.textContent = data.success ? data.logs : 'No logs available';
                });
        }

        function clearLogs() {
            document.getElementById('logOutput').textContent = 'Logs cleared. Click "Refresh Logs" to reload.';
        }

        // Settings functions
        function applySettings() {
            alert('⚙️ Settings would be applied (feature in development)');
        }

        // Initialize
        checkStatus();
        setInterval(checkStatus, 10000); // Auto-refresh every 10 seconds
    </script>
</body>
</html>
EOF

# MUMUDVB CONFIG
print_status "MuMuDVB konfiguracija..."
mkdir -p /etc/mumudvb

cat > /etc/mumudvb/mumudvb.conf << 'EOF'
# MuMuDVB Basic Configuration
adapter=0
freq=12422
pol=h
srate=27500
delivery_system=DVBS2

# Multicast
multicast=1
multicast_iface=eth0
ip_multicast=239.100.0.0
port_multicast=1234

# Autoconfiguration
autoconfiguration=full
autoconf_radios=1
autoconf_scrambled=1

# SAP
sap=1

# HTTP
unicast=1
ip_http=0.0.0.0
port_http=4242

# Logging
log_type=console
EOF

# SYSTEMD SERVIS
print_status "Systemd servis..."

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
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mumudvb-webpanel
systemctl start mumudvb-webpanel

print_success "🎉 NO-OSCAM INSTALACIJA ZAVRŠENA!"
print_success "🌐 Web Panel: http://$(hostname -I | awk '{print $1}'):8887"

echo ""
print_status "📋 INSTALIRANO:"
print_success "✅ MuMuDVB: $(which mumudvb)"
print_success "✅ Node.js: $(node --version)"
print_success "✅ Web Panel: /opt/mumudvb-webpanel"
print_success "✅ Config: /etc/mumudvb/mumudvb.conf"

echo ""
print_status "🌐 PRISTUP:"
print_success "Web Panel: http://localhost:8887"
print_success "Web Panel: http://$(hostname -I | awk '{print $1}'):8887"

echo ""
print_success "🚀 SAMO MUMUDVB + WEB PANEL - BEZ OSCAM SRANJA!"