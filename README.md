# MuMuDVB Web Panel - Kompletno Rešenje

## Pregled

Kompletno rešenje za upravljanje MuMuDVB DVB streaming serverom sa web interfejsom, automatskim skeniranjem kanala i OSCam integracijom.

## Brzo pokretanje

1. **Jednostavno pokretanje:**
   ```
   run_all.bat
   ```

2. **Otvori web panel:**
   - Automatski će se otvoriti u browseru
   - Ili idite na: http://localhost:8080

## Struktura projekta

```
mumudvb_with_web_settings/
├── MuMuDVB/              # Originalni MuMuDVB kod
├── web_panel/            # Web interfejs
│   ├── index.html        # Glavni web interfejs
│   ├── server.js         # Node.js server
│   ├── styles.css        # CSS stilovi
│   ├── script.js         # Frontend JavaScript
│   └── package.json      # Node.js zavisnosti
├── run_all.bat          # Skript za pokretanje
└── README.md            # Ova dokumentacija
```

## Funkcionalnosti

### 1. DVB Skeniranje
- Automatsko skeniranje DVB-T/C/S kanala
- Detekcija DVB adaptera
- Kreiranje liste kanala

### 2. MuMuDVB Konfiguracija
- Automatska generacija config fajlova
- Podešavanje multicast stream-ova
- Monitoring status servera

### 3. OSCam Integracija
- Konfiguracija software descramblinga
- Upravljanje card reader-ima
- Monitoring dekriptovanih kanala

### 4. Stream Management
- Lista aktivnih stream-ova
- Real-time monitoring
- Bandwidth tracking

### 5. Log Praćenje
- Real-time log prikaz
- Error tracking
- Debug informacije

## Kompajliranje MuMuDVB-a

### Zahtevi
- Visual Studio 2022 Professional
- pthread-win32 biblioteke
- Windows SDK

### Koraci
1. Preuzmite pthread-win32 sa: https://sourceforge.net/projects/pthreads-win32/
2. Raspakujte u `MuMuDVB/pthread/lib/`
3. Pokrenite `run_all.bat`

### Manuelno kompajliranje
```batch
cd MuMuDVB
"C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" MuMuDVB.sln /p:Configuration=Release
```

## Web Panel Korišćenje

### Pokretanje servera
```bash
cd web_panel
npm install
node server.js
```

### API Endpoints
- `GET /api/scan` - Pokreni skeniranje
- `GET /api/config` - Generiši konfiguraciju  
- `GET /api/streams` - Lista stream-ova
- `GET /api/logs` - Sistemski logovi
- `WebSocket ws://localhost:8081` - Real-time updates

### Browser kompatibilnost
- Chrome/Edge (preporučeno)
- Firefox
- Safari

## Konfiguracija

### DVB Settings
```javascript
const dvbConfig = {
    adapter: 0,
    frontend: 0,
    demux: 0,
    frequency: 474000000,
    bandwidth: "8MHz"
};
```

### OSCam Settings
```javascript
const oscamConfig = {
    protocol: "cs378x", 
    host: "localhost",
    port: 12000,
    username: "user",
    password: "pass"
};
```

## Troubleshooting

### Česti problemi

1. **MuMuDVB se ne kompajlira**
   - Proverite da li je pthread-win32 instaliran
   - Proverite Visual Studio instalaciju

2. **Web panel se ne pokreće**
   - Proverite da li je Node.js instaliran
   - Pokrenite `npm install` u web_panel direktorijumu

3. **DVB adapter nije pronađen**
   - Proverite da li su DVB drajveri instalirani
   - Pokrenite kao administrator

### Debug mode
```bash
set DEBUG=true
node server.js
```

## Dodatne funkcionalnosti

### w_scan integracija
- Automatsko skeniranje DVB signala
- Kreiranje kanala lista za MuMuDVB
- Support za DVB-T/C/S/S2

### Real-time monitoring
- WebSocket konekcije za live updates
- Bandwidth monitoring
- Error alerting

### Configuration backup
- Automatski backup konfiguracije
- Restore funkcionalnost
- Version control

## Kontakt

Za podršku i dodatne informacije:
- GitHub Issues
- Email support
- Community forum

## Licenca

GPL v2 - videti COPYING fajl za detalje