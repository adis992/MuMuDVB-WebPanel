# Astra 19.2°E - Kompletna konfiguracija

## Pregled Astra 19.2°E satelita

Astra 19.2°E je glavni evropski satelit sa najvećim brojem FTA i premium kanala.

### Osnovne informacije:
- **Pozicija**: 19.2° Istok
- **Operater**: SES Astra
- **Glavni transponder-i**: 10700-12750 MHz
- **Polarizacije**: Horizontalna (H) i Vertikalna (V)
- **LNB tip**: Universal (9750/10600 MHz)

## W-Scan za Astra 19.2°E

### Kompletno skeniranje:
```bash
w-scan -fs -s S19E2 -v -o 7 -t 3 > /opt/mumudvb-webpanel/configs/astra19_channels.conf
```

### Samo FTA kanali:
```bash
w-scan -fs -s S19E2 -f -v -o 7 -t 3 > /opt/mumudvb-webpanel/configs/astra19_fta.conf
```

### HD kanali samo:
```bash
w-scan -fs -s S19E2 -v -o 7 -t 5 | grep -i "hd\|uhd" > /opt/mumudvb-webpanel/configs/astra19_hd.conf
```

## Popularni transponder-i na Astra 19.2°E

### Niemieckie FTA:
```
Freq: 11538 MHz H, SR: 22000, FEC: 5/6
Kanali: Das Erste HD, ZDF HD, RTL, ProSieben, SAT.1
```

### Sky Deutschland:
```
Freq: 12031 MHz H, SR: 27500, FEC: 3/4  
Kanali: Sky Sport, Sky Cinema (šifrovano)
```

### Französke kanali:
```
Freq: 11623 MHz V, SR: 22000, FEC: 5/6
Kanali: TF1 HD, France 2 HD, M6 HD
```

### Španski kanali:
```
Freq: 10847 MHz V, SR: 22000, FEC: 5/6
Kanali: La 1 HD, La 2 HD, Antena 3 HD
```

## MuMuDVB konfiguracija za Astra 19.2°E

### Bazna konfiguracija:
```bash
# /etc/mumudvb/astra19_mumudvb.conf
adapter=0
freq=11538
pol=h
srate=22000
fec=5/6
delivery_system=DVBS2
autoconfiguration=full
unicast=1
port_http=4242
cam_support=1
scam_support=1
sap=1
sap_organisation="Astra 19.2E"
sap_uri="http://192.168.1.100:4242"
```

### Multi-transponder setup:
```bash
# Transponder 1 - Duitse FTA
[TS1]
freq=11538
pol=h
srate=22000
fec=5/6
pids=163,104,105  # RTL Television

# Transponder 2 - Franse kanali  
[TS2]
freq=11623
pol=v
srate=22000
fec=5/6
pids=110,121,122  # TF1 HD
```

## OSCam konfiguracija za Astra satelite

### oscam.conf za Sky Germany:
```bash
[global]
logfile = /var/log/oscam.log
clienttimeout = 5000
fallbacktimeout = 2500
clientmaxidle = 120
cachedelay = 120
nice = -1
maxlogsize = 50
preferlocalcards = 1

[webif]
httpport = 8888
httpuser = admin
httppwd = admin
httprefresh = 10
httpallowed = 192.168.1.0-192.168.1.255

[dvbapi]
enabled = 1
au = 1
boxtype = pc
user = localuser
```

### oscam.server za Sky Germania:
```bash
[reader]
label = sky_germany
protocol = mouse
device = /dev/ttyUSB0
caid = 1702,1722,1834
detect = cd
mhz = 368
cardmhz = 368
ident = 000000
aeskeys = [AES keys za Sky]
group = 1
emmcache = 1,1,2,0
```

## DiSEqC konfiguracija

### Za LNB bez DiSEqC:
```bash
# Direktna konekcija na Astra 19.2°E
committed_port=0
```

### Za DiSEqC 1.0 (4 pozicije):
```bash
# Astra 19.2°E na poziciji 1
committed_port=1
# Hotbird 13°E na poziciji 2  
# committed_port=2
```

### Za DiSEqC 1.1 (16 pozicija):
```bash
committed_port=1
uncommitted_port=0
```

## Troubleshooting za Astra 19.2°E

### Proverite signal:
```bash
# Instalacija dvb-apps
apt install dvb-apps

# Provera signala
dvb-fe-tool -m -a 0

# Skeniranje transponder-a
scan -a 0 /usr/share/dvb/dvb-s/Astra-19.2E
```

### Česti problemi:

#### 1. Slabi signal:
- Proverite da li je antena pravilno usmerena na 19.2°E
- Očistite LNB od snega/leda
- Proverite koaksijalni kabl

#### 2. Nema kanala:
- Proverite DiSEqC konfiguraciju
- Testiranje sa poznate frekvencije: 11538 MHz H

#### 3. Šifrovani kanali:
- Instalirajte valjan CAM/CI+ modul
- Konfigurirajte OSCam sa validnom karticom

## Preporučene frekvencije za testiranje

### Test transponder-i (uvek dostupni):
```bash
# ARD/ZDF Bouquet
11538 MHz H, SR: 22000, FEC: 5/6

# France Bouquet  
11623 MHz V, SR: 22000, FEC: 5/6

# Spain Bouquet
10847 MHz V, SR: 22000, FEC: 5/6

# UK Bouquet (Sky)
11954 MHz H, SR: 27500, FEC: 2/3
```

### Komanda za brzo testiranje:
```bash
# Test osnovne konekcije
w-scan -fs -s S19E2 -I 11538000 -Q 11538000 -v -o 7 -t 10
```

Ova komanda će skenirati samo jedan transponder (11538 MHz) što je dobro za brzo testiranje.