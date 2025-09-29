#!/bin/bash

# Test script for MuMuDVB WebPanel Complete Solution
# Quickly checks if all components are working

echo "=== MuMuDVB WebPanel Complete Solution Test ==="
echo ""

# Check if services are running
echo "1. Checking Services Status:"
echo "   - MuMuDVB WebPanel:"
if systemctl is-active --quiet mumudvb-webpanel; then
    echo "     ✅ RUNNING"
else
    echo "     ❌ NOT RUNNING"
fi

echo "   - OSCam:"
if systemctl is-active --quiet oscam; then
    echo "     ✅ RUNNING"
else
    echo "     ❌ NOT RUNNING"
fi

echo ""

# Check if ports are listening
echo "2. Checking Port Status:"
echo "   - Web Panel (8887):"
if netstat -tuln | grep -q ":8887 "; then
    echo "     ✅ LISTENING"
else
    echo "     ❌ NOT LISTENING"
fi

echo "   - OSCam Web (8888):"
if netstat -tuln | grep -q ":8888 "; then
    echo "     ✅ LISTENING"
else
    echo "     ❌ NOT LISTENING"
fi

echo "   - MuMuDVB HTTP (4242):"
if netstat -tuln | grep -q ":4242 "; then
    echo "     ✅ LISTENING"
else
    echo "     ❌ NOT LISTENING (OK if not streaming)"
fi

echo ""

# Check if binaries exist
echo "3. Checking Installed Binaries:"
echo "   - MuMuDVB:"
if command -v mumudvb &> /dev/null; then
    echo "     ✅ INSTALLED"
else
    echo "     ❌ NOT FOUND"
fi

echo "   - OSCam:"
if [ -f "/usr/local/bin/oscam" ]; then
    echo "     ✅ INSTALLED"
else
    echo "     ❌ NOT FOUND"
fi

echo "   - W-Scan:"
if command -v w-scan &> /dev/null || [ -f "/usr/local/bin/w-scan" ]; then
    echo "     ✅ INSTALLED"
else
    echo "     ❌ NOT FOUND"
fi

echo ""

# Check config files
echo "4. Checking Configuration Files:"
echo "   - MuMuDVB Config:"
if [ -f "/etc/mumudvb/mumudvb.conf" ]; then
    echo "     ✅ EXISTS"
else
    echo "     ❌ NOT FOUND"
fi

echo "   - OSCam Config:"
if [ -d "/var/etc/oscam" ]; then
    echo "     ✅ EXISTS"
else
    echo "     ❌ NOT FOUND"
fi

echo "   - Web Panel:"
if [ -d "/opt/mumudvb-webpanel" ]; then
    echo "     ✅ EXISTS"
else
    echo "     ❌ NOT FOUND"
fi

echo ""

# Check DVB adapters
echo "5. Checking DVB Hardware:"
if ls /dev/dvb* &> /dev/null; then
    echo "   - DVB Adapters:"
    ls /dev/dvb*/adapter* 2>/dev/null | sed 's/^/     ✅ /'
else
    echo "     ❌ NO DVB ADAPTERS FOUND"
fi

echo ""

# Show access URLs
echo "6. Access URLs:"
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "   - Master Panel: http://$LOCAL_IP:8887"
echo "   - OSCam Web: http://$LOCAL_IP:8888"
echo "   - MuMuDVB HTTP: http://$LOCAL_IP:4242"

echo ""
echo "=== Test Complete ==="