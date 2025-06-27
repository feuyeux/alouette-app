/**
 * Text-to-Speech Service
 * Handles TTS playback for both desktop and Android platforms
 */

import { invoke } from '@tauri-apps/api/core'
import { isTauriEnv, isAndroid } from '../utils/environment.js'

/**
 * TTS Service class for handling speech synthesis
 */
export class TTSService {
    constructor() {
        this.playingText = null
        this.isPlayingAll = false
    }

    /**
     * Play text-to-speech for a specific text and language
     * @param {string} text - Text to synthesize
     * @param {string} lang - Target language for voice selection
     * @param {Object} settings - TTS settings
     */
    async playTTS(text, lang, settings = {}) {
        // Check Tauri environment
        if (!isTauriEnv()) {
            console.error('TTS playback failed: not running in Tauri environment')
            alert('Please run this application through Tauri, not directly in a browser.\\nExecute: npm run dev')
            return
        }

        try {
            // Set playback state
            this.playingText = text
            console.log(`Starting TTS playback - Text: "${text}", Language: ${lang}`)

            // Call Tauri backend for TTS
            await invoke('play_tts', {
                text: text,
                lang: lang
            })

            console.log('TTS playback completed successfully')
            this.playingText = null

        } catch (error) {
            console.error('TTS playback failed:', error)

            // Check if this is an Android TTS command
            const errorMsg = error.message || error.toString() || 'Unknown error'
            if (errorMsg.startsWith('ANDROID_TTS_COMMAND:')) {
                await this.handleAndroidTTS(errorMsg, settings)
                return
            }

            this.playingText = null
            // Display specific error message
            alert(`TTS playback failed: ${errorMsg}`)
        }
    }

    /**
     * Handle Android TTS through WebView speechSynthesis API
     * @param {string} errorMsg - Error message containing TTS command
     * @param {Object} settings - TTS settings
     */
    async handleAndroidTTS(errorMsg, settings) {
        try {
            const jsonCommand = errorMsg.substring('ANDROID_TTS_COMMAND:'.length)
            const ttsCommand = JSON.parse(jsonCommand)

            console.log('Processing Android TTS command:', ttsCommand)

            // Check if speechSynthesis is available
            if ('speechSynthesis' in window && speechSynthesis) {
                // Cancel any ongoing speech
                speechSynthesis.cancel()

                // Wait for voices to load if they're not ready
                const voices = await this.waitForVoices()
                console.log('Available voices:', voices.map(v => `${v.name} (${v.lang})`))

                const utterance = new SpeechSynthesisUtterance(ttsCommand.text)

                // Enhanced voice matching with fallbacks
                const matchingVoice = this.findMatchingVoice(voices, ttsCommand)

                // Configure utterance
                utterance.lang = ttsCommand.locale || 'en-US'
                utterance.rate = (ttsCommand.rate || 1.0) * (settings.rate || 0.8)
                utterance.volume = ttsCommand.volume || settings.volume || 0.9
                utterance.pitch = ttsCommand.pitch || 1.0

                if (matchingVoice) {
                    utterance.voice = matchingVoice
                    console.log(`✅ Using voice: ${matchingVoice.name} (${matchingVoice.lang})`)
                } else {
                    console.log(`⚠️ No matching voice found for ${ttsCommand.locale}, using system default`)
                }

                // Play the speech with enhanced error handling
                await this.speakUtterance(utterance, ttsCommand.timeout || 10000)

            } else {
                // speechSynthesis not available - provide user feedback
                this.handleSpeechSynthesisUnavailable(ttsCommand)
            }

        } catch (parseError) {
            console.error('Failed to parse Android TTS command:', parseError)
            this.playingText = null
            throw new Error(`Android TTS command parsing failed: ${parseError.message}`)
        }
    }

    /**
     * Wait for speech synthesis voices to load
     * @returns {Promise<Array>} Array of available voices
     */
    waitForVoices() {
        return new Promise((resolve) => {
            let voices = speechSynthesis.getVoices()
            if (voices.length > 0) {
                resolve(voices)
                return
            }

            const onVoicesChanged = () => {
                voices = speechSynthesis.getVoices()
                if (voices.length > 0) {
                    speechSynthesis.removeEventListener('voiceschanged', onVoicesChanged)
                    resolve(voices)
                }
            }

            speechSynthesis.addEventListener('voiceschanged', onVoicesChanged)

            // Fallback timeout
            setTimeout(() => {
                speechSynthesis.removeEventListener('voiceschanged', onVoicesChanged)
                resolve(speechSynthesis.getVoices())
            }, 3000)
        })
    }

    /**
     * Find matching voice for TTS command
     * @param {Array} voices - Available voices
     * @param {Object} ttsCommand - TTS command object
     * @returns {Object|null} Matching voice or null
     */
    findMatchingVoice(voices, ttsCommand) {
        let matchingVoice = null
        const fallbackLocales = ttsCommand.fallback_locales || [ttsCommand.locale]

        // Try primary locale first
        for (const locale of fallbackLocales) {
            matchingVoice = voices.find(voice =>
                voice.lang === locale ||
                voice.lang.toLowerCase() === locale.toLowerCase()
            )
            if (matchingVoice) break
        }

        // Try partial matching if exact match fails
        if (!matchingVoice) {
            const languageCode = ttsCommand.locale.split('-')[0]
            matchingVoice = voices.find(voice =>
                voice.lang.startsWith(languageCode)
            )
        }

        return matchingVoice
    }

