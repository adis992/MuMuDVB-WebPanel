# MuMuDVB Web Panel - Ubuntu Installation Guide

Advanced DVB streaming solution with web interface for Ubuntu Server 20.04+

## 🚀 Quick Installation

```bash
# Download and run installation script
wget https://raw.githubusercontent.com/braice/MuMuDVB/mumudvb2/install-ubuntu.sh
chmod +x install-ubuntu.sh
./install-ubuntu.sh
```

## 📋 Manual Installation Steps

### 1. System Requirements

- Ubuntu Server 20.04 LTS or newer
- DVB-S/T/C card or USB tuner
- Minimum 2GB RAM
- Internet connection for packages

### 2. Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y build-essential git wget curl vim htop

# Install DVB tools
sudo apt install -y dvb-apps dvb-tools w-scan szap libdvbv5-dev

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install MuMuDVB dependencies  
sudo apt install -y autoconf automake libtool pkg-config libdvbcsa-dev
```

### 3. Compile MuMuDVB

```bash
# Clone repository
git clone https://github.com/braice/MuMuDVB.git
cd MuMuDVB

# Configure and compile
autoreconf -i -f
./configure --enable-cam-support --enable-scam-support
make -j$(nproc)
sudo make install
sudo ldconfig
```

### 4. Setup Web Panel

```bash
# Install web panel dependencies
cd web_panel
npm install

# Create systemd service
sudo cp ../scripts/mumudvb-web-panel.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mumudvb-web-panel
sudo systemctl start mumudvb-web-panel
```

## 🎛️ Web Panel Features

### DVB Scanning Tab
- **Auto-detection**: Scans for DVB-S/T/C adapters
- **Satellite Scanning**: Full transponder scanning with w_scan
- **Channel Lists**: Automatic channel list generation
- **Signal Monitoring**: Real-time signal strength and quality

### Configuration Tab  
- **Auto-configuration**: Generates MuMuDVB config files
- **DVB Parameters**: Frequency, polarization, symbol rate setup
- **Network Settings**: Multicast, unicast, HTTP configuration
- **Export/Import**: Download/upload configuration files

### OSCam Integration Tab
- **Connection Testing**: Test OSCam server connectivity
- **Descrambling Setup**: Configure software descrambling
- **DECSA Parameters**: Fine-tune descrambling delays
- **Status Monitoring**: Real-time descrambling status

### Monitoring Tab
- **Service Status**: MuMuDVB and OSCam service monitoring
- **Signal Meters**: Live signal strength, quality, and BER
- **System Logs**: Real-time log viewer with filtering
- **Performance**: CPU and memory usage tracking

### Stream Information Tab
- **Active Streams**: List all running multicast streams
- **Quality Metrics**: Bitrate, packet rate, error monitoring
- **Stream Control**: Start/stop individual streams
- **Multicast Info**: IP addresses, ports, TTL settings

## 🔧 Configuration

### DVB-S Setup Example

```bash
# Scan Astra 19.2°E satellite
w_scan -f s -s S19E2 -a 0 -x > /tmp/channels.conf

# Create MuMuDVB configuration
sudo nano /etc/mumudvb/mumudvb-0.conf
```

Sample DVB-S configuration:
```ini
# DVB-S Configuration for Astra 19.2°E
card=0
freq=11996
pol=h
srate=27500

# Autoconfiguration
autoconfiguration=full

# Network settings
multicast_ttl=2
unicast=1
port_http=4242

# Logging
log_type=1
log_file=/var/log/mumudvb/mumudvb-0.log
pid_file=/var/run/mumudvb/mumudvb-0.pid
```

### DVB-T Setup Example

```ini
# DVB-T Configuration
card=0
freq=506
bandwidth=8

# Autoconfiguration for terrestrial
autoconfiguration=full
autoconf_unicast_start_port=8080
```

## 🎯 Usage

### Start Services

```bash
# Start web panel
sudo systemctl start mumudvb-web-panel

# Start MuMuDVB on adapter 0
sudo systemctl start mumudvb@0

# Check status
sudo systemctl status mumudvb-web-panel
sudo systemctl status mumudvb@0
```

### Access Web Interface

- **Local**: http://localhost:8080
- **Remote**: http://your-server-ip:8080

### Command Line Tools

```bash
# Scan satellites (DVB-S)
w_scan -f s -s S19E2 -a 0 -x

# Scan terrestrial (DVB-T)  
w_scan -f t -c RS -a 0 -x

# Check DVB adapters
ls /dev/dvb*

# Monitor signal
szap-s2 -c channels.conf "Channel Name" -a 0

# View logs
tail -f /var/log/mumudvb/mumudvb-0.log
```

## 🔍 Troubleshooting

### DVB Adapter Not Detected

```bash
# Check kernel modules
lsmod | grep dvb

# Check PCI devices
lspci | grep -i multimedia

# Check USB devices (for USB tuners)
lsusb | grep -i dvb

# Install drivers (example for common cards)
sudo apt install dvb-usb-firmware
```

### Permission Issues

```bash
# Add user to video group
sudo usermod -a -G video $USER

# Set DVB device permissions
sudo chmod 666 /dev/dvb/adapter*/frontend*
sudo chmod 666 /dev/dvb/adapter*/demux*
sudo chmod 666 /dev/dvb/adapter*/dvr*
```

### No Signal

1. Check cable connections
2. Verify satellite/antenna alignment  
3. Check polarization settings
4. Verify frequency and symbol rate
5. Test with external DVB software

### Web Panel Issues

```bash
# Check service status
sudo systemctl status mumudvb-web-panel

# View logs
sudo journalctl -u mumudvb-web-panel -f

# Restart service
sudo systemctl restart mumudvb-web-panel

# Check ports
sudo netstat -tlnp | grep 8080
```

## 📁 File Locations

- **Configuration**: `/etc/mumudvb/`
- **Logs**: `/var/log/mumudvb/`
- **PID files**: `/var/run/mumudvb/`
- **Web panel**: `~/MuMuDVB/web_panel/`
- **Binary**: `/usr/local/bin/mumudvb`

## 🌐 Network Configuration

### Firewall Setup

```bash
# Ubuntu UFW
sudo ufw allow 8080/tcp comment "MuMuDVB Web Panel"
sudo ufw allow 4242/tcp comment "MuMuDVB HTTP"
sudo ufw allow 1234:1244/udp comment "Multicast streams"

# iptables (alternative)
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 4242 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 1234:1244 -j ACCEPT
```

### Multicast Routing

```bash
# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf

# Add multicast routes
sudo route add -net 239.0.0.0 netmask 255.0.0.0 dev eth0
```

## 🔗 Useful Links

- [MuMuDVB Documentation](http://mumudvb.net/documentation/)
- [DVB-S Satellite List](https://www.lyngsat.com/)
- [DVB-T Frequency Tables](https://en.wikipedia.org/wiki/Digital_terrestrial_television)
- [OSCam Configuration](http://www.streamboard.tv/oscam/)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/braice/MuMuDVB/issues)
- **Wiki**: [Project Wiki](https://github.com/braice/MuMuDVB/wiki)
- **Community**: DVB forums and IRC channels

## 📄 License

GPL v2 - See COPYING file for details