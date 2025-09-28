#!/bin/bash

# Complete Node.js fix for Ubuntu 20.04 - Resolves snap/apt conflicts
echo "🔧 Complete Node.js Fix for Ubuntu 20.04"
echo "========================================"

# Function for colored output
print_status() { echo -e "🔄 \e[34m$1\e[0m"; }
print_success() { echo -e "✅ \e[32m$1\e[0m"; }
print_error() { echo -e "❌ \e[31m$1\e[0m"; }

print_status "Starting complete Node.js cleanup..."

# Kill any running node processes
sudo pkill -f node 2>/dev/null || true
sudo pkill -f npm 2>/dev/null || true

# Remove ALL Node.js installations (apt + snap)
print_status "Removing all existing Node.js installations..."
sudo apt remove -y nodejs npm nodejs-doc libnode-dev node-gyp 2>/dev/null || true
sudo snap remove node 2>/dev/null || true
sudo apt autoremove -y

# Clean filesystem completely
print_status "Cleaning Node.js files from system..."
sudo rm -rf /usr/local/bin/node /usr/local/bin/npm 2>/dev/null || true
sudo rm -rf /usr/local/lib/node_modules 2>/dev/null || true
sudo rm -rf ~/.npm ~/.node-gyp 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true

# Update package database
sudo apt update

print_status "Installing fresh Node.js 18.x LTS..."

# Add NodeSource repository
if curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -; then
    print_success "NodeSource repository configured"
else
    print_error "Failed to configure NodeSource repository"
    exit 1
fi

# Install Node.js
if sudo apt install -y nodejs; then
    print_success "Node.js package installed"
else
    print_error "Package installation failed"
    exit 1
fi

# Wait for installation to settle
sleep 3

# Test installation
print_status "Testing Node.js installation..."

# Check if commands are available
NODE_CMD=""
NPM_CMD=""

# Find working node command
if command -v node &> /dev/null; then
    NODE_CMD="node"
elif command -v /usr/bin/node &> /dev/null; then
    NODE_CMD="/usr/bin/node"
    sudo ln -sf /usr/bin/node /usr/local/bin/node 2>/dev/null || true
fi

# Find working npm command  
if command -v npm &> /dev/null; then
    NPM_CMD="npm"
elif command -v /usr/bin/npm &> /dev/null; then
    NPM_CMD="/usr/bin/npm"
    sudo ln -sf /usr/bin/npm /usr/local/bin/npm 2>/dev/null || true
fi

# Verify both commands work
if [ -n "$NODE_CMD" ] && [ -n "$NPM_CMD" ]; then
    NODE_VERSION=$($NODE_CMD --version 2>/dev/null)
    NPM_VERSION=$($NPM_CMD --version 2>/dev/null)
    
    if [ -n "$NODE_VERSION" ] && [ -n "$NPM_VERSION" ]; then
        print_success "Node.js: $NODE_VERSION"
        print_success "npm: $NPM_VERSION"
        
        # Test npm functionality
        if $NPM_CMD --version &> /dev/null; then
            print_success "npm is working correctly!"
        else
            print_status "Updating npm to latest version..."
            sudo $NPM_CMD install -g npm@latest
        fi
        
        echo ""
        echo "🎯 Node.js installation completed successfully!"
        echo "📋 Summary:"
        echo "   Node.js: $NODE_VERSION"
        echo "   npm: $NPM_VERSION"
        echo ""
        echo "🚀 You can now continue with MuMuDVB web panel installation"
        
    else
        print_error "Commands found but not working properly"
        exit 1
    fi
else
    print_error "Node.js installation failed completely"
    print_status "Trying alternative binary installation..."
    
    # Download Node.js binaries directly
    cd /tmp
    wget https://nodejs.org/dist/v18.18.0/node-v18.18.0-linux-x64.tar.xz
    tar -xf node-v18.18.0-linux-x64.tar.xz
    sudo cp -r node-v18.18.0-linux-x64/{bin,include,lib,share} /usr/local/
    rm -rf node-v18.18.0*
    
    # Test binary installation
    if /usr/local/bin/node --version &> /dev/null && /usr/local/bin/npm --version &> /dev/null; then
        NODE_VERSION=$(/usr/local/bin/node --version)
        NPM_VERSION=$(/usr/local/bin/npm --version)
        print_success "Node.js: $NODE_VERSION (binary install)"
        print_success "npm: $NPM_VERSION (binary install)"
        echo ""
        echo "🎯 Node.js binary installation successful!"
    else
        print_error "All installation methods failed!"
        echo ""
        echo "Manual installation steps:"
        echo "1. curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "2. sudo apt install -y nodejs"
        echo "3. Test with: node --version && npm --version"
        exit 1
    fi
fi