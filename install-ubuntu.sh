#!/bin/bash

# MuMuDVB Web Panel - Ubuntu Server 20.04 Installation Script
# Author: GitHub Copilot
# Date: September 2025

set -e

echo "======================================================"
echo "    MuMuDVB Web Panel - Ubuntu Server 20.04 Setup   "
echo "======================================================"
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

print_status "Starting MuMuDVB Web Panel installation..."

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
print_status "Installing essential packages..."
sudo apt install -y \
    build-essential \
    git \
    wget \
    curl \
    vim \
    htop \
    unzip \
    bc \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install DVB development packages
print_status "Installing DVB development packages..."
sudo apt install -y \
    linux-headers-$(uname -r) \
    dvb-apps \
    dvb-tools \
    w-scan \
    libdvbv5-dev

# Install additional DVB tools based on Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
print_status "Detected Ubuntu $UBUNTU_VERSION"

if [[ $(echo "$UBUNTU_VERSION >= 22.04" | bc -l) -eq 1 ]]; then
    print_status "Installing DVB tools for Ubuntu 22.04+..."
    sudo apt install -y szap-utils libdvbv5-tools || print_warning "Some DVB tools not available"
else
    print_status "Installing DVB tools for Ubuntu 20.04..."
    # For Ubuntu 20.04, use alternative packages
    sudo apt install -y dvb-apps || print_warning "dvb-apps installation failed"
    # szap is part of dvb-apps in Ubuntu 20.04
fi

# Install w_scan from source if not available in repos
if ! command -v w_scan &> /dev/null; then
    print_status "w_scan not found, installing from source..."
    cd /tmp
    wget -q http://wirbel.htpc-forum.de/w_scan/w_scan-20170107.tar.bz2 || print_warning "Could not download w_scan source"
    if [ -f w_scan-20170107.tar.bz2 ]; then
        tar -xjf w_scan-20170107.tar.bz2
        cd w_scan-20170107
        make && sudo make install
        cd ..
        rm -rf w_scan-20170107*
        print_success "w_scan installed from source"
    fi
fi

# Install Node.js 18.x LTS
print_status "Installing Node.js 18.x LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify Node.js installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js installed: $NODE_VERSION"
print_success "npm installed: $NPM_VERSION"

# Install MuMuDVB dependencies
print_status "Installing MuMuDVB compilation dependencies..."
sudo apt install -y \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libdvbcsa-dev \
    gettext

# Clone MuMuDVB repository if not already present
if [ ! -d "MuMuDVB" ]; then
    print_status "Cloning MuMuDVB repository..."
    git clone https://github.com/braice/MuMuDVB.git
    cd MuMuDVB
else
    print_status "MuMuDVB directory already exists, updating..."
    cd MuMuDVB
    git pull origin mumudvb2
fi

# Configure and compile MuMuDVB
print_status "Configuring MuMuDVB..."
autoreconf -i -f
./configure --enable-cam-support --enable-scam-support

print_status "Compiling MuMuDVB..."
make -j$(nproc)

print_status "Installing MuMuDVB..."
sudo make install
sudo ldconfig

# Create MuMuDVB directories
print_status "Creating MuMuDVB directories..."
sudo mkdir -p /etc/mumudvb
sudo mkdir -p /var/log/mumudvb
sudo mkdir -p /var/run/mumudvb

# Set permissions
sudo chown $(whoami):$(whoami) /var/log/mumudvb
sudo chown $(whoami):$(whoami) /var/run/mumudvb

cd ..

# Install web panel dependencies
print_status "Installing web panel dependencies..."
cd web_panel
npm install

# Create systemd service for web panel
print_status "Creating systemd service for web panel..."
sudo tee /etc/systemd/system/mumudvb-web-panel.service > /dev/null << EOF
[Unit]
Description=MuMuDVB Web Panel
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=8080

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mumudvb-web-panel

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable mumudvb-web-panel

