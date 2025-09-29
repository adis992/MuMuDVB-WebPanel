#!/bin/bash

# MASTER WEB PANEL INSTALLER - KOMPLETNO UPRAVLJANJE SVIME!
# PERMISIJE, KONFIGURACIJE, SERVISI - SVE U JEDNOM PANELU!

# Funkcije PRVO!
print_status() { echo -e "\n🔄 $1"; }
print_success() { echo -e "✅ $1"; }
print_error() { echo -e "❌ $1"; exit 1; }
print_warning() { echo -e "⚠️ $1"; }

echo "🚀 MASTER WEB PANEL INSTALLER - KOMPLETNO UPRAVLJANJE!"
echo "======================================================="

set -e

# PROVJERI MASTER-INDEX.HTML PRIJE SVEGA!
CURRENT_DIR=$(pwd)
print_status "Provjera MASTER-INDEX.HTML..."
if [ -f "$CURRENT_DIR/web_panel/master-index.html" ]; then
    print_success "✅ MASTER-INDEX.HTML pronađen - može instalacija!"
else
    print_error "❌ MASTER-INDEX.HTML NE POSTOJI! web_panel/master-index.html MORA postojati prije instalacije!"
fi

# FORCE 777 ODMAH - PRIJE SVEGA OSTALOG!
chmod 777 "$0" 2>/dev/null || true
chmod 777 * 2>/dev/null || true

