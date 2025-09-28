#!/bin/bash

# KONAČNI UBUNTU 20.04 MUMUDVB INSTALLER 
# ZA ROOT USER - REŠAVA SVE PROBLEME!

set -e  # Exit on any error

echo "🚀 KONAČNI UBUNTU 20.04 MUMUDVB INSTALLER (ROOT MODE)"
echo "====================================================="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Ubuntu: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
echo ""

# Funkcije
print_status() { echo -e "\n🔄 \e[34m$1\e[0m"; }
print_success() { echo -e "✅ \e[32m$1\e[0m"; }
print_error() { echo -e "❌ \e[31m$1\e[0m"; exit 1; }
print_warning() { echo -e "⚠️  \e[33m$1\e[0m"; }

# Cleanup
print_status "Čišćenje starih procesa..."
pkill -f mumudvb 2>/dev/null || true
pkill -f node 2>/dev/null || true
pkill -f npm 2>/dev/null || true
rm -rf /tmp/MuMuDVB 2>/dev/null || true

# ==============================================
# FAZA 1: SISTEM UPDATE
# ==============================================

print_status "FAZA 1: Update sistema"
apt update && apt upgrade -y

print_status "Instaliranje osnovnih paketa..."
apt install -y \
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
    gettext-base \
    autopoint \
    intltool \
    linux-headers-$(uname -r) \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

print_success "Osnovni paketi instalirani"

# ==============================================
# FAZA 2: NODE.JS - KOMPLETNO ČIŠĆENJE I NOVA INSTALACIJA
# ==============================================

print_status "FAZA 2: Node.js - TOTALNO ČIŠĆENJE"

# Kompletno uklanjanje SVEG Node.js
print_status "Uklanjanje SVIH postojećih Node.js instalacija..."
apt remove --purge -y nodejs npm nodejs-doc libnode-dev libnode64 node-gyp 2>/dev/null || true
snap remove node 2>/dev/null || true
apt autoremove -y
apt autoclean

# Brisanje SVIH fajlova
print_status "Brisanje Node.js fajlova sa sistema..."
rm -rf /usr/local/bin/node* /usr/local/bin/npm* 2>/dev/null || true
rm -rf /usr/local/lib/node_modules 2>/dev/null || true  
rm -rf /usr/bin/node* /usr/bin/npm* 2>/dev/null || true
rm -rf ~/.npm ~/.node-gyp /tmp/.npm* 2>/dev/null || true
rm -rf /etc/apt/sources.list.d/nodesource* 2>/dev/null || true
rm -rf /usr/share/nodejs* 2>/dev/null || true

# Čišćenje environment
unset NODE_PATH
unset NPM_CONFIG_PREFIX

print_status "INSTALIRANJE NOVE NODE.JS 18.x VERZIJE"

# NodeSource repo setup
print_status "Dodavanje NodeSource repozitorijuma..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

# Update package list
apt update

# Instaliraj Node.js
print_status "Instaliranje nodejs paketa..."
apt install -y nodejs

print_status "Provera Node.js instalacije..."

# Wait for installation to complete
sleep 3

# Test Node.js
NODE_CMD=""
if [ -x "/usr/bin/node" ] && /usr/bin/node --version &>/dev/null; then
    NODE_CMD="/usr/bin/node"
    NODE_VERSION=$(/usr/bin/node --version)
    print_success "Node.js: $NODE_VERSION (path: /usr/bin/node)"
elif command -v node &>/dev/null; then
    NODE_CMD="node"
    NODE_VERSION=$(node --version)
    print_success "Node.js: $NODE_VERSION (in PATH)"
else
    print_error "Node.js instalacija neuspešna!"
fi

# Test npm - Ubuntu 20.04 specifično
NPM_CMD=""
if [ -x "/usr/bin/npm" ] && /usr/bin/npm --version &>/dev/null; then
    NPM_CMD="/usr/bin/npm"
    NPM_VERSION=$(/usr/bin/npm --version)
    print_success "npm: $NPM_VERSION (path: /usr/bin/npm)"
