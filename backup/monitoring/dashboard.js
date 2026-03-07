/**
 * Dashboard JavaScript
 * Handles all API calls and interactions via the FastAPI proxy
 */

// API Base URL - uses proxy endpoints
var API_BASE = '/api';

/**
 * Refresh all dashboard data
 */
function refreshAll() {
    document.getElementById('last-updated').textContent = new Date().toLocaleTimeString();
    checkCurrentAgent();
    checkApiHealth();
}

/**
 * Check current agent on Letta Server
 */
function checkCurrentAgent() {
    var div = document.getElementById("current-agent");
    div.innerHTML = "Checking...";
    
    fetch(API_BASE + "/agents")
        .then(function(response) { return response.json(); })
        .then(function(agents) {
            if (!agents || agents.length === 0) {
                div.innerHTML = '<span class="warning">No agents found. Create one below!</span>';
            } else {
                var agent = agents[0];
                var html = "<span class='success'>Agent Found!</span><br>Name: " + 
                    (agent.name || "Unnamed") + "<br>Model: " + 
                    agent.model + "<br>ID: " + agent.id;
                div.innerHTML = html;
            }
        })
        .catch(function(e) {
            div.innerHTML = "<span class='error'>Error: " + e.message + "</span>";
        });
}

/**
 * List all agents on Letta Server
 */
function listAgents() {
    var div = document.getElementById('agent-list');
    div.innerHTML = 'Loading...';
    
    fetch(API_BASE + "/agents")
        .then(function(response) { return response.json(); })
        .then(function(agents) {
            if (!agents || agents.length === 0) {
                div.innerHTML = '<span class="warning">No agents found</span>';
            } else {
                var html = '<table><tr><th>Name</th><th>Model</th><th>ID</th></tr>';
                for (var i = 0; i < agents.length; i++) {
                    var a = agents[i];
                    html += '<tr><td>' + (a.name || 'Unnamed') + '</td><td>' + 
                           a.model + '</td><td>' + a.id + '</td></tr>';
                }
                html += '</table>';
                div.innerHTML = html;
            }
        })
        .catch(function(e) {
            div.innerHTML = '<span class="error">Error: ' + e.message + '</span>';
        });
}

/**
 * Create a new agent on Letta Server
 */
function createAgent() {
    var name = document.getElementById('agent-name').value || 'My Agent';
    var model = document.getElementById('agent-model').value;
    var system = document.getElementById('agent-system').value || 'You are a helpful assistant.';
    var resultDiv = document.getElementById('create-result');
    
    resultDiv.style.display = 'block';
    resultDiv.innerHTML = 'Creating...';
    
    fetch(API_BASE + "/agents", {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: name, model: model, system: system })
    })
    .then(function(response) { return response.json(); })
    .then(function(data) {
        if (data.id) {
            resultDiv.innerHTML = '<span class="success">Agent created!</span><br>ID: ' + data.id + 
                '<br><br>To set as Telegram agent, run:<br><code>docker exec letta-bot lettabot model set ' + data.id + '</code>';
        } else {
            resultDiv.innerHTML = '<span class="error">Error: ' + JSON.stringify(data) + '</span>';
        }
    })
    .catch(function(e) {
        resultDiv.innerHTML = '<span class="error">Error: ' + e.message + '</span>';
    });
}

/**
 * Validate Telegram bot token
 */
function validateTelegramBot() {
    var token = document.getElementById('telegram-token').value.trim();
    var statusDiv = document.getElementById('telegram-status');
    
    if (!token) {
        statusDiv.innerHTML = '<span class="warning">Enter a bot token</span>';
        return;
    }
    
    statusDiv.innerHTML = 'Validating...';
    
    // Use the proxy endpoint for Telegram validation
    fetch(API_BASE + "/telegram/validate/" + token)
        .then(function(response) { return response.json(); })
        .then(function(data) {
            if (data.ok) {
                statusDiv.innerHTML = '<span class="success">Bot valid!</span> @' + data.result.username;
            } else {
                statusDiv.innerHTML = '<span class="error">' + data.description + '</span>';
            }
        })
        .catch(function(e) {
            statusDiv.innerHTML = '<span class="error">Error: ' + e.message + '</span>';
        });
}

/**
 * Check pairing requests via API
 */
function checkPairing() {
    var statusDiv = document.getElementById('pairing-status');
    var section = document.getElementById('pairing-section');
    
    statusDiv.innerHTML = 'Checking for pairing requests...';
    
    fetch(API_BASE + "/pairing/list")
        .then(function(response) { return response.json(); })
        .then(function(data) {
            if (data.success) {
                statusDiv.innerHTML = data.output || 'No pending pairing requests';
            } else {
                statusDiv.innerHTML = '<span class="error">Error: ' + (data.error || 'Unknown error') + '</span>';
            }
        })
        .catch(function(e) {
            statusDiv.innerHTML = '<span class="error">Error: ' + e.message + '</span>';
        });
    
    section.style.display = 'block';
}

/**
 * Approve pairing via API
 */
function approvePairing() {
    var code = document.getElementById('pairing-code').value.trim();
    var statusDiv = document.getElementById('pairing-status');
    
    if (!code) {
        statusDiv.innerHTML = '<span class="error">Enter a pairing code</span>';
        return;
    }
    
    statusDiv.innerHTML = 'Approving...';
    
    fetch(API_BASE + "/pairing/approve", {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code: code })
    })
    .then(function(response) { return response.json(); })
    .then(function(data) {
        if (data.success) {
            statusDiv.innerHTML = '<span class="success">Approved!</span><br>' + data.output + 
                '<br><br>LettaBot will notify the user on Telegram.';
        } else {
            statusDiv.innerHTML = '<span class="error">Error: ' + (data.error || 'Unknown error') + '</span>';
        }
    })
    .catch(function(e) {
        statusDiv.innerHTML = '<span class="error">Error: ' + e.message + '</span>';
    });
}

/**
 * Check Letta Server API health
 */
function checkApiHealth() {
    var statusDiv = document.getElementById('api-status');
    statusDiv.innerHTML = 'Checking...';
    
    fetch(API_BASE + "/health")
        .then(function(response) { return response.json(); })
        .then(function(data) {
            if (data.status === 'ok') {
                statusDiv.innerHTML = '<span class="success">Letta API is healthy!</span><br>' + data.message;
            } else {
                statusDiv.innerHTML = '<span class="error">' + data.message + '</span>';
            }
        })
        .catch(function(e) {
            statusDiv.innerHTML = '<span class="error">Cannot connect: ' + e.message + '</span>';
        });
}

// Initialize dashboard on page load
document.addEventListener('DOMContentLoaded', function() {
    refreshAll();
});