# Create MuMuDVB systemd service template
print_status "Creating MuMuDVB systemd service template..."
sudo tee /etc/systemd/system/mumudvb@.service > /dev/null << EOF
[Unit]
Description=MuMuDVB DVB Streaming Server (Adapter %i)
After=network.target

[Service]
Type=forking
User=$(whoami)
WorkingDirectory=/etc/mumudvb
ExecStart=/usr/local/bin/mumudvb -d -c /etc/mumudvb/mumudvb-%i.conf
PIDFile=/var/run/mumudvb/mumudvb-%i.pid
Restart=always
RestartSec=10

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mumudvb-%i

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

# Configure firewall if ufw is active
if sudo ufw status | grep -q "Status: active"; then
    print_status "Configuring firewall..."
    sudo ufw allow 8080/tcp comment "MuMuDVB Web Panel"
    sudo ufw allow 1234:1244/udp comment "MuMuDVB Multicast"
    sudo ufw allow 4242/tcp comment "MuMuDVB HTTP"
    print_success "Firewall rules added"
fi

# Check DVB devices
print_status "Checking DVB devices..."
if ls /dev/dvb* > /dev/null 2>&1; then
    print_success "DVB devices found:"
    ls -la /dev/dvb*/
else
    print_warning "No DVB devices found. Please ensure your DVB-S card is properly installed."
    print_warning "You may need to install specific drivers for your DVB-S card."
fi

# Create sample configuration
print_status "Creating sample configuration..."
sudo tee /etc/mumudvb/mumudvb-0.conf > /dev/null << EOF
# MuMuDVB Sample Configuration for DVB-S
# Generated by installation script

# Basic settings
card=0
freq=11996
pol=h
srate=27500

# Autoconfiguration
autoconfiguration=full

# Network settings
multicast_ttl=2
unicast=1
port_http=4242

# SAP announces
sap=1

# Logging
log_type=1
log_file=/var/log/mumudvb/mumudvb-0.log

# PID file
pid_file=/var/run/mumudvb/mumudvb-0.pid

# Stream rewriting
rewrite_pat=1
rewrite_sdt=1
sort_eit=1
EOF

print_success "Sample configuration created at /etc/mumudvb/mumudvb-0.conf"

# Start web panel service
print_status "Starting MuMuDVB Web Panel service..."
sudo systemctl start mumudvb-web-panel

# Check service status
if sudo systemctl is-active --quiet mumudvb-web-panel; then
    print_success "MuMuDVB Web Panel service started successfully"
else
    print_error "Failed to start MuMuDVB Web Panel service"
    print_status "Checking service status..."
    sudo systemctl status mumudvb-web-panel --no-pager
fi

echo
echo "======================================================"
echo "           INSTALLATION COMPLETED!"
echo "======================================================"
echo
print_success "MuMuDVB Web Panel is now installed and running!"
echo
echo "Access the web panel at: http://$(hostname -I | awk '{print $1}'):8080"
echo "or: http://localhost:8080"
echo
echo "Useful commands:"
echo "  sudo systemctl status mumudvb-web-panel    # Check web panel status"
echo "  sudo systemctl restart mumudvb-web-panel   # Restart web panel"
echo "  sudo systemctl start mumudvb@0             # Start MuMuDVB on adapter 0"
echo "  sudo systemctl status mumudvb@0            # Check MuMuDVB status"
echo "  tail -f /var/log/mumudvb/mumudvb-0.log     # View MuMuDVB logs"
echo "  w_scan -f s -s S19E2 -a 0 -x               # Scan Astra satellites"
echo
echo "Configuration files:"
echo "  /etc/mumudvb/mumudvb-0.conf                # MuMuDVB configuration"
echo "  /var/log/mumudvb/                          # Log directory"
echo
echo "DVB devices:"
ls /dev/dvb* 2>/dev/null || echo "  No DVB devices found - install drivers first"
echo
print_warning "Don't forget to configure your satellite parameters in the web panel!"
echo