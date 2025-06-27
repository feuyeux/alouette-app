/**
 * Main Application Component
 * Vue.js component integrating all services and utilities
 */

import { TTSService } from '../services/ttsService.js'
import { TranslationService } from '../services/translationService.js'
import { LLMConfigService } from '../services/llmConfigService.js'
import { CacheService } from '../services/cacheService.js'

import {
    isTauriEnv,
    isAndroid,
    getDefaultServerUrl,
    logPlatformInfo
} from '../utils/environment.js'

import {
    AVAILABLE_LANGUAGES,
    detectLanguage,
    isAllLanguagesSelected,
    getRealLanguages
} from '../utils/language.js'

import {
    loadTTSSettings,
    saveTTSSettings,
    loadLLMConfig,
    saveLLMConfig,
    migrateLegacyConfig
} from '../utils/storage.js'

export default {
    name: 'App',

    data() {
        return {
            // Translation input and output
            inputText: '',
            selectedLanguages: [],
            availableLanguages: AVAILABLE_LANGUAGES,

            // UI state
            showTauriWarning: false,
            showSettings: false,
            isTesting: false,

            // Services
            ttsService: null,
            translationService: null,
            llmConfigService: null,
            cacheService: null,

            // Settings loaded from storage
            ttsSettings: {},
            llmConfig: {}
        }
    },

    async mounted() {
        console.log('Alouette application initializing...')

        // Log platform information
        logPlatformInfo()

        // Initialize services
        this.initializeServices()

        // Load settings from storage
        this.loadSettings()

        // Handle legacy configuration migration
        this.handleLegacyMigration()

        // Check Tauri environment
        if (!isTauriEnv()) {
            this.showTauriWarning = true
        } else {
            // Initialize cache information
            await this.initializeCache()
        }

        this.logInitializationComplete()
    },

    computed: {
        /**
         * Check if LLM provider is properly configured
         */
        isConfigured() {
            return this.llmConfig.serverUrl && this.llmConfig.selectedModel
        },

        /**
         * Check if all real languages are selected
         */
        isAllSelected() {
            return isAllLanguagesSelected(this.selectedLanguages)
        },

        /**
         * Get current translation from translation service
         */
        currentTranslation() {
            return this.translationService?.getCurrentTranslation()
        },

        /**
         * Check if translation is in progress
         */
        isTranslating() {
            return this.translationService?.getTranslationState().isTranslating || false
        },

        /**
         * Get TTS playback state
         */
        ttsState() {
            return this.ttsService?.getPlaybackState() || {
                playingText: null,
                isPlayingAll: false,
                isPlaying: false
            }
        },

        /**
         * Get LLM connection state
         */
        llmState() {
            return {
                isTestingConnection: this.llmConfigService?.isTestingConnectionStatus() || false,
                connectionStatus: this.llmConfigService?.getConnectionStatus(),
                availableModels: this.llmConfigService?.getAvailableModels() || []
            }
        },

        /**
         * Get cache state
         */
        cacheState() {
            return this.cacheService?.getCacheState() || {
                cacheInfo: null,
                isRefreshingCache: false,
                isClearingCache: false,
                hasCache: false,
                stats: null
            }
        }
    },

    methods: {
        // ===================
        // Initialization
        // ===================

        /**
         * Initialize all services
         */
        initializeServices() {
            this.ttsService = new TTSService()
            this.translationService = new TranslationService()
            this.llmConfigService = new LLMConfigService()
            this.cacheService = new CacheService()
        },

        /**
         * Load settings from localStorage
         */
        loadSettings() {
            this.ttsSettings = loadTTSSettings()
            this.llmConfig = loadLLMConfig()

            // Set platform-specific defaults if needed
            if (!this.llmConfig.serverUrl) {
                this.llmConfig.serverUrl = getDefaultServerUrl(this.llmConfig.provider)
            }
        },

        /**
         * Handle legacy configuration migration
         */
        handleLegacyMigration() {
            const migratedConfig = migrateLegacyConfig()
            if (migratedConfig) {
                this.llmConfig = { ...this.llmConfig, ...migratedConfig }
                console.log('Legacy configuration migrated successfully')
            }
        },

        /**
         * Initialize cache information
         */
        async initializeCache() {
            try {
                await this.cacheService.refreshCacheInfo()
            } catch (error) {
                console.warn('Failed to load cache information:', error)
            }
        },

        /**
         * Log initialization completion
         */
        logInitializationComplete() {
            console.log('Configuration loaded:', {
                platform: isAndroid() ? 'Android' : 'Desktop',
                llmProvider: this.llmConfig.provider,
                serverUrl: this.llmConfig.serverUrl,
                selectedModel: this.llmConfig.selectedModel,
                ttsSettings: this.ttsSettings
            })
        },

        // ===================
        // Language Selection
        // ===================

        /**
         * Toggle language selection
         */
        toggleLanguage(language) {
            if (language === 'All') {
                this.toggleAllLanguages()
                return
            }

            const index = this.selectedLanguages.indexOf(language)
            if (index === -1) {
                this.selectedLanguages.push(language)
            } else {
                this.selectedLanguages.splice(index, 1)
            }

            // Update 'All' selection based on individual selections
            this.updateAllSelection()
        },

        /**
         * Toggle all languages selection
         */
        toggleAllLanguages() {
            const realLanguages = getRealLanguages()
            if (this.isAllSelected) {
                this.selectedLanguages = []
            } else {
                this.selectedLanguages = [...realLanguages]
            }
        },

        /**
         * Update 'All' selection based on individual selections
         */
        updateAllSelection() {
            // This is handled by the computed property isAllSelected
            // No action needed here, but kept for compatibility
        },

        // ===================
        // Translation
        // ===================

        /**
         * Translate the input text
         */
        async translateText() {
            try {
                await this.translationService.translateText(
                    this.inputText,
                    this.selectedLanguages,
                    this.llmConfig
                )
            } catch (error) {
                alert(error.message)
            }
        },

        /**
         * Save current translation to file
         */
        async saveTranslation() {
            if (!this.currentTranslation) {
                alert('No translation available to save')
                return
            }

            const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
            const filename = `translation_${timestamp}.txt`

            try {
                const savedPath = await this.translationService.saveTranslation(filename, 'txt')
                alert(`Translation saved successfully to: ${savedPath}`)
            } catch (error) {
                alert(error.message)
            }
        },

        // ===================
        // TTS Functionality
        // ===================

        /**
         * Play TTS for specific text and language
         */
        async playTTS(text, lang) {
            await this.ttsService.playTTS(text, lang, this.ttsSettings)
        },

        /**
         * Play all translations sequentially
         */
        async playAll() {
            if (!this.currentTranslation || this.ttsState.isPlayingAll) return

            console.log('Starting sequential playback of all translations')
            this.ttsService.isPlayingAll = true

            try {
                // Auto-detect language for original text
                const originalLanguage = detectLanguage(this.currentTranslation.original)
                console.log(`Auto-detected original language: ${originalLanguage}`)

                // Play original text
                await this.ttsService.playTTSPromise(this.currentTranslation.original, originalLanguage)

                // Wait between languages
                if (this.ttsSettings.pauseBetweenLanguages > 0) {
                    await new Promise(resolve => setTimeout(resolve, this.ttsSettings.pauseBetweenLanguages))
                }

                // Play all translations
                for (const lang of this.selectedLanguages) {
                    if (this.currentTranslation.translations[lang]) {
                        await this.ttsService.playTTSPromise(this.currentTranslation.translations[lang], lang)

                        // Wait between languages (except for the last one)
                        if (this.ttsSettings.pauseBetweenLanguages > 0 &&
                            lang !== this.selectedLanguages[this.selectedLanguages.length - 1]) {
                            await new Promise(resolve => setTimeout(resolve, this.ttsSettings.pauseBetweenLanguages))
                        }
                    }
                }

                console.log('✅ Sequential playback completed successfully')

            } catch (error) {
                console.error('❌ Sequential playback failed:', error)
                alert(`Playback failed: ${error.message || error}`)
            } finally {
                this.ttsService.isPlayingAll = false
            }
        },

        /**
         * Test TTS functionality
         */
        async testTTS() {
            this.isTesting = true
            try {
                const testText = "Hello! This is a TTS test."
                const testLang = "English"

                await this.ttsService.testTTS(testText, testLang, this.ttsSettings)
                alert('✅ TTS test completed successfully!')
            } catch (error) {
                // Error already handled by TTS service
            } finally {
                this.isTesting = false
            }
        },

        // ===================
        // LLM Configuration
        // ===================

        /**
         * Test LLM connection
         */
        async testConnection() {
            try {
                const result = await this.llmConfigService.testConnection(this.llmConfig)
                alert(`✅ Connection successful!\\n\\nFound ${result.models.length} models.`)
            } catch (error) {
                alert(error.message)
            }
        },

        /**
         * Save LLM configuration
         */
        saveConfiguration() {
            saveLLMConfig(this.llmConfig)
            saveTTSSettings(this.ttsSettings)
            alert('Configuration saved successfully!')
            this.showSettings = false
        },

        // ===================
        // Cache Management
        // ===================

        /**
         * Refresh cache information
         */
        async refreshCacheInfo() {
            try {
                await this.cacheService.refreshCacheInfo()
            } catch (error) {
                alert(error.message)
            }
        },

        /**
         * Clear TTS cache
         */
        async clearCache() {
            if (!confirm('Are you sure you want to clear all TTS cache? This will delete all cached voice files.')) {
                return
            }

            try {
                const result = await this.cacheService.clearCache()
                alert(result.message)
            } catch (error) {
                alert(error.message)
            }
        },

        // ===================
        // Utility Methods
        // ===================

        /**
         * Format server URL for display
         */
        formatServerUrl(url) {
            if (!url) return 'Not Set'

            try {
                const urlObj = new URL(url)
                return urlObj.host
            } catch (error) {
                return url.length > 30 ? url.substring(0, 27) + '...' : url
            }
        },

        /**
         * Detect language of input text
         */
        detectLanguage(text) {
            return detectLanguage(text)
        }
    }
}
