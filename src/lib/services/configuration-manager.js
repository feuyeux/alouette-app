/**
 * Configuration Manager Service
 * Handles all application configuration and settings persistence
 */

import { PlatformDetection } from '../utils/platform-detection.js'
import { StorageManager } from '../utils/storage-manager.js'

export class ConfigurationManager {
  constructor() {
    this.storage = new StorageManager()
    this.config = {
      llm: {
        provider: 'ollama',
        serverUrl: '',
        apiKey: '',
        selectedModel: '',
        timeout: 30000
      },
      tts: {
        rate: 1.0,
        volume: 1.0,
        pauseBetweenLanguages: 500,
        autoSelectVoice: true,
        cacheEnabled: true
      },
      ui: {
        language: 'en',
        theme: 'light',
        fontSize: 'medium',
        compactMode: false
      },
      performance: {
        maxConcurrentRequests: 3,
        requestRetries: 2,
        cacheSize: 100
      }
    }
    this.isInitialized = false
  }

  /**
   * Initialize configuration manager
   */
  async initialize() {
    if (this.isInitialized) {
      console.warn('Configuration manager already initialized')
      return
    }

    console.log('⚙️ Initializing configuration manager...')

    try {
      // Load existing configuration
      await this.loadConfiguration()
      
      // Apply platform-specific defaults
      this.applyPlatformDefaults()
      
      // Migrate legacy configuration if needed
      this.migrateLegacyConfiguration()
      
      // Validate configuration
      this.validateConfiguration()
      
      // Save any changes made during initialization
      await this.saveConfiguration()
      
      this.isInitialized = true
      console.log('✅ Configuration manager initialized successfully')
      
    } catch (error) {
      console.error('❌ Failed to initialize configuration manager:', error)
      throw error
    }
  }

  /**
   * Load configuration from storage
   */
  async loadConfiguration() {
    try {
      const savedConfig = await this.storage.getObject('app-config', this.config)
      
      // Merge saved config with defaults
      this.config = this.mergeConfigurations(this.config, savedConfig)
      
      console.log('📥 Configuration loaded from storage')
      
    } catch (error) {
      console.warn('⚠️ Failed to load configuration, using defaults:', error)
    }
  }

  /**
   * Save configuration to storage
   */
  async saveConfiguration() {
    try {
      await this.storage.setObject('app-config', this.config)
      console.log('💾 Configuration saved to storage')
      
    } catch (error) {
      console.error('❌ Failed to save configuration:', error)
      throw error
    }
  }

  /**
   * Apply platform-specific default values
   */
  applyPlatformDefaults() {
    const platform = PlatformDetection.detectPlatform()
    const recommendations = PlatformDetection.getConfigurationRecommendations(platform)
    
    // Apply TTS defaults if not already set
    if (!this.config.tts.rate || this.config.tts.rate === 1.0) {
      this.config.tts.rate = recommendations.tts.rate
    }
    
    // Apply UI defaults
    this.config.ui.compactMode = recommendations.ui.compactMode
    
    // Set default server URLs based on platform
    if (!this.config.llm.serverUrl) {
      const recommendedUrls = PlatformDetection.getRecommendedServerUrls(platform)
      this.config.llm.serverUrl = recommendedUrls[this.config.llm.provider]?.[0] || ''
    }
    
    console.log('🎯 Applied platform-specific defaults')
  }

  /**
   * Migrate legacy configuration format
   */
  migrateLegacyConfiguration() {
    // Migrate from old localStorage keys
    const legacyMappings = {
      'llmProvider': 'llm.provider',
      'serverUrl': 'llm.serverUrl',
      'ollamaUrl': 'llm.serverUrl', // Special case for Ollama
      'selectedModel': 'llm.selectedModel',
      'apiKey': 'llm.apiKey',
      'ttsRate': 'tts.rate',
      'ttsVolume': 'tts.volume',
      'ttsPause': 'tts.pauseBetweenLanguages',
      'ttsAutoSelect': 'tts.autoSelectVoice'
    }

    let migrated = false
    
    for (const [oldKey, newPath] of Object.entries(legacyMappings)) {
      const oldValue = localStorage.getItem(oldKey)
      if (oldValue !== null) {
        this.setNestedValue(this.config, newPath, this.parseStorageValue(oldValue))
        localStorage.removeItem(oldKey)
        migrated = true
      }
    }

    if (migrated) {
      console.log('🔄 Migrated legacy configuration')
    }
  }

