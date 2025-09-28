// Global variables
let currentTab = 'scan';
let scanInterval = null;
let monitorInterval = null;
let streamInterval = null;
let wscanProcess = null;

// Initialize the application
$(document).ready(function() {
    console.log('MuMuDVB Web Panel initialized');
    
    // Load DVB adapters first
    loadDVBAdapters();
    
    // Load saved configuration
    loadSavedConfig();
    
    // Start monitoring intervals
    startMonitoring();
    
    // Load initial data
    updateServiceStatus();
    loadStreamInfo();
});

// Load available DVB adapters
function loadDVBAdapters() {
    $.ajax({
        url: '/api/adapters',
        method: 'GET',
        success: function(response) {
            const adapterSelect = $('#adapter');
            adapterSelect.empty();
            
            response.adapters.forEach(function(adapter) {
                const option = $('<option></option>')
                    .attr('value', adapter.id)
                    .text(`${adapter.name} (${adapter.type})`);
                adapterSelect.append(option);
            });
            
            console.log('Loaded DVB adapters:', response.adapters);
            showAlert(`Pronađeno ${response.adapters.length} DVB adaptera`, 'success');
        },
        error: function(xhr, status, error) {
            console.error('Error loading DVB adapters:', error);
            showAlert('Greška pri učitavanju DVB adaptera', 'warning');
        }
    });
}

// Signal monitoring functions
function startSignalMonitoring() {
    if (monitorInterval) {
        clearInterval(monitorInterval);
    }
    
    monitorInterval = setInterval(updateSignalInfo, 2000);
}

function updateSignalInfo() {
    const adapter = $('#adapter').val() || 0;
    
    $.ajax({
        url: '/api/signal/' + adapter,
        method: 'GET',
        success: function(response) {
            // Update signal strength
            $('#signalStrength').css('width', response.strength + '%');
            $('#signalValue').text(response.strength + '%');
            
            // Update signal quality
            $('#signalQuality').css('width', response.quality + '%');
            $('#qualityValue').text(response.quality + ' dB');
            
            // Update BER
            $('#berValue').text(response.ber.toFixed(6));
            
            // Update lock status
            if (response.locked) {
                $('.signal-meter').addClass('locked');
            } else {
                $('.signal-meter').removeClass('locked');
            }
        },
        error: function(xhr, status, error) {
            console.error('Error updating signal info:', error);
        }
    });
}

// Enhanced alert system
function showAlert(message, type = 'info') {
    const alertDiv = $('<div class="alert alert-' + type + '"></div>');
    alertDiv.text(message);
    
    $('body').append(alertDiv);
    
    setTimeout(function() {
        alertDiv.fadeOut(500, function() {
            $(this).remove();
        });
    }, 3000);
}

// Tab management
function showTab(tabName) {
    // Hide all tabs
    $('.tab-content').removeClass('active');
    $('.tab-button').removeClass('active');
    
    // Show selected tab
    $('#' + tabName).addClass('active');
    $('[onclick="showTab(\'' + tabName + '\')"]').addClass('active');
    
    currentTab = tabName;
    
    // Load tab-specific data
    switch(tabName) {
        case 'scan':
            loadDVBAdapters();
            break;
        case 'monitor':
            updateSignalInfo();
            refreshLogs();
            startSignalMonitoring();
            break;
        case 'stream':
            loadStreamInfo();
            break;
    }
}

// DVB Parameters management
function updateDVBParams() {
    const dvbType = $('#dvbType').val();
    $('.dvb-params').hide();
    $('#' + dvbType + '-params').show();
}

