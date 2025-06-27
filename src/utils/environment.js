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
    if (isAndroid()) {
        // For Android, default to a common local network IP
        return provider === 'ollama' ? 'http://192.168.1.100:11434' : 'http://192.168.1.100:1234'
    } else {
        return provider === 'ollama' ? 'http://localhost:11434' : 'http://localhost:1234'
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
