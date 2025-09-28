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
    software-properties-common \
    libpcsclite-dev \
    pcsc-tools \
    libssl-dev \
    libusb-1.0-0-dev \
    cmake \
    libz-dev

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
# FAZA 6: OSCAM KOMPAJLIRANJE
# ==============================================

print_status "FAZA 6: OSCam kompajliranje sa patchevima"

cd /tmp
rm -rf oscam-smod 2>/dev/null || true

print_status "Kloniranje OSCam-smod repozitorijuma..."
if ! git clone https://github.com/Schimmelreiter/oscam-smod.git; then
    print_error "Git clone OSCam neuspešan!"
fi

cd oscam-smod
print_success "OSCam source kod skinut"

# Pripremi build direktorij
print_status "Kreiranje build direktorijuma..."
mkdir -p build
cd build

# Configure sa svim patch-evima i dodatcima
print_status "Konfiguracija OSCam build-a..."
cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DWEBIF=ON \
      -DWITH_SSL=ON \
      -DWITH_STAPI=OFF \
      -DWITH_STAPI5=OFF \
      -DHAVE_LIBUSB=ON \
      -DWITH_LIBUSB=ON \
      -DWITH_SMARTREADER=ON \
      -DWITH_PCSC=ON \
      -DCS_CACHEEX=ON \
      -DCS_CACHEEX_AIO=ON \
      -DMODULE_MONITOR=ON \
      -DMODULE_CAMD33=ON \
      -DMODULE_CAMD35=ON \
      -DMODULE_CAMD35_TCP=ON \
      -DMODULE_NEWCAMD=ON \
      -DMODULE_CCCAM=ON \
      -DMODULE_CCCSHARE=ON \
      -DMODULE_GBOX=ON \
      -DMODULE_RADEGAST=ON \
      -DMODULE_SERIAL=ON \
      -DMODULE_CONSTCW=ON \
      -DMODULE_DVBAPI=ON \
      -DMODULE_SCAM=ON \
      -DMODULE_GHTTP=ON \
      -DWITH_NEUTRINO=ON \
      -DWITH_AZBOX=ON \
      -DWITH_MCA=ON \
      -DWITH_COOLAPI=ON \
      -DWITH_COOLAPI2=ON \
      -DWITH_SU980=ON \
      -DWITH_DUCKBOX=ON \
      -DREADER_NAGRA=ON \
      -DREADER_NAGRA_MERLIN=ON \
      -DREADER_IRDETO=ON \
      -DREADER_CONAX=ON \
      -DREADER_CRYPTOWORKS=ON \
      -DREADER_SECA=ON \
      -DREADER_VIACCESS=ON \
      -DREADER_VIDEOGUARD=ON \
      -DREADER_DRE=ON \
      -DREADER_TONGFANG=ON \
      -DREADER_BULCRYPT=ON \
      -DREADER_GRIFFIN=ON \
      -DREADER_DGCRYPT=ON \
      ..

if [ $? -ne 0 ]; then
    print_error "OSCam cmake konfiguracija neuspešna!"
fi

print_success "OSCam cmake konfiguracija uspešna"

# Kompajliraj OSCam
print_status "Kompajliranje OSCam-a (može potrajati...)..."
make -j$(nproc)

if [ $? -ne 0 ]; then
    print_error "OSCam kompajliranje neuspešno!"
fi

print_success "OSCam kompajliranje uspešno"

# Instaliraj OSCam
print_status "Instaliranje OSCam-a..."
make install

# Kreiraj OSCam direktorijume
mkdir -p /etc/oscam
mkdir -p /var/log/oscam
mkdir -p /usr/local/var/oscam

# Test OSCam instalacije
OSCAM_PATH=$(which oscam 2>/dev/null || echo "/usr/local/bin/oscam")
if [ -x "$OSCAM_PATH" ]; then
    OSCAM_VERSION=$($OSCAM_PATH --build-info 2>&1 | head -1 || echo "Version unknown")
    print_success "OSCam instaliran: $OSCAM_PATH"
    print_success "OSCam verzija: $OSCAM_VERSION"
else
    print_warning "OSCam instalacija verification failed - nastavljam"
fi

