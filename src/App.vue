<template>
  <div id="app">
    <!-- Settings Panel -->
    <div class="settings-panel" v-if="showSettings">
      <div class="settings-overlay" @click="showSettings = false"></div>
      <div class="settings-content">
        <!-- Settings Header with Controls -->
        <div class="settings-header">
          <h3>🔧 Application Settings</h3>
          <div class="settings-header-buttons">
            <button @click="saveSettings" class="btn-primary btn-medium">
              ✓ OK
            </button>
            <button @click="cancelSettings" class="btn-ghost btn-medium">
              ✕ Cancel
            </button>
          </div>
        </div>

        <!-- Scrollable Settings Body -->
        <div class="settings-body">
          <!-- LLM Service Settings -->
          <div class="settings-section">
            <h4>🤖 AI Translation Service</h4>

            <!-- Single Row Layout -->
            <div class="service-config-row">
              <!-- Service Type Selection -->
              <div class="service-type-group">
                <label class="config-label">Service Type:</label>
                <div class="service-type-buttons">
                  <label
                    class="service-btn"
                    :class="{ active: llmProvider === 'ollama' }"
                  >
                    <input
                      type="radio"
                      v-model="llmProvider"
                      value="ollama"
                      @change="onProviderChange"
                    />
                    <span class="service-name">Ollama</span>
                    <small>Local AI models</small>
                  </label>
                  <label
                    class="service-btn"
                    :class="{ active: llmProvider === 'lmstudio' }"
                  >
                    <input
                      type="radio"
                      v-model="llmProvider"
                      value="lmstudio"
                      @change="onProviderChange"
                    />
                    <span class="service-name">LM Studio</span>
                    <small>AI inference server</small>
                  </label>
                </div>
              </div>

              <!-- Server Address (Optional) -->
              <div class="server-address-group">
                <label class="config-label">Server Address (Optional):</label>
                <input
                  v-model="serverUrl"
                  type="url"
                  :placeholder="
                    llmProvider === 'ollama'
                      ? 'http://localhost:11434'
                      : llmProvider === 'lmstudio'
                      ? 'http://localhost:1234'
                      : 'Select service type first'
                  "
                  class="server-input"
                  :disabled="!llmProvider"
                />
              </div>

              <!-- Connect Button -->
              <div class="connect-group">
                <label class="config-label">&nbsp;</label>
                <button
                  @click="testConnection"
                  class="btn-primary btn-medium connect-btn"
                  :disabled="!llmProvider || isTestingConnection"
                >
                  {{ isTestingConnection ? "Connecting..." : "Connect" }}
                </button>
              </div>
            </div>

            <!-- Connection Status -->
            <div
              v-if="connectionStatus"
              :class="['connection-status', connectionStatus.type]"
            >
              {{ connectionStatus.message }}
            </div>

            <!-- Model Selection -->
            <div class="setting-group" v-if="availableModels.length > 0">
              <label>Available Models:</label>
              <select v-model="selectedModel" class="setting-select">
                <option value="">Select a model</option>
                <option
                  v-for="model in availableModels"
                  :key="model"
                  :value="model"
                >
                  {{ model }}
                </option>
              </select>
            </div>
          </div>

          <!-- TTS Settings -->
          <div class="settings-section">
            <h4>🔊 Text-to-Speech Settings</h4>

            <div class="tts-controls-grid">
              <div class="setting-group">
                <label>Rate:</label>
                <div class="range-setting">
                  <input
                    v-model="ttsSettings.rate"
                    type="range"
                    min="0.1"
                    max="2"
                    step="0.1"
                    class="range-input"
                  />
                  <span class="range-value">{{ ttsSettings.rate }}x</span>
                </div>
              </div>

              <div class="setting-group">
                <label>Volume:</label>
                <div class="range-setting">
                  <input
                    v-model="ttsSettings.volume"
                    type="range"
                    min="0"
                    max="1"
                    step="0.1"
                    class="range-input"
                  />
                  <span class="range-value">{{ Math.round(ttsSettings.volume * 100) }}%</span>
                </div>
              </div>

              <div class="setting-group">
                <label>Pause:</label>
                <div class="range-setting">
                  <input
                    v-model="ttsSettings.pauseBetweenLanguages"
                    type="range"
                    min="0"
                    max="2000"
                    step="100"
                    class="range-input"
                  />
                  <span class="range-value">{{ ttsSettings.pauseBetweenLanguages }}ms</span>
                </div>
              </div>
            </div>

            <div class="setting-group">
              <label class="checkbox-label">
                <input
                  v-model="ttsSettings.autoSelectVoice"
                  type="checkbox"
                  class="checkbox-input"
                />
                Auto-select matching voice
              </label>
            </div>

            <div class="setting-group">
              <button
                @click="testTTS"
                class="btn-secondary btn-medium"
                :disabled="isTesting"
              >
                {{ isTesting ? "Testing..." : "Test Speech" }}
              </button>
            </div>
          </div>

          <!-- TTS Cache Management -->
          <div class="settings-section">
            <h4>💾 Cache Management</h4>

            <div class="setting-group">
              <div class="cache-info" v-if="cacheInfo">
                <p>📊 {{ cacheInfo.file_count }} files, {{ cacheInfo.total_size_mb.toFixed(2) }} MB</p>
              </div>
              <div class="cache-buttons btn-group-tight">
                <button
                  @click="refreshCacheInfo"
                  class="btn-info btn-small"
                  :disabled="isRefreshingCache"
                >
                  {{ isRefreshingCache ? "Refreshing..." : "🔄 Refresh" }}
                </button>
                <button
                  @click="clearCache"
                  class="btn-danger btn-small"
                  :disabled="isClearingCache"
                >
                  {{ isClearingCache ? "Clearing..." : "🗑️ Clear" }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Interface -->
    <header>
      <div class="header-logo">
        🐦
      </div>
      <h1>Alouette</h1>
      <div class="header-actions">
        <button @click="showSettings = true" class="btn-light btn-small">
          ⚙️ Settings
        </button>

        <button
          @click="translateText"
          :disabled="
            isTranslating || !inputText.trim() || selectedLanguages.length === 0
          "
          class="btn-secondary btn-small"
        >
          {{ isTranslating ? "⏳ Translating..." : "🌐 Translate" }}
        </button>
        <button @click="clearAll" class="btn-ghost btn-small">🗑️ Clear</button>
      </div>
    </header>

    <!-- LLM Service Status -->
    <div class="llm-status-bar">
      <div class="llm-info">
        <div class="status-section">
          <span class="status-label">🤖 LLM Service:</span>
          <span
            :class="[
              'status-value',
              {
                'status-connected': isConfigured,
                'status-disconnected': !isConfigured,
              },
            ]"
          >
            {{ isConfigured ? "Connected" : "Not Configured" }}
          </span>
        </div>
        <div class="status-section" v-if="llmProvider">
          <span class="status-label">🔧 Provider:</span>
          <span class="status-value">{{
            llmProvider === "ollama" ? "Ollama" : "LM Studio"
          }}</span>
        </div>
        <div class="status-section" v-if="serverUrl">
          <span class="status-label">🌐 Server:</span>
          <span class="status-value">{{ formatServerUrl(serverUrl) }}</span>
        </div>
        <div class="status-section" v-if="selectedModel">
          <span class="status-label">🧠 Model:</span>
          <span class="status-value">{{ selectedModel }}</span>
        </div>
        <div class="status-section" v-if="availableModels.length > 0">
          <span class="status-label">📊 Available Models:</span>
          <span class="status-value">{{ availableModels.length }}</span>
        </div>
      </div>
    </div>

    <!-- Warning Notice -->
    <div v-if="showTauriWarning" class="warning-card">
      <div class="warning-content">
        <span class="warning-icon">⚠️</span>
        <div class="warning-text">
          <strong>Notice:</strong> Currently running in web mode, speech
          features may be limited. <br />Recommended to download the desktop
          version for full functionality.
        </div>
        <button
          @click="showTauriWarning = false"
          class="btn-danger btn-mini btn-icon-only"
        >
          ×
        </button>
      </div>
    </div>

    <!-- Translation Input Section -->
    <div class="translation-section">
      <!-- Language Selection - Top Position -->
      <div class="language-selection">
        <label class="control-label">Select languages:</label>
        <div class="language-grid">
          <label
            v-for="language in availableLanguages"
            :key="language"
            class="language-option"
            :class="{ 'select-all-option': language === 'All' }"
          >
            <input
              type="checkbox"
              :value="language"
              v-model="selectedLanguages"
              :checked="
                language === 'All'
                  ? isAllSelected
                  : selectedLanguages.includes(language)
              "
              @change="language === 'All' ? toggleSelectAll($event) : null"
            />
            <span class="language-name">
              <span v-if="language === 'All'">
                ALL ({{
                  selectedLanguages.filter((lang) => lang !== "All").length
                }}/{{
                  availableLanguages.filter((lang) => lang !== "All").length
                }})
              </span>
              <span v-else>{{ getLanguageAbbreviation(language) }}</span>
            </span>
          </label>
        </div>
      </div>

      <!-- Main Translation Interface -->
      <div class="translation-interface">
        <!-- Text Input -->
        <div class="input-area">
          <textarea
            v-model="inputText"
            placeholder="Enter text to translate..."
            rows="4"
            class="translation-input"
          ></textarea>
        </div>
      </div>
    </div>

    <!-- Translation Results -->
    <div class="results-section" v-if="currentTranslation">
      <div class="results-header">
        <h3>📚 Translation Results</h3>
        <div class="control-buttons btn-group-tight">
          <button
            @click="playAll"
            :disabled="isPlayingAll || playingText"
            class="btn-secondary btn-medium"
          >
            {{ isPlayingAll ? "⏸️ Pause" : "🎵 Play All" }}
          </button>
          <button
            @click="stopPlayAll"
            :disabled="!playingText && !isPlayingAll"
            class="btn-danger btn-medium"
          >
            🛑 Stop
          </button>
        </div>
      </div>

      <!-- Original Text Display -->
      <div class="original-text">
        <span class="original-label">Original:</span>
        <span class="original-content">{{ currentTranslation.original }}</span>
      </div>

      <!-- Translation Results List -->
      <div class="translations">
        <div
          v-for="language in orderedLanguages"
          :key="language"
          class="translation-row"
        >
          <div class="language-name">
            {{ getLanguageAbbreviation(language) }}
          </div>
          <div class="translation-text" :class="getLanguageClass(language)">
            {{ currentTranslation.translations[language] }}
          </div>
          <button
            @click="
              playTTS(currentTranslation.translations[language], language, true)
            "
            :disabled="
              playingText === currentTranslation.translations[language]
            "
            :class="[
              'btn-primary',
              'btn-small',
              {
                'btn-playing':
                  playingText === currentTranslation.translations[language],
              },
            ]"
          >
            {{
              playingText === currentTranslation.translations[language]
                ? "🔊"
                : "▶️"
            }}
          </button>
        </div>
      </div>
    </div>

    <!-- Results Placeholder -->
    <div v-else class="results-placeholder">
      <div class="placeholder-content">
        <div class="placeholder-icon">🌐</div>
        <h3>Ready to Translate</h3>
        <p>
          Enter text above, select your target languages, and click "Translate"
          to see results here.
        </p>
        <div class="placeholder-steps">
          <div class="step">
            <span class="step-number">1</span>
            <span class="step-text">Select languages</span>
          </div>
          <div class="step">
            <span class="step-number">2</span>
            <span class="step-text">Enter text</span>
          </div>
          <div class="step">
            <span class="step-number">3</span>
            <span class="step-text">Translate</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import AppComponent from "./lib/components/app-component-simple.js";
export default AppComponent;
</script>

<style>
@import "./styles/main.css";
</style>
