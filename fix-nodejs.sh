#!/bin/bash

# Quick Node.js fix for Ubuntu 20.04
# Run this if npm is not found

echo "🔧 Node.js & npm Fix for Ubuntu 20.04"
echo "====================================="

# Remove old nodejs
echo "📦 Removing old Node.js..."
sudo apt remove -y nodejs npm nodejs-doc 2>/dev/null || true
sudo apt autoremove -y

# Install Node.js 18.x from NodeSource
echo "📦 Installing Node.js 18.x LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    echo "✅ Node.js: $(node --version)"
    echo "✅ npm: $(npm --version)"
    echo ""
    echo "🎯 Node.js fix completed successfully!"
    echo "You can now continue with the web panel installation."
else
    echo "❌ Installation failed, trying alternative method..."
    
    # Try snap installation
    sudo snap install node --classic
    
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        echo "✅ Node.js: $(node --version) (via snap)"
        echo "✅ npm: $(npm --version)"
        echo ""
        echo "🎯 Node.js fix completed via snap!"
    else
        echo "❌ All methods failed. Please install Node.js manually:"
        echo "   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "   sudo apt install -y nodejs"
        exit 1
    fi
fi