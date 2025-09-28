# MuMuDVB Web Panel

🚀 **Kompletna web-bazirana upravljačka konzola za MuMuDVB DVB-S/S2 streaming server**

## ⚡ Brza instalacija

```bash
# Skini i pokreni installer
wget https://raw.githubusercontent.com/adis992/MuMuDVB-WebPanel/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 🌟 Karakteristike

- ✅ **Kompletna MuMuDVB instalacija** sa CAM/SCAM podrškom
- ✅ **Web interface** na portu 8080  
- ✅ **Real-time monitoring** preko WebSocket-a
- ✅ **Systemd integration** za automatski restart
- ✅ **DVB adapter detection**
- ✅ **Ubuntu 20.04 optimizovano**

## 🌐 Pristup

Posle instalacije:
- **Web panel**: `http://YOUR_SERVER_IP:8080`
- **Streamovi**: `http://YOUR_SERVER_IP:8100/`

## ⚙️ Konfiguracija

```bash
sudo nano /etc/mumudvb/mumudvb.conf
```

Primjer za Astra 19.2°E:
```
freq=11538000
pol=h  
srate=22000000
card=0
tuner=0
```

## 📋 Komande

```bash
# Status servisa
sudo systemctl status mumudvb-webpanel

# Restart servisa  
sudo systemctl restart mumudvb-webpanel

# Logovi
journalctl -u mumudvb-webpanel -f
```

---

**Ubuntu 20.04 LTS ready** 🐧