/**
 * Local Storage Management Utilities
 * Provides centralized access to localStorage with defaults
 */

/**
 * Storage keys for the application
 */
export const STORAGE_KEYS = {
    LLM_PROVIDER: 'llmProvider',
    SERVER_URL: 'serverUrl',
    API_KEY: 'apiKey',
    SELECTED_MODEL: 'selectedModel',
    OLLAMA_URL: 'ollamaUrl', // Legacy support
    TTS_RATE: 'ttsRate',
    TTS_VOLUME: 'ttsVolume',
    TTS_PAUSE: 'ttsPause',
    TTS_AUTO_SELECT: 'ttsAutoSelect'
}

/**
 * Default values for settings
 */
export const DEFAULT_VALUES = {
    LLM_PROVIDER: 'ollama',
    SERVER_URL: '',
    API_KEY: '',
    SELECTED_MODEL: '',
    OLLAMA_URL: 'http://localhost:11434',
    TTS_RATE: 0.8,
    TTS_VOLUME: 0.9,
    TTS_PAUSE: 500,
    TTS_AUTO_SELECT: true
}

/**
 * Get a value from localStorage with default fallback
 * @param {string} key - Storage key
 * @param {any} defaultValue - Default value if key doesn't exist
 * @returns {any} Stored value or default
 */
export const getStorageValue = (key, defaultValue = null) => {
    try {
        const stored = localStorage.getItem(key)
        if (stored === null) return defaultValue

        // Handle boolean values
        if (defaultValue === true || defaultValue === false) {
            return stored !== 'false'
        }

        // Handle numeric values
        if (typeof defaultValue === 'number') {
            const parsed = parseFloat(stored)
            return isNaN(parsed) ? defaultValue : parsed
        }

        // Handle integers
        if (key === STORAGE_KEYS.TTS_PAUSE) {
            const parsed = parseInt(stored)
            return isNaN(parsed) ? defaultValue : parsed
        }

        return stored
    } catch (error) {
        console.warn(`Failed to get storage value for key "${key}":`, error)
        return defaultValue
    }
}

/**
 * Set a value in localStorage
 * @param {string} key - Storage key
 * @param {any} value - Value to store
 */
export const setStorageValue = (key, value) => {
    try {
        localStorage.setItem(key, String(value))
    } catch (error) {
        console.warn(`Failed to set storage value for key "${key}":`, error)
    }
}

/**
 * Remove a value from localStorage
 * @param {string} key - Storage key
 */
export const removeStorageValue = (key) => {
    try {
        localStorage.removeItem(key)
    } catch (error) {
        console.warn(`Failed to remove storage value for key "${key}":`, error)
    }
}

/**
 * Load TTS settings from localStorage
 * @returns {Object} TTS settings object
 */
export const loadTTSSettings = () => {
    return {
        rate: getStorageValue(STORAGE_KEYS.TTS_RATE, DEFAULT_VALUES.TTS_RATE),
        volume: getStorageValue(STORAGE_KEYS.TTS_VOLUME, DEFAULT_VALUES.TTS_VOLUME),
        pauseBetweenLanguages: getStorageValue(STORAGE_KEYS.TTS_PAUSE, DEFAULT_VALUES.TTS_PAUSE),
        autoSelectVoice: getStorageValue(STORAGE_KEYS.TTS_AUTO_SELECT, DEFAULT_VALUES.TTS_AUTO_SELECT)
    }
}

/**
 * Save TTS settings to localStorage
 * @param {Object} settings - TTS settings object
 */
export const saveTTSSettings = (settings) => {
    setStorageValue(STORAGE_KEYS.TTS_RATE, settings.rate)
    setStorageValue(STORAGE_KEYS.TTS_VOLUME, settings.volume)
    setStorageValue(STORAGE_KEYS.TTS_PAUSE, settings.pauseBetweenLanguages)
    setStorageValue(STORAGE_KEYS.TTS_AUTO_SELECT, settings.autoSelectVoice)
}

/**
 * Load LLM configuration from localStorage
 * @returns {Object} LLM configuration object
 */
export const loadLLMConfig = () => {
    return {
        provider: getStorageValue(STORAGE_KEYS.LLM_PROVIDER, DEFAULT_VALUES.LLM_PROVIDER),
        serverUrl: getStorageValue(STORAGE_KEYS.SERVER_URL, DEFAULT_VALUES.SERVER_URL),
        apiKey: getStorageValue(STORAGE_KEYS.API_KEY, DEFAULT_VALUES.API_KEY),
        selectedModel: getStorageValue(STORAGE_KEYS.SELECTED_MODEL, DEFAULT_VALUES.SELECTED_MODEL),
        // Legacy support
        ollamaUrl: getStorageValue(STORAGE_KEYS.OLLAMA_URL, DEFAULT_VALUES.OLLAMA_URL)
    }
}

/**
 * Save LLM configuration to localStorage
 * @param {Object} config - LLM configuration object
 */
export const saveLLMConfig = (config) => {
    setStorageValue(STORAGE_KEYS.LLM_PROVIDER, config.provider)
    setStorageValue(STORAGE_KEYS.SERVER_URL, config.serverUrl)
    setStorageValue(STORAGE_KEYS.API_KEY, config.apiKey)
    setStorageValue(STORAGE_KEYS.SELECTED_MODEL, config.selectedModel)
}

/**
 * Migrate legacy configuration
 * @returns {Object|null} Migrated configuration or null if no migration needed
 */
export const migrateLegacyConfig = () => {
    const hasLegacyConfig = !getStorageValue(STORAGE_KEYS.LLM_PROVIDER) &&
        getStorageValue(STORAGE_KEYS.OLLAMA_URL)

    if (hasLegacyConfig) {
        console.log('Migrating legacy Ollama configuration...')
        const legacyUrl = getStorageValue(STORAGE_KEYS.OLLAMA_URL, DEFAULT_VALUES.OLLAMA_URL)

        const migratedConfig = {
            provider: 'ollama',
            serverUrl: legacyUrl,
            apiKey: '',
            selectedModel: getStorageValue(STORAGE_KEYS.SELECTED_MODEL, '')
        }

        saveLLMConfig(migratedConfig)
        return migratedConfig
    }

    return null
}