    /**
     * Speak utterance with promise-based completion
     * @param {SpeechSynthesisUtterance} utterance - Utterance to speak
     * @param {number} timeout - Timeout in milliseconds
     * @returns {Promise} Promise that resolves when speech is complete
     */
    speakUtterance(utterance, timeout = 10000) {
        return new Promise((resolve) => {
            let completed = false

            const cleanup = () => {
                if (!completed) {
                    completed = true
                    utterance.onend = null
                    utterance.onerror = null
                    this.playingText = null
                }
            }

            utterance.onend = () => {
                console.log('✅ Android TTS playback completed successfully')
                cleanup()
                resolve()
            }

            utterance.onerror = (event) => {
                console.error('❌ Android TTS playback error:', event.error, event)
                cleanup()
                // Don't reject on error, just complete silently for better UX
                resolve()
            }

            // Check if speech was cancelled
            utterance.onpause = () => {
                console.log('⏸️ Android TTS playback paused')
            }

            utterance.onresume = () => {
                console.log('▶️ Android TTS playback resumed')
            }

            // Enhanced timeout with status checking
            const timeoutId = setTimeout(() => {
                if (!completed) {
                    console.log('⏰ Android TTS timeout reached, checking status...')
                    if (speechSynthesis.speaking) {
                        console.log('🔄 TTS still speaking, extending timeout...')
                        setTimeout(() => {
                            if (!completed) {
                                console.log('⏰ Final timeout, assuming completed')
                                speechSynthesis.cancel()
                                cleanup()
                                resolve()
                            }
                        }, 5000)
                    } else {
                        console.log('✅ TTS completed (timeout fallback)')
                        cleanup()
                        resolve()
                    }
                }
            }, timeout)

            // Play the speech
            speechSynthesis.speak(utterance)

            // Cleanup timeout when completed
            const originalResolve = resolve
            resolve = () => {
                clearTimeout(timeoutId)
                originalResolve()
            }
        })
    }

    /**
     * Handle case when speechSynthesis is not available
     * @param {Object} ttsCommand - TTS command object
     */
    handleSpeechSynthesisUnavailable(ttsCommand) {
        console.log('speechSynthesis not available in this WebView')

        // For Android emulator, speechSynthesis may not be available
        // Provide user-friendly feedback instead of error
        alert(`📱 Android TTS Note: speechSynthesis API is not available in this WebView environment.

🔧 This is normal for Android emulators. TTS functionality requires either:
• Real Android device with TTS engine
• WebView with speechSynthesis support

Text to speak: "${ttsCommand.text}"
Language: ${ttsCommand.locale}`)

        this.playingText = null
    }

    /**
     * Play TTS as a promise for sequential playback
     * @param {string} text - Text to synthesize
     * @param {string} lang - Target language
     * @param {Object} settings - TTS settings
     * @returns {Promise} Promise that resolves when TTS is complete
     */
    async playTTSPromise(text, lang, settings = {}) {
        await invoke('play_tts', { text: text, lang: lang })
    }

    /**
     * Test TTS functionality
     * @param {string} text - Test text
     * @param {string} lang - Test language
     * @param {Object} settings - TTS settings
     */
    async testTTS(text, lang, settings = {}) {
        if (!isTauriEnv()) {
            console.error('TTS test failed: not running in Tauri environment')
            alert('Please run this application through Tauri, not directly in a browser.\\nExecute: npm run dev')
            return
        }

        try {
            console.log('Testing TTS functionality...')

            // Test both regular TTS and Android TTS if on Android
            if (isAndroid()) {
                // Test Android TTS command generation
                const testResult = await invoke('test_android_tts', {
                    text: text,
                    language: lang
                })

                if (testResult.startsWith('ANDROID_TTS_COMMAND:')) {
                    await this.handleAndroidTTS(testResult, settings)
                } else {
                    console.log('Android TTS test result:', testResult)
                }
            } else {
                // Regular desktop TTS test
                await this.playTTS(text, lang, settings)
            }

            console.log('✅ TTS test completed successfully')

        } catch (error) {
            console.error('❌ TTS test failed:', error)
            alert(`TTS test failed: ${error.message || error}`)
        }
    }

    /**
     * Get current playback state
     * @returns {Object} Playback state
     */
    getPlaybackState() {
        return {
            playingText: this.playingText,
            isPlayingAll: this.isPlayingAll,
            isPlaying: this.playingText !== null
        }
    }

    /**
     * Stop current TTS playback
     */
    stopTTS() {
        if ('speechSynthesis' in window && speechSynthesis) {
            speechSynthesis.cancel()
        }
        this.playingText = null
        this.isPlayingAll = false
    }
}
