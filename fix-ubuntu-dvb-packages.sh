#!/bin/bash

# Quick fix for DVB packages on Ubuntu 20.04
echo "🔧 DVB Packages Fix for Ubuntu 20.04"
echo "===================================="

# Function for colored output
print_status() { echo -e "🔄 \e[34m$1\e[0m"; }
print_success() { echo -e "✅ \e[32m$1\e[0m"; }
print_error() { echo -e "❌ \e[31m$1\e[0m"; }
print_warning() { echo -e "⚠️  \e[33m$1\e[0m"; }

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "20.04")
print_status "Detected Ubuntu $UBUNTU_VERSION"

if [[ "$UBUNTU_VERSION" == "20.04" ]]; then
    print_status "Installing Ubuntu 20.04 compatible DVB packages..."
    
    # Update package list
    sudo apt update
    
    # Install kernel headers
    print_status "Installing kernel headers..."
    sudo apt install -y linux-headers-$(uname -r) 2>/dev/null || print_warning "Headers may already be installed"
    
    # Check what's actually available
    print_status "Checking available DVB packages..."
    
    # Install what exists in Ubuntu 20.04
    PACKAGES_TO_INSTALL=""
    
    # Check each package individually
    for pkg in "dvb-tools" "w-scan" "libdvbv5-dev" "dvb-apps"; do
        if apt-cache show "$pkg" &>/dev/null; then
            PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $pkg"
            print_status "✓ $pkg is available"
        else
            print_warning "✗ $pkg not found in repositories"
        fi
    done
    
    # Install available packages
    if [ -n "$PACKAGES_TO_INSTALL" ]; then
        print_status "Installing: $PACKAGES_TO_INSTALL"
        if sudo apt install -y $PACKAGES_TO_INSTALL; then
            print_success "DVB packages installed successfully"
        else
            print_error "Some packages failed to install"
        fi
    else
        print_error "No DVB packages found in repositories"
    fi
    
    # Note about missing packages
    print_warning "Note: Ubuntu 20.04 doesn't have 'szap' and 'libdvbv5-tools' packages"
    print_status "These were replaced with different package names or removed"
    
else
    print_status "Installing DVB packages for Ubuntu $UBUNTU_VERSION..."
    sudo apt update
    sudo apt install -y dvb-apps dvb-tools w-scan libdvbv5-dev szap-utils libdvbv5-tools 2>/dev/null || true
fi

# Check what we actually have
print_status "Checking installed DVB tools..."

TOOLS_FOUND=0
if command -v w_scan &> /dev/null || command -v w-scan &> /dev/null; then
    print_success "w_scan: Available"
    TOOLS_FOUND=1
fi

if command -v dvb-fe-tool &> /dev/null; then
    print_success "dvb-fe-tool: Available"
    TOOLS_FOUND=1
fi

if command -v szap &> /dev/null; then
    print_success "szap: Available"
    TOOLS_FOUND=1
fi

if [ $TOOLS_FOUND -eq 1 ]; then
    print_success "DVB tools are ready!"
else
    print_warning "Limited DVB tools - MuMuDVB will work with basic functionality"
fi

echo ""
echo "🎯 DVB packages fix completed!"
echo "You can now continue with the installation."