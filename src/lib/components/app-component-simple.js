/**
 * Main Application Component - Simplified Version
 * Basic Vue.js component with core functionality
 */

import { getLanguageAbbreviation } from '../utils/language.js'

const AVAILABLE_LANGUAGES = [
  'English', 'Chinese', 'Spanish', 'French', 'German',
  'Japanese', 'Korean', 'Russian', 'Arabic', 'Hindi', 'All'
]

export default {
  name: 'AlouetteApp',

  data() {
    return {
      // UI State
      showSettings: false,
      showTauriWarning: true,
      logoError: false,

      // Input and Selection
      inputText: '',
      selectedLanguages: [],
      availableLanguages: AVAILABLE_LANGUAGES,

      // Current state
      currentTranslation: null,
      isTranslating: false,

      // TTS state
      playingText: null,
      isPlayingAll: false,
      isTesting: false,

      // Configuration state
      llmConfig: {
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        apiKey: '',
        selectedModel: ''
      },
      ttsSettings: {
        rate: 1.0,
        volume: 1.0,
        pauseBetweenLanguages: 500,
        autoSelectVoice: true
      },

      // Connection state
      isTestingConnection: false,
      connectionStatus: null,
      availableModels: [],

      // Cache state
      cacheInfo: null,
      isRefreshingCache: false,
      isClearingCache: false
    }
  },

  mounted() {
    console.log('🎉 Alouette app component mounted')
    this.loadConfigurationFromStorage()
    this.checkTauriEnvironment()
  },

  computed: {
    isConfigured() {
      return this.llmConfig.serverUrl && this.llmConfig.selectedModel
    },

    isAllSelected() {
      const realLanguages = this.availableLanguages.filter(lang => lang !== 'All')
      const selectedRealLanguages = this.selectedLanguages.filter(lang => lang !== 'All')
      return selectedRealLanguages.length === realLanguages.length && realLanguages.length > 0
    },

    orderedLanguages() {
      if (!this.currentTranslation?.translations) return []
      return Object.keys(this.currentTranslation.translations)
    },

    // Template compatibility properties
    llmProvider: {
      get() { return this.llmConfig.provider },
      set(value) { this.llmConfig.provider = value }
    },

    serverUrl: {
      get() { return this.llmConfig.serverUrl },
      set(value) { this.llmConfig.serverUrl = value }
    },

    selectedModel: {
      get() { return this.llmConfig.selectedModel },
      set(value) { this.llmConfig.selectedModel = value }
    }
  },

  methods: {
    // ===================
    // Language Display
    // ===================

    getLanguageAbbreviation(languageName) {
      return getLanguageAbbreviation(languageName)
    },

    // ===================
    // Initialization
    // ===================

    loadConfigurationFromStorage() {
      // Load LLM config
      this.llmConfig.provider = localStorage.getItem('llmProvider') || 'ollama'
      this.llmConfig.serverUrl = localStorage.getItem('serverUrl') || 'http://localhost:11434'
      this.llmConfig.selectedModel = localStorage.getItem('selectedModel') || ''
      this.llmConfig.apiKey = localStorage.getItem('apiKey') || ''

      // Load TTS settings
      this.ttsSettings.rate = parseFloat(localStorage.getItem('ttsRate')) || 1.0
      this.ttsSettings.volume = parseFloat(localStorage.getItem('ttsVolume')) || 1.0
      this.ttsSettings.pauseBetweenLanguages = parseInt(localStorage.getItem('ttsPause')) || 500
      this.ttsSettings.autoSelectVoice = localStorage.getItem('ttsAutoSelect') !== 'false'
    },

    checkTauriEnvironment() {
      const isTauri = !!(
        window.__TAURI__ ||
        window.__TAURI_INTERNALS__ ||
        window.__TAURI_METADATA__
      )
      this.showTauriWarning = !isTauri
    },

    // ===================
    // Translation
    // ===================

    async translateText() {
      if (!this.inputText.trim() || this.selectedLanguages.length === 0) {
        alert('Please enter text and select target languages')
        return
      }

      if (!this.isConfigured) {
        alert('Please configure your LLM provider first')
        this.showSettings = true
        return
      }

      this.isTranslating = true

      try {
        // Import and use translation service dynamically
        const { invoke } = await import('@tauri-apps/api/core')

        const realSelectedLanguages = this.selectedLanguages.filter(lang => lang !== 'All')

        const result = await invoke('translate_text', {
          request: {
            text: this.inputText,
            target_languages: realSelectedLanguages,
            provider: this.llmConfig.provider,
            server_url: this.llmConfig.serverUrl,
            model_name: this.llmConfig.selectedModel,
            api_key: this.llmConfig.apiKey || null
          }
        })

        this.currentTranslation = {
          original: this.inputText,
          translations: result.translations,
          timestamp: new Date().toISOString()
        }

        console.log('Translation completed successfully:', result)

      } catch (error) {
        console.error('Translation failed:', error)
        alert(`Translation failed: ${error.message || error}`)
      } finally {
        this.isTranslating = false
      }
    },

    clearInput() {
      this.inputText = ''
      this.selectedLanguages = []
    },

    clearAll() {
      this.inputText = ''
      this.selectedLanguages = []
      this.currentTranslation = null
      this.playingText = null
      this.isPlayingAll = false
    },

    focusTranslateInput() {
      // Focus on the translation input
      this.$nextTick(() => {
        const inputElement = document.querySelector('.translation-input')
        if (inputElement) {
          inputElement.focus()
        }
      })
    },

    // ===================
    // Language Selection
    // ===================

    toggleSelectAll(event) {
      const realLanguages = this.availableLanguages.filter(lang => lang !== 'All')

      if (event.target.checked) {
        this.selectedLanguages = [...realLanguages]
      } else {
        this.selectedLanguages = []
      }
    },

    // ===================
    // TTS
    // ===================

    async playTTS(text, lang, showAlert = true) {
      console.log(`🎵 [FRONTEND-TTS] Starting TTS playback`);
      console.log(`🎵 [FRONTEND-TTS] Text: "${text.substring(0, 100)}${text.length > 100 ? '...' : ''}"`);
      console.log(`🎵 [FRONTEND-TTS] Language: ${lang}`);
      console.log(`🎵 [FRONTEND-TTS] Show alert on error: ${showAlert}`);
      
      try {
        console.log(`🔄 [FRONTEND-TTS] Importing Tauri API...`);
        const { invoke } = await import('@tauri-apps/api/core');
        
        console.log(`🔄 [FRONTEND-TTS] Setting playing state...`);
        this.playingText = text;
        
        console.log(`🔄 [FRONTEND-TTS] Invoking play_tts command...`);
        const startTime = Date.now();
        
        await invoke('play_tts', { text: text, lang: lang });
        
        const duration = Date.now() - startTime;
        console.log(`✅ [FRONTEND-TTS] TTS playback completed successfully in ${duration}ms`);
        
        this.playingText = null;
      } catch (error) {
        console.error(`❌ [FRONTEND-TTS] TTS playback failed:`, error);
        console.error(`❌ [FRONTEND-TTS] Error details:`, {
          message: error.message || 'Unknown error',
          stack: error.stack || 'No stack trace',
          type: typeof error,
          text: text.substring(0, 50),
          lang: lang
        });
        
        this.playingText = null;
        
        if (showAlert) {
          alert(`TTS failed: ${error.message || error}`);
        }
        throw error; // Re-throw so calling functions can handle it
      }
    },

    async playAll() {
      if (!this.currentTranslation || this.isPlayingAll) return

      console.log(`🎵 [FRONTEND-PLAY-ALL] Starting play all`);
      console.log(`🎵 [FRONTEND-PLAY-ALL] Languages to play: ${this.orderedLanguages.join(', ')}`);
      console.log(`🎵 [FRONTEND-PLAY-ALL] Pause between languages: ${this.ttsSettings.pauseBetweenLanguages}ms`);

      this.isPlayingAll = true
      try {
        for (const [index, lang] of this.orderedLanguages.entries()) {
          if (this.currentTranslation.translations[lang]) {
            console.log(`🎵 [FRONTEND-PLAY-ALL] Playing ${index + 1}/${this.orderedLanguages.length}: ${lang}`);
            
            await this.playTTS(this.currentTranslation.translations[lang], lang, false);
            
            if (index < this.orderedLanguages.length - 1) {
              console.log(`⏸️ [FRONTEND-PLAY-ALL] Pausing for ${this.ttsSettings.pauseBetweenLanguages}ms`);
              await new Promise(resolve => setTimeout(resolve, this.ttsSettings.pauseBetweenLanguages));
            }
          } else {
            console.log(`⚠️ [FRONTEND-PLAY-ALL] No translation found for ${lang}`);
          }
        }
        console.log(`✅ [FRONTEND-PLAY-ALL] Play all completed successfully`);
      } catch (error) {
        console.error(`❌ [FRONTEND-PLAY-ALL] Play all failed:`, error);
        alert(`Playback failed: ${error.message || error}`);
      } finally {
        this.isPlayingAll = false;
        this.playingText = null;
      }
    },

    stopPlayAll() {
      this.isPlayingAll = false
      this.playingText = null
    },

    async testTTS() {
      console.log(`🧪 [FRONTEND-TTS-TEST] Starting TTS test`);
      
      this.isTesting = true
      try {
        console.log(`🧪 [FRONTEND-TTS-TEST] Calling playTTS with test message`);
        await this.playTTS('Hello! This is a TTS test.', 'English', false) // Don't show alert in playTTS
        console.log(`✅ [FRONTEND-TTS-TEST] TTS test completed successfully`);
        alert('✅ TTS test completed successfully!')
      } catch (error) {
        console.error(`❌ [FRONTEND-TTS-TEST] TTS test failed:`, error);
        alert(`❌ TTS test failed: ${error.message || error}`)
      } finally {
        this.isTesting = false
      }
    },

    // ===================
    // Configuration
    // ===================

    onProviderChange() {
      // Update default server URL based on provider
      if (this.llmConfig.provider === 'ollama') {
        this.llmConfig.serverUrl = 'http://localhost:11434'
      } else if (this.llmConfig.provider === 'lmstudio') {
        this.llmConfig.serverUrl = 'http://localhost:1234'
      }

      // Clear existing model selection
      this.llmConfig.selectedModel = ''
      this.availableModels = []
      this.connectionStatus = null
    },

    async testConnection() {
      if (!this.llmConfig.serverUrl) {
        this.connectionStatus = { type: 'error', message: 'Please enter server address' }
        return
      }

      this.isTestingConnection = true
      this.connectionStatus = { type: 'info', message: 'Testing connection...' }

      try {
        const { invoke } = await import('@tauri-apps/api/core')

        const models = await invoke('connect_llm', {
          provider: this.llmConfig.provider,
          serverUrl: this.llmConfig.serverUrl,
          apiKey: this.llmConfig.apiKey || null
        })

        this.availableModels = models
        this.connectionStatus = {
          type: 'success',
          message: `Found ${models.length} models`
        }

        // Auto-select first model if none selected
        if (!this.llmConfig.selectedModel && models.length > 0) {
          this.llmConfig.selectedModel = models[0]
        }

      } catch (error) {
        this.connectionStatus = {
          type: 'error',
          message: error.message || error
        }
        this.availableModels = []
      } finally {
        this.isTestingConnection = false
      }
    },

    saveSettings() {
      // Save to localStorage
      localStorage.setItem('llmProvider', this.llmConfig.provider)
      localStorage.setItem('serverUrl', this.llmConfig.serverUrl)
      localStorage.setItem('selectedModel', this.llmConfig.selectedModel)
      localStorage.setItem('apiKey', this.llmConfig.apiKey)

      localStorage.setItem('ttsRate', this.ttsSettings.rate.toString())
      localStorage.setItem('ttsVolume', this.ttsSettings.volume.toString())
      localStorage.setItem('ttsPause', this.ttsSettings.pauseBetweenLanguages.toString())
      localStorage.setItem('ttsAutoSelect', this.ttsSettings.autoSelectVoice.toString())

      alert('Settings saved successfully!')
      this.showSettings = false
    },

    cancelSettings() {
      // Restore settings from localStorage without saving current changes
      this.llmConfig.provider = localStorage.getItem('llmProvider') || ''
      this.llmConfig.serverUrl = localStorage.getItem('serverUrl') || ''
      this.llmConfig.selectedModel = localStorage.getItem('selectedModel') || ''
      this.llmConfig.apiKey = localStorage.getItem('apiKey') || ''

      this.ttsSettings.rate = parseFloat(localStorage.getItem('ttsRate') || '1')
      this.ttsSettings.volume = parseFloat(localStorage.getItem('ttsVolume') || '1')
      this.ttsSettings.pauseBetweenLanguages = parseInt(localStorage.getItem('ttsPause') || '500')
      this.ttsSettings.autoSelectVoice = localStorage.getItem('ttsAutoSelect') === 'true'

      this.showSettings = false
    },

    // ===================
    // Cache Management
    // ===================

    async refreshCacheInfo() {
      if (this.showTauriWarning) return

      this.isRefreshingCache = true
      try {
        const { invoke } = await import('@tauri-apps/api/core')
        this.cacheInfo = await invoke('get_tts_cache_info')
      } catch (error) {
        console.error('Failed to refresh cache info:', error)
      } finally {
        this.isRefreshingCache = false
      }
    },

    async clearCache() {
      if (!confirm('Are you sure you want to clear all TTS cache?')) return

      this.isClearingCache = true
      try {
        const { invoke } = await import('@tauri-apps/api/core')
        const freedSize = await invoke('clear_tts_cache')
        const freedMB = (freedSize / (1024 * 1024)).toFixed(2)
        alert(`Cache cleared! Freed ${freedMB} MB`)
        await this.refreshCacheInfo()
      } catch (error) {
        alert(`Failed to clear cache: ${error.message}`)
      } finally {
        this.isClearingCache = false
      }
    },

    // ===================
    // Utility Methods
    // ===================

    formatServerUrl(url) {
      if (!url) return 'Not Set'
      try {
        const urlObj = new URL(url)
        return urlObj.host
      } catch {
        return url.length > 30 ? url.substring(0, 27) + '...' : url
      }
    },

    getLanguageClass(language) {
      return `lang-${language.toLowerCase().replace(/\s+/g, '-')}`
    },

    // ===================
    // Logo Management
    // ===================

    handleLogoError() {
      console.log('Logo image failed to load, switching to SVG fallback')
      this.logoError = true
    },
  }
}