  /**
   * Validate configuration values
   */
  validateConfiguration() {
    // Validate TTS settings
    this.config.tts.rate = Math.max(0.1, Math.min(3.0, this.config.tts.rate))
    this.config.tts.volume = Math.max(0.0, Math.min(1.0, this.config.tts.volume))
    this.config.tts.pauseBetweenLanguages = Math.max(0, Math.min(5000, this.config.tts.pauseBetweenLanguages))
    
    // Validate performance settings
    this.config.performance.maxConcurrentRequests = Math.max(1, Math.min(10, this.config.performance.maxConcurrentRequests))
    this.config.performance.requestRetries = Math.max(0, Math.min(5, this.config.performance.requestRetries))
    this.config.performance.cacheSize = Math.max(10, Math.min(1000, this.config.performance.cacheSize))
    
    console.log('✅ Configuration validated')
  }

  /**
   * Get configuration value by path
   */
  get(path, defaultValue = null) {
    return this.getNestedValue(this.config, path, defaultValue)
  }

  /**
   * Set configuration value by path
   */
  async set(path, value) {
    this.setNestedValue(this.config, path, value)
    await this.saveConfiguration()
  }

  /**
   * Get entire configuration object
   */
  getAll() {
    return { ...this.config }
  }

  /**
   * Update multiple configuration values
   */
  async updateMultiple(updates) {
    for (const [path, value] of Object.entries(updates)) {
      this.setNestedValue(this.config, path, value)
    }
    await this.saveConfiguration()
  }

  /**
   * Reset configuration to defaults
   */
  async reset() {
    this.config = {
      llm: {
        provider: 'ollama',
        serverUrl: '',
        apiKey: '',
        selectedModel: '',
        timeout: 30000
      },
      tts: {
        rate: 1.0,
        volume: 1.0,
        pauseBetweenLanguages: 500,
        autoSelectVoice: true,
        cacheEnabled: true
      },
      ui: {
        language: 'en',
        theme: 'light',
        fontSize: 'medium',
        compactMode: false
      },
      performance: {
        maxConcurrentRequests: 3,
        requestRetries: 2,
        cacheSize: 100
      }
    }
    
    this.applyPlatformDefaults()
    await this.saveConfiguration()
    
    console.log('🔄 Configuration reset to defaults')
  }

  /**
   * Helper method to get nested object value
   */
  getNestedValue(obj, path, defaultValue = null) {
    return path.split('.').reduce((current, key) => {
      return current && current[key] !== undefined ? current[key] : defaultValue
    }, obj)
  }

  /**
   * Helper method to set nested object value
   */
  setNestedValue(obj, path, value) {
    const keys = path.split('.')
    const lastKey = keys.pop()
    const target = keys.reduce((current, key) => {
      if (!current[key] || typeof current[key] !== 'object') {
        current[key] = {}
      }
      return current[key]
    }, obj)
    target[lastKey] = value
  }

  /**
   * Parse storage value to appropriate type
   */
  parseStorageValue(value) {
    if (value === 'true') return true
    if (value === 'false') return false
    if (!isNaN(value) && !isNaN(parseFloat(value))) return parseFloat(value)
    return value
  }

  /**
   * Merge two configuration objects
   */
  mergeConfigurations(defaultConfig, savedConfig) {
    const merged = { ...defaultConfig }
    
    for (const [key, value] of Object.entries(savedConfig)) {
      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        merged[key] = this.mergeConfigurations(defaultConfig[key] || {}, value)
      } else {
        merged[key] = value
      }
    }
    
    return merged
  }
}
