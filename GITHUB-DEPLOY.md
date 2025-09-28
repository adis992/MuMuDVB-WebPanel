# 🚀 GitHub Deployment Instructions

## 📋 Kreiranje GitHub Repository

1. **Idite na GitHub** i kreirajte novi **public** repository:
   - Repository name: `MuMuDVB-WebPanel` 
   - Description: `Advanced DVB streaming web interface for Ubuntu Server`
   - ✅ Public repository
   - ❌ Ne dodavajte README, .gitignore, ili license (već imamo)

2. **Kopirajte URL** vašeg novog repo (npr: `https://github.com/YOUR_USERNAME/MuMuDVB-WebPanel.git`)

## 🔗 Povezivanje sa GitHub

```bash
# Dodajte remote origin (zamenite YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/MuMuDVB-WebPanel.git

# Pushajte kod na GitHub
git push -u origin mumudvb2
```

## 🎯 Alternativno - Fork postojećeg repo

Ako hoćete da forkujete postojeći MuMuDVB repo:

```bash
# Dodajte remote na braice/MuMuDVB
git remote add origin https://github.com/braice/MuMuDVB.git

# Pushajte na mumudvb2 branch
git push -u origin mumudvb2
```

## 📥 Ubuntu Server Deployment

Kada je kod na GitHub-u, na Ubuntu serveru:

### Opcija 1: Direct clone
```bash
# Klonirajte direktno sa GitHub-a
git clone https://github.com/YOUR_USERNAME/MuMuDVB-WebPanel.git
cd MuMuDVB-WebPanel

# Pokrenite instalaciju
chmod +x install-ubuntu.sh
./install-ubuntu.sh
```

### Opcija 2: One-liner deployment
```bash
# Jedan red instalacija
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/MuMuDVB-WebPanel/mumudvb2/install-ubuntu.sh | bash
```

## 🌐 Raw GitHub URLs

Posle push-a, vaše skripte će biti dostupne na:
- Installation script: `https://raw.githubusercontent.com/YOUR_USERNAME/MuMuDVB-WebPanel/mumudvb2/install-ubuntu.sh`
- Deployment script: `https://raw.githubusercontent.com/YOUR_USERNAME/MuMuDVB-WebPanel/mumudvb2/deploy.sh`

## ✅ Verification

Kada instalirate na Ubuntu serveru, proverite:

```bash
# Provera web panel-a
curl http://localhost:8080

# Provera servisa
sudo systemctl status mumudvb-web-panel

# Provera DVB adaptera
ls /dev/dvb*

# Provera w_scan
w_scan -h
```

## 🔧 Post-deployment

1. **Konfigurirajte DVB-S parametre** u web interfejsu
2. **Skenirajte kanale** preko web panel-a
3. **Testirajte stream-ove** 
4. **Konfigurirajte OSCam** (ako je potrebno)

---

**Panel će biti dostupan na: http://YOUR_SERVER_IP:8080** 🎉