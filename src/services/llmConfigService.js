/**
 * LLM Configuration Service
 * Handles connection and configuration for LLM providers (Ollama, LM Studio)
 */

import { invoke } from '@tauri-apps/api/core'
import { isTauriEnv } from '../utils/environment.js'

/**
 * LLM Configuration Service class
 */
export class LLMConfigService {
    constructor() {
        this.availableModels = []
        this.connectionStatus = null
        this.isTestingConnection = false
    }

    /**
     * Test connection to LLM provider
     * @param {Object} config - LLM configuration
     * @returns {Promise<Object>} Connection test result
     */
    async testConnection(config) {
        if (!isTauriEnv()) {
            throw new Error('Connection testing requires Tauri environment. Please run: npm run dev')
        }

        this.isTestingConnection = true
        this.connectionStatus = null

        try {
            console.log('Testing LLM connection:', {
                provider: config.provider,
                serverUrl: config.serverUrl,
                hasApiKey: !!config.apiKey
            })

            let result
            if (config.provider === 'ollama') {
                result = await invoke('connect_ollama', {
                    url: config.serverUrl
                })
            } else {
                result = await invoke('connect_llm', {
                    provider: config.provider,
                    server_url: config.serverUrl,
                    api_key: config.apiKey || ''
                })
            }

            this.availableModels = result.models || []
            this.connectionStatus = {
                success: true,
                message: `Successfully connected to ${config.provider}`,
                modelCount: this.availableModels.length,
                timestamp: new Date().toISOString()
            }

            console.log('✅ LLM connection successful:', this.connectionStatus)
            console.log('Available models:', this.availableModels)

            return {
                success: true,
                models: this.availableModels,
                message: this.connectionStatus.message
            }

        } catch (error) {
            console.error('❌ LLM connection failed:', error)

            const errorMsg = error.message || error.toString()
            this.connectionStatus = {
                success: false,
                message: this.formatConnectionError(errorMsg, config),
                timestamp: new Date().toISOString()
            }

            throw new Error(this.connectionStatus.message)

        } finally {
            this.isTestingConnection = false
        }
    }

    /**
     * Format connection error message for better user experience
     * @param {string} errorMsg - Raw error message
     * @param {Object} config - LLM configuration
     * @returns {string} Formatted error message
     */
    formatConnectionError(errorMsg, config) {
        if (errorMsg.includes('Connection refused') || errorMsg.includes('ECONNREFUSED')) {
            return `Cannot connect to ${config.provider} server at ${config.serverUrl}. Please ensure the server is running and accessible.`
        } else if (errorMsg.includes('timeout') || errorMsg.includes('ETIMEDOUT')) {
            return `Connection to ${config.provider} server timed out. Please check the server URL and network connectivity.`
        } else if (errorMsg.includes('Not found') || errorMsg.includes('404')) {
            return `${config.provider} server not found at ${config.serverUrl}. Please verify the URL is correct.`
        } else if (errorMsg.includes('Unauthorized') || errorMsg.includes('401')) {
            return `Authentication failed. Please check your API key for ${config.provider}.`
        } else if (errorMsg.includes('network') || errorMsg.includes('DNS')) {
            return `Network error connecting to ${config.provider}. Please check your internet connection and server URL.`
        } else {
            return `Connection failed: ${errorMsg}`
        }
    }

    /**
     * Get TTS voices from the backend
     * @returns {Promise<Object>} Available TTS voices by language
     */
    async getTTSVoices() {
        if (!isTauriEnv()) {
            throw new Error('TTS voice retrieval requires Tauri environment. Please run: npm run dev')
        }

        try {
            console.log('Fetching available TTS voices...')
            const voices = await invoke('get_edge_tts_voices')
            console.log('Available TTS voices:', voices)
            return voices
        } catch (error) {
            console.error('Failed to get TTS voices:', error)
            throw new Error(`Failed to get TTS voices: ${error.message || error}`)
        }
    }

    /**
     * Get available models for current provider
     * @returns {Array} Array of available model names
     */
    getAvailableModels() {
        return this.availableModels
    }

    /**
     * Get connection status
     * @returns {Object|null} Current connection status
     */
    getConnectionStatus() {
        return this.connectionStatus
    }

    /**
     * Check if currently testing connection
     * @returns {boolean} True if testing connection
     */
    isTestingConnectionStatus() {
        return this.isTestingConnection
    }

    /**
     * Validate LLM configuration
     * @param {Object} config - LLM configuration to validate
     * @returns {Object} Validation result
     */
    validateConfig(config) {
        const errors = []
        const warnings = []

        // Required fields
        if (!config.provider) {
            errors.push('LLM provider is required')
        }

        if (!config.serverUrl) {
            errors.push('Server URL is required')
        } else {
            // URL format validation
            try {
                const url = new URL(config.serverUrl)
                if (!['http:', 'https:'].includes(url.protocol)) {
                    errors.push('Server URL must use HTTP or HTTPS protocol')
                }
            } catch (e) {
                errors.push('Server URL format is invalid')
            }
        }

        if (!config.selectedModel) {
            warnings.push('No model selected - you will need to select a model after testing connection')
        }

        // Provider-specific validation
        if (config.provider === 'lmstudio' && !config.apiKey) {
            warnings.push('API key is recommended for LM Studio')
        }

        // URL-specific warnings
        if (config.serverUrl) {
            if (config.serverUrl.includes('localhost') || config.serverUrl.includes('127.0.0.1')) {
                warnings.push('Using localhost - ensure the server is running on this machine')
            }

            if (config.serverUrl.startsWith('http:') && !config.serverUrl.includes('localhost')) {
                warnings.push('Using HTTP (not HTTPS) for remote server - consider using HTTPS for security')
            }
        }

        return {
            isValid: errors.length === 0,
            errors,
            warnings
        }
    }

    /**
     * Get recommended settings for a provider
     * @param {string} provider - LLM provider name
     * @param {boolean} isAndroid - Whether running on Android
     * @returns {Object} Recommended settings
     */
    getRecommendedSettings(provider, isAndroid = false) {
        const baseUrl = isAndroid ? 'http://192.168.1.100' : 'http://localhost'

        switch (provider) {
            case 'ollama':
                return {
                    serverUrl: `${baseUrl}:11434`,
                    apiKey: '',
                    description: 'Ollama typically runs on port 11434',
                    setupInstructions: [
                        'Install Ollama from https://ollama.ai',
                        'Run "ollama serve" to start the server',
                        'Pull a model with "ollama pull llama3.2" or similar'
                    ]
                }

            case 'lmstudio':
                return {
                    serverUrl: `${baseUrl}:1234`,
                    apiKey: '',
                    description: 'LM Studio typically runs on port 1234',
                    setupInstructions: [
                        'Install LM Studio from https://lmstudio.ai',
                        'Load a model in LM Studio',
                        'Start the local server from the server tab'
                    ]
                }

            default:
                return {
                    serverUrl: `${baseUrl}:11434`,
                    apiKey: '',
                    description: 'Default configuration',
                    setupInstructions: []
                }
        }
    }

    /**
     * Clear connection status and models
     */
    clearConnection() {
        this.availableModels = []
        this.connectionStatus = null
        this.isTestingConnection = false
    }
}
