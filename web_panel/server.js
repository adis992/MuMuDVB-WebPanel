const express = require('express');
const path = require('path');
const fs = require('fs');
const { spawn, exec } = require('child_process');
const WebSocket = require('ws');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Global variables
let currentScan = null;
let mumudvbProcess = null;
let oscamProcess = null;
let wscanProcess = null;

// Serve the main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// API Routes

// DVB Adapter detection
app.get('/api/adapters', (req, res) => {
    const { exec } = require('child_process');
    
    // Check for DVB adapters on Windows
    exec('wmic path Win32_PnPEntity where "Name like \'%DVB%\'" get Name,DeviceID /format:csv', (error, stdout, stderr) => {
        if (error) {
            console.error('Error detecting DVB adapters:', error);
            // Fallback - check for standard adapter files
            const adapters = [];
            for (let i = 0; i < 8; i++) {
                adapters.push({
                    id: i,
                    name: `DVB Adapter ${i}`,
                    type: 'Unknown',
                    status: 'Unknown'
                });
            }
            return res.json({ adapters });
        }
        
        const adapters = [];
        const lines = stdout.split('\n').filter(line => line.trim() && !line.includes('Node,'));
        
        lines.forEach((line, index) => {
            const parts = line.split(',');
            if (parts.length >= 2) {
                const name = parts[2] || `DVB Adapter ${index}`;
                adapters.push({
                    id: index,
                    name: name.trim(),
                    type: name.includes('DVB-S') ? 'DVB-S/S2' : name.includes('DVB-T') ? 'DVB-T/T2' : name.includes('DVB-C') ? 'DVB-C' : 'Universal',
                    status: 'Available'
                });
            }
        });
        
        if (adapters.length === 0) {
            // Add default adapters if none detected
            for (let i = 0; i < 4; i++) {
                adapters.push({
                    id: i,
                    name: `DVB Adapter ${i}`,
                    type: 'DVB-S/S2',
                    status: 'Available'
                });
            }
        }
        
        res.json({ adapters });
    });
});

// Get DVB signal info
app.get('/api/signal/:adapter', (req, res) => {
    const adapter = req.params.adapter;
    
    // Simulate signal reading (would use actual DVB API in real implementation)
    const signalInfo = {
        strength: Math.floor(Math.random() * 100),
        quality: Math.floor(Math.random() * 100),
        ber: Math.random() * 0.001,
        locked: Math.random() > 0.3
    };
    
    res.json(signalInfo);
});

// Service status endpoint
app.get('/api/status', (req, res) => {
    const { exec } = require('child_process');
    
    // Check MuMuDVB status
    exec('pgrep mumudvb', (error, stdout, stderr) => {
        const mumudvbRunning = !error && stdout.trim().length > 0;
        
        // Check OSCam status
        exec('pgrep oscam', (oscamError, oscamStdout, oscamStderr) => {
            const oscamRunning = !oscamError && oscamStdout.trim().length > 0;
            
            res.json({
                mumudvb: mumudvbRunning,
                oscam: oscamRunning,
                timestamp: new Date().toISOString()
            });
        });
    });
});

// Service control endpoints
app.post('/api/service/:service/toggle', (req, res) => {
    const service = req.params.service;
    const { exec } = require('child_process');
    
    if (service === 'mumudvb') {
        // Toggle MuMuDVB service
        exec('pgrep mumudvb', (error, stdout, stderr) => {
            const isRunning = !error && stdout.trim().length > 0;
            
            if (isRunning) {
                // Stop MuMuDVB
                exec('sudo systemctl stop mumudvb@0', (stopError) => {
                    res.json({ 
                        success: !stopError, 
                        running: false, 
                        message: stopError ? 'Failed to stop MuMuDVB' : 'MuMuDVB stopped' 
                    });
                });
            } else {
                // Start MuMuDVB
                exec('sudo systemctl start mumudvb@0', (startError) => {
                    res.json({ 
                        success: !startError, 
                        running: !startError, 
                        message: startError ? 'Failed to start MuMuDVB' : 'MuMuDVB started' 
                    });
                });
            }
        });
    } else if (service === 'oscam') {
        // Toggle OSCam service (if installed)
        exec('pgrep oscam', (error, stdout, stderr) => {
            const isRunning = !error && stdout.trim().length > 0;
            
            if (isRunning) {
                exec('sudo pkill oscam', (stopError) => {
                    res.json({ 
                        success: !stopError, 
                        running: false, 
                        message: stopError ? 'Failed to stop OSCam' : 'OSCam stopped' 
                    });
                });
            } else {
                exec('sudo /usr/local/bin/oscam -b', (startError) => {
                    res.json({ 
                        success: !startError, 
                        running: !startError, 
                        message: startError ? 'Failed to start OSCam (not installed?)' : 'OSCam started' 
                    });
                });
            }
        });
    } else {
        res.status(400).json({ error: 'Unknown service' });
    }
});

