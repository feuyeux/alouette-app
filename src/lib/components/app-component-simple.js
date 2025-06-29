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
      isDiagnosing: false,

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
      try {
        const { invoke } = await import('@tauri-apps/api/core')
        this.playingText = text
        await invoke('play_tts', { text: text, lang: lang })
        this.playingText = null
      } catch (error) {
        this.playingText = null
        if (showAlert) {
          alert(`TTS failed: ${error.message || error}`)
        }
        throw error // Re-throw so calling functions can handle it
      }
    },

    async playAll() {
      if (!this.currentTranslation || this.isPlayingAll) return

      this.isPlayingAll = true
      try {
        // Play original text first
        await this.playTTS(this.currentTranslation.original, 'English', false)

        // Wait between languages
        await new Promise(resolve => setTimeout(resolve, this.ttsSettings.pauseBetweenLanguages))

        // Play all translations
        for (const lang of this.orderedLanguages) {
          if (this.currentTranslation.translations[lang]) {
            await this.playTTS(this.currentTranslation.translations[lang], lang, false)
            await new Promise(resolve => setTimeout(resolve, this.ttsSettings.pauseBetweenLanguages))
          }
        }
      } catch (error) {
        alert(`Playback failed: ${error.message || error}`)
      } finally {
        this.isPlayingAll = false
        this.playingText = null
      }
    },

    stopPlayAll() {
      this.isPlayingAll = false
      this.playingText = null
    },

    async testTTS() {
      this.isTesting = true
      try {
        await this.playTTS('Hello! This is a TTS test.', 'English', false) // Don't show alert in playTTS
        alert('✅ TTS test completed successfully!')
      } catch (error) {
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

    async diagnoseAndroidTTS() {
      this.isDiagnosing = true
      try {
        console.log('Starting Android TTS diagnostics...')
        
        // Import TTS service dynamically to avoid circular dependencies
        const { TTSService } = await import('../services/tts-service.js')
        const ttsService = new TTSService()
        
        // First test WebView TTS initialization
        let webViewTTSReady = false
        if ('speechSynthesis' in window) {
          try {
            webViewTTSReady = await ttsService.initializeAndroidTTS()
          } catch (e) {
            console.log('WebView TTS initialization failed:', e)
          }
        }
        
        const diagnostics = await ttsService.diagnoseAndroidTTS()
        
        // Create a user-friendly diagnostic report
        let report = '🔍 Android TTS Diagnostic Report\n\n'
        
        if (diagnostics.platform === 'android') {
          report += `📱 Platform: Android ${diagnostics.android_version || 'Unknown'}\n`
          report += `⏰ Test Time: ${new Date(diagnostics.timestamp).toLocaleString()}\n\n`
          
          // TTS Service Status
          if (diagnostics.tests.tts_service) {
            const ttsService = diagnostics.tests.tts_service
            report += `🔧 TTS Service: ${ttsService.available ? '✅ Available' : '❌ Not Available'}\n`
            if (ttsService.status) {
              report += `   Status: ${ttsService.status}\n`
            }
          }
          
          // Google TTS Status
          if (diagnostics.tests.google_tts) {
            const googleTts = diagnostics.tests.google_tts
            report += `📢 Google TTS: ${googleTts.installed ? '✅ Installed' : '❌ Not Installed'}\n`
          }
          
          // espeak-ng Status
          if (diagnostics.tests.espeak_ng) {
            const espeak = diagnostics.tests.espeak_ng
            report += `🎤 espeak-ng: ${espeak.available ? '✅ Available' : '❌ Not Available'}\n`
          }
          
          // Browser TTS Support
          const browserTTS = 'speechSynthesis' in window
          const voices = browserTTS ? speechSynthesis.getVoices().length : 0
          report += `🌐 Browser TTS: ${browserTTS ? '✅ Available' : '❌ Not Available'}\n`
          if (browserTTS) {
            report += `   Voices: ${voices} available\n`
            report += `   WebView Ready: ${webViewTTSReady ? '✅ Yes' : '⚠️ Needs initialization'}\n`
          }
          
          // Recommendations
          report += '\n💡 Recommendations:\n'
          
          if (diagnostics.tests.google_tts?.installed && browserTTS) {
            report += '1. ✅ You have Google TTS installed and WebView supports TTS\n'
            report += '2. 🔧 Try the "Test Speech" button to verify functionality\n'
            if (!webViewTTSReady) {
              report += '3. ⚠️ WebView TTS needs initialization - try speaking once to activate\n'
            }
          } else if (!diagnostics.tests.google_tts?.installed) {
            report += '1. 📱 Install Google Text-to-Speech from Play Store\n'
            report += '2. ⚙️ Go to Settings > Accessibility > Text-to-speech\n'
            report += '3. � Select Google TTS as preferred engine\n'
          }
          
          if (!diagnostics.tests.tts_service?.available) {
            report += '4. 🔄 Restart the app after installing TTS engine\n'
            report += '5. ⚙️ Enable TTS in Android Accessibility settings\n'
          }
          
          if (!browserTTS) {
            report += '6. 🌐 Your WebView doesn\'t support speechSynthesis\n'
            report += '7. 📱 Try updating Android System WebView from Play Store\n'
          }
          
          report += '\n🔧 Quick Fixes:\n'
          report += '• Go to Android Settings > Apps > Google TTS > Enable\n'
          report += '• Settings > Accessibility > Text-to-speech > Google TTS\n'
          report += '• Test with "Test Speech" button after changes\n'
          
        } else if (diagnostics.platform === 'browser') {
          report += '🌐 Platform: Web Browser\n\n'
          report += `Browser TTS: ${diagnostics.speechSynthesis.available ? '✅ Available' : '❌ Not Available'}\n`
          report += `Available Voices: ${diagnostics.speechSynthesis.voices}\n`
          report += `WebView Ready: ${webViewTTSReady ? '✅ Yes' : '❌ No'}\n`
          
        } else {
          report += `Platform: ${diagnostics.platform || 'Unknown'}\n`
          report += `Message: ${diagnostics.message || 'No diagnostic information available'}\n`
        }
        
        // Show the diagnostic report
        alert(report)
        
        // Also log detailed diagnostics for debugging
        console.log('Detailed TTS Diagnostics:', diagnostics)
        
      } catch (error) {
        console.error('Failed to run Android TTS diagnostics:', error)
        alert(`❌ Diagnostic failed: ${error.message}`)
      } finally {
        this.isDiagnosing = false
      }
    },
  }
}
