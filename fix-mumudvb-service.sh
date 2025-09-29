#!/bin/bash

# FIX MUMUDVB SERVICE - SPREČAVA INFINITE RESTART LOOP
# Rješava problem sa konstantnim restartovanjem MuMuDVB servisa

echo "🔧 FIXING MuMuDVB Service - Infinite Restart Fix"
echo "================================================="

# Stop postojeći servis
echo "🛑 Stopping MuMuDVB service..."
systemctl stop mumudvb 2>/dev/null || true
pkill -f mumudvb 2>/dev/null || true
sleep 2

# Kreiranje ispravnog systemd servisa
echo "🔧 Creating proper MuMuDVB systemd service..."
cat > /etc/systemd/system/mumudvb.service << 'EOF'
[Unit]
Description=MuMuDVB Multicast Streamer
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/mumudvb -c /etc/mumudvb/mumudvb.conf -d
Restart=on-failure
RestartSec=5
TimeoutStartSec=30
TimeoutStopSec=10
StandardOutput=journal
StandardError=journal

# Prevent rapid restart loops - KLJUČNO ZA FIX!
StartLimitInterval=60
StartLimitBurst=3

# DVB device access
SupplementaryGroups=audio video

[Install]
WantedBy=multi-user.target
EOF

# Popravka MuMuDVB konfiguracije
echo "🔧 Fixing MuMuDVB configuration..."
if [ -f "/etc/mumudvb/mumudvb.conf" ]; then
    # Backup originala
    cp /etc/mumudvb/mumudvb.conf /etc/mumudvb/mumudvb.conf.backup
    
    # Fix multicast parameter ako je pogrešan
    sed -i 's/multicast_ipv4=1/multicast=1/g' /etc/mumudvb/mumudvb.conf
    
    # Remove -v flag iz ExecStart (verbose može uzrokovati probleme)
    sed -i 's/mumudvb -c \/etc\/mumudvb\/mumudvb.conf -d -v/mumudvb -c \/etc\/mumudvb\/mumudvb.conf -d/g' /etc/systemd/system/mumudvb.service
    
    echo "✅ Configuration fixed"
else
    echo "❌ MuMuDVB config ne postoji - kreirati ga prvo!"
fi

# Reload systemd
echo "🔄 Reloading systemd..."
systemctl daemon-reload

# Enable servis
echo "🔧 Enabling MuMuDVB service..."
systemctl enable mumudvb

# Reset restart counter
echo "🔄 Resetting systemd failure count..."
systemctl reset-failed mumudvb 2>/dev/null || true

# Test config syntax
echo "🧪 Testing MuMuDVB config syntax..."
if mumudvb -c /etc/mumudvb/mumudvb.conf -t 2>/dev/null; then
    echo "✅ Config syntax OK"
else
    echo "❌ Config syntax ERROR - check /etc/mumudvb/mumudvb.conf"
    exit 1
fi

# Start servis
echo "🚀 Starting MuMuDVB service..."
systemctl start mumudvb

# Check status
sleep 3
if systemctl is-active mumudvb >/dev/null; then
    echo "✅ MuMuDVB service is running!"
    echo "📺 HTTP interface: http://localhost:4242"
    
    # Show status
    systemctl status mumudvb --no-pager -n 5
else
    echo "❌ MuMuDVB service failed to start"
    echo "🔍 Check logs: journalctl -u mumudvb -n 20"
    systemctl status mumudvb --no-pager -n 10
fi

echo ""
echo "🎯 RESTART LOOP FIX APPLIED!"
echo "📋 Key changes:"
echo "   - Restart=on-failure (umjesto always)"
echo "   - StartLimitInterval=60"  
echo "   - StartLimitBurst=3"
echo "   - Removed -v flag"
echo "   - Fixed multicast parameter"
echo ""
echo "💡 If still failing, check:"
echo "   - DVB adapter exists: ls /dev/dvb*"
echo "   - Config syntax: mumudvb -c /etc/mumudvb/mumudvb.conf -t"
echo "   - Logs: journalctl -u mumudvb -f"