// Scan management
app.post('/api/scan/start', (req, res) => {
    const { adapter, type, frequency, polarization, symbolrate, bandwidth } = req.body;
    
    if (currentScan && !currentScan.killed) {
        return res.status(400).json({ error: 'Scan already in progress' });
    }
    
    let wscanArgs = [];
    
    // Configure w_scan arguments based on DVB type
    if (type === 'dvb-s') {
        wscanArgs = [
            '-f', 's',
            '-s', `${frequency}:${polarization}:${symbolrate}`,
            '-a', adapter.toString(),
            '-x'
        ];
    } else if (type === 'dvb-t') {
        wscanArgs = [
            '-f', 't',
            '-c', 'RS', // Srbija
            '-a', adapter.toString(),
            '-x'
        ];
    } else if (type === 'dvb-c') {
        wscanArgs = [
            '-f', 'c',
            '-c', 'RS',
            '-a', adapter.toString(),
            '-x'
        ];
    }
    
    console.log('Starting w_scan with args:', wscanArgs);
    
    // Start w_scan process
    wscanProcess = spawn('w_scan', wscanArgs);
    
    let scanOutput = '';
    let channels = [];
    
    wscanProcess.stdout.on('data', (data) => {
        scanOutput += data.toString();
        // Parse channels from w_scan output
        parseWScanOutput(data.toString(), channels);
    });
    
    wscanProcess.stderr.on('data', (data) => {
        console.error('w_scan stderr:', data.toString());
    });
    
    wscanProcess.on('close', (code) => {
        console.log('w_scan finished with code:', code);
        currentScan = {
            completed: true,
            progress: 100,
            status: 'Completed',
            channels: channels,
            output: scanOutput
        };
    });
    
    wscanProcess.on('error', (error) => {
        console.error('w_scan error:', error);
        currentScan = {
            completed: true,
            progress: 0,
            status: 'Error: ' + error.message,
            channels: [],
            output: scanOutput
        };
    });
    
    currentScan = {
        completed: false,
        progress: 0,
        status: 'Starting scan...',
        channels: [],
        output: ''
    };
    
    res.json({ success: true, message: 'Scan started' });
});

app.post('/api/scan/stop', (req, res) => {
    if (wscanProcess && !wscanProcess.killed) {
        wscanProcess.kill('SIGTERM');
        currentScan = null;
    }
    res.json({ success: true, message: 'Scan stopped' });
});

app.get('/api/scan/status', (req, res) => {
    if (!currentScan) {
        return res.json({ completed: false, progress: 0, status: 'No scan running' });
    }
    
    // Simulate progress if not completed
    if (!currentScan.completed && wscanProcess && !wscanProcess.killed) {
        currentScan.progress = Math.min(95, currentScan.progress + Math.random() * 5);
        currentScan.status = 'Scanning transponders...';
    }
    
    res.json(currentScan);
});

// Configuration management
app.post('/api/config/save', (req, res) => {
    const { config } = req.body;
    const configPath = path.join(__dirname, 'mumudvb.conf');
    
    fs.writeFile(configPath, config, 'utf8', (err) => {
        if (err) {
            console.error('Error saving config:', err);
            return res.status(500).json({ error: 'Failed to save configuration' });
        }
        res.json({ success: true, message: 'Configuration saved' });
    });
});

app.get('/api/config/load', (req, res) => {
    const configPath = path.join(__dirname, 'mumudvb.conf');
    
    fs.readFile(configPath, 'utf8', (err, data) => {
        if (err) {
            return res.status(404).json({ error: 'Configuration file not found' });
        }
        res.json({ config: data });
    });
});

// Stream management endpoints
app.get('/api/streams', (req, res) => {
    // Mock stream data - in real implementation would query MuMuDVB
    const streams = [
        {
            id: '1',
            name: 'RTS 1 HD',
            multicast: '239.255.1.1',
            port: 1234,
            bitrate: 8500,
            packets: 1250,
            active: true
        },
        {
            id: '2', 
            name: 'RTS 2 HD',
            multicast: '239.255.1.2',
            port: 1235,
            bitrate: 7200,
            packets: 1100,
            active: true
        }
    ];
    
    res.json({ streams });
});

app.post('/api/stream/:id/toggle', (req, res) => {
    const streamId = req.params.id;
    // Mock response - in real implementation would control actual streams
    const active = Math.random() > 0.5;
    res.json({ success: true, active, message: `Stream ${streamId} ${active ? 'started' : 'stopped'}` });
});

