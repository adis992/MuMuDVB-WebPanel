# QUICK START - MuMuDVB WebPanel Complete Solution

## 🚀 1-Command Installation

```bash
git clone https://github.com/adis992/MuMuDVB-WebPanel.git
cd MuMuDVB-WebPanel  
chmod +x complete-installer.sh
sudo ./complete-installer.sh
```

## ✅ What Gets Installed

- **MuMuDVB** (DVB streaming server)
- **OSCam** (Softcam for decryption)  
- **W-Scan** (Channel scanner)
- **Web Panel** (Management interface)
- **All services** (Auto-started)

## 🌐 Access URLs (After Installation)

- **Master Panel**: http://YOUR_IP:8887
- **OSCam Web**: http://YOUR_IP:8888 (admin/admin)
- **MuMuDVB HTTP**: http://YOUR_IP:4242

## 📡 Quick Channel Scan (Astra 19.2°E)

```bash
# From web panel or manual:
w-scan -fs -s S19E2 -o 7 -t 3 > /opt/mumudvb-webpanel/configs/channels.conf
```

## 🔧 Quick Test

```bash
chmod +x test-system.sh
./test-system.sh
```

## 📋 Pre-Requirements

- Ubuntu/Debian Linux
- DVB-S/S2 hardware
- Root access
- Internet connection

## 🆘 Quick Troubleshooting

```bash
# Check services
systemctl status mumudvb-webpanel oscam

# Check DVB hardware  
ls /dev/dvb*

# Check logs
journalctl -u mumudvb-webpanel -f
```

---

**JEDAN INSTALLER ZA SVE!** 🎯 Everything works out-of-the-box!