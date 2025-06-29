/**
 * Application Core Service
 * Central service that coordinates all application functionality
 */

import { TranslationService } from './translation-service.js'
import { TTSService } from './tts-service.js'
import { LLMConfigService } from './llm-config-service.js'
import { CacheService } from './cache-service.js'
import { EventBus } from '../utils/event-bus.js'

export class ApplicationCore {
  constructor() {
    this.services = new Map()
    this.eventBus = new EventBus()
    this.isInitialized = false
  }

  /**
   * Initialize all core services
   */
  async initialize() {
    if (this.isInitialized) {
      console.warn('Application core already initialized')
      return
    }

    console.log('🔧 Initializing application core services...')

    try {
      // Initialize services in dependency order
      await this.initializeServices()
      
      // Set up service communication
      this.setupServiceCommunication()
      
      // Mark as initialized
      this.isInitialized = true
      
      console.log('✅ Application core services initialized successfully')
      
    } catch (error) {
      console.error('❌ Failed to initialize application core:', error)
      throw error
    }
  }

  /**
   * Initialize individual services
   */
  async initializeServices() {
    // Create service instances
    const translationService = new TranslationService()
    const ttsService = new TTSService()
    const llmConfigService = new LLMConfigService()
    const cacheService = new CacheService()

    // Initialize services
    await Promise.all([
      translationService.initialize(),
      ttsService.initialize(),
      llmConfigService.initialize(),
      cacheService.initialize()
    ])

    // Store services
    this.services.set('translation', translationService)
    this.services.set('tts', ttsService)
    this.services.set('llmConfig', llmConfigService)
    this.services.set('cache', cacheService)

    console.log(`📦 Initialized ${this.services.size} core services`)
  }

  /**
   * Set up inter-service communication
   */
  setupServiceCommunication() {
    // Translation completed event
    this.eventBus.on('translation:completed', (data) => {
      console.log('🔄 Translation completed, notifying TTS service')
      this.getService('tts').onTranslationCompleted(data)
    })

    // TTS playback events
    this.eventBus.on('tts:playback:started', (data) => {
      console.log('🔊 TTS playback started')
    })

    this.eventBus.on('tts:playback:completed', (data) => {
      console.log('✅ TTS playback completed')
    })

    // Configuration change events
    this.eventBus.on('config:changed', (data) => {
      console.log('⚙️ Configuration changed, updating services')
      this.services.forEach(service => {
        if (service.onConfigChanged) {
          service.onConfigChanged(data)
        }
      })
    })
  }

  /**
   * Get a service by name
   */
  getService(name) {
    const service = this.services.get(name)
    if (!service) {
      throw new Error(`Service '${name}' not found`)
    }
    return service
  }

  /**
   * Get all services
   */
  getAllServices() {
    return Object.fromEntries(this.services)
  }

  /**
   * Get event bus for custom events
   */
  getEventBus() {
    return this.eventBus
  }

  /**
   * Shutdown all services
   */
  async shutdown() {
    console.log('🛑 Shutting down application core...')

    for (const [name, service] of this.services) {
      try {
        if (service.shutdown) {
          await service.shutdown()
        }
        console.log(`✅ Service '${name}' shut down successfully`)
      } catch (error) {
        console.error(`❌ Failed to shut down service '${name}':`, error)
      }
    }

    this.services.clear()
    this.eventBus.removeAllListeners()
    this.isInitialized = false

    console.log('✅ Application core shut down completed')
  }

  /**
   * Get application health status
   */
  getHealthStatus() {
    const status = {
      isInitialized: this.isInitialized,
      services: {},
      timestamp: new Date().toISOString()
    }

    for (const [name, service] of this.services) {
      status.services[name] = {
        initialized: service.isInitialized || true,
        healthy: service.isHealthy ? service.isHealthy() : true,
        lastError: service.lastError || null
      }
    }

    return status
  }
}
