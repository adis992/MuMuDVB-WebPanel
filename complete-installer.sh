#!/bin/bash

echo "🚀 MUMUDVB MASTER INSTALLER - JEDAN FAJL ZA SVE!"
echo "================================================"

# OSNOVNE FUNKCIJE
print_status() { echo -e "\n🔄 $1"; }
print_success() { e# W-Scan
app.post('/api/wscan/start', (req, res) => {
    const satellite = req.body.satellite || 'S19E2';
    const outputFile = '/opt/mumudvb-webpanel/configs/channels.conf';
    
    exec('which w-scan', (checkError) => {
        if (checkError) {
            return res.json({ success: false, error: 'w-scan not installed' });
        }
        
        // Create configs directory if not exists
        exec('mkdir -p /opt/mumudvb-webpanel/configs', () => {
            const wscanCmd = 'w-scan -f s -s ' + satellite + ' -o 7 -t 3 > ' + outputFile;
            exec(wscanCmd, (error, stdout, stderr) => {
                res.json({ 
                    success: !error, 
                    output: error ? stderr : 'Channels saved to: ' + outputFile,
                    file: outputFile
                });
            });
        });
    });
});"; }
print_error() { echo -e "❌ $1"; exit 1; }
print_warning() { echo -e "⚠️ $1"; }

# AUTO CHMOD 777 ODMAH
chmod 777 * 2>/dev/null || true
CURRENT_DIR=$(pwd)

# 1. CLEANUP POSTOJEĆIH INSTALACIJA
print_status "Cleanup postojećih instalacija..."
systemctl stop mumudvb-webpanel 2>/dev/null || true
systemctl stop oscam 2>/dev/null || true
rm -rf /opt/mumudvb-webpanel 2>/dev/null || true
killall mumudvb 2>/dev/null || true
killall oscam 2>/dev/null || true
print_success "Cleanup done"

# 2. DEPENDENCY INSTALL
print_status "Dependencies..."
apt update
apt install -y build-essential git cmake mercurial autotools-dev autoconf libtool pkg-config
apt install -y libdvbcsa-dev libssl-dev libpcsclite-dev dvb-tools libdvbv5-dev
apt install -y nodejs npm w-scan || {
    print_warning "w-scan failed, trying alternatives..."
    add-apt-repository universe -y 2>/dev/null || true
    apt update && apt install -y w-scan || print_warning "w-scan skip"
}

# 3. DVB CHECK
print_status "DVB adapters check..."
DVB_COUNT=$(ls /dev/dvb* 2>/dev/null | wc -l)
print_success "DVB adapters found: $DVB_COUNT"

# 4. MUMUDVB CLONE & BUILD
print_status "MuMuDVB setup..."
if [ ! -d "$CURRENT_DIR/MuMuDVB" ]; then
    git clone https://github.com/braice/MuMuDVB.git || git clone https://github.com/mumudvb/mumudvb.git MuMuDVB
fi
cd "$CURRENT_DIR/MuMuDVB"
chmod 777 * -R 2>/dev/null || true
make clean 2>/dev/null || true
autoreconf -i -f
./configure --enable-cam-support --enable-scam-support
make -j$(nproc)
cp mumudvb /usr/local/bin/mumudvb 2>/dev/null || cp src/mumudvb /usr/local/bin/mumudvb
chmod 777 /usr/local/bin/mumudvb
print_success "MuMuDVB installed: $(which mumudvb)"

# 5. OSCAM CLONE & BUILD
print_status "OSCam setup..."
cd "$CURRENT_DIR"
if [ ! -d "oscam" ]; then
    svn checkout http://www.streamboard.tv/svn/oscam/trunk oscam || print_warning "OSCam SVN failed"
fi
if [ -d "oscam" ]; then
    cd oscam
    chmod 777 * -R 2>/dev/null || true
    make clean 2>/dev/null || true
    make
    OSCAM_BIN=$(find . -name "oscam*" -type f -executable | head -1)
    if [ -n "$OSCAM_BIN" ]; then
        cp "$OSCAM_BIN" /usr/local/bin/oscam
        chmod 777 /usr/local/bin/oscam
        print_success "OSCam installed"
    fi
fi

# 6. DIRECTORIES
print_status "Creating directories..."
mkdir -p /etc/mumudvb /var/etc/oscam /opt/mumudvb-webpanel/{public,uploads,configs}
chmod 777 /etc/mumudvb /var/etc/oscam /opt/mumudvb-webpanel -R

# 7. CONFIGS
print_status "Creating configs..."
cat > /etc/mumudvb/mumudvb.conf << 'EOF'
# MuMuDVB Configuration - ASTRA 19.2E
adapter=0
freq=10832
pol=h
srate=22000
fec=5/6
delivery_system=DVBS

# Multicast konfiguracija
multicast=1
multicast_iface=eth0
ip_multicast=239.100.0.0
port_multicast=1234
ttl_multicast=2

# Autoconfiguration - automatski kanali
autoconfiguration=full
autoconf_radios=1
autoconf_scrambled=1
autoconf_pid_update=1

# SAP announces
sap=1
sap_group=239.255.255.255

# HTTP Unicast
unicast=1
ip_http=0.0.0.0
port_http=4242
unicast_max_clients=20

# Logging
log_type=console
log_header=1
show_traffic=1

# CAM/SCAM support
cam_support=1
scam_support=1

# Rewrite za compatibility
rewrite_pat=1
rewrite_sdt=1
EOF

cat > /var/etc/oscam/oscam.conf << 'EOF'
[global]
serverip = 0.0.0.0
logfile = /var/log/oscam.log
cachedelay = 120

[webif]
httpport = 8888
httpuser = admin
httppwd = admin
httpallowed = 0.0.0.0-255.255.255.255

[monitor]
port = 988
aulow = 120
EOF

# 8. WEB PANEL
print_status "Web panel setup..."
cd /opt/mumudvb-webpanel

cat > package.json << 'EOF'
{
  "name": "mumudvb-master-panel",
  "version": "2.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "cors": "^2.8.5"
  }
}
EOF

