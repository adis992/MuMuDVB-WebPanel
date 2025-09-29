#!/bin/bash

echo "🚀 HITNO REŠAVANJE W-SCAN I MUMUDVB PROBLEMA"
echo "============================================="

# 1. INSTALL W-SCAN
echo "📡 Instalacija w-scan..."
apt update
apt install -y w-scan || {
    echo "Probam alternative repo..."
    add-apt-repository universe
    apt update  
    apt install -y w-scan
}

# Provjeri w-scan
which w-scan && echo "✅ w-scan instaliran" || echo "❌ w-scan failed"

# 2. CHECK MUMUDVB BINARY
echo ""
echo "📺 Provjera MuMuDVB binary..."
which mumudvb && echo "✅ MuMuDVB found" || {
    echo "❌ MuMuDVB not in PATH, checking build..."
    find /home -name "mumudvb" -type f -executable 2>/dev/null | head -5
    find /opt -name "mumudvb" -type f -executable 2>/dev/null | head -5
    find /usr -name "mumudvb" -type f -executable 2>/dev/null | head -5
}

# 3. CHECK DVB ADAPTER
echo ""
echo "📡 Provjera DVB adapter..."
ls -la /dev/dvb* 2>/dev/null || echo "❌ Nema DVB adaptera!"

# 4. TEST MUMUDVB CONFIG
echo ""
echo "⚙️ Test MuMuDVB config..."
mumudvb -t -c /etc/mumudvb/mumudvb.conf 2>/dev/null && echo "✅ Config OK" || echo "❌ Config problem"

# 5. RESTART WEB PANEL
echo ""
echo "🔄 Restart web panel..."
systemctl restart mumudvb-webpanel

echo ""
echo "📊 Final status:"
echo "w-scan: $(which w-scan || echo 'NOT FOUND')"
echo "mumudvb: $(which mumudvb || echo 'NOT FOUND')"
echo "DVB adapters: $(ls /dev/dvb* 2>/dev/null | wc -l) found"
echo "Web panel: $(systemctl is-active mumudvb-webpanel)"