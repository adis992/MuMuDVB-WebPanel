#!/bin/bash

# 🗑️ KOMPLETNO BRISANJE - CLEAN SLATE KOMANDE
# Koristi ovo pre nove instalacije

echo "🗑️ KOMPLETNO BRISANJE POSTOJEĆE INSTALACIJE..."
echo "=============================================="

# STOP SVIM SERVISIMA
echo "⏹️ Stopping servisi..."
systemctl stop mumudvb-webpanel 2>/dev/null || true
systemctl stop oscam 2>/dev/null || true
systemctl stop cccam 2>/dev/null || true
systemctl stop mumudvb 2>/dev/null || true

# DISABLE SERVISI
echo "🚫 Disabling servisi..."
systemctl disable mumudvb-webpanel 2>/dev/null || true
systemctl disable oscam 2>/dev/null || true
systemctl disable cccam 2>/dev/null || true

# KILL PROCESI
echo "💀 Killing procesi..."
pkill -f mumudvb 2>/dev/null || true
pkill -f oscam 2>/dev/null || true
pkill -f cccam 2>/dev/null || true
pkill -f "node.*mumudvb" 2>/dev/null || true

# UKLONI PORTOVE
echo "🔓 Freeing portovi..."
fuser -k 8887/tcp 2>/dev/null || true  # Web panel
fuser -k 8888/tcp 2>/dev/null || true  # OSCam
fuser -k 4242/tcp 2>/dev/null || true  # MuMuDVB HTTP
fuser -k 16001/tcp 2>/dev/null || true # CCcam web
fuser -k 12000/tcp 2>/dev/null || true # CCcam server

# UKLONI SYSTEMD FAJLOVE
echo "🗂️ Uklanjanje systemd fajlova..."
rm -f /etc/systemd/system/mumudvb-webpanel.service
rm -f /etc/systemd/system/oscam.service  
rm -f /etc/systemd/system/cccam.service
systemctl daemon-reload

# UKLONI DIREKTORIJUME
echo "📁 Uklanjanje direktorijuma..."
rm -rf /opt/mumudvb-webpanel
rm -rf /etc/mumudvb
rm -rf /var/etc/oscam
rm -rf /var/etc/cccam
rm -rf /var/log/oscam
rm -rf /var/log/mumudvb
rm -rf /usr/local/var/oscam

# UKLONI BINARE
echo "🗑️ Uklanjanje binary fajlova..."
rm -f /usr/local/bin/oscam
rm -f /usr/local/bin/cccam
rm -f /usr/local/bin/w-scan
rm -f /usr/bin/mumudvb

# UKLONI KONFIGURACIJE
echo "⚙️ Uklanjanje config fajlova..."
rm -f /etc/default/mumudvb
rm -f /etc/init.d/mumudvb
rm -f /etc/init.d/oscam

# CLEAN APT CACHE
echo "🧹 Cleaning apt cache..."
apt autoremove -y
apt autoclean

echo ""
echo "✅ KOMPLETNO BRISANJE ZAVRŠENO!"
echo "✅ Sada možeš da pokreneš čistu instalaciju"
echo ""