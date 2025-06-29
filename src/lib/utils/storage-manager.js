/**
 * Storage Manager Utility
 * Provides unified interface for localStorage with error handling and type conversion
 */

export class StorageManager {
  constructor(prefix = 'alouette') {
    this.prefix = prefix
  }

  /**
   * Generate storage key with prefix
   */
  getKey(key) {
    return `${this.prefix}:${key}`
  }

  /**
   * Get string value from storage
   */
  getString(key, defaultValue = null) {
    try {
      const value = localStorage.getItem(this.getKey(key))
      return value !== null ? value : defaultValue
    } catch (error) {
      console.warn(`Failed to get string value for key '${key}':`, error)
      return defaultValue
    }
  }

  /**
   * Set string value in storage
   */
  setString(key, value) {
    try {
      localStorage.setItem(this.getKey(key), value)
      return true
    } catch (error) {
      console.error(`Failed to set string value for key '${key}':`, error)
      return false
    }
  }

  /**
   * Get number value from storage
   */
  getNumber(key, defaultValue = 0) {
    try {
      const value = localStorage.getItem(this.getKey(key))
      if (value === null) return defaultValue
      
      const parsed = parseFloat(value)
      return !isNaN(parsed) ? parsed : defaultValue
    } catch (error) {
      console.warn(`Failed to get number value for key '${key}':`, error)
      return defaultValue
    }
  }

  /**
   * Set number value in storage
   */
  setNumber(key, value) {
    return this.setString(key, value.toString())
  }

  /**
   * Get boolean value from storage
   */
  getBoolean(key, defaultValue = false) {
    try {
      const value = localStorage.getItem(this.getKey(key))
      if (value === null) return defaultValue
      
      return value === 'true'
    } catch (error) {
      console.warn(`Failed to get boolean value for key '${key}':`, error)
      return defaultValue
    }
  }

  /**
   * Set boolean value in storage
   */
  setBoolean(key, value) {
    return this.setString(key, value.toString())
  }

  /**
   * Get object value from storage
   */
  getObject(key, defaultValue = null) {
    try {
      const value = localStorage.getItem(this.getKey(key))
      if (value === null) return defaultValue
      
      return JSON.parse(value)
    } catch (error) {
      console.warn(`Failed to get object value for key '${key}':`, error)
      return defaultValue
    }
  }

  /**
   * Set object value in storage
   */
  setObject(key, value) {
    try {
      const serialized = JSON.stringify(value)
      return this.setString(key, serialized)
    } catch (error) {
      console.error(`Failed to set object value for key '${key}':`, error)
      return false
    }
  }

  /**
   * Remove value from storage
   */
  remove(key) {
    try {
      localStorage.removeItem(this.getKey(key))
      return true
    } catch (error) {
      console.error(`Failed to remove key '${key}':`, error)
      return false
    }
  }

  /**
   * Check if key exists in storage
   */
  has(key) {
    try {
      return localStorage.getItem(this.getKey(key)) !== null
    } catch (error) {
      console.warn(`Failed to check existence of key '${key}':`, error)
      return false
    }
  }

  /**
   * Clear all storage with prefix
   */
  clear() {
    try {
      const keysToRemove = []
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i)
        if (key && key.startsWith(`${this.prefix}:`)) {
          keysToRemove.push(key)
        }
      }
      
      keysToRemove.forEach(key => localStorage.removeItem(key))
      return true
    } catch (error) {
      console.error('Failed to clear storage:', error)
      return false
    }
  }

  /**
   * Get all keys with prefix
   */
  getAllKeys() {
    try {
      const keys = []
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i)
        if (key && key.startsWith(`${this.prefix}:`)) {
          keys.push(key.substring(`${this.prefix}:`.length))
        }
      }
      return keys
    } catch (error) {
      console.warn('Failed to get all keys:', error)
      return []
    }
  }

  /**
   * Get storage usage information
   */
  getStorageInfo() {
    try {
      let totalSize = 0
      let itemCount = 0
      
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i)
        if (key && key.startsWith(`${this.prefix}:`)) {
          const value = localStorage.getItem(key)
          totalSize += (key.length + (value ? value.length : 0)) * 2 // UTF-16 encoding
          itemCount++
        }
      }
      
      return {
        itemCount,
        totalSize,
        totalSizeKB: Math.round(totalSize / 1024 * 100) / 100,
        totalSizeMB: Math.round(totalSize / (1024 * 1024) * 100) / 100
      }
    } catch (error) {
      console.warn('Failed to get storage info:', error)
      return {
        itemCount: 0,
        totalSize: 0,
        totalSizeKB: 0,
        totalSizeMB: 0
      }
    }
  }
}