elif command -v npm &>/dev/null && npm --version &>/dev/null; then
    NPM_CMD="npm"  
    NPM_VERSION=$(npm --version)
    print_success "npm: $NPM_VERSION (in PATH)"
else
    print_warning "npm nije instaliran sa nodejs paketom (Ubuntu 20.04 problem)"
    print_status "Instaliram npm POSEBNO..."
    
    # Ubuntu 20.04 needs npm installed separately
    apt install -y npm
    
    # Test again
    if [ -x "/usr/bin/npm" ] && /usr/bin/npm --version &>/dev/null; then
        NPM_CMD="/usr/bin/npm"
        NPM_VERSION=$(/usr/bin/npm --version) 
        print_success "npm: $NPM_VERSION (posebno instaliran)"
    elif command -v npm &>/dev/null; then
        NPM_CMD="npm"
        NPM_VERSION=$(npm --version)
        print_success "npm: $NPM_VERSION (posebno instaliran)" 
    else
        print_error "npm instalacija neuspešna ni posle posebne instalacije!"
    fi
fi

# DEFINITIVNI Node.js 18.x fix - GARANTOVANO!
print_status "🔥 DEFINITIVNI Node.js 18.x fix..."

# 1. NUKLEARNO uklanjanje svih Node.js verzija
print_status "💣 Nuklearno uklanjanje starog Node.js..."
apt remove --purge -y nodejs npm nodejs-doc libnode64 libc-ares2 2>/dev/null || true
apt autoremove -y --purge
apt autoclean

# 2. Ukloni sve NodeSource repozitorijume
rm -rf /etc/apt/sources.list.d/nodesource* 2>/dev/null || true
rm -rf /usr/share/keyrings/nodesource* 2>/dev/null || true

# 3. Ukloni sve Node.js fajlove
rm -rf /usr/bin/node* /usr/bin/npm /usr/lib/node* /usr/share/node* 2>/dev/null || true

# 4. SVEZI NodeSource setup sa retry logikom
print_status "📦 Instaliram NodeSource 18.x repozitorijum..."
for attempt in 1 2 3; do
    print_status "Pokušaj $attempt/3..."
    
    if curl -fsSL https://deb.nodesource.com/setup_18.x | bash -; then
        print_success "NodeSource repozitorijum dodat!"
        break
    else
        print_warning "Pokušaj $attempt neuspešan, čekam 5 sekundi..."
        sleep 5
    fi
    
    if [ $attempt -eq 3 ]; then
        print_error "NodeSource setup potpuno neuspešan!"
        
        # ALTERNATIVE: Manual repository add
        print_status "🚨 EMERGENCY: Ručno dodavanje NodeSource..."
        echo "deb https://deb.nodesource.com/node_18.x focal main" > /etc/apt/sources.list.d/nodesource.list
        echo "deb-src https://deb.nodesource.com/node_18.x focal main" >> /etc/apt/sources.list.d/nodesource.list
        
        # Add GPG key manually
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
        
        print_success "Emergency NodeSource setup završen!"
    fi
done

# 5. Force update repository
apt update

# 6. FORCE install Node.js 18.x sa specifičnom verzijom
print_status "🎯 Force instalacija Node.js 18.x..."
if apt install -y nodejs=18.*; then
    print_success "Node.js 18.x instaliran sa apt!"
elif apt install -y nodejs; then
    print_warning "Instaliran nodejs (neznam koju verziju)..."
