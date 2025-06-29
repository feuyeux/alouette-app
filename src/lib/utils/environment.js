/**
 * Environment Detection Utilities
 * Provides functions to detect Tauri environment and platform
 */

/**
 * Check if the application is running in Tauri environment
 * @returns {boolean} True if running in Tauri, false otherwise
 */
export const isTauriEnv = () => {
    if (typeof window === 'undefined') return false

    // Check for multiple possible Tauri global variables
    return !!(
        window.__TAURI__ ||
        window.__TAURI_INTERNALS__ ||
        window.__TAURI_METADATA__ ||
        (window.navigator && window.navigator.userAgent && window.navigator.userAgent.includes('Tauri'))
    )
}

/**
 * Check if running on Android platform
 * @returns {boolean} True if running on Android
 */
export const isAndroid = () => {
    return navigator.userAgent.toLowerCase().includes('android') ||
        window.location.hostname.includes('tauri.localhost')
}

/**
 * Get platform-specific default server URLs
 * @param {string} provider - LLM provider ('ollama' or 'lmstudio')
 * @returns {string} Default server URL for the platform
 */
export const getDefaultServerUrl = (provider = 'ollama') => {
    // Check for environment variable OLLAMA_HOST first
    const ollamaHost = getOllamaHost()
    
    if (provider === 'ollama' && ollamaHost) {
        return `http://${ollamaHost}:11434`
    }
    
    if (isAndroid()) {
        // For Android, default to the IP you provided
        return provider === 'ollama' ? 'http://192.168.31.228:11434' : 'http://192.168.31.228:1234'
    } else {
        return provider === 'ollama' ? 'http://localhost:11434' : 'http://localhost:1234'
    }
}

/**
 * Get OLLAMA_HOST from environment variables or storage
 * @returns {string|null} OLLAMA_HOST value or null if not set
 */
export const getOllamaHost = () => {
    // Try to get from environment variable (for desktop/server environments)
    if (typeof process !== 'undefined' && process.env && process.env.OLLAMA_HOST) {
        return process.env.OLLAMA_HOST
    }
    
    // Try to get from localStorage (for web/mobile environments)
    if (typeof localStorage !== 'undefined') {
        const storedHost = localStorage.getItem('OLLAMA_HOST')
        if (storedHost) {
            return storedHost
        }
    }
    
    return null
}

/**
 * Set OLLAMA_HOST globally
 * @param {string} host - The host IP address or hostname
 */
export const setOllamaHost = (host) => {
    if (typeof localStorage !== 'undefined') {
        if (host) {
            localStorage.setItem('OLLAMA_HOST', host)
        } else {
            localStorage.removeItem('OLLAMA_HOST')
        }
    }
}

/**
 * Log platform information for debugging
 */
export const logPlatformInfo = () => {
    const platform = isAndroid() ? 'Android' : 'Desktop'
    const tauriDetected = isTauriEnv()

    console.log('Platform Detection Results:', {
        platform,
        tauriDetected,
        userAgent: navigator.userAgent,
        hostname: window.location.hostname
    })

    if (isAndroid()) {
        console.log('🤖 Android environment detected')
    }

    if (!tauriDetected) {
        console.warn('Application not running in Tauri environment - some features may be limited')
    } else {
        console.log('✅ Tauri environment detected')
    }
}
