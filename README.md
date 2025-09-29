# MuMuDVB WebPanel - Complete Solution

🚀 **Kompletno DVB streaming rešenje sa web-baziranim upravljačkim panelom za MuMuDVB, OSCam i W-Scan**

## ⚡ Brza instalacija

```bash
git clone https://github.com/adis992/MuMuDVB-WebPanel.git
cd MuMuDVB-WebPanel
chmod +x complete-installer.sh
sudo ./complete-installer.sh
```

## 🌟 Karakteristike

- ✅ **MuMuDVB** - DVB streaming server sa CAM/SCAM podrškom
- ✅ **OSCam** - Softcam za dekriptovanje
- ✅ **W-Scan** - Channel scanning utility  
- ✅ **Web Panel** - Kompletni web interface za upravljanje
- ✅ **Auto-instalacija** - Jedan script instalira sve
- ✅ **Systemd integration** za automatski restart
- ✅ **DVB adapter detection** (0-4 adapteri)

## 🌐 Pristup

Posle instalacije:

- **Master Panel**: `http://YOUR_IP:8887`
- **OSCam Web**: `http://YOUR_IP:8888` (admin/admin)
- **MuMuDVB HTTP**: `http://YOUR_IP:4242` (kada radi)

## 📡 W-Scan korišćenje

### 1. Building w_scan
Obično nije potrebno - w_scan se automatski build-uje tokom instalacije.

#### 1.a Korišćenjem autotools:

```bash
./configure
make
make install
```

#### 1.b Korišćenjem cmake:

```bash
mkdir build && cd build
cmake ..
make
make install
```

**NAPOMENA**: Za kompajliranje su potrebni up-to-date DVB headers sa DVB API 5.3 podrškom.

### 2. Osnovno korišćenje

**NAPOMENA**: Novije verzije w_scan zahtevaju podešavanje '-c' za zemlju ili '-s' za satelit.

#### 2.a. DVB-C (Nemačka primer):

```bash
./w_scan -fc -c DE >> channels.conf
```

#### 2.b. DVB-T:

```bash
./w_scan -c DE >> channels.conf
```

#### 2.c. DVB-S (Astra 19.2E):

```bash
./w_scan -fs -s S19E2
```

#### 2.d. ATSC (US):

```bash
./w_scan -fa -c US >> channels.conf
```

**NAPOMENA**: Pogledaj `./w_scan -s?` za listu satelita.

## ⚙️ Konfiguracija

### MuMuDVB Config (ASTRA 19.2E primer):

```bash
adapter=0
freq=10832
pol=h
srate=22000
fec=5/6
delivery_system=DVBS
autoconfiguration=full
unicast=1
port_http=4242
cam_support=1
scam_support=1
```

### OSCam Config:

```bash
[global]
serverip = 0.0.0.0
logfile = /var/log/oscam.log

[webif]
httpport = 8888
httpuser = admin
httppwd = admin
```

## 📁 Lokacije fajlova

- **MuMuDVB Config**: `/etc/mumudvb/mumudvb.conf`
- **OSCam Config**: `/var/etc/oscam/`
- **W-Scan Rezultati**: `/opt/mumudvb-webpanel/configs/channels.conf`
- **Web Panel**: `/opt/mumudvb-webpanel/`

## 🔧 Troubleshooting

### DVB Adapteri Check:

```bash
ls /dev/dvb*
```

### Status servisa:

```bash
systemctl status mumudvb-webpanel
systemctl status oscam
```

### Logovi:

```bash
journalctl -u mumudvb-webpanel -f
journalctl -u oscam -f
```

## 📋 Komponente

- **MuMuDVB**: Auto-clone sa https://github.com/braice/MuMuDVB.git
- **OSCam**: Auto-clone sa SVN repozitorijuma
- **W-Scan**: Auto-clone sa https://github.com/tbsdtv/w_scan.git
- **Node.js**: Za web panel
- **Systemd Servisi**: Auto-konfigurisani i pokrenuti

---

**JEDAN INSTALLER ZA SVE!** � Sve dostupno kroz jedan web interface na portu 8887!