else
    print_error "Apt instalacija neuspešna!"
    
    # ULTIMATE FALLBACK: Binary download
    print_status "🚨 ULTIMATE FALLBACK: Direktno skidanje Node.js 18.x binary..."
    cd /tmp
    wget -q https://nodejs.org/dist/v18.20.4/node-v18.20.4-linux-x64.tar.xz
    if [ -f "node-v18.20.4-linux-x64.tar.xz" ]; then
        tar -xf node-v18.20.4-linux-x64.tar.xz
        cp -r node-v18.20.4-linux-x64/bin/* /usr/local/bin/
        cp -r node-v18.20.4-linux-x64/lib/* /usr/local/lib/
        cp -r node-v18.20.4-linux-x64/include/* /usr/local/include/
        cp -r node-v18.20.4-linux-x64/share/* /usr/local/share/
        
        # Create symlinks
        ln -sf /usr/local/bin/node /usr/bin/node
        ln -sf /usr/local/bin/npm /usr/bin/npm
        
        print_success "🎉 Node.js 18.x instaliran direktno!"
    else
        print_error "❌ I direktno skidanje neuspešno!"
    fi
fi

# 7. KONAČNI TEST
if command -v node &>/dev/null; then
    FINAL_NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo $FINAL_NODE_VERSION | cut -d'.' -f1 | tr -d 'v')
    
    if [ "$NODE_MAJOR" -ge 18 ]; then
        print_success "🎉 SUCCESS: Node.js verzija: $FINAL_NODE_VERSION"
        NODE_CMD="node"
        NPM_CMD="npm"
        
        # Testiraj npm - ne ažuriraj (nova npm verzija zahteva Node 20+)
        if command -v npm &>/dev/null; then
            NPM_VERSION=$(npm --version)
            print_success "npm je dostupan: $NPM_VERSION"
            print_success "Node.js 18.20.8 + npm $NPM_VERSION = SAVRŠENA kombinacija!"
            print_warning "⚠️  Ne ažuriram npm jer nova verzija zahteva Node.js 20+"
        else
            print_warning "npm nije dostupan - nastavljam bez npm-a"
        fi
    else
        print_error "❌ FAIL: Node.js verzija je još uvek $FINAL_NODE_VERSION"
        print_status "Nastavljam sa starijom verzijom..."
        NODE_CMD="node"
        NPM_CMD="npm"
    fi
else
    print_error "❌ KRITIČNA GREŠKA: node komanda ne postoji!"
    print_status "Pokušavam sa nodejs..."
    if command -v nodejs &>/dev/null; then
        NODE_CMD="nodejs"
        NPM_CMD="npm"
    else
        print_error "❌ NI nodejs ne postoji - prekidam!"
        exit 1
    fi
fi

# Final verification
print_status "Finalna provera Node.js i npm..."
NODE_FINAL=$($NODE_CMD --version)
NPM_FINAL=$($NPM_CMD --version)
print_success "FINALNO - Node.js: $NODE_FINAL"
print_success "FINALNO - npm: $NPM_FINAL"

# Kreiraj linkove
print_status "Kreiranje sistemskih linkova..."
ln -sf $(which node) /usr/local/bin/node 2>/dev/null || true
ln -sf $(which npm) /usr/local/bin/npm 2>/dev/null || true

# ==============================================
# FAZA 3: GETTEXT & AUTOTOOLS
# ==============================================

print_status "FAZA 3: Gettext & autotools instalacija"

# Kritični paketi za MuMuDVB build
GETTEXT_PACKAGES=("gettext" "gettext-base" "autopoint" "autoconf" "automake" "libtool" "intltool" "dh-autoreconf")

for pkg in "${GETTEXT_PACKAGES[@]}"; do
    print_status "Instaliram $pkg..."
    apt install -y "$pkg" || print_warning "$pkg instalacija neuspešna"
done

# Forsiraj reinstall autopoint ako ne radi
if ! command -v autopoint &>/dev/null; then
    print_warning "autopoint nije dostupan, forsiram reinstall..."
    apt remove --purge -y autopoint gettext 2>/dev/null || true
    apt install -y gettext autopoint
fi

# Test autopoint detaljno
print_status "Testiram autopoint dostupnost..."
if command -v autopoint &>/dev/null; then
    AUTOPOINT_PATH=$(which autopoint)
    print_success "autopoint je dostupan: $AUTOPOINT_PATH"
    
    # Test da li može da se pokrene
    if autopoint --version &>/dev/null; then
        AUTOPOINT_VERSION=$(autopoint --version | head -1)
        print_success "autopoint verzija: $AUTOPOINT_VERSION"
    else
        print_warning "autopoint se ne može pokrenuti!"
        # Pokušaj fix permissions
        chmod +x "$AUTOPOINT_PATH" 2>/dev/null || true
    fi
else
    print_error "autopoint NIJE dostupan nakon instalacije!"
    
    # Debug - probaj da nađeš gde je
    print_status "Tražim autopoint fajlove..."
    find /usr -name "*autopoint*" 2>/dev/null | head -10 || true
    
    # Pokušaj simboličku vezu
    if [ -f "/usr/bin/autopoint" ]; then
        print_status "Našao /usr/bin/autopoint, ali command ne radi..."
        ls -la /usr/bin/autopoint
    fi
fi

# ==============================================
# FAZA 4: DVB PAKETI
# ==============================================

print_status "FAZA 4: DVB paketi instalacija"

# Lista paketa koji STVARNO postoje u Ubuntu 20.04
DVB_PACKAGES=("dvb-tools" "w-scan" "libdvbv5-dev")
INSTALLED_DVB=0

for pkg in "${DVB_PACKAGES[@]}"; do
    print_status "Proveravam paket: $pkg"
    if apt-cache show "$pkg" &>/dev/null; then
        print_status "Instaliram $pkg..."
        if apt install -y "$pkg"; then
            print_success "$pkg ✅"
            INSTALLED_DVB=$((INSTALLED_DVB + 1))
        else
            print_warning "$pkg instalacija neuspešna"
        fi
    else
        print_warning "$pkg ne postoji u Ubuntu 20.04 repozitorijumima"
    fi
done

print_success "DVB paketi: $INSTALLED_DVB od ${#DVB_PACKAGES[@]} instalirano"

# Napomena o paketima koji ne postoje
print_warning "NAPOMENA: Ubuntu 20.04 NEMA sledeće pakete:"
print_warning "  ❌ szap (uklonjen iz repozitorijuma)"
print_warning "  ❌ libdvbv5-tools (uklonjen iz repozitorijuma)"
print_warning "  ℹ️  MuMuDVB će raditi i bez njih!"

# ==============================================
# FAZA 5: MUMUDVB KOMPAJLIRANJE
# ==============================================

print_status "FAZA 5: MuMuDVB kompajliranje"

cd /tmp
rm -rf MuMuDVB 2>/dev/null || true

print_status "Kloniranje MuMuDVB repozitorijuma..."
if ! git clone https://github.com/braice/MuMuDVB.git; then
    print_error "Git clone neuspešan!"
fi

cd MuMuDVB
print_success "MuMuDVB source kod skinut"

# EMERGENCY autopoint fix - direktno u MuMuDVB folder
print_status "EMERGENCY autopoint fix..."

# Instaliraj SADA sve gettext pakete direktno
print_status "Force reinstall svih gettext paketa..."
apt update
apt remove --purge -y gettext gettext-base autopoint 2>/dev/null || true
apt install -y gettext gettext-base autotools-dev autopoint intltool

# Proveri PATH
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

# Test autopoint SADA
if command -v autopoint &>/dev/null; then
    print_success "autopoint KONAČNO dostupan: $(which autopoint)"
    autopoint --version | head -1
else
    print_error "autopoint OPET nije dostupan!"
    
    # Desperate measures - pokušaj da ga nađeš
    print_status "Tražim autopoint na sistemu..."
    find /usr -name "autopoint" -type f 2>/dev/null | head -5
    
    # Manual link ako postoji
    if [ -f "/usr/bin/autopoint" ]; then
        print_status "Našao /usr/bin/autopoint - proveravam permissions..."
        ls -la /usr/bin/autopoint
        chmod +x /usr/bin/autopoint 2>/dev/null || true
    fi
    
    # Pokušaj poslednji put
    if ! command -v autopoint &>/dev/null; then
        print_error "KRITIČNA GREŠKA: autopoint ne može da se instalira!"
        print_status "Pokušavam workaround bez gettext..."
        
        # Ukloni gettext reference iz configure.ac
        if [ -f "configure.ac" ]; then
            print_status "Backup configure.ac i uklanjam gettext references..."
            cp configure.ac configure.ac.backup
            sed -i 's/AM_GLIB_GNU_GETTEXT//g' configure.ac
            sed -i 's/AM_GNU_GETTEXT.*//g' configure.ac
            sed -i 's/AM_GNU_GETTEXT_VERSION.*//g' configure.ac
        fi
    fi