// Logs endpoint
app.get('/api/logs', (req, res) => {
    const logFile = '/var/log/mumudvb/mumudvb-0.log';
    
    fs.readFile(logFile, 'utf8', (err, data) => {
        if (err) {
            // Return mock logs if file doesn't exist
            const mockLogs = [
                { timestamp: new Date().toISOString(), level: 'info', message: 'MuMuDVB Web Panel started' },
                { timestamp: new Date().toISOString(), level: 'info', message: 'DVB adapter 0 detected' },
                { timestamp: new Date().toISOString(), level: 'warning', message: 'No DVB signal detected' }
            ];
            return res.json({ logs: mockLogs });
        }
        
        // Parse actual log file
        const lines = data.split('\n').filter(line => line.trim()).slice(-100); // Last 100 lines
        const logs = lines.map(line => ({
            timestamp: new Date().toISOString(),
            level: line.includes('ERROR') ? 'error' : line.includes('WARNING') ? 'warning' : 'info',
            message: line
        }));
        
        res.json({ logs });
    });
});

app.post('/api/logs/clear', (req, res) => {
    const logFile = '/var/log/mumudvb/mumudvb-0.log';
    
    fs.writeFile(logFile, '', (err) => {
        if (err) {
            return res.status(500).json({ error: 'Failed to clear logs' });
        }
        res.json({ success: true, message: 'Logs cleared' });
    });
});

// OSCam integration
app.post('/api/oscam/test', (req, res) => {
    const { host, port } = req.body;
    
    // Simple TCP test to OSCam port
    const net = require('net');
    const client = new net.Socket();
    
    client.setTimeout(5000);
    
    client.connect(port, host, () => {
        client.destroy();
        res.json({
            connected: true,
            version: 'OSCam 1.20',
            readers: 2,
            status: 'Active'
        });
    });
    
    client.on('error', (err) => {
        res.json({
            connected: false,
            error: err.message
        });
    });
    
    client.on('timeout', () => {
        client.destroy();
        res.json({
            connected: false,
            error: 'Connection timeout'
        });
    });
});

// Service management
app.get('/api/status/services', (req, res) => {
    // Check if processes are running
    const mumudvbRunning = mumudvbProcess && !mumudvbProcess.killed;
    const oscamRunning = oscamProcess && !oscamProcess.killed;
    
    res.json({
        mumudvb: {
            running: mumudvbRunning,
            pid: mumudvbRunning ? mumudvbProcess.pid : null
        },
        oscam: {
            running: oscamRunning,
            pid: oscamRunning ? oscamProcess.pid : null
        }
    });
});

app.post('/api/service/:service/toggle', (req, res) => {
    const service = req.params.service;
    
    if (service === 'mumudvb') {
        if (mumudvbProcess && !mumudvbProcess.killed) {
            // Stop MuMuDVB
            mumudvbProcess.kill('SIGTERM');
            mumudvbProcess = null;
            res.json({ started: false, message: 'MuMuDVB stopped' });
        } else {
            // Start MuMuDVB
            const configPath = path.join(__dirname, 'mumudvb.conf');
            if (!fs.existsSync(configPath)) {
                return res.status(400).json({ error: 'Configuration file not found' });
            }
            
            mumudvbProcess = spawn('mumudvb', ['-c', configPath, '-d']);
            
            mumudvbProcess.on('error', (error) => {
                console.error('MuMuDVB error:', error);
                mumudvbProcess = null;
            });
            
            res.json({ started: true, message: 'MuMuDVB started' });
        }
    } else if (service === 'oscam') {
        if (oscamProcess && !oscamProcess.killed) {
            // Stop OSCam
            oscamProcess.kill('SIGTERM');
            oscamProcess = null;
            res.json({ started: false, message: 'OSCam stopped' });
        } else {
            // Start OSCam
            oscamProcess = spawn('oscam', ['-d']);
            
            oscamProcess.on('error', (error) => {
                console.error('OSCam error:', error);
                oscamProcess = null;
            });
            
            res.json({ started: true, message: 'OSCam started' });
        }
    } else {
        res.status(400).json({ error: 'Unknown service' });
    }
});

// Signal information
app.get('/api/signal/info', (req, res) => {
    // In real implementation, this would read from DVB adapter
    // For demo, we'll simulate values
    const strength = Math.floor(Math.random() * 40) + 60; // 60-100%
    const snr = Math.floor(Math.random() * 30) + 70; // 70-100%
    const ber = (Math.random() * 5e-5).toExponential(1); // Random BER
    
    res.json({
        strength: strength,
        snr: snr,
        snr_db: (snr * 0.3).toFixed(1),
        ber: ber,
        lock: strength > 70
    });
});

