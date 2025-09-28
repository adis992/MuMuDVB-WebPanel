#!/bin/bash

# Quick fix for Ubuntu 20.04 DVB packages
# Run this if the main installer fails on DVB packages

echo "🔧 Ubuntu 20.04 DVB Package Fix"
echo "================================="

# Install basic DVB support
sudo apt update
sudo apt install -y dvb-apps dvb-tools

# Check if w_scan is available
if ! command -v w_scan &> /dev/null; then
    echo "📡 Installing w_scan from source..."
    cd /tmp
    wget -q http://wirbel.htpc-forum.de/w_scan/w_scan-20170107.tar.bz2
    if [ -f w_scan-20170107.tar.bz2 ]; then
        tar -xjf w_scan-20170107.tar.bz2
        cd w_scan-20170107
        make && sudo make install
        cd ..
        rm -rf w_scan-20170107*
        echo "✅ w_scan installed successfully"
    else
        echo "❌ Could not download w_scan, trying alternative..."
        # Try installing from Ubuntu repos with different name
        sudo apt install -y w-scan || echo "⚠️  w_scan not available"
    fi
fi

# Verify DVB tools
echo ""
echo "🔍 Verifying DVB tools installation:"
echo "dvb-apps: $(dpkg -l | grep dvb-apps | wc -l) packages"
echo "w_scan: $(command -v w_scan &> /dev/null && echo "✅ Available" || echo "❌ Not found")"

# Check DVB devices
echo ""
echo "📡 DVB devices:"
ls /dev/dvb* 2>/dev/null || echo "No DVB devices found - install drivers first"

echo ""
echo "🎯 DVB tools setup complete!"
echo "You can now continue with the main installation."