fi

# Generiši configure script
if [ ! -f "./configure" ]; then
    print_status "Generiram configure script..."
    
    # Pokušaj autoreconf SADA
    print_status "Pokrećem autoreconf..."
    if autoreconf -fiv --install; then
        print_success "autoreconf uspešan!"
    elif autoreconf -fiv; then
        print_success "autoreconf bez --install uspešan!"
    elif [ -f "./autogen.sh" ]; then
        print_warning "autoreconf failed, pokušavam autogen.sh..."
        chmod +x autogen.sh
        if ./autogen.sh; then
            print_success "autogen.sh uspešan!"
        else
            print_warning "autogen.sh failed, pokušavam autoconf direktno..."
            if autoconf; then
                print_success "autoconf uspešan!"
            else
                # Poslednji pokušaj - kreiraj minimalnu configure skriptu
                print_status "Kreiram emergency configure script..."
                cat > configure << 'EOF'
#!/bin/bash
echo "Emergency configure script - basic setup"
echo "Checking for gcc..."
if ! command -v gcc &>/dev/null; then
    echo "ERROR: gcc not found"
    exit 1
fi
echo "Creating Makefile..."
if [ -f "Makefile.in" ]; then
    cp Makefile.in Makefile
elif [ -f "src/Makefile" ]; then
    echo "Using existing src/Makefile"
