/**
 * Android TTS Fallback Service
 * Uses Web Speech API when available (Android WebView supports this)
 * Falls back to Rust backend if Web Speech API is not available
 */

/**
 * Android TTS Fallback using Web Speech API
 */
export class AndroidTTSFallback {
    constructor() {
        this.synthesis = null
        this.supportedVoices = []
        this.isAvailable = false
        this.init()
    }

    /**
     * Initialize Web Speech API
     */
    init() {
        if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
            this.synthesis = window.speechSynthesis
            this.isAvailable = true
            
            // Load voices
            this.loadVoices()
            
            // Listen for voice changes (voices load asynchronously)
            if (this.synthesis.onvoiceschanged !== undefined) {
                this.synthesis.onvoiceschanged = () => {
                    this.loadVoices()
                }
            }
            
            console.log('✅ Web Speech API available - Android TTS fallback ready')
        } else {
            console.log('❌ Web Speech API not available')
        }
    }

    /**
     * Load available voices
     */
    loadVoices() {
        if (!this.synthesis) return
        
        this.supportedVoices = this.synthesis.getVoices()
        console.log(`📢 Loaded ${this.supportedVoices.length} TTS voices:`, 
                   this.supportedVoices.map(v => `${v.name} (${v.lang})`))
    }

    /**
     * Check if Web Speech API is available and functional
     */
    isWebSpeechAvailable() {
        return this.isAvailable && this.synthesis && this.supportedVoices.length > 0
    }

    /**
     * Find best voice for language
     * @param {string} language - Target language
     * @returns {SpeechSynthesisVoice|null} Best matching voice
     */
    findVoiceForLanguage(language) {
        if (!this.supportedVoices.length) {
            this.loadVoices() // Try to reload voices
        }

        // Language mapping
        const langMap = {
            'English': 'en',
            'Spanish': 'es', 
            'French': 'fr',
            'German': 'de',
            'Italian': 'it',
            'Russian': 'ru',
            'Chinese': 'zh',
            'Japanese': 'ja',
            'Korean': 'ko',
            'Arabic': 'ar',
            'Hindi': 'hi',
            'Greek': 'el'
        }

        const targetLangCode = langMap[language] || language.toLowerCase().substr(0, 2)
        
        // Find exact language match
        let bestVoice = this.supportedVoices.find(voice => 
            voice.lang.toLowerCase().startsWith(targetLangCode)
        )
        
        // If no exact match, try broader search
        if (!bestVoice) {
            bestVoice = this.supportedVoices.find(voice => 
                voice.lang.toLowerCase().includes(targetLangCode)
            )
        }
        
        // Default to first available voice
        if (!bestVoice && this.supportedVoices.length > 0) {
            bestVoice = this.supportedVoices[0]
        }
        
        if (bestVoice) {
            console.log(`🎙️ Selected voice: ${bestVoice.name} (${bestVoice.lang}) for language: ${language}`)
        }
        
        return bestVoice
    }

    /**
     * Play TTS using Web Speech API
     * @param {string} text - Text to synthesize
     * @param {string} language - Target language
     * @param {Object} settings - TTS settings
     * @returns {Promise} Promise that resolves when speech is complete
     */
    async playTTSWebAPI(text, language, settings = {}) {
        return new Promise((resolve, reject) => {
            if (!this.isWebSpeechAvailable()) {
                reject(new Error('Web Speech API not available'))
                return
            }

            // Stop any ongoing speech
            this.synthesis.cancel()

            // Create utterance
            const utterance = new SpeechSynthesisUtterance(text)
            
            // Find appropriate voice
            const voice = this.findVoiceForLanguage(language)
            if (voice) {
                utterance.voice = voice
                utterance.lang = voice.lang
            } else {
                // Set language code if no specific voice found
                const langMap = {
                    'English': 'en-US',
                    'Spanish': 'es-ES',
                    'French': 'fr-FR',
                    'German': 'de-DE',
                    'Italian': 'it-IT',
                    'Russian': 'ru-RU',
                    'Chinese': 'zh-CN',
                    'Japanese': 'ja-JP',
                    'Korean': 'ko-KR',
                    'Arabic': 'ar-SA',
                    'Hindi': 'hi-IN',
                    'Greek': 'el-GR'
                }
                utterance.lang = langMap[language] || 'en-US'
            }

            // Apply settings
            utterance.rate = settings.rate || 1.0
            utterance.volume = settings.volume || 1.0
            utterance.pitch = settings.pitch || 1.0

            // Event handlers
            utterance.onend = () => {
                console.log('✅ Web Speech API TTS completed')
                resolve()
            }

            utterance.onerror = (event) => {
                console.error('❌ Web Speech API TTS failed:', event.error)
                reject(new Error(`TTS failed: ${event.error}`))
            }

            utterance.onstart = () => {
                console.log('🔊 Web Speech API TTS started')
            }

            // Start speech
            console.log(`🎵 Starting Web Speech API TTS - Text: "${text.substring(0, 50)}...", Language: ${language}`)
            this.synthesis.speak(utterance)
        })
    }

    /**
     * Test Web Speech API functionality
     * @param {string} text - Test text
     * @param {string} language - Test language
     * @returns {Promise} Test result
     */
    async testWebSpeechAPI(text = "Hello! This is a TTS test.", language = "English") {
        try {
            if (!this.isWebSpeechAvailable()) {
                throw new Error('Web Speech API not available')
            }

            console.log('🧪 Testing Web Speech API...')
            await this.playTTSWebAPI(text, language)
            console.log('✅ Web Speech API test successful')
            return { success: true, method: 'web_speech_api' }

        } catch (error) {
            console.error('❌ Web Speech API test failed:', error)
            return { success: false, method: 'web_speech_api', error: error.message }
        }
    }

    /**
     * Get diagnostic information about TTS capabilities
     * @returns {Object} Diagnostic information
     */
    getDiagnostics() {
        const diagnostics = {
            web_speech_api: {
                available: this.isAvailable,
                functional: this.isWebSpeechAvailable(),
                voice_count: this.supportedVoices.length,
                supported_languages: []
            },
            platform: navigator.userAgent.includes('Android') ? 'android' : 'unknown',
            timestamp: new Date().toISOString()
        }

        // Extract supported languages
        if (this.supportedVoices.length > 0) {
            const languages = new Set()
            this.supportedVoices.forEach(voice => {
                const lang = voice.lang.split('-')[0]
                languages.add(lang)
            })
            diagnostics.web_speech_api.supported_languages = Array.from(languages)
        }

        // Add voice details
        diagnostics.web_speech_api.voices = this.supportedVoices.map(voice => ({
            name: voice.name,
            lang: voice.lang,
            localService: voice.localService,
            default: voice.default
        }))

        return diagnostics
    }

    /**
     * Stop any ongoing speech
     */
    stop() {
        if (this.synthesis) {
            this.synthesis.cancel()
            console.log('🛑 Web Speech API TTS stopped')
        }
    }
}

// Create global instance
export const androidTTSFallback = new AndroidTTSFallback()