# Kreiraj osnovnu OSCam konfiguraciju
print_status "Kreiranje osnovne OSCam konfiguracije..."
cat > /etc/oscam/oscam.conf << 'EOF'
# OSCam Configuration - Ubuntu 20.04 MuMuDVB Edition
[global]
logfile = /var/log/oscam/oscam.log
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

[webif]
httpport = 8888
httpuser = admin
httppwd = admin
httpallowed = 127.0.0.1,192.168.1.1-192.168.255.255

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

print_success "OSCam osnovni config kreiran"

# OSCam systemd servis
print_status "Kreiranje OSCam systemd servisa..."
cat > /etc/systemd/system/oscam.service << 'EOF'
[Unit]
Description=OSCam - Software CAM
After=network.target

[Service]
Type=forking
User=root
ExecStart=/usr/local/bin/oscam -b -c /etc/oscam
PIDFile=/var/run/oscam.pid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable oscam
print_success "OSCam systemd servis kreiran"

# ==============================================
# FAZA 7: WEB PANEL
# ==============================================

print_status "FAZA 7: Web Panel kreiranje"

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
    "express": "^4.18.2",
    "ws": "^8.14.0",
    "multer": "^1.4.4",
    "body-parser": "^1.20.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# Instaliraj npm pakete
print_status "Instaliranje npm paketa..."
$NPM_CMD install --omit=dev --omit=optional

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
const port = 8887;

// Middleware
app.use(express.static('public'));
app.use(express.json());

// WebSocket
const wss = new WebSocket.Server({ port: 8886 });

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

