/**
 * Text-to-Speech Service
 * Simplified service that delegates all TTS functionality to Rust backend
 */

import { invoke } from '@tauri-apps/api/core'
import { isTauriEnv } from '../utils/environment.js'

/**
 * TTS Service class for handling speech synthesis via Rust backend
 */
export class TTSService {
    constructor() {
        this.playingText = null
        this.isPlayingAll = false
    }

    /**
     * Play text-to-speech for a specific text and language
     * All TTS processing happens in Rust backend for consistency across platforms
     * @param {string} text - Text to synthesize
     * @param {string} lang - Target language for voice selection
     * @param {Object} settings - TTS settings (currently unused as Rust handles this)
     */
    async playTTS(text, lang, settings = {}) {
        // Check Tauri environment
        if (!isTauriEnv()) {
            console.error('TTS playback failed: not running in Tauri environment')
            alert('Please run this application through Tauri, not directly in a browser.\nExecute: npm run dev')
            return
        }

        try {
            // Set playback state
            this.playingText = text
            console.log(`🎵 Starting TTS playback - Text: "${text}", Language: ${lang}`)

            // Call Rust backend for unified TTS handling
            await invoke('play_tts', {
                text: text,
                lang: lang
            })

            console.log('✅ TTS playback completed successfully')
            this.playingText = null

        } catch (error) {
            console.error('❌ TTS playback failed:', error)
            this.playingText = null
            
            // Display user-friendly error message
            const errorMsg = error.message || error.toString() || 'Unknown error'
            alert(`TTS playback failed: ${errorMsg}`)
        }
    }

    /**
     * Play TTS as a promise for sequential playback
     * @param {string} text - Text to synthesize
     * @param {string} lang - Target language
     * @param {Object} settings - TTS settings
     * @returns {Promise} Promise that resolves when TTS is complete
     */
    async playTTSPromise(text, lang, settings = {}) {
        await this.playTTS(text, lang, settings)
    }

    /**
     * Test TTS functionality
     * @param {string} text - Test text
     * @param {string} lang - Test language
     * @param {Object} settings - TTS settings
     */
    async testTTS(text = "Hello! This is a TTS test.", lang = "English", settings = {}) {
        if (!isTauriEnv()) {
            console.error('TTS test failed: not running in Tauri environment')
            alert('Please run this application through Tauri, not directly in a browser.\nExecute: npm run dev')
            return
        }

        try {
            console.log('🧪 Testing TTS functionality...')
            await this.playTTS(text, lang, settings)
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
        this.playingText = null
        this.isPlayingAll = false
        console.log('🛑 TTS playback stopped')
    }

    /**
     * Diagnose TTS issues and provide troubleshooting information
     * @returns {Promise<Object>} Diagnostic information
     */
    async diagnoseAndroidTTS() {
        if (!isTauriEnv()) {
            return {
                platform: 'browser',
                message: 'TTS diagnostics only available in Tauri environment'
            }
        }

        try {
            console.log('🔍 Running TTS diagnostics...')
            const diagnostics = await invoke('diagnose_android_tts')
            console.log('TTS Diagnostics:', diagnostics)
            return diagnostics
        } catch (error) {
            console.error('Failed to run TTS diagnostics:', error)
            return {
                error: error.message || error,
                platform: 'unknown',
                message: 'Failed to run diagnostics'
            }
        }
    }
}