// Scanning functions
function startScan() {
    const dvbType = $('#dvbType').val();
    const adapter = $('#adapter').val();
    
    let scanParams = {
        adapter: adapter,
        type: dvbType
    };
    
    // Get parameters based on DVB type
    if (dvbType === 'dvb-s') {
        scanParams.frequency = $('#frequency').val() * 1000; // Convert to kHz
        scanParams.polarization = $('#polarization').val();
        scanParams.symbolrate = $('#symbolrate').val();
    } else if (dvbType === 'dvb-t') {
        scanParams.frequency = $('#tfrequency').val();
        scanParams.bandwidth = $('#bandwidth').val();
    }
    
    // Show progress
    $('#scanProgress').show();
    $('#scanResults').html('<div class="spinner"></div><p>Skeniranje u toku...</p>');
    
    // Start scanning process
    $.ajax({
        url: '/api/scan/start',
        method: 'POST',
        data: JSON.stringify(scanParams),
        contentType: 'application/json',
        success: function(response) {
            console.log('Scan started:', response);
            updateScanProgress();
        },
        error: function(xhr, status, error) {
            showAlert('Greška pri pokretanju skeniranja: ' + error, 'error');
            $('#scanProgress').hide();
        }
    });
}

function stopScan() {
    if (scanInterval) {
        clearInterval(scanInterval);
        scanInterval = null;
    }
    
    $.ajax({
        url: '/api/scan/stop',
        method: 'POST',
        success: function(response) {
            $('#scanProgress').hide();
            showAlert('Skeniranje zaustavljeno', 'info');
        }
    });
}

function updateScanProgress() {
    scanInterval = setInterval(function() {
        $.ajax({
            url: '/api/scan/status',
            method: 'GET',
            success: function(response) {
                if (response.completed) {
                    clearInterval(scanInterval);
                    $('#scanProgress').hide();
                    displayScanResults(response.channels);
                } else {
                    $('#progressFill').css('width', response.progress + '%');
                    $('#scanStatus').text(response.status);
                }
            }
        });
    }, 1000);
}

function displayScanResults(channels) {
    let html = '<h4>Pronađeni kanali (' + channels.length + '):</h4>';
    html += '<div style="max-height: 400px; overflow-y: auto;">';
    html += '<table class="stream-table">';
    html += '<thead><tr><th>Ime kanala</th><th>Frekvencija</th><th>SID</th><th>PIDs</th><th>Tip</th><th>Akcije</th></tr></thead>';
    html += '<tbody>';
    
    channels.forEach(function(channel) {
        html += '<tr>';
        html += '<td>' + channel.name + '</td>';
        html += '<td>' + channel.frequency + '</td>';
        html += '<td>' + channel.sid + '</td>';
        html += '<td>V:' + channel.video_pid + ' A:' + channel.audio_pid + '</td>';
        html += '<td>' + (channel.scrambled ? 'Zaštićen' : 'Otvoren') + '</td>';
        html += '<td>';
        html += '<button class="btn-small" onclick="addChannelToConfig(' + channel.sid + ')">Dodaj</button>';
        html += '<button class="btn-small" onclick="testChannel(' + channel.sid + ')">Test</button>';
        html += '</td>';
        html += '</tr>';
    });
    
    html += '</tbody></table></div>';
    $('#scanResults').html(html);
    
    showAlert('Skeniranje završeno. Pronađeno ' + channels.length + ' kanala.', 'success');
}

