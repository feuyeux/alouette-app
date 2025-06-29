/**
 * Platform Detection Utility
 * Detects the current platform and environment for Tauri applications
 */

export class PlatformDetection {
  /**
   * Detect the current platform
   */
  static detectPlatform() {
    const userAgent = navigator.userAgent.toLowerCase()
    const platform = navigator.platform.toLowerCase()
    
    let type = 'unknown'
    let version = 'unknown'
    let isTauri = false
    let isAndroid = false
    let isIOS = false
    let isMobile = false

    // Check if running in Tauri environment
    isTauri = !!(
      window.__TAURI__ ||
      window.__TAURI_INTERNALS__ ||
      window.__TAURI_METADATA__ ||
      (window.navigator && window.navigator.userAgent && window.navigator.userAgent.includes('Tauri'))
    )

    // Detect Android
    if (userAgent.includes('android') || window.location.hostname.includes('tauri.localhost')) {
      type = 'android'
      isAndroid = true
      isMobile = true
      
      // Extract Android version
      const androidMatch = userAgent.match(/android (\d+\.?\d*)/i)
      if (androidMatch) {
        version = androidMatch[1]
      }
    }
    // Detect iOS
    else if (/ipad|iphone|ipod/.test(userAgent)) {
      type = 'ios'
      isIOS = true
      isMobile = true
      
      // Extract iOS version
      const iosMatch = userAgent.match(/os (\d+_?\d*)/i)
      if (iosMatch) {
        version = iosMatch[1].replace('_', '.')
      }
    }
    // Detect macOS
    else if (platform.includes('mac') || userAgent.includes('macintosh')) {
      type = 'macos'
      
      // Extract macOS version
      const macMatch = userAgent.match(/mac os x (\d+_?\d*)/i)
      if (macMatch) {
        version = macMatch[1].replace('_', '.')
      }
    }
    // Detect Windows
    else if (platform.includes('win') || userAgent.includes('windows')) {
      type = 'windows'
      
      // Extract Windows version
      if (userAgent.includes('windows nt 10.0')) {
        version = '10/11'
      } else if (userAgent.includes('windows nt 6.3')) {
        version = '8.1'
      } else if (userAgent.includes('windows nt 6.2')) {
        version = '8'
      } else if (userAgent.includes('windows nt 6.1')) {
        version = '7'
      }
    }
    // Detect Linux
    else if (platform.includes('linux') || userAgent.includes('linux')) {
      type = 'linux'
    }

    return {
      type,
      version,
      isTauri,
      isAndroid,
      isIOS,
      isMobile,
      isDesktop: !isMobile,
      userAgent,
      platform,
      capabilities: PlatformDetection.getCapabilities({
        type,
        isTauri,
        isAndroid,
        isIOS,
        isMobile
      })
    }
  }

  /**
   * Get platform-specific capabilities
   */
  static getCapabilities(platform) {
    const capabilities = {
      tts: false,
      fileSystem: false,
      networkAccess: true,
      notifications: false,
      clipboard: false,
      webview: false,
      nativeMenus: false
    }

    if (platform.isTauri) {
      capabilities.fileSystem = true
      capabilities.notifications = true
      capabilities.clipboard = true
      capabilities.webview = true
      
      if (platform.isDesktop) {
        capabilities.nativeMenus = true
      }
    }

    // TTS availability varies by platform
    if (platform.isAndroid || platform.isIOS) {
      capabilities.tts = 'speechSynthesis' in window
    } else if (platform.isTauri) {
      capabilities.tts = true // Tauri provides native TTS
    }

    return capabilities
  }

  /**
   * Get recommended server URLs based on platform
   */
  static getRecommendedServerUrls(platform) {
    const urls = {
      ollama: [],
      lmstudio: []
    }

    if (platform.isAndroid) {
      // For Android, recommend network IPs including the user's specific IP
      urls.ollama = [
        'http://192.168.31.228:11434', // User's specific IP
        'http://192.168.1.100:11434',
        'http://192.168.0.100:11434',
        'http://10.0.2.2:11434' // Android emulator host
      ]
      urls.lmstudio = [
        'http://192.168.31.228:1234', // User's specific IP
        'http://192.168.1.100:1234',
        'http://192.168.0.100:1234',
        'http://10.0.2.2:1234'
      ]
    } else {
      // For desktop platforms, use localhost
      urls.ollama = ['http://localhost:11434']
      urls.lmstudio = ['http://localhost:1234']
    }

    return urls
  }

  /**
   * Check if a feature is supported on the current platform
   */
  static isFeatureSupported(feature, platform = null) {
    if (!platform) {
      platform = PlatformDetection.detectPlatform()
    }

    return platform.capabilities[feature] || false
  }

  /**
   * Get platform-specific configuration recommendations
   */
  static getConfigurationRecommendations(platform = null) {
    if (!platform) {
      platform = PlatformDetection.detectPlatform()
    }

    const recommendations = {
      tts: {
        rate: 1.0,
        volume: 1.0,
        pauseBetweenLanguages: 500
      },
      ui: {
        fontSize: 'medium',
        compactMode: platform.isMobile
      },
      performance: {
        cacheEnabled: true,
        prefetchModels: !platform.isMobile
      }
    }

    // Platform-specific adjustments
    if (platform.isAndroid) {
      recommendations.tts.rate = 0.9 // Slightly slower for Android TTS
      recommendations.ui.fontSize = 'large'
      recommendations.performance.prefetchModels = false
    }

    if (platform.isIOS) {
      recommendations.tts.rate = 1.1 // iOS TTS tends to be slower
      recommendations.ui.fontSize = 'large'
    }

    return recommendations
  }

  /**
   * Log platform information for debugging
   */
  static logPlatformInfo() {
    const platform = PlatformDetection.detectPlatform()
    
    console.group('🔍 Platform Detection')
    console.log(`Platform: ${platform.type} ${platform.version}`)
    console.log(`Tauri Environment: ${platform.isTauri ? '✅' : '❌'}`)
    console.log(`Mobile Device: ${platform.isMobile ? '✅' : '❌'}`)
    console.log('Capabilities:', platform.capabilities)
    console.log('User Agent:', platform.userAgent)
    console.groupEnd()

    return platform
  }
}
