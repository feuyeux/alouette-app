/**
 * Translation Service
 * Handles communication with LLM providers for text translation
 */

import { invoke } from '@tauri-apps/api/core'
import { isTauriEnv } from '../utils/environment.js'

/**
 * Translation Service class for handling AI-powered translations
 */
export class TranslationService {
    constructor() {
        this.currentTranslation = null
        this.isTranslating = false
    }

    /**
     * Translate text to multiple target languages
     * @param {string} inputText - Text to translate
     * @param {Array} targetLanguages - Array of target language names
     * @param {Object} config - LLM configuration
     * @returns {Promise<Object>} Translation result object
     */
    async translateText(inputText, targetLanguages, config) {
        if (!isTauriEnv()) {
            throw new Error('Translation requires Tauri environment. Please run: npm run dev')
        }

        if (!inputText || inputText.trim().length === 0) {
            throw new Error('Please enter text to translate')
        }

        if (!targetLanguages || targetLanguages.length === 0) {
            throw new Error('Please select at least one target language')
        }

        if (!config.serverUrl || !config.selectedModel) {
            throw new Error('Please configure LLM settings first')
        }

        this.isTranslating = true

        try {
            console.log('Starting translation request:', {
                text: inputText,
                targetLanguages,
                config: {
                    provider: config.provider,
                    serverUrl: config.serverUrl,
                    model: config.selectedModel
                }
            })

            const translationRequest = {
                text: inputText.trim(),
                target_languages: targetLanguages,
                llm_provider: config.provider,
                server_url: config.serverUrl,
                api_key: config.apiKey || '',
                model: config.selectedModel
            }

            const result = await invoke('translate_text', translationRequest)

            this.currentTranslation = {
                original: inputText.trim(),
                translations: result,
                timestamp: new Date().toISOString(),
                languages: targetLanguages,
                config: { ...config }
            }

            console.log('Translation completed successfully:', this.currentTranslation)
            return this.currentTranslation

        } catch (error) {
            console.error('Translation failed:', error)

            // Provide more specific error messages
            const errorMsg = error.message || error.toString()
            if (errorMsg.includes('Connection refused') || errorMsg.includes('network')) {
                throw new Error(`Cannot connect to ${config.provider} server at ${config.serverUrl}. Please check if the server is running and accessible.`)
            } else if (errorMsg.includes('Unauthorized') || errorMsg.includes('401')) {
                throw new Error('Authentication failed. Please check your API key.')
            } else if (errorMsg.includes('Not found') || errorMsg.includes('404')) {
                throw new Error(`Model "${config.selectedModel}" not found. Please check if the model is available.`)
            } else if (errorMsg.includes('timeout')) {
                throw new Error('Translation request timed out. The server may be busy.')
            } else {
                throw new Error(`Translation failed: ${errorMsg}`)
            }
        } finally {
            this.isTranslating = false
        }
    }

    /**
     * Save translation to file
     * @param {string} filename - Filename for the saved translation
     * @param {string} format - File format ('txt', 'json', 'md')
     * @returns {Promise<string>} Path to saved file
     */
    async saveTranslation(filename, format = 'txt') {
        if (!this.currentTranslation) {
            throw new Error('No translation available to save')
        }

        if (!isTauriEnv()) {
            throw new Error('File saving requires Tauri environment. Please run: npm run dev')
        }

        try {
            let content = ''

            switch (format.toLowerCase()) {
                case 'json':
                    content = JSON.stringify(this.currentTranslation, null, 2)
                    break

                case 'md':
                case 'markdown':
                    content = this.formatAsMarkdown(this.currentTranslation)
                    break

                case 'txt':
                default:
                    content = this.formatAsText(this.currentTranslation)
                    break
            }

            const savedPath = await invoke('save_translation_file', {
                filename: filename,
                content: content
            })

            console.log('Translation saved successfully:', savedPath)
            return savedPath

        } catch (error) {
            console.error('Failed to save translation:', error)
            throw new Error(`Failed to save translation: ${error.message || error}`)
        }
    }

    /**
     * Format translation as plain text
     * @param {Object} translation - Translation object
     * @returns {string} Formatted text content
     */
    formatAsText(translation) {
        let content = `Translation Results\\n`
        content += `Generated: ${new Date(translation.timestamp).toLocaleString()}\\n`
        content += `Original Language: Auto-detected\\n`
        content += `Target Languages: ${translation.languages.join(', ')}\\n`
        content += `Model: ${translation.config.selectedModel}\\n\\n`

        content += `Original Text:\\n${translation.original}\\n\\n`

        content += `Translations:\\n`
        for (const [lang, translatedText] of Object.entries(translation.translations)) {
            content += `\\n${lang}:\\n${translatedText}\\n`
        }

        return content
    }

    /**
     * Format translation as Markdown
     * @param {Object} translation - Translation object
     * @returns {string} Formatted Markdown content
     */
    formatAsMarkdown(translation) {
        let content = `# Translation Results\\n\\n`
        content += `**Generated:** ${new Date(translation.timestamp).toLocaleString()}  \\n`
        content += `**Original Language:** Auto-detected  \\n`
        content += `**Target Languages:** ${translation.languages.join(', ')}  \\n`
        content += `**Model:** ${translation.config.selectedModel}\\n\\n`

        content += `## Original Text\\n\\n`
        content += `${translation.original}\\n\\n`

        content += `## Translations\\n\\n`
        for (const [lang, translatedText] of Object.entries(translation.translations)) {
            content += `### ${lang}\\n\\n${translatedText}\\n\\n`
        }

        return content
    }

    /**
     * Get current translation
     * @returns {Object|null} Current translation object or null
     */
    getCurrentTranslation() {
        return this.currentTranslation
    }

    /**
     * Clear current translation
     */
    clearTranslation() {
        this.currentTranslation = null
    }

    /**
     * Get translation state
     * @returns {Object} Translation state
     */
    getTranslationState() {
        return {
            isTranslating: this.isTranslating,
            hasTranslation: !!this.currentTranslation,
            currentTranslation: this.currentTranslation
        }
    }

    /**
     * Format translation for display
     * @param {Object} translation - Translation object
     * @returns {Object} Formatted translation for UI display
     */
    formatForDisplay(translation = null) {
        const trans = translation || this.currentTranslation
        if (!trans) return null

        return {
            original: trans.original,
            translations: trans.translations,
            languages: trans.languages,
            timestamp: new Date(trans.timestamp).toLocaleString(),
            model: trans.config.selectedModel,
            provider: trans.config.provider
        }
    }
}
