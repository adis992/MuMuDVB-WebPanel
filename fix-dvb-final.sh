#!/bin/bash

# DEFINITIVNI FIX za Ubuntu 20.04 DVB pakete
echo "🔧 KONAČNI DVB FIX za Ubuntu 20.04"
echo "=================================="

# Debug info
echo "🔍 Sistem info:"
echo "   $(lsb_release -a 2>/dev/null | head -4)"
echo "   Kernel: $(uname -r)"
echo ""

# Funkcije za output
print_status() { echo -e "🔄 \e[34m$1\e[0m"; }
print_success() { echo -e "✅ \e[32m$1\e[0m"; }
print_error() { echo -e "❌ \e[31m$1\e[0m"; }

print_status "Ažuriranje package liste..."
sudo apt update

print_status "Instaliranje osnovnih paketa..."
sudo apt install -y \
    build-essential \
    linux-headers-$(uname -r) \
    ca-certificates \
    curl \
    wget \
    git

print_status "Instaliranje SAMO paketa koji postoje u Ubuntu 20.04..."

# Lista paketa koji STVARNO postoje u Ubuntu 20.04
UBUNTU_20_PACKAGES=(
    "dvb-tools"
    "w-scan" 
    "libdvbv5-dev"
    "dvb-apps"
)

INSTALLED_COUNT=0

for package in "${UBUNTU_20_PACKAGES[@]}"; do
    print_status "Proveravam paket: $package"
    
    if apt-cache show "$package" &>/dev/null; then
        print_status "📦 Instaliram $package..."
        if sudo apt install -y "$package"; then
            print_success "$package ✅"
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        else
            print_error "$package ❌"
        fi
    else
        print_error "$package ne postoji u repozitorijumima"
    fi
done

print_status "Proveravam dostupne DVB alate..."

# Proveri šta imamo
if command -v w_scan &> /dev/null; then
    print_success "w_scan je dostupan"
elif command -v w-scan &> /dev/null; then
    print_success "w-scan je dostupan"  
else
    print_error "Nema channel scanner-a"
fi

if command -v dvb-fe-tool &> /dev/null; then
    print_success "dvb-fe-tool je dostupan"
else
    print_error "Nema dvb-fe-tool"
fi

echo ""
echo "📊 REZIME:"
echo "   Instalirano paketa: $INSTALLED_COUNT od ${#UBUNTU_20_PACKAGES[@]}"

if [ $INSTALLED_COUNT -gt 0 ]; then
    print_success "DVB paketi su instalirani!"
    echo ""
    echo "🎯 MOŽEŠ SADA DA NASTAVIŠ SA:"
    echo "   cd /tmp"  
    echo "   git clone https://github.com/braice/MuMuDVB.git"
    echo "   cd MuMuDVB"
    echo "   ./configure --enable-cam-support --enable-scam-support"
    echo "   make && sudo make install"
else
    print_error "Nijedan DVB paket nije instaliran!"
fi

echo ""
echo "⚠️  NAPOMENA: Ubuntu 20.04 NEMA:"
echo "   ❌ szap paket" 
echo "   ❌ libdvbv5-tools paket"
echo "   ℹ️  Ovi paketi su uklonjeni ili preimenovani"

echo ""
echo "🚀 DVB fix završen!"