# 🚀 KOMPLETNE KOMANDE - BRISANJE I INSTALACIJA

## 🗑️ KORAK 1: KOMPLETNO BRISANJE (Clean Slate)

```bash
# Skini clean removal script
wget https://raw.githubusercontent.com/adis992/MuMuDVB-WebPanel/main/CLEAN-REMOVE.sh
chmod +x CLEAN-REMOVE.sh
sudo ./CLEAN-REMOVE.sh
```

**ili manualno:**

```bash
# Stop sve servise
sudo systemctl stop mumudvb-webpanel oscam cccam 2>/dev/null || true

# Disable servise
sudo systemctl disable mumudvb-webpanel oscam cccam 2>/dev/null || true

# Kill procese
sudo pkill -f mumudvb
sudo pkill -f oscam  
sudo pkill -f cccam
sudo pkill -f "node.*mumudvb"

# Free portove
sudo fuser -k 8887/tcp 8888/tcp 4242/tcp 16001/tcp 12000/tcp 2>/dev/null || true

# Ukloni systemd fajlove
sudo rm -f /etc/systemd/system/mumudvb-webpanel.service
sudo rm -f /etc/systemd/system/oscam.service
sudo rm -f /etc/systemd/system/cccam.service
sudo systemctl daemon-reload

# Ukloni direktorijume
sudo rm -rf /opt/mumudvb-webpanel
sudo rm -rf /etc/mumudvb
sudo rm -rf /var/etc/oscam
sudo rm -rf /var/etc/cccam

# Ukloni binare
sudo rm -f /usr/local/bin/oscam
sudo rm -f /usr/local/bin/cccam
sudo rm -f /usr/local/bin/w-scan
```

---

## 🚀 KORAK 2: ČISTA INSTALACIJA

### Opcija A - Master Panel Installer (Preporučeno):

```bash
# Clone projekat
git clone https://github.com/adis992/MuMuDVB-WebPanel.git
cd MuMuDVB-WebPanel

# Pokreni master installer
chmod +x master-panel-install.sh
sudo ./master-panel-install.sh
```

### Opcija B - Complete Installer:

```bash
# Clone projekat
git clone https://github.com/adis992/MuMuDVB-WebPanel.git
cd MuMuDVB-WebPanel

# Pokreni complete installer
chmod +x complete-installer.sh
sudo ./complete-installer.sh
```

### Opcija C - Direktan Download:

```bash
# Master installer
wget https://raw.githubusercontent.com/adis992/MuMuDVB-WebPanel/main/master-panel-install.sh
chmod +x master-panel-install.sh
sudo ./master-panel-install.sh

# ili Complete installer
wget https://raw.githubusercontent.com/adis992/MuMuDVB-WebPanel/main/complete-installer.sh
chmod +x complete-installer.sh
sudo ./complete-installer.sh
```

---

## ✅ KORAK 3: VERIFIKACIJA

```bash
# Test system
wget https://raw.githubusercontent.com/adis992/MuMuDVB-WebPanel/main/test-system.sh
chmod +x test-system.sh
./test-system.sh
```

**ili manualno proverit:**

```bash
# Status servisa
systemctl status mumudvb-webpanel
systemctl status oscam

# Portovi
netstat -tuln | grep -E "(8887|8888|4242|16001)"

# DVB adapteri
ls /dev/dvb*

# Logovi
journalctl -u mumudvb-webpanel --no-pager | tail -20
```

---

## 🌐 PRISTUP (nakon instalacije):

- **Master Panel**: http://YOUR_IP:8887
- **OSCam Web**: http://YOUR_IP:8888 (admin/admin)
- **MuMuDVB HTTP**: http://YOUR_IP:4242 (kad radi)
- **CCcam Web**: http://YOUR_IP:16001 (kad je CCcam aktivan)

---

## 🔧 BRZO TESTIRANJE:

```bash
# Test web panel
curl -I http://localhost:8887

# Test OSCam  
curl -I http://localhost:8888

# Check dhoom.org CCcam server
grep -r "dhoom.org" /var/etc/oscam/

# W-scan test (Astra 19.2E)
w-scan -fs -s S19E2 -v -t 5 | head -10
```

---

## 🎯 ŠTA SE INSTALIRA:

✅ **MuMuDVB** - DVB streaming server  
✅ **OSCam** - Schimmelreiter smod sa dhoom.org reader-om  
✅ **CCcam** - Alternativni server sa CCcam.cfg  
✅ **W-Scan** - Channel scanner (build from source)  
✅ **Web Panel** - Node.js interface sa svim kontrolama  
✅ **Systemd Servisi** - Auto-start i monitoring  

**JEDAN INSTALLER ZA SVE!** 🚀