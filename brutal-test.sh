#!/bin/bash

echo "🔍 BRUTALNA DIJAGNOZA WEB SERVERA"
echo "================================="

# 1. Test syntax
echo "1. SYNTAX CHECK:"
cd /opt/mumudvb-webpanel
node -c server.js && echo "✅ Syntax OK" || echo "❌ SYNTAX ERROR!"

# 2. Direct test
echo ""  
echo "2. DIRECT RUN TEST:"
timeout 3 node server.js &
sleep 1
curl -s http://localhost:8887 >/dev/null && echo "✅ Server responds" || echo "❌ Server dead"
pkill -f "node server.js" 2>/dev/null

# 3. Service logs
echo ""
echo "3. SERVICE LOGS:"
journalctl -u mumudvb-webpanel -n 10 --no-pager

# 4. Port check
echo ""
echo "4. PORT CHECK:"
netstat -tulpn | grep :8887 || echo "❌ Port 8887 NOT listening"

# 5. File check
echo ""
echo "5. FILES CHECK:"
ls -la /opt/mumudvb-webpanel/

# 6. Node version
echo ""
echo "6. NODE VERSION:"
node --version

# 7. Manual server start with full output
echo ""
echo "7. MANUAL START:"
cd /opt/mumudvb-webpanel
echo "Starting server manually..."
timeout 5 node server.js || echo "Server failed"