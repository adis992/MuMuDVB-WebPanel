#!/bin/bash

echo "🔥 BRUTAL FIX server.js - CLEAN ALL EXTRA BRACKETS"
echo "================================================="

cd /opt/mumudvb-webpanel

# Backup
cp server.js server.js.backup

echo "Before fix - lines 165-170:"
sed -n '165,170p' server.js

echo ""
echo "🔧 Removing ALL problematic brackets..."

# Remove lines 167-169 (the extra }); lines)
sed -i '167,169d' server.js

echo ""
echo "After fix - lines 165-170:"
sed -n '165,170p' server.js

echo ""
echo "🔍 Test syntax:"
node -c server.js && echo "✅ SYNTAX FINALLY OK!" || {
    echo "❌ Still broken, trying alternative fix..."
    
    # Restore backup and try different approach
    cp server.js.backup server.js
    
    # Remove ALL standalone }); lines
    sed -i '/^});$/d' server.js
    sed -i '/^    });$/d' server.js
    
    # Test again
    node -c server.js && echo "✅ Alternative fix worked!" || echo "💀 Total failure"
}

echo ""
echo "🔄 Force restart service:"
systemctl stop mumudvb-webpanel
sleep 2
systemctl start mumudvb-webpanel

echo ""
echo "📊 Final status:"
systemctl status mumudvb-webpanel --no-pager -n 3

echo ""
echo "🌐 Test web panel:"
sleep 2
curl -s -m 5 http://localhost:8887 | head -2 || echo "Web panel still dead"