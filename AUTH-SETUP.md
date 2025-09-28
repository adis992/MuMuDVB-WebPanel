# 🔐 GitHub Authentication Setup

## Problem
GitHub zahteva Personal Access Token umesto password-a za push operacije.

## ✅ Rešenje - Personal Access Token

### 1. Kreirajte Personal Access Token

1. **Idite na GitHub.com** → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. **Kliknite "Generate new token (classic)"**
3. **Token Name**: `MuMuDVB-WebPanel`
4. **Expiration**: `90 days` (ili koliko želite)
5. **Select scopes**: ✅ `repo` (full control of private repositories)
6. **Kliknite "Generate token"**
7. **⚠️ KOPIRAJTE TOKEN** - nećete ga više videti!

### 2. Push sa Token-om

```bash
# Metoda 1: Git Credential Manager (preporučeno)
git push -u origin main
# Kada traži username: adis992
# Kada traži password: PASTE_YOUR_TOKEN_HERE

# Metoda 2: URL sa token-om
git remote set-url origin https://adis992:YOUR_TOKEN@github.com/adis992/MuMuDVB-WebPanel.git
git push -u origin main
```

### 3. Alternatively - SSH Keys (trajno rešenje)

```bash
# Generiši SSH key
ssh-keygen -t ed25519 -C "adis992@example.com"

# Dodaj u SSH agent
ssh-add ~/.ssh/id_ed25519

# Kopiraj public key u GitHub Settings → SSH Keys
cat ~/.ssh/id_ed25519.pub

# Promeni remote na SSH
git remote set-url origin git@github.com:adis992/MuMuDVB-WebPanel.git
git push -u origin main
```

## 🚀 Posle uspešnog push-a

Vaš repository će biti dostupan na:
**https://github.com/adis992/MuMuDVB-WebPanel**

Ubuntu instalacija će raditi sa:
```bash
wget https://raw.githubusercontent.com/adis992/MuMuDVB-WebPanel/main/install-ubuntu.sh
chmod +x install-ubuntu.sh
./install-ubuntu.sh
```

## 📋 Trenutno stanje

- ✅ Git repository kreiran
- ✅ Svi fajlovi committed
- ✅ Remote dodat
- ⏳ Čeka push sa autentifikacijom

**Sledeći korak**: Kreirajte Personal Access Token i pushajte! 🎉