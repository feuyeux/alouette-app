/**
 * Ollama Configuration Component
 * Simple component for configuring OLLAMA_HOST
 */

import { OllamaConfig } from '../utils/ollama-config.js'

export class OllamaConfigComponent {
  constructor() {
    this.status = null
    this.element = null
  }

  /**
   * Create the configuration UI element
   * @returns {HTMLElement} The configuration form element
   */
  createConfigUI() {
    const container = document.createElement('div')
    container.className = 'ollama-config-container'
    container.innerHTML = `
      <div class="config-section">
        <h3>🦙 Ollama Server Configuration</h3>
        
        <div class="config-field">
          <label for="ollama-host">Ollama Host (IP Address):</label>
          <input type="text" id="ollama-host" placeholder="192.168.31.228" />
          <small>Enter IP address without http:// or port (port 11434 will be used automatically)</small>
        </div>
        
        <div class="config-actions">
          <button id="set-host-btn" class="btn-primary">Set Host</button>
          <button id="test-connection-btn" class="btn-secondary">Test Connection</button>
          <button id="auto-detect-btn" class="btn-secondary">Auto Detect</button>
          <button id="clear-host-btn" class="btn-danger">Clear</button>
        </div>
        
        <div id="config-status" class="config-status"></div>
        
        <div id="detected-hosts" class="detected-hosts" style="display: none;">
          <h4>Detected Ollama Servers:</h4>
          <div id="hosts-list"></div>
        </div>
      </div>
    `

    // Add event listeners
    this.setupEventListeners(container)
    
    // Load current status
    this.refreshStatus(container)
    
    this.element = container
    return container
  }

  /**
   * Setup event listeners for the configuration UI
   */
  setupEventListeners(container) {
    const hostInput = container.querySelector('#ollama-host')
    const setBtn = container.querySelector('#set-host-btn')
    const testBtn = container.querySelector('#test-connection-btn')
    const autoDetectBtn = container.querySelector('#auto-detect-btn')
    const clearBtn = container.querySelector('#clear-host-btn')

    // Set host
    setBtn.addEventListener('click', async () => {
      const host = hostInput.value.trim()
      if (host) {
        OllamaConfig.setHost(host)
        await this.refreshStatus(container)
        this.showMessage('Host configured successfully!', 'success')
      }
    })

    // Test connection
    testBtn.addEventListener('click', async () => {
      this.showMessage('Testing connection...', 'info')
      const isReachable = await OllamaConfig.testConnection()
      
      if (isReachable) {
        this.showMessage('✅ Connection successful!', 'success')
      } else {
        this.showMessage('❌ Connection failed. Check host and ensure Ollama is running.', 'error')
      }
    })

    // Auto detect
    autoDetectBtn.addEventListener('click', async () => {
      this.showMessage('Scanning for Ollama servers...', 'info')
      
      const hosts = await OllamaConfig.autoDetectHosts()
      const hostsList = container.querySelector('#hosts-list')
      const detectedSection = container.querySelector('#detected-hosts')
      
      if (hosts.length > 0) {
        detectedSection.style.display = 'block'
        hostsList.innerHTML = hosts.map(host => 
          `<button class="host-option" data-host="${host}">${host}</button>`
        ).join('')
        
        // Add click handlers for detected hosts
        hostsList.querySelectorAll('.host-option').forEach(btn => {
          btn.addEventListener('click', () => {
            hostInput.value = btn.dataset.host
            OllamaConfig.setHost(btn.dataset.host)
            this.refreshStatus(container)
            this.showMessage(`Host set to ${btn.dataset.host}`, 'success')
          })
        })
        
        this.showMessage(`Found ${hosts.length} Ollama server(s)`, 'success')
      } else {
        detectedSection.style.display = 'none'
        this.showMessage('No Ollama servers detected on common network addresses', 'warning')
      }
    })

    // Clear host
    clearBtn.addEventListener('click', () => {
      OllamaConfig.clearHost()
      hostInput.value = ''
      this.refreshStatus(container)
      this.showMessage('Host configuration cleared', 'info')
    })

    // Enter key support
    hostInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        setBtn.click()
      }
    })
  }

  /**
   * Refresh the configuration status display
   */
  async refreshStatus(container) {
    const status = await OllamaConfig.getStatus()
    const statusDiv = container.querySelector('#config-status')
    const hostInput = container.querySelector('#ollama-host')
    
    // Update input with current host
    hostInput.value = status.host || ''
    
    // Update status display
    let statusHTML = `<div class="status-item">
      <strong>Current URL:</strong> ${status.url}
    </div>`
    
    if (status.isConfigured) {
      statusHTML += `<div class="status-item ${status.isReachable ? 'status-success' : 'status-error'}">
        <strong>Status:</strong> ${status.isReachable ? '✅ Connected' : '❌ Not reachable'}
      </div>`
    } else {
      statusHTML += `<div class="status-item status-warning">
        <strong>Status:</strong> ⚠️ Not configured (using default)
      </div>`
    }
    
    statusDiv.innerHTML = statusHTML
    this.status = status
  }

  /**
   * Show a temporary message to the user
   */
  showMessage(message, type = 'info') {
    if (!this.element) return
    
    const existingMessage = this.element.querySelector('.temp-message')
    if (existingMessage) {
      existingMessage.remove()
    }
    
    const messageDiv = document.createElement('div')
    messageDiv.className = `temp-message message-${type}`
    messageDiv.textContent = message
    
    this.element.appendChild(messageDiv)
    
    // Remove message after 3 seconds
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.remove()
      }
    }, 3000)
  }

  /**
   * Get the current configuration status
   */
  getStatus() {
    return this.status
  }
}

// CSS styles for the configuration component
export const configStyles = `
.ollama-config-container {
  max-width: 600px;
  margin: 20px 0;
  padding: 20px;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: #f9f9f9;
}

.config-section h3 {
  margin-top: 0;
  color: #333;
}

.config-field {
  margin: 15px 0;
}

.config-field label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

.config-field input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 14px;
}

.config-field small {
  display: block;
  margin-top: 5px;
  color: #666;
  font-size: 12px;
}

.config-actions {
  margin: 20px 0;
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.config-actions button {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-danger {
  background: #dc3545;
  color: white;
}

.config-actions button:hover {
  opacity: 0.8;
}

.config-status {
  margin: 15px 0;
  padding: 10px;
  background: white;
  border-radius: 4px;
  border: 1px solid #eee;
}

.status-item {
  margin: 5px 0;
}

.status-success {
  color: #28a745;
}

.status-error {
  color: #dc3545;
}

.status-warning {
  color: #ffc107;
}

.detected-hosts {
  margin: 20px 0;
  padding: 15px;
  background: white;
  border-radius: 4px;
  border: 1px solid #eee;
}

.detected-hosts h4 {
  margin-top: 0;
}

#hosts-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.host-option {
  padding: 8px 12px;
  background: #e9ecef;
  border: 1px solid #ced4da;
  border-radius: 4px;
  cursor: pointer;
  font-family: monospace;
}

.host-option:hover {
  background: #dee2e6;
}

.temp-message {
  margin: 10px 0;
  padding: 10px;
  border-radius: 4px;
  font-weight: bold;
}

.message-success {
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.message-error {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.message-warning {
  background: #fff3cd;
  color: #856404;
  border: 1px solid #ffeaa7;
}

.message-info {
  background: #d1ecf1;
  color: #0c5460;
  border: 1px solid #bee5eb;
}
`
