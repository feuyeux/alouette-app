/**
 * Cache Management Service
 * Handles TTS cache operations and management
 */

import { invoke } from '@tauri-apps/api/core'
import { isTauriEnv } from '../utils/environment.js'

/**
 * Cache Management Service class
 */
export class CacheService {
    constructor() {
        this.cacheInfo = null
        this.isRefreshingCache = false
        this.isClearingCache = false
    }

    /**
     * Get TTS cache information
     * @returns {Promise<Object>} Cache information object
     */
    async getCacheInfo() {
        if (!isTauriEnv()) {
            throw new Error('Cache info requires Tauri environment. Please run: npm run dev')
        }

        this.isRefreshingCache = true
        try {
            console.log('Fetching TTS cache information...')
            this.cacheInfo = await invoke('get_tts_cache_info')
            console.log('Cache information retrieved:', this.cacheInfo)
            return this.cacheInfo
        } catch (error) {
            console.error('Failed to get cache information:', error)
            throw new Error(`Failed to get cache information: ${error.message || error}`)
        } finally {
            this.isRefreshingCache = false
        }
    }

    /**
     * Refresh cache information
     * @returns {Promise<Object>} Updated cache information
     */
    async refreshCacheInfo() {
        return await this.getCacheInfo()
    }

    /**
     * Clear all TTS cache files
     * @returns {Promise<number>} Size of cleared cache in bytes
     */
    async clearCache() {
        if (!isTauriEnv()) {
            throw new Error('Cache clearing requires Tauri environment. Please run: npm run dev')
        }

        this.isClearingCache = true

        try {
            console.log('Starting TTS cache cleanup...')
            const clearedSize = await invoke('clear_tts_cache')

            const clearedMB = (clearedSize / (1024 * 1024)).toFixed(2)
            console.log(`Cache cleared successfully. Freed ${clearedMB} MB of disk space.`)

            // Refresh cache information after clearing
            await this.refreshCacheInfo()

            return {
                clearedSize,
                clearedMB: parseFloat(clearedMB),
                message: `Cache cleared successfully! Freed ${clearedMB} MB of disk space.`
            }

        } catch (error) {
            console.error('Failed to clear cache:', error)
            throw new Error(`Failed to clear cache: ${error.message || error}`)
        } finally {
            this.isClearingCache = false
        }
    }

    /**
     * Format cache size for display
     * @param {number} bytes - Size in bytes
     * @returns {string} Formatted size string
     */
    formatCacheSize(bytes) {
        if (!bytes || bytes === 0) return '0 B'

        const units = ['B', 'KB', 'MB', 'GB']
        let size = bytes
        let unitIndex = 0

        while (size >= 1024 && unitIndex < units.length - 1) {
            size /= 1024
            unitIndex++
        }

        return `${size.toFixed(unitIndex === 0 ? 0 : 2)} ${units[unitIndex]}`
    }

    /**
     * Get cache statistics for display
     * @returns {Object|null} Formatted cache statistics
     */
    getCacheStats() {
        if (!this.cacheInfo) return null

        return {
            fileCount: this.cacheInfo.file_count || 0,
            totalSize: this.formatCacheSize(this.cacheInfo.total_size || 0),
            totalSizeBytes: this.cacheInfo.total_size || 0,
            isLarge: (this.cacheInfo.total_size || 0) > 100 * 1024 * 1024, // > 100MB
            isEmpty: (this.cacheInfo.file_count || 0) === 0
        }
    }

    /**
     * Get cache management state
     * @returns {Object} Current state of cache operations
     */
    getCacheState() {
        return {
            cacheInfo: this.cacheInfo,
            isRefreshingCache: this.isRefreshingCache,
            isClearingCache: this.isClearingCache,
            hasCache: !!this.cacheInfo,
            stats: this.getCacheStats()
        }
    }

    /**
     * Check if cache needs attention (too large or too many files)
     * @returns {Object} Cache health check result
     */
    checkCacheHealth() {
        const stats = this.getCacheStats()
        if (!stats) {
            return {
                needsAttention: false,
                message: 'Cache information not available'
            }
        }

        const sizeMB = stats.totalSizeBytes / (1024 * 1024)
        const fileCount = stats.fileCount

        if (sizeMB > 500) {
            return {
                needsAttention: true,
                level: 'warning',
                message: `Cache is very large (${stats.totalSize}). Consider clearing it to free disk space.`
            }
        }

        if (fileCount > 1000) {
            return {
                needsAttention: true,
                level: 'info',
                message: `Cache contains many files (${fileCount}). Consider clearing old files.`
            }
        }

        if (sizeMB > 100) {
            return {
                needsAttention: true,
                level: 'info',
                message: `Cache size: ${stats.totalSize}. You can clear it to free disk space if needed.`
            }
        }

        return {
            needsAttention: false,
            level: 'good',
            message: `Cache is healthy: ${stats.totalSize} in ${fileCount} files.`
        }
    }

    /**
     * Get cache recommendations
     * @returns {Array} Array of recommendation objects
     */
    getCacheRecommendations() {
        const health = this.checkCacheHealth()
        const recommendations = []

        if (health.needsAttention) {
            switch (health.level) {
                case 'warning':
                    recommendations.push({
                        type: 'clear',
                        priority: 'high',
                        message: 'Clear cache to free significant disk space',
                        action: 'Clear Cache'
                    })
                    break

                case 'info':
                    recommendations.push({
                        type: 'consider_clear',
                        priority: 'medium',
                        message: 'Consider clearing cache to free space and improve performance',
                        action: 'Clear Cache'
                    })
                    break
            }
        }

        // Always show refresh option if cache info is stale
        recommendations.push({
            type: 'refresh',
            priority: 'low',
            message: 'Refresh cache information to see current status',
            action: 'Refresh Info'
        })

        return recommendations
    }
}
