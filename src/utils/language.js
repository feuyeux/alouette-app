/**
 * Language Detection Utilities
 * Provides text analysis and language detection capabilities
 */

/**
 * Available languages for translation
 */
export const AVAILABLE_LANGUAGES = [
    // (Germanic)
    'English', 'German',
    // (Romance) 
    'French', 'Spanish', 'Italian',
    // (Slavic)
    'Russian',
    // (Hellenic)
    'Greek',
    // (Indo-Aryan)
    'Hindi',
    // (Afro-Asiatic)
    'Arabic',
    // (Sino-Tibetan)
    'Chinese',
    // (Japonic)
    'Japanese',
    // (Koreanic)
    'Korean',
    'All'
]

/**
 * Detect the language of input text using simple character analysis
 * @param {string} text - Text to analyze
 * @returns {string} Detected language name
 */
export const detectLanguage = (text) => {
    if (!text || text.trim().length === 0) return 'English'

    const trimmedText = text.trim()

    // Chinese characters (CJK Unified Ideographs)
    if (/[\u4e00-\u9fff]/.test(trimmedText)) {
        return 'Chinese'
    }

    // Japanese characters (Hiragana, Katakana, and Kanji)
    if (/[\u3040-\u309f\u30a0-\u30ff\u4e00-\u9fff]/.test(trimmedText)) {
        return 'Japanese'
    }

    // Korean characters (Hangul)
    if (/[\uac00-\ud7af\u1100-\u11ff\u3130-\u318f]/.test(trimmedText)) {
        return 'Korean'
    }

    // Arabic characters
    if (/[\u0600-\u06ff\u0750-\u077f]/.test(trimmedText)) {
        return 'Arabic'
    }

    // Hindi characters (Devanagari)
    if (/[\u0900-\u097f]/.test(trimmedText)) {
        return 'Hindi'
    }

    // Russian/Cyrillic characters
    if (/[\u0400-\u04ff]/.test(trimmedText)) {
        return 'Russian'
    }

    // Greek characters
    if (/[\u0370-\u03ff]/.test(trimmedText)) {
        return 'Greek'
    }

    // Common European diacritics and patterns
    const frenchIndicators = /[àâäéèêëïîôöùûüÿç]/i
    const spanishIndicators = /[ñáéíóúü¿¡]/i
    const germanIndicators = /[äöüß]/i
    const italianIndicators = /[àèéìíîòóù]/i

    if (frenchIndicators.test(trimmedText)) {
        return 'French'
    }
    if (spanishIndicators.test(trimmedText)) {
        return 'Spanish'
    }
    if (germanIndicators.test(trimmedText)) {
        return 'German'
    }
    if (italianIndicators.test(trimmedText)) {
        return 'Italian'
    }

    // Default to English if no specific patterns found
    return 'English'
}

/**
 * Check if all real languages are selected
 * @param {Array} selectedLanguages - Currently selected languages
 * @returns {boolean} True if all languages except 'All' are selected
 */
export const isAllLanguagesSelected = (selectedLanguages) => {
    const realLanguages = AVAILABLE_LANGUAGES.filter(lang => lang !== 'All')
    return realLanguages.every(lang => selectedLanguages.includes(lang))
}

/**
 * Format language list for display
 * @param {Array} languages - Language list
 * @returns {string} Formatted string
 */
export const formatLanguageList = (languages) => {
    if (!languages || languages.length === 0) return 'None'
    if (languages.length === 1) return languages[0]
    if (languages.length === 2) return languages.join(' and ')
    return languages.slice(0, -1).join(', ') + ', and ' + languages[languages.length - 1]
}

/**
 * Get the real languages (excluding 'All')
 * @returns {Array} Array of real language names
 */
export const getRealLanguages = () => {
    return AVAILABLE_LANGUAGES.filter(lang => lang !== 'All')
}
