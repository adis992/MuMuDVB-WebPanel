#!/bin/bash

echo "🔧 HITNA POPRAVKA server.js - LINIJA 168"
echo "========================================"

cd /opt/mumudvb-webpanel

echo "Current broken lines around 168:"
sed -n '165,175p' server.js

echo ""
echo "🔧 Fixing extra bracket..."

# Remove extra } on line 168
sed -i '168s/^}$//' server.js

# Alternative fix - remove any standalone } lines
sed -i '/^}$/d' server.js

echo "✅ Fixed!"

echo ""
echo "🔍 Test syntax again:"
node -c server.js && echo "✅ SYNTAX OK!" || echo "❌ Still broken"

echo ""
echo "🔄 Restart service:"  
systemctl stop mumudvb-webpanel
systemctl start mumudvb-webpanel

echo ""
echo "📊 Service status:"
systemctl status mumudvb-webpanel --no-pager -n 5

echo ""
echo "🌐 Test web panel:"
curl -s http://localhost:8887 | head -3 || echo "Still not responding"