cat > server.js << 'EOF'
const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.static('public'));
app.use(express.json());

// Health Check
app.get('/', (req, res) => {
    res.json({ status: 'OK', service: 'MuMuDVB Master Panel' });
});

// MuMuDVB Control
app.post('/api/mumudvb/start', (req, res) => {
    exec('mumudvb -d -c /etc/mumudvb/mumudvb.conf', (error, stdout, stderr) => {
        res.json({ success: !error, output: stdout || stderr });
    });
});

app.post('/api/mumudvb/stop', (req, res) => {
    exec('pkill -f mumudvb', (error) => {
        res.json({ success: true, message: 'MuMuDVB stopped' });
    });
});

// OSCam Control
app.post('/api/oscam/start', (req, res) => {
    exec('oscam -b -c /var/etc/oscam', (error) => {
        res.json({ success: !error, message: 'OSCam started' });
    });
});

app.post('/api/oscam/stop', (req, res) => {
    exec('pkill -f oscam', (error) => {
        res.json({ success: true, message: 'OSCam stopped' });
    });
});

// W-Scan
app.post('/api/wscan/start', (req, res) => {
    const satellite = req.body.satellite || 'S19E2';
    exec('which w-scan', (checkError) => {
        if (checkError) {
            return res.json({ success: false, error: 'w-scan not installed' });
        }
        exec('w-scan -f s -s ' + satellite + ' -o 7 -t 3', (error, stdout, stderr) => {
            res.json({ success: !error, output: stdout || stderr });
        });
    });
});

// Config management
app.get('/api/mumudvb/config', (req, res) => {
    try {
        const config = fs.readFileSync('/etc/mumudvb/mumudvb.conf', 'utf8');
        res.json({ success: true, config: config });
    } catch (error) {
        res.json({ success: false, error: 'Config not found' });
    }
});