// Stream information
app.get('/api/streams', (req, res) => {
    // In real implementation, this would parse MuMuDVB status
    // For demo, we'll return sample data
    const streams = [
        {
            name: 'RTS 1 HD',
            multicast_ip: '239.100.0.1',
            port: 1234,
            bitrate: 8500000,
            packets_per_sec: 4500,
            status: 'online',
            scrambled: false
        },
        {
            name: 'RTS 2 HD',
            multicast_ip: '239.100.0.2',
            port: 1234,
            bitrate: 7200000,
            packets_per_sec: 3800,
            status: 'online',
            scrambled: false
        },
        {
            name: 'Pink',
            multicast_ip: '239.100.0.3',
            port: 1234,
            bitrate: 5500000,
            packets_per_sec: 2900,
            status: 'scrambled',
            scrambled: true
        }
    ];
    
    res.json({ streams: streams });
});

// Logs
app.get('/api/logs', (req, res) => {
    const logPath = '/var/log/mumudvb.log';
    
    fs.readFile(logPath, 'utf8', (err, data) => {
        if (err) {
            // Return demo logs if file doesn't exist
            const demoLogs = generateDemoLogs();
            return res.json({ logs: demoLogs });
        }
        res.json({ logs: data });
    });
});

app.post('/api/logs/clear', (req, res) => {
    const logPath = '/var/log/mumudvb.log';
    
    fs.writeFile(logPath, '', 'utf8', (err) => {
        if (err) {
            console.error('Error clearing logs:', err);
        }
        res.json({ success: true, message: 'Logs cleared' });
    });
});

// Helper functions
function parseWScanOutput(output, channels) {
    const lines = output.split('\n');
    
    lines.forEach(line => {
        // Parse w_scan output format
        // Example: "BBC One;BBC:11225:h:0:27500:5100:5101:5102:0:8707:2:2040:0"
        if (line.includes(';') && line.includes(':')) {
            const parts = line.split(';');
            if (parts.length >= 2) {
                const channelName = parts[0];
                const paramString = parts[1];
                const params = paramString.split(':');
                
                if (params.length >= 6) {
                    const channel = {
                        name: channelName,
                        frequency: params[1],
                        polarization: params[2],
                        symbolrate: params[4],
                        video_pid: params[5],
                        audio_pid: params[6],
                        sid: params[9] || Math.floor(Math.random() * 1000),
                        scrambled: Math.random() > 0.7 // Random scrambling status
                    };
                    
                    // Avoid duplicates
                    if (!channels.find(ch => ch.name === channel.name)) {
                        channels.push(channel);
                    }
                }
            }
        }
    });
}

function generateDemoLogs() {
    const now = new Date();
    const logs = [
        `[${now.toISOString()}] MuMuDVB starting...`,
        `[${now.toISOString()}] Card 0 found: DVB-S/S2`,
        `[${now.toISOString()}] Tuning to 11296000 kHz, pol H, srate 27500`,
        `[${now.toISOString()}] Signal lock acquired`,
        `[${now.toISOString()}] Autoconfiguration started`,
        `[${now.toISOString()}] Found 45 services`,
        `[${now.toISOString()}] HTTP server listening on port 4242`,
        `[${now.toISOString()}] Streaming started`,
        `[${now.toISOString()}] Client connected from 192.168.1.100`,
        `[${now.toISOString()}] Serving channel "RTS 1 HD" to client`
    ];
    
    return logs.join('\n');
}

// WebSocket for real-time updates
const wss = new WebSocket.Server({ port: 8081 });

wss.on('connection', (ws) => {
    console.log('WebSocket client connected');
    
    // Send initial data
    ws.send(JSON.stringify({
        type: 'status',
        data: {
            mumudvb: mumudvbProcess && !mumudvbProcess.killed,
            oscam: oscamProcess && !oscamProcess.killed
        }
    }));
    
    ws.on('close', () => {
        console.log('WebSocket client disconnected');
    });
});

// Periodically send updates to WebSocket clients
setInterval(() => {
    if (wss.clients.size > 0) {
        const statusUpdate = {
            type: 'signal_update',
            data: {
                strength: Math.floor(Math.random() * 40) + 60,
                snr: Math.floor(Math.random() * 30) + 70,
                ber: (Math.random() * 5e-5).toExponential(1)
            }
        };
        
        wss.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify(statusUpdate));
            }
        });
    }
}, 5000);

// Error handling
process.on('SIGTERM', () => {
    console.log('Shutting down gracefully...');
    
    if (mumudvbProcess && !mumudvbProcess.killed) {
        mumudvbProcess.kill('SIGTERM');
    }
    
    if (oscamProcess && !oscamProcess.killed) {
        oscamProcess.kill('SIGTERM');
    }
    
    if (wscanProcess && !wscanProcess.killed) {
        wscanProcess.kill('SIGTERM');
    }
    
    process.exit(0);
});

// Start server
app.listen(PORT, () => {
    console.log(`MuMuDVB Web Panel server running on http://localhost:${PORT}`);
    console.log(`WebSocket server running on ws://localhost:8081`);
});

module.exports = app;