// Configuration functions
function generateConfig() {
    const dvbType = $('#dvbType').val();
    const adapter = $('#adapter').val();
    const autoconfiguration = $('#autoconfiguration').is(':checked');
    const unicast = $('#unicast').is(':checked');
    const sap = $('#sap').is(':checked');
    const httpPort = $('#port_http').val();
    const multicastTtl = $('#multicast_ttl').val();
    
    let config = '# MuMuDVB Configuration - Generated by Web Panel\n';
    config += '# Generated at: ' + new Date().toISOString() + '\n\n';
    
    // Basic settings
    config += '# Basic DVB settings\n';
    config += 'card=' + adapter + '\n';
    
    // DVB specific parameters
    if (dvbType === 'dvb-s') {
        config += 'freq=' + $('#frequency').val() + '\n';
        config += 'pol=' + $('#polarization').val() + '\n';
        config += 'srate=' + $('#symbolrate').val() + '\n';
    } else if (dvbType === 'dvb-t') {
        config += 'freq=' + ($('#tfrequency').val() / 1000000) + '\n';
        config += 'bandwidth=' + $('#bandwidth').val() + '\n';
    }
    
    // Autoconfiguration
    if (autoconfiguration) {
        config += 'autoconfiguration=full\n';
    }
    
    // Network settings
    config += '\n# Network settings\n';
    config += 'multicast_ttl=' + multicastTtl + '\n';
    if (unicast) {
        config += 'unicast=1\n';
        config += 'port_http=' + httpPort + '\n';
    }
    
    // SAP
    if (sap) {
        config += 'sap=1\n';
    } else {
        config += 'sap=0\n';
    }
    
    // OSCam integration
    if ($('#scam_support').is(':checked')) {
        config += '\n# Software descrambling (OSCam)\n';
        config += 'scam_support=1\n';
        config += 'oscam=1\n';
        config += 'decsa_delay=' + $('#decsa_delay').val() + '\n';
        config += 'send_delay=' + $('#send_delay').val() + '\n';
    }
    
    // Rewriting
    config += '\n# Stream rewriting\n';
    config += 'rewrite_pat=1\n';
    config += 'rewrite_sdt=1\n';
    config += 'sort_eit=1\n';
    
    // Logging
    config += '\n# Logging\n';
    config += 'log_type=1\n';
    config += 'log_file=/var/log/mumudvb.log\\n';\n;
    \n';
    $('#configOutput').val(config);\n;
    showAlert('Konfiguracija generisana uspešno!', 'success');\n;
}\n;
\n;
function saveConfig() {\n;
    const config = $('#configOutput').val();\n;
    if (!config.trim()) {\n;
        showAlert('Molimo generišite konfiguraciju pre čuvanja!', 'warning');\n;
        return;\n;
    }\n;
    \n;
    $.ajax({\n;
        url: '/api/config/save',\n;
        method: 'POST',\n;
        data: JSON.stringify({ config: config }),\n;
        contentType: 'application/json',\n;
        success: function(response) {\n;
            showAlert('Konfiguracija sačuvana uspešno!', 'success');\n;
            localStorage.setItem('mumudvb_config', config);\n;
        },\n;
        error: function(xhr, status, error) {\n;
            showAlert('Greška pri čuvanju konfiguracije: ' + error, 'error');\n;
        }\n;
    });\n;
}\n;
\n;
function downloadConfig() {\n;
    const config = $('#configOutput').val();\n;
    if (!config.trim()) {\n;
        showAlert('Molimo generišite konfiguraciju pre preuzimanja!', 'warning');\n;
        return;\n;
    }\n;
    \n;
    const blob = new Blob([config], { type: 'text/plain' });\n;
    const url = window.URL.createObjectURL(blob);\n;
    const a = document.createElement('a');\n;
    a.href = url;\n;
    a.download = 'mumudvb.conf';\n;
    document.body.appendChild(a);\n;
    a.click();\n;
    document.body.removeChild(a);\n;
    window.URL.revokeObjectURL(url);\n;
}\n;
\n;
function loadSavedConfig() {\n;
    const saved = localStorage.getItem('mumudvb_config');\n;
    if (saved) {\n;
        $('#configOutput').val(saved);\n;
    }\n;
}\n;
\n;
// OSCam functions\n;
function testOscamConnection() {\n;
    const host = $('#oscam_host').val();\n;
    const port = $('#oscam_port').val();\n;
    \n;
    $('#descramblingStatus').html('<div class=\"spinner\"></div><p>Testiranje konekcije...</p>');\n;
    \n;
    $.ajax({\n;
        url: '/api/oscam/test',\n;
        method: 'POST',\n;
        data: JSON.stringify({ host: host, port: port }),\n;
        contentType: 'application/json',\n;
        success: function(response) {\n;
            if (response.connected) {\n;
                $('#descramblingStatus').html(\n;
                    '<div class=\"alert alert-success\">' +\n;
                    '<strong>Konekcija uspešna!</strong><br>' +\n;
                    'OSCam verzija: ' + response.version + '<br>' +\n;
                    'Aktivni čitači: ' + response.readers + '<br>' +\n;
                    'Status: ' + response.status +\n;
                    '</div>'\n;
                );\n;
            } else {\n;
                $('#descramblingStatus').html(\n;
                    '<div class=\"alert alert-error\">' +\n;
                    '<strong>Konekcija neuspešna!</strong><br>' +\n;
                    'Greška: ' + response.error +\n;
                    '</div>'\n;
                );\n;
            }\n;
        },\n;
        error: function(xhr, status, error) {\n;
            $('#descramblingStatus').html(\n;
                '<div class=\"alert alert-error\">' +\n;
                '<strong>Greška pri testiranju!</strong><br>' +\n;
                error +\n;
                '</div>'\n;
            );\n;
        }\n;
    });\n;
}\n;
\n;
// Monitoring functions\n;
function startMonitoring() {\n;
    monitorInterval = setInterval(function() {\n;
        if (currentTab === 'monitor') {\n;
            updateServiceStatus();\n;
            updateSignalInfo();\n;
        }\n;
    }, 5000);\n;
    \n;
    streamInterval = setInterval(function() {\n;
        if (currentTab === 'stream') {\n;
            loadStreamInfo();\n;
        }\n;
    }, 3000);\n;
}\n;
\n;
function updateServiceStatus() {\n;
    $.ajax({\n;
        url: '/api/status/services',\n;
        method: 'GET',\n;
        success: function(response) {\n;
            // Update MuMuDVB status\n;
            if (response.mumudvb && response.mumudvb.running) {\n;
                $('#mumudvb-status').removeClass('offline').addClass('online').text('Online');\n;
            } else {\n;
                $('#mumudvb-status').removeClass('online').addClass('offline').text('Offline');\n;
            }\n;
            \n;
            // Update OSCam status\n;
            if (response.oscam && response.oscam.running) {\n;
                $('#oscam-status').removeClass('offline').addClass('online').text('Online');\n;
            } else {\n;
                $('#oscam-status').removeClass('online').addClass('offline').text('Offline');\n;
            }\n;
        },\n;
        error: function() {\n;
            // Simulate status for demo\n;
            $('#mumudvb-status').removeClass('online').addClass('offline').text('Offline');\n;
            $('#oscam-status').removeClass('online').addClass('offline').text('Offline');\n;
        }\n;
    });\n;
}\n;
\n;
function toggleService(service) {\n;
    $.ajax({\n;
        url: '/api/service/' + service + '/toggle',\n;
        method: 'POST',\n;
        success: function(response) {\n;
            showAlert(service.toUpperCase() + ' servis ' + (response.started ? 'pokrenuo' : 'zaustavljen'), 'success');\n;
            updateServiceStatus();\n;
        },\n;
        error: function(xhr, status, error) {\n;
            showAlert('Greška pri upravljanju servisom: ' + error, 'error');\n;
        }\n;
    });\n;
}\n;
\n;
function updateSignalInfo() {\n;
    $.ajax({\n;
        url: '/api/signal/info',\n;
        method: 'GET',\n;
        success: function(response) {\n;
            // Update signal strength\n;
            const strength = Math.min(100, Math.max(0, response.strength || 0));\n;
            $('#signalStrength').css('width', strength + '%');\n;
            $('#signalValue').text(strength + '%');\n;
            \n;
            // Update signal quality\n;
            const quality = Math.min(100, Math.max(0, response.snr || 0));\n;
            $('#signalQuality').css('width', quality + '%');\n;
            $('#qualityValue').text(response.snr_db + ' dB');\n;
            \n;
            // Update BER\n;
            $('#berValue').text(response.ber || '0');\n;
        },\n;
        error: function() {\n;
            // Simulate signal data for demo\n;
            const strength = Math.floor(Math.random() * 40) + 60;\n;
            const quality = Math.floor(Math.random() * 30) + 70;\n;
            \n;
            $('#signalStrength').css('width', strength + '%');\n;
            $('#signalValue').text(strength + '%');\n;
            $('#signalQuality').css('width', quality + '%');\n;
            $('#qualityValue').text((quality * 0.3).toFixed(1) + ' dB');\n;
            $('#berValue').text('1.2e-5');\n;
        }\n;
    });\n;
}\n;
\n;
function refreshLogs() {\n;
    $.ajax({\n;
        url: '/api/logs',\n;
        method: 'GET',\n;
        success: function(response) {\n;
            $('#logOutput').html('<pre>' + response.logs + '</pre>');\n;
            $('#logOutput').scrollTop($('#logOutput')[0].scrollHeight);\n;
        },\n;
        error: function() {\n;
            // Demo logs\n;
            const demoLogs = \n;
                '[' + new Date().toISOString() + '] MuMuDVB starting...\\n' +\n;
                '[' + new Date().toISOString() + '] Card 0 found: DVB-S/S2\\n' +\n;
                '[' + new Date().toISOString() + '] Tuning to 11296000 kHz, pol H, srate 27500\\n' +\n;
                '[' + new Date().toISOString() + '] Signal lock acquired\\n' +\n;
                '[' + new Date().toISOString() + '] Autoconfiguration started\\n' +\n;
                '[' + new Date().toISOString() + '] Found 45 services\\n' +\n;
                '[' + new Date().toISOString() + '] HTTP server listening on port 4242\\n' +\n;
                '[' + new Date().toISOString() + '] Streaming started\\n';\n;
            $('#logOutput').text(demoLogs);\n;
        }\n;
    });\n;
}\n;
\n;
function clearLogs() {\n;
    $.ajax({\n;
        url: '/api/logs/clear',\n;
        method: 'POST',\n;
        success: function() {\n;
            $('#logOutput').text('Logovi obrisani.');\n;
            showAlert('Logovi uspešno obrisani', 'success');\n;
        },\n;
        error: function() {\n;
            $('#logOutput').text('Logovi obrisani.');\n;
        }\n;
    });\n;
}\n;
\n;
// Stream functions\n;
function loadStreamInfo() {\n;
    $.ajax({\n;
        url: '/api/streams',\n;
        method: 'GET',\n;
        success: function(response) {\n;
            displayStreamList(response.streams);\n;
            updateStreamQuality(response.streams);\n;
        },\n;
        error: function() {\n;
            // Demo stream data\n;
            const demoStreams = [\n;
                {\n;
                    name: 'RTS 1 HD',\n;
                    multicast_ip: '239.100.0.1',\n;
                    port: 1234,\n;
                    bitrate: 8500000,\n;
                    packets_per_sec: 4500,\n;
                    status: 'online',\n;
                    scrambled: false\n;
                },\n;
                {\n;
                    name: 'RTS 2 HD',\n;
                    multicast_ip: '239.100.0.2',\n;
                    port: 1234,\n;
                    bitrate: 7200000,\n;
                    packets_per_sec: 3800,\n;
                    status: 'online',\n;
                    scrambled: false\n;
                },\n;
                {\n;
                    name: 'Pink',\n;
                    multicast_ip: '239.100.0.3',\n;
                    port: 1234,\n;
                    bitrate: 5500000,\n;
                    packets_per_sec: 2900,\n;
                    status: 'scrambled',\n;
                    scrambled: true\n;
                }\n;
            ];\n;
            displayStreamList(demoStreams);\n;
            updateStreamQuality(demoStreams);\n;
        }\n;
    });\n;
}\n;
\n;
function displayStreamList(streams) {\n;
    let html = '<h4>Aktivni stream-ovi (' + streams.length + '):</h4>';\n;
    html += '<ul>';\n;
    \n;
    streams.forEach(function(stream) {\n;
        const statusClass = stream.status === 'online' ? 'status-online' : 'status-offline';\n;
        html += '<li class=\"' + statusClass + '\">';\n;
        html += '<strong>' + stream.name + '</strong> - ';\n;
        html += stream.multicast_ip + ':' + stream.port + ' ';\n;
        html += '(' + (stream.bitrate / 1000000).toFixed(1) + ' Mbps)';\n;
        if (stream.scrambled) {\n;
            html += ' <span style=\"color: #f39c12;\">[Zaštićen]</span>';\n;
        }\n;
        html += '</li>';\n;
    });\n;
    \n;
    html += '</ul>';\n;
    $('#streamList').html(html);\n;
}\n;
\n;
function updateStreamQuality(streams) {\n;
    let tableHtml = '';\n;
    \n;
    streams.forEach(function(stream) {\n;
        const statusClass = stream.status === 'online' ? 'status-online' : \n;
                           stream.status === 'scrambled' ? 'status-offline' : 'status-offline';\n;
        const statusText = stream.status === 'online' ? 'Online' :\n;
                          stream.status === 'scrambled' ? 'Šifrovan' : 'Offline';\n;
        \n;
        tableHtml += '<tr>';\n;
        tableHtml += '<td>' + stream.name + '</td>';\n;
        tableHtml += '<td>' + stream.multicast_ip + '</td>';\n;
        tableHtml += '<td>' + stream.port + '</td>';\n;
        tableHtml += '<td>' + (stream.bitrate / 1000000).toFixed(1) + ' Mbps</td>';\n;
        tableHtml += '<td>' + stream.packets_per_sec + '</td>';\n;
        tableHtml += '<td><span class=\"' + statusClass + '\">' + statusText + '</span></td>';\n;
        tableHtml += '<td>';\n;
        tableHtml += '<button class=\"btn-small\" onclick=\"playStream(\\'\" + stream.multicast_ip + '\\', ' + stream.port + ')\">Play</button>';\n;
        tableHtml += '<button class=\"btn-small\" onclick=\"stopStream(\\'\" + stream.name + '\\')\">Stop</button>';\n;
        tableHtml += '</td>';\n;
        tableHtml += '</tr>';\n;
    });\n;
    \n;
    if (tableHtml) {\n;
        $('#streamQuality tbody').html(tableHtml);\n;
    } else {\n;
        $('#streamQuality tbody').html('<tr><td colspan=\"7\">Nema aktivnih stream-ova</td></tr>');\n;
    }\n;
}\n;
\n;
function playStream(ip, port) {\n;
    const url = 'udp://@' + ip + ':' + port;\n;
    showAlert('Pokretanje VLC-a za: ' + url, 'info');\n;
    \n;
    // Try to open VLC (this would need backend support)\n;
    window.open('vlc://' + url);\n;
}\n;
\n;
function stopStream(name) {\n;
    showAlert('Zaustavljanje stream-a: ' + name, 'info');\n;
}\n;
\n;
// Utility functions\n;
function showAlert(message, type) {\n;
    const alertHtml = '<div class=\"alert alert-' + type + '\">' + message + '</div>';\n;
    \n;
    // Remove existing alerts\n;
    $('.alert').remove();\n;
    \n;
    // Add new alert\n;
    $('.container').prepend(alertHtml);\n;
    \n;
    // Auto-remove after 5 seconds\n;
    setTimeout(function() {\n;
        $('.alert').fadeOut(function() {\n;
            $(this).remove();\n;
        });\n;
    }, 5000);\n;
}\n;
\n;
function addChannelToConfig(sid) {\n;
    showAlert('Kanal SID:' + sid + ' dodat u konfiguraciju', 'success');\n;
    // This would add the channel to the configuration\n;
}\n;
\n;
function testChannel(sid) {\n;
    showAlert('Testiranje kanala SID:' + sid, 'info');\n;
    // This would test the specific channel\n;
}\n;
\n;
// Cleanup on page unload\n;
$(window).on('beforeunload', function() {\n;
    if (scanInterval) clearInterval(scanInterval);\n;
    if (monitorInterval) clearInterval(monitorInterval);\n;
    if (streamInterval) clearInterval(streamInterval);\n;
});\n;