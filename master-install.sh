#!/bin/bash

# ==============================================
# MASTER MUMUDVB INSTALLER - OD NULE DO KRAJA!
# GIT CLONE + KOMPLETNA INSTALACIJA
# ==============================================

set -e

echo "🔥 MASTER MUMUDVB INSTALLER - KOMPLETNA INSTALACIJA OD NULE!"
echo "=============================================================="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Ubuntu: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
echo ""

# Funkcije
print_status() { echo -e "\n🔄 \e[34m$1\e[0m"; }
print_success() { echo -e "✅ \e[32m$1\e[0m"; }
print_error() { echo -e "❌ \e[31m$1\e[0m"; exit 1; }
print_warning() { echo -e "⚠️  \e[33m$1\e[0m"; }

# ==============================================
# KORAK 1: KOMPLETNA CLEANUP
# ==============================================

print_status "🔥 KORAK 1: KOMPLETNA CLEANUP - BRISANJE SVEGA!"

# Zaustavi sve servise
systemctl stop mumudvb-webpanel 2>/dev/null || true
systemctl stop oscam 2>/dev/null || true
systemctl stop mumudvb 2>/dev/null || true
systemctl disable mumudvb-webpanel 2>/dev/null || true
systemctl disable oscam 2>/dev/null || true
systemctl disable mumudvb 2>/dev/null || true

# Ubij sve procese
pkill -9 -f mumudvb 2>/dev/null || true
pkill -9 -f oscam 2>/dev/null || true
pkill -9 -f "node.*server.js" 2>/dev/null || true
pkill -9 -f "node.*8887" 2>/dev/null || true
pkill -9 -f npm 2>/dev/null || true

# Očisti portove
fuser -k 8887/tcp 2>/dev/null || true
fuser -k 8886/tcp 2>/dev/null || true  
fuser -k 8888/tcp 2>/dev/null || true

# Obriši systemd servise
rm -f /etc/systemd/system/mumudvb-webpanel.service
rm -f /etc/systemd/system/oscam.service
rm -f /etc/systemd/system/mumudvb.service
systemctl daemon-reload

# Obriši direktorijume
rm -rf /opt/mumudvb-webpanel
rm -rf /etc/mumudvb
rm -rf /etc/oscam
rm -rf /var/log/oscam
rm -rf /usr/local/var/oscam
rm -rf /tmp/MuMuDVB
rm -rf /tmp/oscam*

# Obriši binaries
rm -f /usr/local/bin/mumudvb
rm -f /usr/local/bin/oscam
rm -f /usr/bin/oscam

# Obriši PID fajlove
rm -f /var/run/mumudvb.pid
rm -f /var/run/oscam.pid
rm -f /tmp/*.pid

print_success "🔥 KOMPLETNA CLEANUP ZAVRŠENA!"

# ==============================================
# KORAK 2: GIT CLONE REPO
# ==============================================

print_status "🔄 KORAK 2: Git clone repozitorijuma..."

cd /tmp
rm -rf MuMuDVB-WebPanel 2>/dev/null || true

if ! git clone https://github.com/adis992/MuMuDVB-WebPanel.git; then
    print_error "Git clone neuspešan!"
fi

cd MuMuDVB-WebPanel
print_success "✅ Git repo kloniran u /tmp/MuMuDVB-WebPanel"

# ==============================================
# KORAK 3: POKRENI INSTALL.SH
# ==============================================

print_status "🔄 KORAK 3: Pokretanje install.sh..."

if [ ! -f "install.sh" ]; then
    print_error "install.sh fajl ne postoji u repozitorijumu!"
fi

chmod +x install.sh

print_status "🚀 POKRETANJE KOMPLETNE INSTALACIJE..."
print_warning "⏳ Ovo može potrajati 10-15 minuta..."
echo ""

# Pokreni instalaciju
if ! ./install.sh; then
    print_error "Instalacija neuspešna!"
fi

print_success "🎉 MASTER INSTALACIJA USPEŠNO ZAVRŠENA!"

# ==============================================
# FINALNI IZVEŠTAJ
# ==============================================

print_status "📋 FINALNI IZVEŠTAJ:"
print_success "✅ Git repo: https://github.com/adis992/MuMuDVB-WebPanel.git"
print_success "✅ Lokacija: /tmp/MuMuDVB-WebPanel"
print_success "✅ MuMuDVB: $(which mumudvb 2>/dev/null || echo 'Not found')"
print_success "✅ OSCam: $(which oscam 2>/dev/null || echo 'Not found')"
print_success "✅ Web Panel: http://$(hostname -I | awk '{print $1}'):8887"

echo ""
print_status "🌐 PRISTUP WEB PANELU:"
print_success "   http://localhost:8887"
print_success "   http://$(hostname -I | awk '{print $1}'):8887"

echo ""
print_status "🔧 SERVISI:"
print_success "   systemctl status mumudvb-webpanel"
print_success "   systemctl status oscam"

echo ""
print_success "🚀 INSTALACIJA KOMPLETNA - PRISTUPAJ WEB PANELU!"