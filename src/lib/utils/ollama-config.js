/**
 * Ollama Configuration Management
 * Handles OLLAMA_HOST configuration across different environments
 */

import { getOllamaHost, setOllamaHost } from './environment.js'

export class OllamaConfig {
  /**
   * Get the current OLLAMA_HOST configuration
   * @returns {string|null} Current OLLAMA_HOST or null if not set
   */
  static getHost() {
    return getOllamaHost()
  }

  /**
   * Set the OLLAMA_HOST configuration
   * @param {string} host - The host IP address or hostname (without http:// and port)
   */
  static setHost(host) {
    // Clean the host input (remove protocol and port if provided)
    const cleanHost = host
      .replace(/^https?:\/\//, '') // Remove protocol
      .replace(/:.*$/, '') // Remove port
      .trim()
    
    setOllamaHost(cleanHost)
    
    // Log for debugging
    console.log(`OLLAMA_HOST set to: ${cleanHost}`)
    
    return cleanHost
  }

  /**
   * Clear the OLLAMA_HOST configuration
   */
  static clearHost() {
    setOllamaHost(null)
    console.log('OLLAMA_HOST cleared')
  }

  /**
   * Get the full Ollama URL with the configured host
   * @returns {string} Full Ollama URL
   */
  static getFullUrl() {
    const host = this.getHost()
    if (host) {
      return `http://${host}:11434`
    }
    
    // Fallback to default
    return 'http://localhost:11434'
  }

  /**
   * Test if the configured Ollama host is reachable
   * @returns {Promise<boolean>} True if reachable, false otherwise
   */
  static async testConnection() {
    const url = this.getFullUrl()
    
    try {
      const response = await fetch(`${url}/api/tags`, {
        method: 'GET',
        signal: AbortSignal.timeout(5000) // 5 second timeout
      })
      
      return response.ok
    } catch (error) {
      console.warn(`Failed to connect to Ollama at ${url}:`, error.message)
      return false
    }
  }

  /**
   * Auto-detect available Ollama hosts on common network ranges
   * @returns {Promise<string[]>} Array of reachable hosts
   */
  static async autoDetectHosts() {
    const commonHosts = [
      'localhost',
      '127.0.0.1',
      '192.168.1.100',
      '192.168.1.101',
      '192.168.1.102',
      '192.168.31.228', // User's specific IP
      '192.168.0.100',
      '192.168.0.101',
      '10.0.2.2' // Android emulator host
    ]

    const reachableHosts = []
    
    for (const host of commonHosts) {
      try {
        const response = await fetch(`http://${host}:11434/api/tags`, {
          method: 'GET',
          signal: AbortSignal.timeout(2000) // 2 second timeout for auto-detection
        })
        
        if (response.ok) {
          reachableHosts.push(host)
        }
      } catch (error) {
        // Ignore connection errors during auto-detection
      }
    }

    return reachableHosts
  }

  /**
   * Get configuration status and recommendations
   * @returns {Promise<object>} Configuration status object
   */
  static async getStatus() {
    const currentHost = this.getHost()
    const currentUrl = this.getFullUrl()
    const isReachable = await this.testConnection()
    
    return {
      host: currentHost,
      url: currentUrl,
      isConfigured: !!currentHost,
      isReachable,
      recommendations: currentHost ? [] : await this.autoDetectHosts()
    }
  }

  /**
   * Initialize with the best available configuration
   * @returns {Promise<string>} The configured host
   */
  static async autoInitialize() {
    const currentHost = this.getHost()
    
    // If already configured and reachable, use it
    if (currentHost && await this.testConnection()) {
      console.log(`Using existing OLLAMA_HOST: ${currentHost}`)
      return currentHost
    }
    
    // Try to auto-detect
    const availableHosts = await this.autoDetectHosts()
    
    if (availableHosts.length > 0) {
      const bestHost = availableHosts[0] // Use the first reachable host
      this.setHost(bestHost)
      console.log(`Auto-configured OLLAMA_HOST: ${bestHost}`)
      return bestHost
    }
    
    // No reachable hosts found
    console.warn('No reachable Ollama hosts found')
    return null
  }
}

// Export convenience functions
export const { getHost, setHost, clearHost, getFullUrl, testConnection, autoDetectHosts, getStatus, autoInitialize } = OllamaConfig
