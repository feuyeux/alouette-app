/**
 * Event Bus Utility
 * Simple event system for component communication
 */

export class EventBus {
  constructor() {
    this.events = new Map()
  }

  /**
   * Subscribe to an event
   */
  on(eventName, callback) {
    if (!this.events.has(eventName)) {
      this.events.set(eventName, [])
    }
    
    this.events.get(eventName).push(callback)
    
    // Return unsubscribe function
    return () => this.off(eventName, callback)
  }

  /**
   * Subscribe to an event that only fires once
   */
  once(eventName, callback) {
    const unsubscribe = this.on(eventName, (...args) => {
      unsubscribe()
      callback(...args)
    })
    
    return unsubscribe
  }

  /**
   * Emit an event
   */
  emit(eventName, ...args) {
    const callbacks = this.events.get(eventName)
    if (callbacks) {
      callbacks.forEach(callback => {
        try {
          callback(...args)
        } catch (error) {
          console.error(`Error in event callback for '${eventName}':`, error)
        }
      })
    }
  }

  /**
   * Unsubscribe from an event
   */
  off(eventName, callback) {
    const callbacks = this.events.get(eventName)
    if (callbacks) {
      const index = callbacks.indexOf(callback)
      if (index > -1) {
        callbacks.splice(index, 1)
      }
      
      // Clean up empty event arrays
      if (callbacks.length === 0) {
        this.events.delete(eventName)
      }
    }
  }

  /**
   * Remove all listeners for an event
   */
  removeAllListeners(eventName = null) {
    if (eventName) {
      this.events.delete(eventName)
    } else {
      this.events.clear()
    }
  }

  /**
   * Get list of event names
   */
  getEventNames() {
    return Array.from(this.events.keys())
  }

  /**
   * Get number of listeners for an event
   */
  getListenerCount(eventName) {
    const callbacks = this.events.get(eventName)
    return callbacks ? callbacks.length : 0
  }
}
