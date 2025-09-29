# W-Scan Satellite List and Usage Guide

## Pregled dostupnih satelita

Za pregled svih dostupnih satelita koristite:
```bash
w-scan -s?
```

## Najčešće korišćeni sateliti u regionu

### Astra sateliti:
- **S19E2** - Astra 19.2°E (glavni evropski satelit)
- **S23E5** - Astra 23.5°E  
- **S28E2** - Astra 28.2°E (Sky UK)

### Hotbird:
- **S13E0** - Hotbird 13°E

### Eutelsat:
- **S16E0** - Eutelsat 16°E
- **S7E0** - Eutelsat 7°E
- **S36E0** - Eutelsat 36°E

### Balkanski region sateliti:
- **S39E0** - Hellas Sat 39°E (Nova S, Total TV)
- **S42E0** - Turksat 42°E

## Osnovno skeniranje kanala

### Za Astra 19.2°E (najčešći):
```bash
w-scan -fs -s S19E2 -o 7 -t 3 > /opt/mumudvb-webpanel/configs/channels.conf
```

### Za Hotbird 13°E:
```bash
w-scan -fs -s S13E0 -o 7 -t 3 > /opt/mumudvb-webpanel/configs/channels.conf
```

### Za Hellas Sat 39°E (Nova S):
```bash
w-scan -fs -s S39E0 -o 7 -t 3 > /opt/mumudvb-webpanel/configs/channels.conf
```

## Parametri objašnjeni

- **-fs**: DVB-S/S2 sken
- **-s**: Satelit (primer: S19E2)
- **-o 7**: Output format za VLC/MuMuDVB
- **-t 3**: Timeout 3 sekunde po transponder-u

## Dodatne opcije

### Verbose output:
```bash
w-scan -fs -s S19E2 -v -o 7 -t 3
```

### Samo FTA kanali (bez šifrovanja):
```bash
w-scan -fs -s S19E2 -f -o 7 -t 3
```

### Ograniči na određene frekvencije:
```bash
w-scan -fs -s S19E2 -I 10700000 -Q 12750000 -o 7 -t 3
```

## Primer channels.conf izlaza

Nakon skeniranja, channels.conf će sadržavati linije ovog formata:
```
RTL Television:11538000:h:0:22000:163:104:105:0:12020:1:1089:0
ProSieben:11538000:h:0:22000:167:108:109:0:12020:1:1089:0
SAT.1:11538000:h:0:22000:165:106:107:0:12020:1:1089:0
```

Format: `Naziv:Frekvencija:Polarizacija:DiSEqC:Simbolna_brzina:Video_PID:Audio_PID:Teletext_PID:Conditional_access:Service_ID:Network_ID:Transport_stream_ID:Radio_ID`

## Integracija sa MuMuDVB

Channels.conf fajl se može koristiti za automatsku konfiguraciju MuMuDVB kanala.

### Čitanje specifičnog kanala:
```bash
grep "RTL Television" /opt/mumudvb-webpanel/configs/channels.conf
```

### Konvertovanje u MuMuDVB format:
Iz channels.conf linije:
```
RTL Television:11538000:h:0:22000:163:104:105:0:12020:1:1089:0
```

MuMuDVB config:
```
freq=11538
pol=h
srate=22000
pids=163,104,105
```

## Saveti za uspešno skeniranje

1. **Proverite DVB adapter**: `ls /dev/dvb*`
2. **Kvalitet signala**: Koristite `dvb-fe-tool` za proveru
3. **DiSEqC podešavanja**: Dodajte `-D` ako imate DiSEqC switch
4. **Timeout**: Povećajte `-t` vrednost za slabiji signal
5. **Verbose mode**: Koristite `-v` za debugging

## Troubleshooting

### Greška "no useable DVB card found":
```bash
# Proverite da li su DVB moduli učitani
lsmod | grep dvb
# Proverite permisije
sudo chmod 666 /dev/dvb/adapter0/*
```

### Slabi signal:
```bash
# Povećajte timeout
w-scan -fs -s S19E2 -t 10 -o 7
# Koristite verbose mode za dijagnostiku
w-scan -fs -s S19E2 -v -o 7
```

### Nema transponder liste:
```bash
# Ažurirajte w-scan
git pull origin master
make clean && make
```