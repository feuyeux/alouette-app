/**
 * Alouette Application - Unified Entry Point
 * Combines main.js, main-application.js, and app-script.js functionality
 */

import { createApp } from 'vue'
import App from './App.vue'
import './styles/main.css'

// Import core services and utilities
import { ApplicationCore } from './lib/services/application-core.js'
import { PlatformDetection } from './lib/utils/platform-detection.js'
import { ConfigurationManager } from './lib/services/configuration-manager.js'

/**
 * Initialize application core services
 */
async function initializeApplication() {
  console.log('🚀 Initializing Alouette Application...')
  
  try {
    // Detect platform and environment
    const platform = PlatformDetection.detectPlatform()
    console.log(`📱 Platform detected: ${platform.type} (${platform.version})`)
    
    // Initialize configuration manager
    const configManager = new ConfigurationManager()
    await configManager.initialize()
    
    // Initialize application core
    const appCore = new ApplicationCore()
    await appCore.initialize()
    
    console.log('✅ Application core initialized successfully')
    
    return {
      platform,
      configManager,
      appCore
    }
  } catch (error) {
    console.error('❌ Failed to initialize core services:', error)
    // Return minimal services for basic functionality
    return {
      platform: { type: 'unknown', version: 'unknown' },
      configManager: null,
      appCore: null
    }
  }
}

/**
 * Create and mount Vue application
 */
async function createVueApp() {
  try {
    console.log('🚀 Starting Alouette Application...')
    
    // Initialize core services (optional - app can work without them)
    const services = await initializeApplication()
    
    // Create Vue app instance
    const app = createApp(App)
    
    // Provide services to the entire app (if available)
    if (services.platform) {
      app.provide('platform', services.platform)
      app.config.globalProperties.$platform = services.platform
    }
    
    if (services.configManager) {
      app.provide('configManager', services.configManager)
    }
    
    if (services.appCore) {
      app.provide('appCore', services.appCore)
    }
    
    // Configure global properties
    app.config.globalProperties.$services = services
    
    // Mount the application
    app.mount('#app')
    
    console.log('🎉 Alouette Application mounted successfully!')
    console.log('📦 Unified application architecture loaded')
    
  } catch (error) {
    console.error('❌ Failed to initialize application:', error)
    
    // Fallback: Try to mount basic Vue app without services
    try {
      console.log('🔄 Attempting fallback initialization...')
      const basicApp = createApp(App)
      basicApp.mount('#app')
      console.log('✅ Basic application mounted successfully (without services)')
    } catch (fallbackError) {
      console.error('❌ Fallback initialization also failed:', fallbackError)
      
      // Show user-friendly error message
      document.body.innerHTML = `
        <div style="
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          height: 100vh;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          text-align: center;
          padding: 20px;
          background: linear-gradient(135deg, #f8fffe 0%, #e8f5e8 100%);
        ">
          <h1 style="color: #e74c3c; margin-bottom: 20px;">
            ⚠️ Application Initialization Failed
          </h1>
          <p style="color: #2c3e50; font-size: 16px; max-width: 600px; line-height: 1.6;">
            There was an error starting the application. Please check the console for details.
          </p>
          <p style="color: #7f8c8d; font-size: 14px; margin-top: 10px;">
            Error: ${error.message}
          </p>
          <button 
            onclick="window.location.reload()" 
            style="
              margin-top: 20px;
              padding: 12px 24px;
              background: #3498db;
              color: white;
              border: none;
              border-radius: 6px;
              cursor: pointer;
              font-size: 14px;
            "
          >
            Reload Application
          </button>
        </div>
      `
    }
  }
}

// Start the application when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', createVueApp)
} else {
  createVueApp()
}

// Export functions for potential external use or testing
export { createVueApp, initializeApplication }