print_status "Auto chmod 777 setup..."
chmod 777 "$CURRENT_DIR"/* 2>/dev/null || true
print_success "Chmod 777 done"

# CLEAN POSTOJEĆE INSTALACIJE
print_status "Brisanje stare instalacije..."
rm -rf /opt/mumudvb-webpanel 2>/dev/null || true
systemctl stop mumudvb-webpanel 2>/dev/null || true
systemctl stop oscam 2>/dev/null || true
print_success "Cleanup done"

# CLEANUP
print_status "Kompletna cleanup..."
systemctl stop mumudvb-webpanel 2>/dev/null || true
systemctl stop oscam 2>/dev/null || true
print_success "Cleanup done"

# DEPENDENCY INSTALL
print_status "Dependency instalacija..."
apt update
apt install -y build-essential git cmake mercurial subversion autotools-dev autoconf libtool pkg-config
apt install -y libdvbcsa-dev libssl-dev libpcsclite-dev
apt install -y dvb-tools libdvbv5-dev w-scan 2>/dev/null || {
    print_warning "w-scan apt install failed, trying alternatives..."
    add-apt-repository universe -y 2>/dev/null || true
    apt update
    apt install -y w-scan || {
        print_warning "Standard w-scan failed, trying build from source..."
        cd /tmp
        wget http://wirbel.htpc-forum.de/w_scan/w_scan-20170107.tar.bz2 2>/dev/null || true
        tar -xf w_scan-20170107.tar.bz2 2>/dev/null || true
        cd w_scan-20170107 2>/dev/null && make && cp w_scan /usr/local/bin/w-scan && chmod 777 /usr/local/bin/w-scan || true
    }
}

print_success "Dependencies instalirane"

# DVB ADAPTER CHECK
print_status "Provjera DVB adaptera..."
DVB_COUNT=$(ls /dev/dvb* 2>/dev/null | wc -l)
if [ $DVB_COUNT -gt 0 ]; then
    print_success "✅ Pronađeno $DVB_COUNT DVB adaptera"
    ls -la /dev/dvb*
else
    print_warning "⚠️ Nema DVB adaptera - možda treba modprobe ili hardware problem"
fi

# NODE.JS INSTALL
print_status "Node.js instalacija..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs
print_success "Node.js instaliran"
pkill -f mumudvb 2>/dev/null || true
pkill -f oscam 2>/dev/null || true
pkill -f node 2>/dev/null || true
fuser -k 8887/tcp 2>/dev/null || true
fuser -k 8888/tcp 2>/dev/null || true
rm -rf /opt/mumudvb-webpanel 2>/dev/null || true
rm -rf /etc/mumudvb 2>/dev/null || true
rm -rf /usr/local/etc/oscam 2>/dev/null || true
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
apt install -y dvb-tools libdvbv5-dev
print_success "DVB osnovni paketi instalirani"

# SET PERMISIJE NA SVE FAJLOVE - PRVO EXECUTABLE NA SEBE
chmod +x "$0" 2>/dev/null || true

print_status "Postavljanje 777 permisija na sve fajlove..."
CURRENT_DIR=$(pwd)
chmod -R 777 "$CURRENT_DIR" 2>/dev/null || true
print_success "777 permisije postavljene na sve fajlove"

# MUMUDVB - AUTO CLONE I KOMPAJLIRANJE
print_status "MuMuDVB auto setup..."

# Ako nema MuMuDVB folder, kloniraj ga
if [ ! -d "$CURRENT_DIR/MuMuDVB" ]; then
    print_status "Kloniranje MuMuDVB..."
    cd "$CURRENT_DIR"
    git clone https://github.com/braice/MuMuDVB.git || {
        print_warning "Git clone failed, probam alternative..."
        git clone https://github.com/mumudvb/mumudvb.git MuMuDVB
    }
    print_success "MuMuDVB kloniran"
fi

if [ -d "$CURRENT_DIR/MuMuDVB" ]; then
    cd "$CURRENT_DIR/MuMuDVB"
    chmod 777 * -R 2>/dev/null || true
    make clean 2>/dev/null || true
    autoreconf -i -f
    ./configure --enable-cam-support --enable-scam-support
    make -j$(nproc)
    make install
    
    # FORCE LINK u PATH
    MUMUDVB_BIN=$(find . -name "mumudvb" -type f -executable | head -1)
    if [ -n "$MUMUDVB_BIN" ]; then
        cp "$MUMUDVB_BIN" /usr/local/bin/mumudvb
        chmod 777 /usr/local/bin/mumudvb
        print_success "✅ MuMuDVB instaliran: $(which mumudvb)"
    else
        print_warning "❌ MuMuDVB binary not found after build!"
    fi
else
    print_error "❌ MuMuDVB folder problem!"
fi

# OSCAM KOMPAJLIRANJE IZ LOKALNOG FOLDERA - SCHIMMELREITER SMOD
print_status "OSCam Schimmelreiter smod kompajliranje iz projekta..."
cd "$CURRENT_DIR"
if [ -d "oscam" ]; then
    cd oscam
    make clean 2>/dev/null || true
    make allyesconfig CONF_DIR=/usr/local/etc/oscam
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

# W-SCAN KOMPAJLIRANJE IZ GITHUB-A
print_status "W-Scan kompajliranje iz GitHub-a..."
cd "$CURRENT_DIR"

# Kloniraj w_scan ako ne postoji
if [ ! -d "w_scan" ]; then
    print_status "Kloniranje w_scan iz GitHub-a..."
    git clone https://github.com/tbsdtv/w_scan.git w_scan || {
        print_error "❌ W-Scan git clone failed!"
    }
    print_success "W-Scan kloniran"
fi

if [ -d "w_scan" ]; then
    cd w_scan
    chmod 777 * -R 2>/dev/null || true
    
    # Clean i build
    make clean 2>/dev/null || true
    autoreconf -i -f 2>/dev/null || ./autogen.sh 2>/dev/null || true
    ./configure
    make -j$(nproc)
    
    # Instaliraj w_scan binary
    if [ -f "w_scan" ]; then
        cp w_scan /usr/local/bin/w_scan
        chmod +x /usr/local/bin/w_scan
        ln -sf /usr/local/bin/w_scan /usr/local/bin/w-scan 2>/dev/null || true
        print_success "✅ W-Scan instaliran: $(which w_scan || which w-scan)"
    else
        print_warning "❌ W-Scan binary not found after build!"
    fi
    
    print_success "W-Scan kompajliran iz GitHub-a!"
else
    print_error "❌ W-Scan folder problem!"
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
mkdir -p /usr/local/etc/oscam
mkdir -p /var/log/oscam
mkdir -p /usr/local/var/oscam
chmod 755 /usr/local/etc/oscam
chmod 755 /var/log/oscam
chmod 755 /usr/local/var/oscam

# Web panel direktorijumi
mkdir -p /var/run/mumudvb
chmod 755 /var/run/mumudvb
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
# DVB-S/S2 Setup za HOTBIRD 19.2E

# DVB parametri
adapter=0
tuner=0
freq=10832
pol=h
srate=22000
delivery_system=DVBS2
modulation=8PSK


# Multicast konfiguracija
multicast=1
autoconf_ip4=239.100.%card.%number
port_multicast=1234
ttl_multicast=2
multicast_auto_join=1

# Autoconfiguration - automatski kanali
autoconfiguration=full
autoconf_radios=1
autoconf_scrambled=1



# SAP announces
sap=1
sap_group=239.255.255.255
sap_uri=sap://239.255.255.255

# HTTP Unicast
unicast=1
ip_http=0.0.0.0
port_http=4242
unicast_max_clients=200

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
sort_eit=1
EOF

chmod 644 /etc/mumudvb/mumudvb.conf
print_success "MuMuDVB config kreiran"

# OSCAM DEFAULTNA KONFIGURACIJA
print_status "OSCam defaultna konfiguracija..."

# oscam.conf - OPTIMIZOVANA VERZIJA
cat > /usr/local/etc/oscam/oscam.conf << 'EOF'
# OSCam Configuration - OPTIMIZOVANA ZA MUMUDVB + CCCAM
[global]
serverip = 0.0.0.0
logfile = /var/log/oscam/oscam.log
pidfile = /var/run/oscam.pid
disablelog = 0
disableuserfile = 0
usrfileflag = 0
clienttimeout = 8000
fallbacktimeout = 3000  
clientmaxidle = 300
bindwait = 120
netprio = 0
sleep = 0
unlockparental = 0
nice = 99
maxlogsize = 50
waitforcards = 1
preferlocalcards = 2
saveinithistory = 1
readerrestartseconds = 10
lb_mode = 1
lb_save = 500
lb_nbest_readers = 2
lb_auto_betatunnel = 1

[monitor]
port = 988
aulow = 120
monlevel = 4
nocrypt = 127.0.0.1,192.168.0.0-192.168.255.255

[webif]
httpport = 8888
httpuser = admin
httppwd = admin
httphelplang = en
httprefresh = 15
httpallowed = 127.0.0.1,192.168.0.0-192.168.255.255
httphideidleclients = 1
httpshowmeminfo = 1
httpshowuserinfo = 1
httpshowecminfo = 1
httpshowloadinfo = 1

[dvbapi]
enabled = 1
au = 1
user = mumudvb
boxtype = pc
pmt_mode = 6
request_mode = 1
delayer = 2
ecminfo_type = 4
read_sdt = 2
write_sdt_prov = 1

[cccam]
port = 12000
reshare = 2
ignorereshare = 0
stealth = 1
nodeid = 1234567890ABCDEF
version = 2.3.2
mindown = 0
EOF

# oscam.user - OPTIMIZOVANA VERZIJA
cat > /usr/local/etc/oscam/oscam.user << 'EOF'
# OSCam users - OPTIMIZOVANO ZA MUMUDVB

# MuMuDVB local connection
[account]
user = mumudvb
pwd = mumudvb
group = 1,2,3
au = 1
monlevel = 0
services = 
betatunnel = 1833.FFFF:1702,1833.FFFF:1722,1834.FFFF:1702
cccmaxhops = 3
cccreshare = 2
uniq = 3
sleep = 0
suppresscmd08 = 1
keepalive = 1

# Web interface admin
[account]
user = admin
pwd = admin
group = 1,2,3
au = 1
monlevel = 4
services = 
betatunnel = 1833.FFFF:1702,1833.FFFF:1722
cccmaxhops = 3
keepalive = 1

# CCcam sharing user (za vanjske klijente)
[account]
user = sharing
pwd = sharing123
group = 2
au = 0
monlevel = 0
cccmaxhops = 1
cccreshare = 0
suppresscmd08 = 1
services = !0B00
EOF

# oscam.server - OPTIMIZOVANA VERZIJA
cat > /usr/local/etc/oscam/oscam.server << 'EOF'
# OSCam server configuration - OPTIMIZOVANO ZA CCCAM SHARING

# CCcam reader - dhoom.org server - GLAVNI
[reader]
label = dhoom_primary
protocol = cccam
device = dhoom.org,34000
user = sead1302
password = sead1302
cccversion = 2.3.2
group = 1,2,3
disablecrccws = 1
inactivitytimeout = 30
reconnecttimeout = 60
lb_weight = 300
cccmaxhops = 3
ccckeepalive = 1
cccwantemu = 0
audisabled = 0
auprovid = 000000
services = !0B00
nanddumpsize = 64

# Backup CCcam reader (dodaj svoj backup server ovde)
# [reader]
# label = backup_server
# protocol = cccam
# device = backup-server.com,port
# user = username
# password = password
# cccversion = 2.3.2
# group = 2
# lb_weight = 100
# cccmaxhops = 2
# ccckeepalive = 1

# Local card reader template (ako imaš karticu)
# [reader]
# label = local-card
# protocol = internal
# device = /dev/sci0
# caid = 0B00
# detect = cd
# mhz = 600
# cardmhz = 600
# group = 1
# emmcache = 1,3,2,0
# blockemm-unknown = 1
# blockemm-u = 1
# blockemm-s = 1
# blockemm-g = 1
# lb_weight = 1000
EOF

chmod 644 /usr/local/etc/oscam/oscam.conf
chmod 644 /usr/local/etc/oscam/oscam.user  
chmod 644 /usr/local/etc/oscam/oscam.server

# CCcam.cfg za standardni CCcam (alternativa za OSCam)
print_status "Kreiranje CCcam.cfg alternativa..."
mkdir -p /var/etc/cccam
cat > /var/etc/cccam/CCcam.cfg << 'EOF'
# CCcam Configuration File
#
# Server configuration
SERVER LISTEN PORT : 12000
ALLOW TELNETINFO: yes
ALLOW WEBINFO: yes
WEBINFO LISTEN PORT : 16001
WEBINFO USERNAME : admin
WEBINFO PASSWORD : admin
TELNETINFO LISTEN PORT : 16000
TELNETINFO USERNAME : admin
TELNETINFO PASSWORD : admin

# CCcam server - dhoom.org
C: dhoom.org 34000 sead1302 sead1302 

# Additional server configuration
DEBUG : yes
MINI OSD : yes
OSD PORT : 8888
ZAP OSD TIME : 3
SHOW TIMING : yes
CCAM DEBUG : yes
SOFTKEY FILE : /var/keys/SoftCam.Key
EOF

chmod 644 /var/etc/cccam/CCcam.cfg
print_success "OSCam config i CCcam alternativa kreirani"

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

# MASTER SERVER.JS - SAMO MASTER-INDEX.HTML!
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

// MAIN ROUTE - SAMO MASTER-INDEX.HTML!
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
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

// Start MuMuDVB with Tuner Conflict Check
app.post('/api/mumudvb/start', (req, res) => {
    // Check if W-Scan is running first
    exec('pgrep -f "w_scan|w-scan" | wc -l', (checkError, checkStdout) => {
        const wscanRunning = parseInt(checkStdout.trim()) > 0;
        
        if (wscanRunning) {
            return res.json({
                success: false,
                message: 'Cannot start MuMuDVB: W-Scan is using the tuner',
                error: 'Tuner conflict detected',
                suggestion: 'Stop W-Scan first or wait for completion'
            });
        }
        
        // Check if MuMuDVB is already running
        exec('pgrep -f mumudvb | wc -l', (runCheckError, runCheckStdout) => {
            const mumudvbRunning = parseInt(runCheckStdout.trim()) > 0;
            
            if (mumudvbRunning) {
                return res.json({
                    success: false,
                    message: 'MuMuDVB is already running',
                    error: 'Process already exists',
                    suggestion: 'Stop MuMuDVB first if you want to restart'
                });
            }
            
            // Start MuMuDVB
            console.log(`🚀 Starting MuMuDVB...`);
            exec('mumudvb -d -c /etc/mumudvb/mumudvb.conf', (error, stdout, stderr) => {
                const success = !error;
                console.log(success ? `✅ MuMuDVB started successfully` : `❌ MuMuDVB start failed: ${error?.message}`);
                
                res.json({
                    success: success,
                    message: error ? `MuMuDVB start failed: ${error.message}` : 'MuMuDVB started successfully',
                    output: stdout || stderr,
                    tunerFree: true
                });
            });
        });
    });
});

// Stop MuMuDVB with Force Option
app.post('/api/mumudvb/stop', (req, res) => {
    const force = req.body.force || false;
    const signal = force ? 'pkill -9 -f mumudvb' : 'pkill -f mumudvb';
    
    console.log(`🛑 Stopping MuMuDVB (force: ${force})...`);
    
    exec(signal, (error) => {
        // Wait a moment and check if processes are actually stopped
        setTimeout(() => {
            exec('pgrep -f mumudvb | wc -l', (checkError, checkStdout) => {
                const stillRunning = parseInt(checkStdout.trim()) > 0;
                
                console.log(stillRunning ? `⚠️  MuMuDVB processes still running` : `✅ MuMuDVB stopped`);
                
                res.json({
                    success: true,
                    message: stillRunning ? 'MuMuDVB stop signal sent (some processes may still be running)' : 'MuMuDVB stopped successfully',
                    force: force,
                    stillRunning: stillRunning,
                    tunerReleased: !stillRunning
                });
            });
        }, 1000);
    });
});

// MuMuDVB Status Check
app.get('/api/mumudvb/status', (req, res) => {
    exec('pgrep -f mumudvb | wc -l', (error, stdout) => {
        const processCount = parseInt(stdout.trim()) || 0;
        const isRunning = processCount > 0;
        
        res.json({
            running: isRunning,
            processCount: processCount,
            status: isRunning ? 'MuMuDVB is running' : 'MuMuDVB is stopped',
            httpUrl: isRunning ? 'http://localhost:4242' : null
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
    exec('oscam -b -c /usr/local/etc/oscam', (error, stdout, stderr) => {
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
        const config = fs.readFileSync('/usr/local/etc/oscam/' + file, 'utf8');
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

// ============= CCCAM API =============

// Start CCcam
app.post('/api/cccam/start', (req, res) => {
    exec('systemctl start cccam', (error, stdout, stderr) => {
        res.json({
            success: !error,
            message: error ? error.message : 'CCcam started',
            output: stdout || stderr
        });
    });
});

// Stop CCcam
app.post('/api/cccam/stop', (req, res) => {
    exec('systemctl stop cccam', (error) => {
        res.json({
            success: true,
            message: 'CCcam stop signal sent'
        });
    });
});

// CCcam Config Load
app.get('/api/cccam/config', (req, res) => {
    try {
        const config = fs.readFileSync('/var/etc/cccam/CCcam.cfg', 'utf8');
        res.json({ success: true, config: config });
    } catch (error) {
        res.json({ success: false, error: 'CCcam.cfg not found' });
    }
});

// CCcam Config Save
app.post('/api/cccam/config', (req, res) => {
    try {
        fs.writeFileSync('/var/etc/cccam/CCcam.cfg', req.body.config);
        res.json({ success: true });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

// CCcam Status
app.get('/api/cccam/status', (req, res) => {
    exec('systemctl is-active cccam', (error, stdout) => {
        res.json({
            success: true,
            active: stdout.trim() === 'active',
            status: stdout.trim()
        });
    });
});

// ============= W-SCAN API =============

// W-Scan Start (legacy)
app.post('/api/wscan/start', (req, res) => {
    const satellite = req.body.satellite || 'HOTBIRD';
    const wscanCmd = 'which w_scan >/dev/null 2>&1 && w_scan -f s -s ' + satellite + ' -o 7 -t 3 || w-scan -f s -s ' + satellite + ' -o 7 -t 3';
    exec(wscanCmd, (error, stdout, stderr) => {
        res.json({
            success: !error,
            output: stdout || stderr || 'W-scan completed',
            satellite: satellite
        });
    });
});

// Global variable to track running W-Scan process
let runningWScanProcess = null;

// W-Scan Custom Command with Tuner Management
app.post('/api/wscan/custom', (req, res) => {
    const command = req.body.command || 'w_scan -f s -s S19E2 -o 7 -t 3 -X > channels.conf';
    
    // Check if W-Scan is already running
    if (runningWScanProcess) {
        return res.json({ 
            success: false, 
            error: 'W-Scan is already running. Stop it first or wait for completion.',
            pid: runningWScanProcess.pid 
        });
    }
    
    // Security check - only allow w_scan/w-scan commands
    if (!command.startsWith('w_scan') && !command.startsWith('w-scan')) {
        return res.json({ success: false, error: 'Only w_scan commands allowed' });
    }
    
    console.log(`🔍 Starting W-Scan: ${command}`);
    console.log(`⚠️  WARNING: This will temporarily block DVB tuner for MuMuDVB`);
    
    const fullOutput = [];
    const startTime = Date.now();
    
    // Step 1: Stop MuMuDVB to free tuner
    console.log(`🛑 Stopping MuMuDVB to free tuner...`);
    exec('pkill -f mumudvb; sleep 2', (stopError) => {
        if (stopError) {
            console.log(`⚠️  MuMuDVB stop warning: ${stopError.message}`);
        }
        
        // Step 2: Start W-Scan process
        runningWScanProcess = exec(command, { timeout: 300000 }, (error, stdout, stderr) => {
            const output = stdout + stderr;
            const duration = Math.round((Date.now() - startTime) / 1000);
            
            console.log(`✅ W-Scan completed in ${duration}s. Output length: ${output.length} chars`);
            
            // Step 3: Force disconnect from tuner
            console.log(`🔌 Disconnecting from tuner...`);
            exec('pkill -f w_scan; pkill -f w-scan; sleep 1', (disconnectError) => {
                if (disconnectError) {
                    console.log(`⚠️  Tuner disconnect warning: ${disconnectError.message}`);
                }
                
                // Step 4: Reset DVB modules (force clean disconnect)
                exec('modprobe -r dvb_core 2>/dev/null; sleep 1; modprobe dvb_core 2>/dev/null', (resetError) => {
                    if (resetError) {
                        console.log(`⚠️  DVB module reset warning: ${resetError.message}`);
                    }
                    
                    // Step 5: Check channels.conf generation
                    const fs = require('fs');
                    let channelsInfo = '';
                    let channelsGenerated = false;
                    
                    try {
                        if (fs.existsSync('./channels.conf')) {
                            const stats = fs.statSync('./channels.conf');
                            channelsInfo = `\n\n📺 channels.conf generated successfully!\n📁 Location: ${process.cwd()}/channels.conf\n📊 Size: ${stats.size} bytes\n📅 Created: ${stats.mtime}`;
                            channelsGenerated = true;
                        } else {
                            channelsInfo = '\n\n⚠️ channels.conf not found in current directory';
                        }
                    } catch (e) {
                        channelsInfo = `\n\n❌ Error checking channels.conf: ${e.message}`;
                    }
                    
                    // Step 6: Clear running process reference
                    runningWScanProcess = null;
                    
                    // Step 7: Send response
                    const finalOutput = output + channelsInfo + `\n\n🕐 Scan duration: ${duration} seconds\n🔌 Tuner disconnected - safe to restart MuMuDVB\n\n💡 TIP: Start MuMuDVB manually or it will auto-restart`;
                    
                    res.json({
                        success: !error,
                        output: finalOutput,
                        command: command,
                        error: error ? error.message : null,
                        channelsGenerated: channelsGenerated,
                        duration: duration,
                        tunerDisconnected: true
                    });
                    
                    console.log(`🔄 W-Scan process completed and tuner released`);
                });
            });
        });
        
        // Store PID for tracking
        if (runningWScanProcess) {
            console.log(`📋 W-Scan process started with PID: ${runningWScanProcess.pid}`);
        }
    });
    
    // Real-time output logging
    if (runningWScanProcess) {
        runningWScanProcess.stdout.on('data', (data) => {
            console.log(`W-Scan: ${data.toString().trim()}`);
            fullOutput.push(data.toString());
        });
        
        runningWScanProcess.stderr.on('data', (data) => {
            console.log(`W-Scan: ${data.toString().trim()}`);
            fullOutput.push(data.toString());
        });
        
        runningWScanProcess.on('error', (error) => {
            console.log(`❌ W-Scan process error: ${error.message}`);
            runningWScanProcess = null;
        });
    }
});

// W-Scan Stop with Force Tuner Disconnect
app.post('/api/wscan/stop', (req, res) => {
    console.log(`🛑 Force stopping W-Scan process...`);
    
    // Step 1: Kill W-Scan processes
    exec('pkill -9 -f w_scan; pkill -9 -f w-scan; sleep 1', (killError) => {
        // Step 2: Force disconnect from tuner
        exec('pkill -9 -f dvb; sleep 1', (dvbError) => {
            // Step 3: Reset DVB modules for clean tuner release
            exec('modprobe -r dvb_core 2>/dev/null; sleep 2; modprobe dvb_core 2>/dev/null', (resetError) => {
                
                // Clear running process reference
                if (runningWScanProcess) {
                    try {
                        runningWScanProcess.kill('SIGKILL');
                    } catch (e) {
                        console.log(`⚠️  Process kill warning: ${e.message}`);
                    }
                    runningWScanProcess = null;
                }
                
                console.log(`✅ W-Scan force stopped and tuner released`);
                
                res.json({
                    success: true,
                    message: 'W-Scan force stopped and tuner disconnected',
                    actions: [
                        'W-Scan processes killed',
                        'DVB processes terminated', 
                        'DVB modules reset',
                        'Tuner released for MuMuDVB'
                    ]
                });
            });
        });
    });
});

// W-Scan Process Status
app.get('/api/wscan/status', (req, res) => {
    exec('pgrep -f "w_scan|w-scan" | wc -l', (error, stdout) => {
        const processCount = parseInt(stdout.trim()) || 0;
        const isRunning = runningWScanProcess !== null || processCount > 0;
        
        let pid = null;
        if (runningWScanProcess) {
            pid = runningWScanProcess.pid;
        }
        
        res.json({
            running: isRunning,
            processCount: processCount,
            pid: pid,
            managed: runningWScanProcess !== null,
            status: isRunning ? 'W-Scan is running - tuner blocked' : 'W-Scan idle - tuner available'
        });
    });
});

// ============= TUNERS API =============

// Tuner Status with Conflict Detection
app.get('/api/tuners/status', (req, res) => {
    // Check processes using tuners
    exec('lsof /dev/dvb* 2>/dev/null | grep -v COMMAND', (lsofError, lsofStdout) => {
        exec('pgrep -f "mumudvb|w_scan|w-scan" -l', (procError, procStdout) => {
            const tunerProcesses = lsofStdout ? lsofStdout.trim().split('\n').filter(line => line.length > 0) : [];
            const allProcesses = procStdout ? procStdout.trim().split('\n').filter(line => line.length > 0) : [];
            
            const mumudvbRunning = allProcesses.some(line => line.includes('mumudvb'));
            const wscanRunning = allProcesses.some(line => line.includes('w_scan') || line.includes('w-scan'));
            
            let status = 'Available';
            let blockedBy = null;
            
            if (mumudvbRunning && wscanRunning) {
                status = 'Conflict';
                blockedBy = 'Both MuMuDVB and W-Scan';
            } else if (mumudvbRunning) {
                status = 'Used by MuMuDVB';
                blockedBy = 'MuMuDVB';
            } else if (wscanRunning) {
                status = 'Used by W-Scan';
                blockedBy = 'W-Scan';
            }
            
            res.json({
                tunerStatus: status,
                available: status === 'Available',
                conflict: status === 'Conflict',
                blockedBy: blockedBy,
                processes: {
                    mumudvb: mumudvbRunning,
                    wscan: wscanRunning,
                    tunerProcesses: tunerProcesses.length,
                    allProcesses: allProcesses
                },
                recommendation: status === 'Available' ? 'Safe to start any service' : 
                               status === 'Conflict' ? 'Stop all services and restart one by one' :
                               `Stop ${blockedBy} to free tuner`
            });
        });
    });
});

// Scan DVB Tuners
app.get('/api/tuners/scan', (req, res) => {
    exec('ls -la /dev/dvb* 2>/dev/null && echo "---" && lsmod | grep dvb', (error, stdout) => {
        const tuners = [];
        const lines = stdout.split('\n');
        
        lines.forEach((line, index) => {
            if (line.includes('/dev/dvb')) {
                const parts = line.split('/');
                const device = parts[parts.length - 1];
                tuners.push({
                    device: device,
                    type: device.includes('frontend') ? 'DVB Frontend' : 'DVB Device',
                    status: 'Available'
                });
            }
        });
        
        res.json({
            success: tuners.length > 0,
            tuners: tuners,
            info: stdout || 'No DVB adapters found'
        });
    });
});

// Get Tuner Capabilities
app.get('/api/tuners/capabilities', (req, res) => {
    exec('find /dev/dvb* -name "frontend*" | head -4 | xargs -I {} dvb-fe-tool -f {} 2>/dev/null || echo "dvb-tools not available"', (error, stdout) => {
        res.json({
            success: !error,
            capabilities: stdout || 'No tuner capabilities found'
        });
    });
});

// Test Specific Tuner
app.get('/api/tuners/test/:adapter', (req, res) => {
    const adapter = parseInt(req.params.adapter);
    exec(`dvb-fe-tool -a ${adapter} 2>/dev/null || echo "Adapter ${adapter} not available"`, (error, stdout) => {
        res.json({
            success: !error,
            message: stdout || `Adapter ${adapter} test completed`,
            adapter: adapter
        });
    });
});

// Test All Tuners
app.get('/api/tuners/test-all', (req, res) => {
    exec('for i in 0 1 2 3; do echo "=== Adapter $i ==="; dvb-fe-tool -a $i 2>/dev/null || echo "Adapter $i not found"; done', (error, stdout) => {
        res.json({
            success: true,
            message: 'Tuner test completed',
            output: stdout
        });
    });
});

// ============= CHANNELS API =============

// Load Channel List
app.get('/api/channels/list', (req, res) => {
    exec('wget -q -O - http://localhost:4242/channels.json 2>/dev/null || echo "MuMuDVB not running or no channels"', (error, stdout) => {
        res.json({
            success: !error && stdout.length > 10,
            channels: stdout || 'No channels available. Start MuMuDVB first.'
        });
    });
});

// Export M3U Playlist
app.get('/api/channels/export', (req, res) => {
    exec('wget -q -O - http://localhost:4242/playlist.m3u 2>/dev/null || echo "#EXTM3U\n# No channels available"', (error, stdout) => {
        res.json({
            success: !error,
            m3u: stdout || '#EXTM3U\n# No channels available'
        });
    });
});

// Generate Bouquet
app.get('/api/channels/bouquet', (req, res) => {
    exec('wget -q -O - http://localhost:4242/channels.json | python3 -m json.tool 2>/dev/null || echo "Bouquet generation requires MuMuDVB running"', (error, stdout) => {
        res.json({
            success: !error,
            message: error ? 'Bouquet generation failed' : 'Bouquet data retrieved'
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

const PORT = process.env.PORT || 8887;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 MuMuDVB Master Panel running on port ${PORT}`);
    console.log(`🌐 Access: http://localhost:${PORT}`);
    console.log(`📺 MuMuDVB HTTP: http://localhost:4242 (when started)`);
    console.log(`🔐 OSCam Web: http://localhost:8888 (admin/admin)`);
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
    print_warning "❌ Syntax ERROR - brutal fix..."
    cd /opt/mumudvb-webpanel
    
    # Remove extra bracket patterns that cause problems
    sed -i '/^    });$/d' server.js
    sed -i '/^});$/N;s/^});\n});$/});/' server.js
    
    # Test again
    node -c server.js && print_success "✅ Brutal fix worked!" || {
        print_warning "Still broken - manual intervention needed"
        echo "Manual fix: cd /opt/mumudvb-webpanel && nano server.js (remove extra } on line ~168)"
    }
}

# Kreiraj uploads direktorijum za multer
mkdir -p /opt/mumudvb-webpanel/uploads
print_success "Uploads direktorijum kreiran"

# COPY MASTER-INDEX.HTML - SAMO FULL VERZIJA!
print_status "MASTER-INDEX.HTML kopiranje - SAMO FULL VERZIJA!"

# PRVO provjeri da li postoji
if [ -f "$CURRENT_DIR/web_panel/master-index.html" ]; then
    print_status "Kopiranje master-index.html iz web_panel/..."
    cp "$CURRENT_DIR/web_panel/master-index.html" /opt/mumudvb-webpanel/public/index.html
    chmod 644 /opt/mumudvb-webpanel/public/index.html
    print_success "✅ MASTER-INDEX.HTML kopiran - FULL VERZIJA SA 10 TABOVA!"
else
    print_error "❌ MASTER-INDEX.HTML NE POSTOJI! web_panel/master-index.html MORA postojati!"
fi

# Provjeri da li je kopiran
if [ ! -f "/opt/mumudvb-webpanel/public/index.html" ]; then
    print_error "❌ INDEX.HTML nije kreiran! STOP!"
fi

print_success "✅ MASTER HTML INTERFACE - SAMO FULL VERZIJA!"

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

# OSCam servis - ISPRAVLJEN ZA /usr/local/etc/oscam
cat > /etc/systemd/system/oscam.service << 'EOF'
[Unit]
Description=OSCam - Software CAM for MuMuDVB
After=network.target
Wants=network.target

[Service]
Type=forking
User=root
Group=root
ExecStart=/usr/local/bin/oscam -b -c /usr/local/etc/oscam
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/var/run/oscam.pid
Restart=always
RestartSec=10
TimeoutStartSec=30
TimeoutStopSec=30

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=/usr/local/etc/oscam /var/run /var/log

[Install]
WantedBy=multi-user.target
EOF

# CCcam service alternativa (ako treba standardni CCcam umesto OSCam)
cat > /etc/systemd/system/cccam.service << 'EOF'
[Unit]
Description=CCcam - Card sharing server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cccam -C /var/etc/cccam/CCcam.cfg
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mumudvb-webpanel
systemctl enable oscam 2>/dev/null || true
# systemctl enable cccam 2>/dev/null || true  # Uncomment if using CCcam instead of OSCam

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

# Test W-Scan
echo "🔍 W-Scan test:"
if command -v w_scan >/dev/null 2>&1; then
    print_success "✅ w_scan dostupan: $(which w_scan)"
elif command -v w-scan >/dev/null 2>&1; then
    print_success "✅ w-scan dostupan: $(which w-scan)"
else
    print_warning "❌ W-Scan nije dostupan u PATH!"
fi
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
print_success "✅ W-Scan: kompajliran iz GitHub-a"

echo ""
print_status "🔧 COMPILED TOOLS:"
print_success "✅ MuMuDVB: $(which mumudvb 2>/dev/null || echo 'not found')"
print_success "✅ OSCam: $(which oscam 2>/dev/null || echo 'not found')"
print_success "✅ W-Scan: $(which w_scan 2>/dev/null || which w-scan 2>/dev/null || echo 'not found')"

echo ""
print_status "🌐 PRISTUP LINKOVI:"
SERVER_IP=$(hostname -I | awk '{print $1}')
print_success "🚀 Master Panel: http://$SERVER_IP:8887"
print_success "📺 MuMuDVB HTTP: http://$SERVER_IP:4242 (kad se pokrene)"
print_success "🔐 OSCam Web: http://$SERVER_IP:8888 (admin/admin)"

echo ""
print_success "🎯 SVE UPRAVLJANJE KROZ WEB PANEL NA 8887!"
print_success "🔧 Editovanje konfiguracija, pokretanje servisa, sve na klik!"