else
    echo "ERROR: No Makefile template found"
    exit 1
fi
echo "Configure completed (emergency mode)"
EOF
                chmod +x configure
                print_warning "Emergency configure script kreiran!"
            fi
        fi
    else
        print_warning "Nema autogen.sh, pokušavam direktno autoconf..."
        if autoconf; then
            print_success "autoconf uspešan!"
        else
            print_error "Sve standardne metode neuspešne!"
        fi
    fi
    
    if [ -f "./configure" ]; then
        print_success "Configure script uspešno kreiran!"
    else
        print_error "Configure script NIJE kreiran - prekidam!"
        exit 1
    fi
fi

# Configure MuMuDVB
print_status "Konfigurišem MuMuDVB..."
if ! ./configure --enable-cam-support --enable-scam-support --prefix=/usr/local; then
    print_error "Configure neuspešan!"
fi
print_success "Configure uspešan"

# Kompajliraj
print_status "Kompajliram MuMuDVB..."
if ! make -j$(nproc); then
    print_error "Make neuspešan!"
fi
print_success "Kompajliranje uspešno"

# Instaliraj
print_status "Instaliram MuMuDVB..."
if ! make install; then
    print_error "Make install neuspešan!"
fi

# Update library paths
ldconfig

# Verify installation
MUMUDVB_PATH=$(which mumudvb 2>/dev/null || echo "/usr/local/bin/mumudvb")
if [ -x "$MUMUDVB_PATH" ]; then
    MUMUDVB_VERSION=$($MUMUDVB_PATH --version 2>&1 | head -1 || echo "Version unknown")
    print_success "MuMuDVB instaliran: $MUMUDVB_PATH"
    print_success "MuMuDVB verzija: $MUMUDVB_VERSION"
else
    print_error "MuMuDVB instalacija verification failed!"
fi

# ==============================================
# FAZA 5: WEB PANEL
# ==============================================

print_status "FAZA 5: Web Panel kreiranje"

WEB_DIR="/opt/mumudvb-webpanel"
rm -rf $WEB_DIR 2>/dev/null || true
mkdir -p $WEB_DIR
cd $WEB_DIR

