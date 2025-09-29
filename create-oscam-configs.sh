#!/bin/bash

# OSCAM CONFIG CREATOR - STANDALONE SKRIPTA
# Kreira oscam.conf, oscam.user, oscam.server fajlove

echo "🔧 KREIRANJE OSCAM KONFIGURACIJA..."

# Kreiranje direktorija
mkdir -p /usr/local/etc/oscam
mkdir -p /var/log/oscam
mkdir -p /var/run

# oscam.conf
cat > /usr/local/etc/oscam/oscam.conf << 'EOF'
# OSCam Configuration - OPTIMIZOVANA ZA MUMUDVB + CCCAM
[global]
serverip = 0.0.0.0
logfile = /var/log/oscam/oscam.log
pidfile = /var/run/oscam.pid
disablelog = 0
disableuserfile = 0
usrfileflag = 0
clienttimeout = 8000
fallbacktimeout = 3000  
clientmaxidle = 300
bindwait = 120
netprio = 0
sleep = 0
unlockparental = 0
nice = 99
maxlogsize = 50
waitforcards = 1
preferlocalcards = 2
saveinithistory = 1
readerrestartseconds = 10
lb_mode = 1
lb_save = 500
lb_nbest_readers = 2
lb_auto_betatunnel = 1

[monitor]
port = 988
aulow = 120
monlevel = 4
nocrypt = 127.0.0.1,192.168.0.0-192.168.255.255

[webif]
httpport = 8888
httpuser = admin
httppwd = admin
httphelplang = en
httprefresh = 15
httpallowed = 127.0.0.1,192.168.0.0-192.168.255.255
httphideidleclients = 1
httpshowmeminfo = 1
httpshowuserinfo = 1
httpshowecminfo = 1
httpshowloadinfo = 1

[dvbapi]
enabled = 1
au = 1
user = mumudvb
boxtype = pc
pmt_mode = 6
request_mode = 1
delayer = 2
ecminfo_type = 4
read_sdt = 2
write_sdt_prov = 1

[cccam]
port = 12000
reshare = 2
ignorereshare = 0
stealth = 1
nodeid = 1234567890ABCDEF
version = 2.3.2
mindown = 0
EOF

# oscam.user
cat > /usr/local/etc/oscam/oscam.user << 'EOF'
# OSCam users - OPTIMIZOVANO ZA MUMUDVB

# MuMuDVB local connection
[account]
user = mumudvb
pwd = mumudvb
group = 1,2,3
au = 1
monlevel = 0

# Admin user
[account]
user = admin
pwd = admin
group = 1,2,3
au = 1
monlevel = 4

# Web user
[account]
user = web
pwd = web
group = 1,2,3
au = 0
monlevel = 0
EOF

# oscam.server
cat > /usr/local/etc/oscam/oscam.server << 'EOF'
# OSCam server configuration - OPTIMIZOVANO ZA CCCAM SHARING

# CCcam reader - dhoom.org server - GLAVNI
[reader]
label = dhoom_primary
protocol = cccam
device = dhoom.org,34000
user = sead1302
password = sead1302
cccversion = 2.3.2
group = 1,2,3
disablecrccws = 1
inactivitytimeout = 30
reconnecttimeout = 60
lb_weight = 300
cccmaxhops = 3
ccckeepalive = 1
cccwantemu = 0
audisabled = 0
auprovid = 000000
services = !0B00
nanddumpsize = 64

# Backup CCcam reader (dodaj svoj backup server ovde)
# [reader]
# label = backup_server
# protocol = cccam
# device = backup-server.com,port
# user = username
# password = password
# cccversion = 2.3.2
# group = 2
# lb_weight = 100
# cccmaxhops = 2
# ccckeepalive = 1

# Local card reader template (ako imaš karticu)
# [reader]
# label = local-card
# protocol = internal
# device = /dev/sci0
# caid = 0B00
# detect = cd
# mhz = 600
# cardmhz = 600
# group = 1
# emmcache = 1,3,2,0
# blockemm-unknown = 1
# blockemm-u = 1
# blockemm-s = 1
# blockemm-g = 1
# lb_weight = 1000
EOF

# Postavke dozvola
chmod 644 /usr/local/etc/oscam/oscam.conf
chmod 644 /usr/local/etc/oscam/oscam.user  
chmod 644 /usr/local/etc/oscam/oscam.server
chmod 755 /usr/local/etc/oscam

# Log direktorij
chmod 755 /var/log/oscam 2>/dev/null || mkdir -p /var/log/oscam && chmod 755 /var/log/oscam

echo "✅ OSCAM KONFIGURACIJE KREIRANE:"
echo "📁 /usr/local/etc/oscam/oscam.conf"
echo "👤 /usr/local/etc/oscam/oscam.user"  
echo "🌐 /usr/local/etc/oscam/oscam.server"
echo ""
echo "🔐 DHOOM.ORG SERVER KONFIGURISAN:"
echo "   Host: dhoom.org:34000"
echo "   User: sead1302"
echo "   Pass: sead1302"
echo ""
echo "🌐 OSCAM WEB INTERFACE:"
echo "   URL: http://localhost:8888"
echo "   User: admin"
echo "   Pass: admin"
echo ""
echo "🚀 POKRETANJE OSCAM:"
echo "   sudo oscam -b -c /usr/local/etc/oscam"
echo ""

# Test da li fajlovi postoje
if [ -f "/usr/local/etc/oscam/oscam.conf" ]; then
    echo "✅ oscam.conf kreiran ($(stat -c%s /usr/local/etc/oscam/oscam.conf) bytes)"
else
    echo "❌ oscam.conf NIJE kreiran!"
fi

if [ -f "/usr/local/etc/oscam/oscam.user" ]; then
    echo "✅ oscam.user kreiran ($(stat -c%s /usr/local/etc/oscam/oscam.user) bytes)"
else
    echo "❌ oscam.user NIJE kreiran!"
fi

if [ -f "/usr/local/etc/oscam/oscam.server" ]; then
    echo "✅ oscam.server kreiran ($(stat -c%s /usr/local/etc/oscam/oscam.server) bytes)"
else
    echo "❌ oscam.server NIJE kreiran!"
fi

echo ""
echo "🎯 KREIRANJE ZAVRŠENO!"