app.post('/api/mumudvb/config', (req, res) => {
    try {
        fs.writeFileSync('/etc/mumudvb/mumudvb.conf', req.body.config);
        res.json({ success: true });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

const PORT = 8887;
app.listen(PORT, () => {
    console.log('🚀 MuMuDVB Master Panel running on port ' + PORT);
});
EOF

# W-SCAN BUILD FROM SOURCE
print_status "W-scan build from source..."
cd "$CURRENT_DIR"
if [ ! -d "w_scan" ]; then
    git clone https://github.com/tbsdtv/w_scan.git w_scan || print_warning "W-scan git failed"
fi
if [ -d "w_scan" ]; then
    cd w_scan
    chmod 777 * -R 2>/dev/null || true
    make clean 2>/dev/null || true
    ./configure 2>/dev/null || autoreconf -i -f && ./configure
    make -j$(nproc)
    cp w_scan /usr/local/bin/w-scan 2>/dev/null || cp w-scan /usr/local/bin/w-scan
    chmod 777 /usr/local/bin/w-scan
    print_success "W-scan built and installed"
else
    print_warning "Using system w-scan"
fi

cd /opt/mumudvb-webpanel

# Install npm packages
npm install

# HTML Interface
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>MuMuDVB Master Panel</title>
<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:10px}.btn{padding:10px 20px;margin:5px;border:none;border-radius:5px;cursor:pointer}.btn-start{background:#28a745;color:white}.btn-stop{background:#dc3545;color:white}.btn-scan{background:#007bff;color:white}textarea{width:100%;height:200px;font-family:monospace}</style>
</head><body>
<div class="container">
<h1>🚀 MuMuDVB Master Panel</h1>

<h2>📺 MuMuDVB Control</h2>
<button class="btn btn-start" onclick="startMuMuDVB()">▶️ Start MuMuDVB</button>
<button class="btn btn-stop" onclick="stopMuMuDVB()">⏹️ Stop MuMuDVB</button>
<button class="btn btn-scan" onclick="loadConfig()">🔄 Load Config</button>
<button class="btn btn-scan" onclick="saveConfig()">💾 Save Config</button>

<h3>Configuration:</h3>
<textarea id="mumudvb-config" placeholder="MuMuDVB configuration will load here..."></textarea>

<h2>🔐 OSCam Control</h2>
<button class="btn btn-start" onclick="startOSCam()">▶️ Start OSCam</button>
<button class="btn btn-stop" onclick="stopOSCam()">⏹️ Stop OSCam</button>
<button class="btn btn-scan" onclick="openOSCamWeb()">🌐 OSCam Web</button>

<h2>📡 W-Scan Pretraga Kanala</h2>
<div style="margin:10px 0;">
<label>Satelit:</label>
<select id="satellite" style="padding:5px;margin:5px;">
<option value="S19E2">ASTRA 19.2°E</option>
<option value="S13E">HOTBIRD 13.0°E</option>
<option value="S1W">THOR 1.0°W</option>
</select>
<button class="btn btn-scan" onclick="startWScan()">🔍 Start Scan</button>
</div>

<div id="output" style="background:#f8f9fa;padding:15px;margin-top:20px;border-radius:5px;white-space:pre-wrap;font-family:monospace;max-height:400px;overflow-y:auto;border:1px solid #ddd;"></div>

<h2>🌐 Pristup Linkovi</h2>
<div style="margin:10px 0;">
<button class="btn btn-scan" onclick="openMuMuDVBWeb()">📺 MuMuDVB HTTP</button>
<button class="btn btn-scan" onclick="openOSCamWeb()">🔐 OSCam Web</button>
<button class="btn btn-scan" onclick="window.open('http://'+getServerIP()+':8887','_blank')">� Master Panel</button>
</div>
</div>

<script>
function log(msg) { 
    const output = document.getElementById("output");
    output.textContent += new Date().toLocaleTimeString() + " - " + msg + "\n"; 
    output.scrollTop = output.scrollHeight;
}

function getServerIP() {
    return window.location.hostname;
}

function openMuMuDVBWeb() {
    window.open("http://" + getServerIP() + ":4242", "_blank");
}

function openOSCamWeb() {
    window.open("http://" + getServerIP() + ":8888", "_blank");
}

function startMuMuDVB() {
    log("Starting MuMuDVB...");
    fetch("/api/mumudvb/start", {method: "POST"})
    .then(r => r.json())
    .then(data => log(data.success ? "✅ MuMuDVB started" : "❌ " + (data.output || "Failed")))
    .catch(e => log("❌ Error: " + e));
}

function stopMuMuDVB() {
    log("Stopping MuMuDVB...");
    fetch("/api/mumudvb/stop", {method: "POST"})
    .then(r => r.json())
    .then(data => log("✅ MuMuDVB stopped"))
    .catch(e => log("❌ Error: " + e));
}

function startOSCam() {
    log("Starting OSCam...");
    fetch("/api/oscam/start", {method: "POST"})
    .then(r => r.json())
    .then(data => log(data.success ? "✅ OSCam started" : "❌ OSCam failed"))
    .catch(e => log("❌ Error: " + e));
}

function stopOSCam() {
    log("Stopping OSCam...");
    fetch("/api/oscam/stop", {method: "POST"})
    .then(r => r.json())
    .then(data => log("✅ OSCam stopped"))
    .catch(e => log("❌ Error: " + e));
}

function loadConfig() {
    fetch("/api/mumudvb/config")
    .then(r => r.json())
    .then(data => {
        if(data.success) {
            document.getElementById("mumudvb-config").value = data.config;
            log("✅ Config loaded");
        } else {
            log("❌ Config load failed");
        }
    });
}

function saveConfig() {
    const config = document.getElementById("mumudvb-config").value;
    fetch("/api/mumudvb/config", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({config: config})
    })
    .then(r => r.json())
    .then(data => log(data.success ? "✅ Config saved" : "❌ Save failed"))
    .catch(e => log("❌ Error: " + e));
}

function startWScan() {
    const satellite = document.getElementById("satellite").value;
    log("Starting W-Scan for " + satellite + "...");
    log("This may take 5-10 minutes...");
    
    fetch("/api/wscan/start", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({satellite: satellite})
    })
    .then(r => r.json())
    .then(data => {
        if(data.success) {
            log("✅ W-Scan completed");
            log(data.output);
        } else {
            log("❌ W-Scan failed: " + (data.error || data.output));
        }
    })
    .catch(e => log("❌ Error: " + e));
}

// Auto-load config on page load
window.onload = function() {
    loadConfig();
    log("🚀 MuMuDVB Master Panel loaded");
};
</script>
</body></html>
EOF

# 9. SYSTEMD SERVICES
print_status "Creating systemd services..."

cat > /etc/systemd/system/mumudvb-webpanel.service << EOF
[Unit]
Description=MuMuDVB Master Web Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mumudvb-webpanel
ExecStart=$(which node) server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/oscam.service << 'EOF'
[Unit]
Description=OSCam Server
After=network.target

[Service]
Type=forking
User=root
ExecStart=/usr/local/bin/oscam -b -c /var/etc/oscam
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 10. START SERVICES
print_status "Starting services..."
systemctl daemon-reload
systemctl enable mumudvb-webpanel oscam
systemctl start mumudvb-webpanel
systemctl start oscam

# 11. FINAL CHECK
print_status "Final check..."
sleep 3
WEB_STATUS=$(systemctl is-active mumudvb-webpanel)
OSCAM_STATUS=$(systemctl is-active oscam)

echo ""
echo "🎉 INSTALLATION COMPLETE!"
echo "========================"
echo "✅ Web Panel: $WEB_STATUS"
echo "✅ OSCam: $OSCAM_STATUS"
echo "✅ MuMuDVB: $(which mumudvb)"
echo "✅ W-Scan: $(which w-scan || echo 'not found')"
echo ""
echo "🌐 ACCESS LINKS:"
echo "🚀 Master Panel: http://$(hostname -I | awk '{print $1}'):8887"
echo "🔐 OSCam Web: http://$(hostname -I | awk '{print $1}'):8888 (admin/admin)"
echo "📺 MuMuDVB HTTP: http://$(hostname -I | awk '{print $1}'):4242 (when started)"
echo ""
echo "💪 SVE RADI - JEDAN INSTALLER ZA SVE!"