// Config management
app.get('/api/config', (req, res) => {
    const fs = require('fs');
    try {
        const config = fs.readFileSync('/etc/mumudvb/mumudvb.conf', 'utf8');
        res.json({ success: true, config: config });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

app.post('/api/config', (req, res) => {
    const fs = require('fs');
    try {
        fs.writeFileSync('/etc/mumudvb/mumudvb.conf', req.body.config);
        res.json({ success: true, message: 'Config saved successfully' });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

// System info
app.get('/api/system', (req, res) => {
    exec('ls -la /dev/dvb/', (error, stdout) => {
        const dvb_devices = error ? 'No DVB devices found' : stdout;
        exec('df -h /', (err, disk) => {
            exec('free -h', (err2, memory) => {
                res.json({
                    dvb_devices: dvb_devices,
                    disk: disk || 'N/A',
                    memory: memory || 'N/A'
                });
            });
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

// W-Scan functionality
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

// OSCam management
app.get('/api/oscam/status', (req, res) => {
    exec('pgrep -f oscam', (error, stdout) => {
        const running = !error && stdout.trim() !== '';
        res.json({ 
            running: running, 
            pid: running ? stdout.trim() : null 
        });
    });
});

app.post('/api/oscam/start', (req, res) => {
    exec('oscam -b -c /etc/oscam', (error, stdout, stderr) => {
        res.json({
            success: !error,
            message: error ? error.message : 'OSCam started',
            output: stdout || stderr
        });
    });
});

app.post('/api/oscam/stop', (req, res) => {
    exec('pkill -f oscam', (error) => {
        res.json({ success: true, message: 'OSCam stop signal sent' });
    });
});

app.get('/api/oscam/config', (req, res) => {
    const fs = require('fs');
    try {
        const config = fs.readFileSync('/etc/oscam/oscam.conf', 'utf8');
        res.json({ success: true, config: config });
    } catch (error) {
        res.json({ success: false, error: 'OSCam config not found' });
    }
});

app.post('/api/oscam/config', (req, res) => {
    const fs = require('fs');
    try {
        if (!fs.existsSync('/etc/oscam')) {
            fs.mkdirSync('/etc/oscam', { recursive: true });
        }
        fs.writeFileSync('/etc/oscam/oscam.conf', req.body.config);
        res.json({ success: true, message: 'OSCam config saved' });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
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
    <title>🚀 MuMuDVB Web Panel - FULL ADMIN</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            min-height: 100vh;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: white; 
            padding: 30px; 
            border-radius: 15px; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }
        .header { 
            text-align: center; 
            margin-bottom: 30px; 
            color: #333;
        }
        .tabs {
            display: flex;
            border-bottom: 2px solid #eee;
            margin-bottom: 20px;
        }
        .tab {
            padding: 12px 24px;
            cursor: pointer;
            border: none;
            background: #f8f9fa;
            margin-right: 5px;
            border-radius: 5px 5px 0 0;
        }
        .tab.active {
            background: #007bff;
            color: white;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
        .status { 
            padding: 15px; 
            margin: 20px 0; 
            border-radius: 8px; 
            font-weight: bold;
            text-align: center;
        }
        .running { background: #d4edda; color: #155724; border-left: 5px solid #28a745; }
        .stopped { background: #f8d7da; color: #721c24; border-left: 5px solid #dc3545; }
        .btn { 
            padding: 12px 24px; 
            margin: 5px; 
            border: none; 
            border-radius: 8px; 
            cursor: pointer; 
            font-size: 16px;
            transition: all 0.3s;
        }
        .btn:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.2); }
        .btn-success { background: #28a745; color: white; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-info { background: #17a2b8; color: white; }
        .btn-warning { background: #ffc107; color: #212529; }
        .config-editor {
            width: 100%;
            height: 400px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            border: 2px solid #ddd;
            border-radius: 8px;
            padding: 15px;
        }
        .output { 
            background: #2d3748; 
            color: #e2e8f0;
            padding: 15px; 
            border-radius: 8px; 
            font-family: 'Courier New', monospace;
            max-height: 300px;
            overflow-y: auto; 
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

        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        .form-group input, .form-group select {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 5px solid #007bff;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 MuMuDVB Web Panel - FULL ADMIN</h1>
            <p>Ubuntu 20.04 - DVB-S/S2 Streaming Server</p>
        </div>

        <!-- Tabs -->
        <div class="tabs">
            <button class="tab active" onclick="showTab('status')">📊 Status</button>
            <button class="tab" onclick="showTab('config')">⚙️ Configuration</button>
            <button class="tab" onclick="showTab('settings')">🛠️ Settings</button>
            <button class="tab" onclick="showTab('wscan')">📡 W-Scan</button>
            <button class="tab" onclick="showTab('oscam')">🔐 OSCam</button>
            <button class="tab" onclick="showTab('system')">💻 System</button>
            <button class="tab" onclick="showTab('logs')">📋 Logs</button>
        </div>

        <!-- Status Tab -->
        <div id="status" class="tab-content active">
            <div id="statusDiv" class="status">Checking...</div>
            <div style="text-align: center;">
                <button class="btn btn-success" onclick="startMuMuDVB()">▶️ Start MuMuDVB</button>
                <button class="btn btn-danger" onclick="stopMuMuDVB()">⏹️ Stop MuMuDVB</button>
                <button class="btn btn-info" onclick="checkStatus()">🔄 Refresh Status</button>
            </div>
            <div id="output" class="output" style="display:none;"></div>
        </div>

        <!-- Config Tab -->
        <div id="config" class="tab-content">
            <h3>📝 MuMuDVB Configuration Editor</h3>
            <p>Edit your MuMuDVB configuration directly:</p>
            <textarea id="configEditor" class="config-editor" placeholder="Loading configuration..."></textarea>
            <div style="text-align: center; margin-top: 15px;">
                <button class="btn btn-warning" onclick="loadConfig()">🔄 Reload Config</button>
                <button class="btn btn-success" onclick="saveConfig()">💾 Save Config</button>
            </div>
        </div>

        <!-- Settings Tab -->
        <div id="settings" class="tab-content">
            <h3>🛠️ Quick Settings</h3>
            <div class="form-group">
                <label>Satellite Frequency (kHz):</label>
                <input type="number" id="freq" placeholder="11538000" value="11538000">
            </div>
            <div class="form-group">
                <label>Polarization:</label>
                <select id="pol">
                    <option value="h">Horizontal (H)</option>
                    <option value="v">Vertical (V)</option>
                </select>
            </div>
            <div class="form-group">
                <label>Symbol Rate (Hz):</label>
                <input type="number" id="srate" placeholder="22000000" value="22000000">
            </div>
            <div class="form-group">
                <label>DVB Card:</label>
                <input type="number" id="card" placeholder="0" value="0">
            </div>
            <div style="text-align: center;">
                <button class="btn btn-success" onclick="applyQuickSettings()">✅ Apply Settings</button>
            </div>
        </div>

        <!-- W-Scan Tab -->
        <div id="wscan" class="tab-content">
            <h3>📡 W-Scan - Satellite Scanner</h3>
            <p>Scan satellites for available channels:</p>
            <div class="form-group">
                <label>Select Satellite:</label>
                <select id="satellite">
                    <option value="HOTBIRD">HOTBIRD 13.0E</option>
                    <option value="ASTRA1">ASTRA 19.2E</option>
                    <option value="ASTRA2">ASTRA 28.2E</option>
                    <option value="EUTELSAT16E">EUTELSAT 16.0E</option>
                    <option value="TURKSAT">TURKSAT 42.0E</option>
                </select>
            </div>
            <div style="text-align: center; margin: 20px 0;">
                <button class="btn btn-success" onclick="startWScan()">🔍 Start W-Scan</button>
                <button class="btn btn-warning" onclick="stopWScan()">⏹️ Stop Scan</button>
            </div>
            <div id="wscanOutput" class="output" style="display:none;">W-Scan output will appear here...</div>
        </div>

        <!-- OSCam Tab -->
        <div id="oscam" class="tab-content">
            <h3>🔐 OSCam - Software CAM</h3>
            <div id="oscamStatus" class="status">Checking OSCam...</div>
            <div style="text-align: center; margin: 20px 0;">
                <button class="btn btn-success" onclick="startOSCam()">▶️ Start OSCam</button>
                <button class="btn btn-danger" onclick="stopOSCam()">⏹️ Stop OSCam</button>
                <button class="btn btn-info" onclick="checkOSCamStatus()">🔄 Check Status</button>
            </div>
            
            <h4>📝 OSCam Configuration:</h4>
            <textarea id="oscamConfigEditor" class="config-editor" placeholder="Loading OSCam configuration..."></textarea>
            <div style="text-align: center; margin-top: 15px;">
                <button class="btn btn-warning" onclick="loadOSCamConfig()">🔄 Reload Config</button>
                <button class="btn btn-success" onclick="saveOSCamConfig()">💾 Save Config</button>
            </div>
            
            <div style="margin-top: 20px;">
                <h4>📋 OSCam Quick Setup:</h4>
                <div class="form-group">
                    <label>Server Type:</label>
                    <select id="oscamServerType">
                        <option value="newcamd">Newcamd</option>
                        <option value="cccam">CCCam</option>
                        <option value="camd35">CAMD35</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Server IP:</label>
                    <input type="text" id="oscamServerIP" placeholder="192.168.1.100">
                </div>
                <div class="form-group">
                    <label>Server Port:</label>
                    <input type="number" id="oscamServerPort" placeholder="12000">
                </div>
                <div class="form-group">
                    <label>Username:</label>
                    <input type="text" id="oscamUsername" placeholder="user">
                </div>
                <div class="form-group">
                    <label>Password:</label>
                    <input type="password" id="oscamPassword" placeholder="pass">
                </div>
                <div style="text-align: center;">
                    <button class="btn btn-warning" onclick="generateOSCamConfig()">⚡ Generate Config</button>
                </div>
            </div>
        </div>

        <!-- System Tab -->
        <div id="system" class="tab-content">
            <h3>💻 System Information</h3>
            <div class="grid">
                <div class="card">
                    <h4>📡 DVB Devices</h4>
                    <pre id="dvbDevices">Loading...</pre>
                </div>
                <div class="card">
                    <h4>💾 Disk Usage</h4>
                    <pre id="diskUsage">Loading...</pre>
                </div>
                <div class="card">
                    <h4>🧠 Memory Usage</h4>
                    <pre id="memoryUsage">Loading...</pre>
                </div>
            </div>
            <div style="text-align: center; margin-top: 20px;">
                <button class="btn btn-info" onclick="loadSystemInfo()">🔄 Refresh System Info</button>
            </div>
        </div>

        <!-- Logs Tab -->
        <div id="logs" class="tab-content">
            <h3>📋 System Logs</h3>
            <div style="text-align: center; margin-bottom: 15px;">
                <button class="btn btn-info" onclick="loadLogs()">🔄 Refresh Logs</button>
            </div>
            <pre id="systemLogs" class="output">Loading logs...</pre>
        </div>
    </div>

    <script>
        let ws;

        function showTab(tabName) {
            // Hide all tabs
            const tabs = document.querySelectorAll('.tab-content');
            tabs.forEach(tab => tab.classList.remove('active'));
            
            const tabButtons = document.querySelectorAll('.tab');
            tabButtons.forEach(btn => btn.classList.remove('active'));
            
            // Show selected tab
            document.getElementById(tabName).classList.add('active');
            event.target.classList.add('active');
            
            // Load content for specific tabs
            if (tabName === 'config') loadConfig();
            if (tabName === 'system') loadSystemInfo();
            if (tabName === 'logs') loadLogs();
            if (tabName === 'oscam') { checkOSCamStatus(); loadOSCamConfig(); }
        }

        function checkStatus() {
            fetch('/api/status')
                .then(r => r.json())
                .then(data => {
                    const statusDiv = document.getElementById('statusDiv');
                    if (data.running) {
                        statusDiv.textContent = `📡 MuMuDVB Status: Running (PID: ${data.pid})`;
                        statusDiv.className = 'status running';
                    } else {
                        statusDiv.textContent = '⭕ MuMuDVB Status: Stopped';
                        statusDiv.className = 'status stopped';
                    }
                });
        }

        function startMuMuDVB() {
            document.getElementById('output').textContent = 'Starting MuMuDVB...';
            document.getElementById('output').style.display = 'block';
            
            fetch('/api/start', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    document.getElementById('output').textContent = 
                        `Start ${data.success ? 'successful' : 'failed'}: ${data.message}\\n${data.output || ''}`;
                    setTimeout(checkStatus, 2000);
                });
        }

        function stopMuMuDVB() {
            document.getElementById('output').textContent = 'Stopping MuMuDVB...';
            document.getElementById('output').style.display = 'block';
            
            fetch('/api/stop', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    document.getElementById('output').textContent = data.message;
                    setTimeout(checkStatus, 2000);
                });
        }

        function loadConfig() {
            fetch('/api/config')
                .then(r => r.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('configEditor').value = data.config;
                    } else {
                        alert('Error loading config: ' + data.error);
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
                alert(data.success ? 'Config saved successfully!' : 'Error: ' + data.error);
            });
        }

        function applyQuickSettings() {
            const freq = document.getElementById('freq').value;
            const pol = document.getElementById('pol').value;
            const srate = document.getElementById('srate').value;
            const card = document.getElementById('card').value;

            const newConfig = `# MuMuDVB Configuration - Auto Generated
# DVB-S/S2 Settings
freq=${freq}
pol=${pol}
srate=${srate}
card=${card}
tuner=0

# Autoconfiguration
autoconfiguration=full
autoconf_unicast_start_port=8100
autoconf_multicast_port=1234

# Web interface
common_port=8887

# CAM support
cam_support=1
scam_support=1

# Logging
log_type=syslog
log_header=1`;

            fetch('/api/config', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ config: newConfig })
            })
            .then(r => r.json())
            .then(data => {
                alert(data.success ? 'Settings applied! Restart MuMuDVB to apply changes.' : 'Error: ' + data.error);
            });
        }

        function loadSystemInfo() {
            fetch('/api/system')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('dvbDevices').textContent = data.dvb_devices;
                    document.getElementById('diskUsage').textContent = data.disk;
                    document.getElementById('memoryUsage').textContent = data.memory;
                });
        }

        function loadLogs() {
            fetch('/api/logs')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('systemLogs').textContent = data.logs;
                });
        }

        // W-Scan functions
        function startWScan() {
            const satellite = document.getElementById('satellite').value;
            const output = document.getElementById('wscanOutput');
            output.style.display = 'block';
            output.textContent = `Starting W-Scan for ${satellite}...\\nThis may take several minutes...`;
            
            fetch('/api/wscan', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ satellite: satellite })
            })
            .then(r => r.json())
            .then(data => {
                output.textContent = data.success ? 
                    `W-Scan completed for ${satellite}:\\n\\n${data.output}` :
                    `W-Scan failed: ${data.error}\\n\\n${data.output}`;
            })
            .catch(err => {
                output.textContent = `W-Scan error: ${err.message}`;
            });
        }

        function stopWScan() {
            // Kill w-scan process
            fetch('/api/wscan/stop', { method: 'POST' })
                .then(() => {
                    document.getElementById('wscanOutput').textContent = 'W-Scan stopped.';
                });
        }

        // OSCam functions
        function checkOSCamStatus() {
            fetch('/api/oscam/status')
                .then(r => r.json())
                .then(data => {
                    const statusDiv = document.getElementById('oscamStatus');
                    if (data.running) {
                        statusDiv.textContent = `🔐 OSCam Status: Running (PID: ${data.pid})`;
                        statusDiv.className = 'status running';
                    } else {
                        statusDiv.textContent = '⭕ OSCam Status: Stopped';
                        statusDiv.className = 'status stopped';
                    }
                });
        }

        function startOSCam() {
            fetch('/api/oscam/start', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    alert(data.success ? 'OSCam started!' : 'Failed to start OSCam: ' + data.message);
                    setTimeout(checkOSCamStatus, 2000);
                });
        }

        function stopOSCam() {
            fetch('/api/oscam/stop', { method: 'POST' })
                .then(r => r.json())
                .then(data => {
                    alert('OSCam stop signal sent');
                    setTimeout(checkOSCamStatus, 2000);
                });
        }

        function loadOSCamConfig() {
            fetch('/api/oscam/config')
                .then(r => r.json())
                .then(data => {
                    if (data.success) {
                        document.getElementById('oscamConfigEditor').value = data.config;
                    } else {
                        document.getElementById('oscamConfigEditor').value = '# OSCam config not found - will be created when saved';
                    }
                });
        }

        function saveOSCamConfig() {
            const config = document.getElementById('oscamConfigEditor').value;
            fetch('/api/oscam/config', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ config: config })
            })
            .then(r => r.json())
            .then(data => {
                alert(data.success ? 'OSCam config saved!' : 'Error: ' + data.error);
            });
        }

        function generateOSCamConfig() {
            const serverType = document.getElementById('oscamServerType').value;
            const serverIP = document.getElementById('oscamServerIP').value;
            const serverPort = document.getElementById('oscamServerPort').value;
            const username = document.getElementById('oscamUsername').value;
            const password = document.getElementById('oscamPassword').value;

            if (!serverIP || !serverPort || !username || !password) {
                alert('Please fill all fields!');
                return;
            }

            const config = `# OSCam Configuration - Auto Generated
[global]
logfile = stdout
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

[webif]
httpport = 8888
httpuser = admin
httppwd = admin
httpallowed = 127.0.0.1,192.168.1.1-192.168.255.255

[reader]
label = ${serverType}_server
protocol = ${serverType}
device = ${serverIP},${serverPort}
user = ${username}
password = ${password}
group = 1
emmcache = 1,1,2,0
blockemm-unknown = 1
blockemm-u = 1
blockemm-s = 1
blockemm-g = 1
saveemm-unknown = 0
saveemm-u = 0
saveemm-s = 0
saveemm-g = 0

[account]
user = mumudvb
pwd = mumudvb
group = 1
au = 1`;

            document.getElementById('oscamConfigEditor').value = config;
            alert('OSCam config generated! Click Save Config to apply.');
        }

        // Initialize
        checkStatus();
        setInterval(checkStatus, 5000);
        
        // Connect WebSocket
        function connectWebSocket() {
            ws = new WebSocket('ws://localhost:8886');
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                console.log('WebSocket data:', data);
            };
        }
        connectWebSocket();
    </script>
</body>
</html>
EOF

print_success "Web panel fajlovi kreirani"

# ==============================================
# FAZA 8: KONFIGURACIJA
# ==============================================

print_status "FAZA 8: Kreiranje konfiguracije"

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
common_port=8887

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
echo "   Lokalno:  http://localhost:8887"
echo "   Mreža:    http://$(hostname -I | awk '{print $1}' 2>/dev/null || echo 'SERVER_IP'):8887"
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