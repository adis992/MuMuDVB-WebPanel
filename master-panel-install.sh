#!/bin/bash

# MASTER WEB PANEL INSTALLER - KOMPLETNO UPRAVLJANJE SVIME!
# PERMISIJE, KONFIGURACIJE, SERVISI - SVE U JEDNOM PANELU!
set -e

echo "🚀 MASTER WEB PANEL INSTALLER - KOMPLETNO UPRAVLJANJE!"
echo "======================================================="

# Funkcije
print_status() { echo -e "\n🔄 $1"; }
print_success() { echo -e "✅ $1"; }
print_error() { echo -e "❌ $1"; exit 1; }
print_warning() { echo -e "⚠️ $1"; }

# CLEANUP
print_status "Kompletna cleanup..."
systemctl stop mumudvb-webpanel 2>/dev/n// W-Scan Start
app.post('/api/wscan/start', (req, res) => {
    const satellite = req.body.satellite || 'S19E2';
    
    // Check if w-scan exists
    exec('which w-scan', (checkError) => {
        if (checkError) {
            return res.json({
                success: false,
                error: 'w-scan nije instaliran! Instaliraj sa: apt install w-scan'
            });
        }
        
        exec('w-scan -f s -s ' + satellite + ' -o 7 -t 3', (error, stdout, stderr) => {|| true
systemctl stop oscam 2>/dev/null || true
pkill -f mumudvb 2>/dev/null || true
pkill -f oscam 2>/dev/null || true
pkill -f node 2>/dev/null || true
fuser -k 8887/tcp 2>/dev/null || true
fuser -k 8888/tcp 2>/dev/null || true
rm -rf /opt/mumudvb-webpanel 2>/dev/null || true
rm -rf /etc/mumudvb 2>/dev/null || true
rm -rf /var/etc/oscam 2>/dev/null || true
rm -f /etc/systemd/system/mumudvb-webpanel.service 2>/dev/null || true
rm -f /etc/systemd/system/oscam.service 2>/dev/null || true

# SYSTEM UPDATE
print_status "System update..."
apt update && apt upgrade -y

# UFW DISABLE - kao što si rekao
print_status "UFW disable..."
ufw --force disable 2>/dev/null || true
systemctl stop ufw 2>/dev/null || true
systemctl disable ufw 2>/dev/null || true

# OSNOVNI PAKETI
print_status "Osnovni paketi..."
apt install -y build-essential git wget curl vim htop autoconf automake libtool pkg-config gettext gettext-base autopoint intltool linux-headers-$(uname -r) ca-certificates gnupg lsb-release software-properties-common

# NODE.JS 18.x
print_status "Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

print_success "Node.js instaliran: $(node --version)"

# DVB PAKETI
print_status "DVB paketi..."
apt install -y dvb-tools w-scan libdvbv5-dev 2>/dev/null || {
    print_warning "w-scan apt install failed, trying manual install..."
    apt update
    apt install -y w-scan || print_warning "w-scan install problem - možda nije dostupan u ovom repo"
}

# SET PERMISIJE NA SVE FAJLOVE - PRVO EXECUTABLE NA SEBE
chmod +x "$0" 2>/dev/null || true

print_status "Postavljanje 777 permisija na sve fajlove..."
CURRENT_DIR=$(pwd)
chmod -R 777 "$CURRENT_DIR" 2>/dev/null || true
print_success "777 permisije postavljene na sve fajlove"

# MUMUDVB KOMPAJLIRANJE IZ LOKALNOG FOLDERA
print_status "MuMuDVB kompajliranje iz projekta..."
if [ -d "$CURRENT_DIR/MuMuDVB" ]; then
    cd "$CURRENT_DIR/MuMuDVB"
    make clean 2>/dev/null || true
    autoreconf -i -f
    ./configure --enable-cam-support --enable-scam-support
    make -j$(nproc)
    make install
    print_success "MuMuDVB instaliran iz lokalnog foldera: $(which mumudvb)"
else
    print_error "MuMuDVB folder ne postoji u projektu! Pokreni iz MuMuDVB-WebPanel foldera!"
fi

# OSCAM KOMPAJLIRANJE IZ LOKALNOG FOLDERA - SCHIMMELREITER SMOD
print_status "OSCam Schimmelreiter smod kompajliranje iz projekta..."
cd "$CURRENT_DIR"
if [ -d "oscam" ]; then
    cd oscam
    make clean 2>/dev/null || true
    make allyesconfig CONF_DIR=/var/etc/oscam
    make -j$(nproc) USE_LIBUSB=1 USE_LIBCRYPTO=1 USE_SSL=1
    
    # Kopiraj u distribution folder - traži pravi binary
    mkdir -p distribution
    
    # Pronađi oscam binary u Distribution folderu
    OSCAM_BINARY=$(find Distribution/ -name "oscam*" -type f -executable | head -n 1)
    if [ -n "$OSCAM_BINARY" ]; then
        cp "$OSCAM_BINARY" distribution/oscam
        cp "$OSCAM_BINARY" /usr/local/bin/oscam
        chmod +x /usr/local/bin/oscam
        print_success "OSCam binary kopiran: $OSCAM_BINARY -> /usr/local/bin/oscam"
    else
        # Fallback - traži bilo koji executable
        OSCAM_BINARY=$(find . -name "*oscam*" -type f -executable | head -n 1)
        if [ -n "$OSCAM_BINARY" ]; then
            cp "$OSCAM_BINARY" /usr/local/bin/oscam
            chmod +x /usr/local/bin/oscam
            print_success "OSCam binary fallback kopiran: $OSCAM_BINARY -> /usr/local/bin/oscam"
        else
            print_warning "OSCam binary nije pronađen!"
        fi
    fi
    
    print_success "OSCam Schimmelreiter smod kompajliran iz lokalnog foldera!"
else
    print_warning "OSCam folder ne postoji - skip kompajliranje"
    apt install -y oscam 2>/dev/null || print_warning "OSCam skip - repo problemi" 
fi

# CLEAN POSTOJEĆE INSTALACIJE
print_status "Brisanje stare instalacije..."
rm -rf /opt/mumudvb-webpanel 2>/dev/null || true
systemctl stop mumudvb-webpanel 2>/dev/null || true
print_success "Clean done"

# KREIRANJE DIREKTORIJUMA SA PERMISIJAMA
print_status "Kreiranje direktorijuma i permisija..."

# MuMuDVB direktorijumi
mkdir -p /etc/mumudvb
mkdir -p /var/log/mumudvb
chmod 755 /etc/mumudvb
chmod 755 /var/log/mumudvb

# OSCam direktorijumi
mkdir -p /var/etc/oscam
mkdir -p /var/log/oscam
mkdir -p /usr/local/var/oscam
chmod 755 /var/etc/oscam
chmod 755 /var/log/oscam
chmod 755 /usr/local/var/oscam

# Web panel direktorijumi
mkdir -p /opt/mumudvb-webpanel/public
mkdir -p /opt/mumudvb-webpanel/configs
chmod 755 /opt/mumudvb-webpanel
chmod 755 /opt/mumudvb-webpanel/public
chmod 755 /opt/mumudvb-webpanel/configs

print_success "Direktorijumi i permisije kreirani"

# MUMUDVB DEFAULTNA KONFIGURACIJA
print_status "MuMuDVB defaultna konfiguracija..."
cat > /etc/mumudvb/mumudvb.conf << 'EOF'
# MuMuDVB Configuration - RADNA VERZIJA
# DVB-S/S2 Setup za HOTBIRD 13.0E

# DVB parametri
adapter=0
freq=12054
pol=h
srate=27500
delivery_system=DVBS2

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
sap_uri=sap://239.255.255.255

# HTTP Unicast
unicast=1
ip_http=0.0.0.0
port_http=4242
unicast_max_clients=20

# Logging
log_type=console
log_header=1
show_traffic=1
log_flush_interval=1

# CAM/SCAM support (ako imaš kartice)
cam_support=1
scam_support=1

# Rewrite za bolje compatibility
rewrite_pat=1
rewrite_sdt=1
EOF

chmod 644 /etc/mumudvb/mumudvb.conf
print_success "MuMuDVB config kreiran"

# OSCAM DEFAULTNA KONFIGURACIJA
print_status "OSCam defaultna konfiguracija..."

# oscam.conf
cat > /var/etc/oscam/oscam.conf << 'EOF'
# OSCam Configuration - RADNA VERZIJA
[global]
serverip = 0.0.0.0
logfile = /var/log/oscam/oscam.log
pidfile = /var/run/oscam.pid
disablelog = 0
disableuserfile = 0
usrfileflag = 0
clienttimeout = 5000
fallbacktimeout = 2500  
clientmaxidle = 120
bindwait = 120
netprio = 0
sleep = 0
unlockparental = 0
nice = 99
maxlogsize = 10
waitforcards = 1
preferlocalcards = 1
saveinithistory = 1
readerrestartseconds = 5

[monitor]
port = 988
aulow = 120
monlevel = 1
nocrypt = 127.0.0.1,192.168.0.0-192.168.255.255

[webif]
httpport = 8888
httpuser = admin
httppwd = admin
httphelplang = en
httprefresh = 30
httpallowed = 127.0.0.1,192.168.0.0-192.168.255.255

[dvbapi]
enabled = 1
au = 1
user = mumudvb
boxtype = pc
pmt_mode = 4
request_mode = 1

[account]
user = mumudvb
pwd = mumudvb
group = 1
au = 1
monlevel = 0
EOF

# oscam.user
cat > /var/etc/oscam/oscam.user << 'EOF'
[account]
user = mumudvb
pwd = mumudvb
group = 1
au = 1
monlevel = 0
services = 
betatunnel = 1833.FFFF:1702,1833.FFFF:1722
cccmaxhops = 2
EOF

# oscam.server
cat > /var/etc/oscam/oscam.server << 'EOF'
# OSCam server configuration
# Add your card readers here

# Example local card reader (uncomment and configure)
# [reader]
# label = local-card
# protocol = internal
# device = /dev/sci0
# group = 1
# emmcache = 1,3,2,0
# blockemm-unknown = 1
# blockemm-u = 1
# blockemm-s = 1
# blockemm-g = 1

# Example network reader (uncomment and configure)
# [reader]
# label = network-server
# protocol = cccam
# device = your-server.com,port
# user = username
# password = password
# group = 1
EOF

chmod 644 /var/etc/oscam/oscam.conf
chmod 644 /var/etc/oscam/oscam.user  
chmod 644 /var/etc/oscam/oscam.server
print_success "OSCam config kreiran"

# W-SCAN SAMPLE CONFIG
print_status "W-Scan sample konfiguracija..."
cat > /opt/mumudvb-webpanel/configs/wscan-satellites.conf << 'EOF'
# W-Scan satellite configuration examples
# Format: satellite_name:frequency_file

HOTBIRD_13E:/opt/mumudvb-webpanel/configs/hotbird.conf
ASTRA_19E:/opt/mumudvb-webpanel/configs/astra19.conf  
ASTRA_28E:/opt/mumudvb-webpanel/configs/astra28.conf
EUTELSAT_16E:/opt/mumudvb-webpanel/configs/eutelsat16.conf
TURKSAT_42E:/opt/mumudvb-webpanel/configs/turksat.conf
EOF

# Sample frequency files
cat > /opt/mumudvb-webpanel/configs/hotbird.conf << 'EOF'
# HOTBIRD 13.0E sample frequencies
S 12054000 H 27500000 2/3 AUTO
S 12092000 H 27500000 3/4 AUTO  
S 12111000 V 27500000 2/3 AUTO
S 12130000 H 27500000 3/4 AUTO
S 12149000 V 27500000 2/3 AUTO
EOF

print_success "W-Scan config kreiran"

# WEB PANEL - COPY IZ PROJEKTA
print_status "Master Web Panel kreiranje..."
mkdir -p /opt/mumudvb-webpanel
cd /opt/mumudvb-webpanel

# Copy web_panel folder ako postoji iz projekta
if [ -d "$CURRENT_DIR/web_panel" ]; then
    cp -r "$CURRENT_DIR/web_panel"/* . 2>/dev/null || true
    print_success "Web panel fajlovi kopirani iz projekta"
fi

# PACKAGE.JSON - sa security fix
cat > /opt/mumudvb-webpanel/package.json << 'EOF'
{
  "name": "mumudvb-master-panel",
  "version": "2.0.0",  
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "ws": "^8.17.1",
    "multer": "^1.4.5-lts.1",
    "fs-extra": "^11.2.0",
    "cors": "^2.8.5"
  }
}
EOF

# MASTER SERVER.JS - SA SVIM API ENDPOINTIMA
cat > /opt/mumudvb-webpanel/server.js << 'EOF'
const express = require('express');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const cors = require('cors');
const app = express();

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.static('public'));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// File upload setup
const upload = multer({ dest: 'uploads/' });

// Health Check
app.get('/', (req, res) => {
    res.json({ 
        status: 'OK', 
        service: 'MuMuDVB Master Panel',
        version: '2.0.0',
        timestamp: new Date().toISOString()
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', uptime: process.uptime() });
});

// ============= MUMUDVB API =============

// MuMuDVB Status
app.get('/api/mumudvb/status', (req, res) => {
    exec('pgrep -f mumudvb', (error, stdout) => {
        res.json({ 
            running: !error, 
            pid: stdout.trim() || null 
        });
    });
});

// Start MuMuDVB
app.post('/api/mumudvb/start', (req, res) => {
    exec('mumudvb -d -c /etc/mumudvb/mumudvb.conf', (error, stdout, stderr) => {
        res.json({
            success: !error,
            message: error ? error.message : 'MuMuDVB started',
            output: stdout || stderr
        });
    });
});

// Stop MuMuDVB
app.post('/api/mumudvb/stop', (req, res) => {
    exec('pkill -f mumudvb', (error) => {
        res.json({
            success: true,
            message: 'MuMuDVB stop signal sent'
        });
    });
});

// MuMuDVB Config Load
app.get('/api/mumudvb/config', (req, res) => {
    try {
        const config = fs.readFileSync('/etc/mumudvb/mumudvb.conf', 'utf8');
        res.json({ success: true, config: config });
    } catch (error) {
        res.json({ success: false, error: 'Config file not found' });
    }
});

// MuMuDVB Config Save
app.post('/api/mumudvb/config', (req, res) => {
    try {
        fs.writeFileSync('/etc/mumudvb/mumudvb.conf', req.body.config);
        res.json({ success: true });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

// ============= OSCAM API =============

// OSCam Status
app.get('/api/oscam/status', (req, res) => {
    exec('pgrep -f oscam', (error, stdout) => {
        res.json({ 
            running: !error, 
            pid: stdout.trim() || null 
        });
    });
});

// Start OSCam
app.post('/api/oscam/start', (req, res) => {
    exec('oscam -b -c /var/etc/oscam', (error, stdout, stderr) => {
        res.json({
            success: !error,
            message: error ? error.message : 'OSCam started',
            output: stdout || stderr
        });
    });
});

// Stop OSCam  
app.post('/api/oscam/stop', (req, res) => {
    exec('pkill -f oscam', (error) => {
        res.json({
            success: true,
            message: 'OSCam stop signal sent'
        });
    });
});

// OSCam Config Load
app.get('/api/oscam/config/:file', (req, res) => {
    const file = req.params.file;
    const allowedFiles = ['oscam.conf', 'oscam.user', 'oscam.server'];
    
    if (!allowedFiles.includes(file)) {
        return res.json({ success: false, error: 'Invalid config file' });
    }
    
    try {
        const config = fs.readFileSync('/var/etc/oscam/' + file, 'utf8');
        res.json({ success: true, config: config });
    } catch (error) {
        res.json({ success: false, error: 'Config file not found' });
    }
});

// OSCam Config Save
app.post('/api/oscam/config/:file', (req, res) => {
    const file = req.params.file;
    const allowedFiles = ['oscam.conf', 'oscam.user', 'oscam.server'];
    
    if (!allowedFiles.includes(file)) {
        return res.json({ success: false, error: 'Invalid config file' });
    }
    
    try {
        fs.writeFileSync('/var/etc/oscam/' + file, req.body.config);
        res.json({ success: true });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

// ============= W-SCAN API =============

// W-Scan Start
app.post('/api/wscan/start', (req, res) => {
    const satellite = req.body.satellite || 'HOTBIRD';
    exec('w-scan -f s -s ' + satellite + ' -o 7 -t 3', (error, stdout, stderr) => {
        res.json({
                success: !error,
                output: stdout || stderr || 'W-scan completed',
                satellite: satellite
            });
        });
    });
});
    });
});

// ============= SYSTEM API =============

// System Info
app.get('/api/system/info', (req, res) => {
    exec('uname -a && echo "---" && free -h && echo "---" && df -h && echo "---" && uptime', (error, stdout) => {
        res.json({
            success: !error,
            info: stdout || 'System info not available'
        });
    });
});

// Service Control
app.post('/api/service/:service/:action', (req, res) => {
    const service = req.params.service;
    const action = req.params.action;
    const allowedServices = ['mumudvb-webpanel', 'oscam'];
    const allowedActions = ['start', 'stop', 'restart', 'status'];
    
    if (!allowedServices.includes(service) || !allowedActions.includes(action)) {
        return res.json({ success: false, error: 'Invalid service or action' });
    }
    
    exec('systemctl ' + action + ' ' + service, (error, stdout, stderr) => {
        res.json({
            success: !error,
            output: stdout || stderr || 'Service ' + service + ' ' + action + ' completed'
        });
    });
});

// Logs
app.get('/api/logs/:service', (req, res) => {
    const service = req.params.service;
    const allowedServices = ['mumudvb-webpanel', 'oscam', 'mumudvb'];
    
    if (!allowedServices.includes(service)) {
        return res.json({ success: false, error: 'Invalid service' });
    }
    
    exec('journalctl -u ' + service + ' -n 100 --no-pager', (error, stdout) => {
        res.json({
            success: !error,
            logs: stdout || 'No logs available'
        });
    });
});

// Links API - za redirect na ostale servise
app.get('/api/links', (req, res) => {
    const serverIP = req.headers.host.split(':')[0];
    res.json({
        mumudvb_http: 'http://' + serverIP + ':4242',
        oscam_web: 'http://' + serverIP + ':8888',
        webpanel: 'http://' + serverIP + ':8887'
    });
});

const PORT = 8887;
app.listen(PORT, () => {
    console.log('🚀 Master MuMuDVB Panel na portu ' + PORT);
    console.log('🌐 Pristup: http://localhost:' + PORT);
});
EOF

print_success "Master server.js kreiran"

# NPM INSTALL - sada kada su svi fajlovi kreirani
print_status "Instalacija Node.js dependencies..."
cd /opt/mumudvb-webpanel && npm install --no-audit
print_success "Node.js packages instalirani"

# FORCE SYNTAX CHECK
print_status "Test server.js syntax..."
node -c /opt/mumudvb-webpanel/server.js && print_success "✅ Syntax OK" || {
    print_warning "❌ Syntax ERROR - popravka..."
    # Manual fix za template literals
    sed -i 's/\\\${\([^}]*\)}/\1/g' /opt/mumudvb-webpanel/server.js
    node -c /opt/mumudvb-webpanel/server.js && print_success "✅ Fixed!" || print_warning "Still broken!"
}

# Kreiraj uploads direktorijum za multer
mkdir -p /opt/mumudvb-webpanel/uploads
print_success "Uploads direktorijum kreiran"

# COPY HTML INTERFACE
print_status "HTML interface kreiranje..."
if [ -f "$CURRENT_DIR/web_panel/master-index.html" ]; then
    cp "$CURRENT_DIR/web_panel/master-index.html" /opt/mumudvb-webpanel/public/index.html
    print_success "master-index.html kopiran"
else
    # Ako nema master-index.html, kreiraj osnovni
    cat > /opt/mumudvb-webpanel/public/index.html << 'HTMLEOF'
<!DOCTYPE html><html><head><title>MuMuDVB Master Panel</title></head>
<body><h1>🚀 MuMuDVB Master Panel</h1><p>Panel se učitava...</p>
<script>setTimeout(() => window.location.reload(), 3000);</script></body></html>
HTMLEOF
fi
print_success "HTML interface kreiran"

# SYSTEMD SERVISI
print_status "Systemd servisi..."

# Detektuj Node.js putanju
NODE_PATH=$(which node || echo "/usr/bin/node")
print_status "Node.js path: $NODE_PATH"

# MuMuDVB Web Panel servis
cat > /etc/systemd/system/mumudvb-webpanel.service << EOF
[Unit]
Description=MuMuDVB Master Web Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mumudvb-webpanel
ExecStart=$NODE_PATH server.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

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
ExecStart=/usr/local/bin/oscam -b -c /var/etc/oscam
PIDFile=/var/run/oscam.pid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mumudvb-webpanel
systemctl enable oscam 2>/dev/null || true

print_success "Systemd servisi kreirani"

# POKRETANJE SERVISA
print_status "Pokretanje servisa..."
systemctl stop mumudvb-webpanel 2>/dev/null || true
systemctl stop oscam 2>/dev/null || true
sleep 2
systemctl start mumudvb-webpanel || print_warning "Web panel servis problem"
systemctl start oscam 2>/dev/null || print_warning "OSCam servis skip"

# FINALNA PROVERA
print_status "Finalna provera..."
sleep 3

# Debug output za web panel servis
echo "🔍 Web panel service debug:"
systemctl status mumudvb-webpanel --no-pager -n 10 || true
echo ""

WEB_STATUS=$(systemctl is-active mumudvb-webpanel 2>/dev/null || echo "inactive")
OSCAM_STATUS=$(systemctl is-active oscam 2>/dev/null || echo "inactive")

print_success "🎉 MASTER WEB PANEL INSTALACIJA ZAVRŠENA!"
echo ""
print_status "📋 STATUS SERVISA:"
print_success "✅ Web Panel: $WEB_STATUS"
print_success "✅ OSCam: $OSCAM_STATUS"

echo ""
print_status "📁 KONFIGURACIJE:"
print_success "✅ MuMuDVB: /etc/mumudvb/mumudvb.conf"
print_success "✅ OSCam: /var/etc/oscam/"
print_success "✅ W-Scan: /opt/mumudvb-webpanel/configs/"

echo ""
print_status "🌐 PRISTUP LINKOVI:"
SERVER_IP=$(hostname -I | awk '{print $1}')
print_success "🚀 Master Panel: http://$SERVER_IP:8887"
print_success "📺 MuMuDVB HTTP: http://$SERVER_IP:4242 (kad se pokrene)"
print_success "🔐 OSCam Web: http://$SERVER_IP:8888 (admin/admin)"

echo ""
print_success "🎯 SVE UPRAVLJANJE KROZ WEB PANEL NA 8887!"
print_success "🔧 Editovanje konfiguracija, pokretanje servisa, sve na klik!"