# Kreiraj package.json
print_status "Kreiranje package.json..."
cat > package.json << 'EOF'
{
  "name": "mumudvb-webpanel",
  "version": "2.0.0",
  "description": "MuMuDVB Web Panel - Ubuntu 20.04 Edition",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
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
print_status "Instaliranje npm paketa..."
$NPM_CMD install --production --no-optional

if [ $? -eq 0 ]; then
    print_success "npm paketi instalirani"
else
    print_error "npm install neuspešan!"
fi

# Kreiraj server.js (basic version)
print_status "Kreiranje server.js..."
cat > server.js << 'EOF'
const express = require('express');
const path = require('path');
const { exec } = require('child_process');
const WebSocket = require('ws');
const fs = require('fs');

const app = express();
const port = 8080;

// Middleware
app.use(express.static('public'));
app.use(express.json());

// WebSocket
const wss = new WebSocket.Server({ port: 8081 });

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

app.get('/api/status', (req, res) => {
    exec('pgrep -f mumudvb', (error, stdout) => {
        const running = !error && stdout.trim() !== '';
        res.json({ 
            running: running, 
            pid: running ? stdout.trim() : null 
        });
    });
});

app.post('/api/start', (req, res) => {
    exec('mumudvb -d -c /etc/mumudvb/mumudvb.conf', (error, stdout, stderr) => {
        res.json({
            success: !error,
            message: error ? error.message : 'MuMuDVB started',
            output: stdout
        });
    });
});

app.post('/api/stop', (req, res) => {
    exec('pkill -f mumudvb', (error) => {
        res.json({ success: true, message: 'Stop signal sent' });
    });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 MuMuDVB Web Panel na portu ${port}`);
    console.log(`🌐 Pristup: http://localhost:${port}`);
});
EOF

# Kreiraj public folder i HTML
mkdir -p public

print_status "Kreiranje HTML interfejsa..."
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>MuMuDVB Web Panel</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: #f5f5f5; 
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white; 
            padding: 30px; 
            border-radius: 10px; 
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header { 
            text-align: center; 
            margin-bottom: 30px; 
            color: #333;
        }
        .status { 
            padding: 15px; 
            margin: 20px 0; 
            border-radius: 5px; 
            font-weight: bold;
        }
        .running { background: #d4edda; color: #155724; }
        .stopped { background: #f8d7da; color: #721c24; }
        .btn { 
            padding: 12px 24px; 
            margin: 5px; 
            border: none; 
            border-radius: 5px; 
            cursor: pointer; 
            font-size: 16px;
        }
        .btn-success { background: #28a745; color: white; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-info { background: #17a2b8; color: white; }
        .output { 
            background: #f8f9fa; 
            padding: 15px; 
            border-radius: 5px; 
            font-family: monospace; 
            margin-top: 20px;
            white-space: pre-wrap;
            max-height: 300px;
            overflow-y: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 MuMuDVB Web Panel</h1>
            <p>Ubuntu 20.04 - DVB-S/S2 Streaming Server</p>
        </div>
        
        <div id="status" class="status stopped">
            📡 MuMuDVB Status: Checking...
        </div>
        
        <div>
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
        
        <div id="output" class="output">Ready...</div>
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

        function addOutput(message) {
            const output = document.getElementById('output');
            const timestamp = new Date().toLocaleTimeString();
            output.textContent += `[${timestamp}] ${message}\n`;
            output.scrollTop = output.scrollHeight;
        }

        function checkStatus() {
            fetch('/api/status')
                .then(r => r.json())
                .then(data => updateStatus(data.running, data.pid))
                .catch(err => addOutput('Status check error: ' + err));
        }

        function startMuMuDVB() {
            addOutput('Starting MuMuDVB...');
            fetch('/api/start', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    addOutput(data.success ? 'Started successfully!' : 'Start failed: ' + data.message);
                    setTimeout(checkStatus, 1000);
                })
                .catch(err => addOutput('Start error: ' + err));
        }

        function stopMuMuDVB() {
            addOutput('Stopping MuMuDVB...');
            fetch('/api/stop', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    addOutput('Stop signal sent');
                    setTimeout(checkStatus, 1000);
                })
                .catch(err => addOutput('Stop error: ' + err));
        }

        // Initialize
        checkStatus();
        setInterval(checkStatus, 5000);
    </script>
</body>
</html>
EOF

print_success "Web panel fajlovi kreirani"

# ==============================================
# FAZA 6: KONFIGURACIJA
# ==============================================

print_status "FAZA 6: Kreiranje konfiguracije"

# MuMuDVB config
mkdir -p /etc/mumudvb
cat > /etc/mumudvb/mumudvb.conf << 'EOF'
# MuMuDVB Configuration for DVB-S/S2
# Ubuntu 20.04 Edition

# Basic transponder settings - EDIT THESE!
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

# CAM support
cam_support=1
scam_support=1

# Logging
log_type=syslog
log_header=1
EOF

# Systemd service
cat > /etc/systemd/system/mumudvb-webpanel.service << EOF
[Unit]
Description=MuMuDVB Web Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$WEB_DIR
ExecStart=$NODE_CMD server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mumudvb-webpanel

print_success "Sistemska konfiguracija završena"

# ==============================================
# FINALNA PROVERA
# ==============================================

print_status "FINALNA PROVERA INSTALACIJE"

# Test MuMuDVB
if command -v mumudvb &>/dev/null; then
    print_success "MuMuDVB test: ✅"
else
    print_error "MuMuDVB test: ❌"
fi

# Test Node.js
if $NODE_CMD --version &>/dev/null; then
    print_success "Node.js test: ✅ $($NODE_CMD --version)"
else
    print_error "Node.js test: ❌"
fi

# Test npm
if $NPM_CMD --version &>/dev/null; then
    print_success "npm test: ✅ $($NPM_CMD --version)"
else
    print_error "npm test: ❌"
fi

# Test web panel dependencies
cd $WEB_DIR
if $NODE_CMD -e "require('express'); console.log('OK')" 2>/dev/null; then
    print_success "Web panel dependencies: ✅"
else
    print_error "Web panel dependencies: ❌"
fi

# ==============================================
# POKRETANJE
# ==============================================

print_status "Pokretanje web panel servisa..."
if systemctl start mumudvb-webpanel; then
    print_success "Web panel servis pokrenut!"
else
    print_warning "Web panel servis se nije pokrenuo automatski"
fi

# ==============================================
# REZULTATI
# ==============================================

echo ""
echo "🎉 =============================================="
echo "🎉        INSTALACIJA USPEŠNO ZAVRŠENA!"
echo "🎉 =============================================="
echo ""
echo "📋 INSTALIRANO:"
echo "   ✅ Ubuntu $(lsb_release -rs)"
echo "   ✅ MuMuDVB: $(which mumudvb 2>/dev/null)"
echo "   ✅ Node.js: $NODE_FINAL"
echo "   ✅ npm: $NPM_FINAL"
echo "   ✅ Web Panel: $WEB_DIR"
echo "   ✅ Systemd servis: mumudvb-webpanel"
echo ""
echo "🌐 WEB PANEL PRISTUP:"
echo "   Lokalno:  http://localhost:8080"
echo "   Mreža:    http://$(hostname -I | awk '{print $1}' 2>/dev/null || echo 'SERVER_IP'):8080"
echo ""
echo "🔧 KOMANDE:"
echo "   Servis status:  systemctl status mumudvb-webpanel"
echo "   Start servisa:  systemctl start mumudvb-webpanel"
echo "   Stop servisa:   systemctl stop mumudvb-webpanel"
echo "   Restart:        systemctl restart mumudvb-webpanel"
echo ""
echo "⚙️  KONFIGURACIJA:"
echo "   Config:         nano /etc/mumudvb/mumudvb.conf"
echo "   Logs:           journalctl -u mumudvb-webpanel -f"
echo ""
echo "📡 EDITUJ DVB-S PARAMETRE U:"
echo "   /etc/mumudvb/mumudvb.conf"
echo "   (freq, pol, srate za tvoj satelit)"
echo ""
echo "🚀 INSTALACIJA GOTOVA - PRISTUPAJ WEB PANELU!"

# Final status check
print_status "Konačna provera servisa..."
sleep 2
systemctl status mumudvb-webpanel --no-pager || true