use crate::edge_tts::EdgeTTSClient;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

#[cfg(not(target_os = "android"))]
use rodio::{Decoder, OutputStream, Sink};
#[cfg(not(target_os = "android"))]
use std::io::Cursor;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoiceInfo {
    pub name: String,
    pub display_name: String,
    pub language: String,
    pub gender: String,
    pub locale: String,
    pub edge_voice: String,
}

impl VoiceInfo {
    pub fn new(name: &str, display_name: &str, language: &str, gender: &str, locale: &str, edge_voice: &str) -> Self {
        Self {
            name: name.to_string(),
            display_name: display_name.to_string(),
            language: language.to_string(),
            gender: gender.to_string(),
            locale: locale.to_string(),
            edge_voice: edge_voice.to_string(),
        }
    }
}

pub struct TTSEngine {
    voices: Vec<VoiceInfo>,
    cache_dir: PathBuf,
}

impl TTSEngine {
    pub fn new() -> Self {
        let cache_dir = Self::get_cache_dir();
        Self {
            voices: Self::init_voices(),
            cache_dir,
        }
    }

    fn get_cache_dir() -> PathBuf {
        // Use user cache directory
        if let Some(cache_dir) = dirs::cache_dir() {
            cache_dir.join("alouette").join("tts_cache")
        } else {
            // Fallback to temp directory
            std::env::temp_dir().join("alouette_tts_cache")
        }
    }

    // Cache key generation moved inline to synthesize_speech_desktop

    // Cache functions removed as they are not used in Android TTS

    pub async fn clear_cache(&self) -> Result<u64, String> {
        let mut total_size = 0u64;
        let mut files_removed = 0u64;

        if !self.cache_dir.exists() {
            return Ok(0);
        }

        let mut entries = tokio::fs::read_dir(&self.cache_dir).await
            .map_err(|e| format!("Failed to read cache directory: {}", e))?;

        while let Some(entry) = entries.next_entry().await
            .map_err(|e| format!("Failed to iterate cache directory: {}", e))? {
            
            let path = entry.path();
            if path.is_file() {
                if let Ok(metadata) = tokio::fs::metadata(&path).await {
                    total_size += metadata.len();
                }
                
                if let Err(e) = tokio::fs::remove_file(&path).await {
                    println!("Failed to delete cache file: {} - {}", path.display(), e);
                } else {
                    files_removed += 1;
                }
            }
        }

        println!("TTS cache cleanup completed: deleted {} files, freed {} bytes", files_removed, total_size);
        Ok(total_size)
    }

    pub async fn get_cache_info(&self) -> Result<(u64, u64), String> {
        let mut total_size = 0u64;
        let mut file_count = 0u64;

        if !self.cache_dir.exists() {
            return Ok((0, 0));
        }

        let mut entries = tokio::fs::read_dir(&self.cache_dir).await
            .map_err(|e| format!("Failed to read cache directory: {}", e))?;

        while let Some(entry) = entries.next_entry().await
            .map_err(|e| format!("Failed to iterate cache directory: {}", e))? {
            
            let path = entry.path();
            if path.is_file() {
                if let Ok(metadata) = tokio::fs::metadata(&path).await {
                    total_size += metadata.len();
                    file_count += 1;
                }
            }
        }

        Ok((file_count, total_size))
    }

    fn init_voices() -> Vec<VoiceInfo> {
        vec![
            // English
            VoiceInfo::new("en-US-AriaNeural", "Aria", "English", "Female", "en-US", "en-US-AriaNeural"),
            VoiceInfo::new("en-US-AndrewNeural", "Andrew", "English", "Male", "en-US", "en-US-AndrewNeural"),
            
            // French
            VoiceInfo::new("fr-FR-DeniseNeural", "Denise", "French", "Female", "fr-FR", "fr-FR-DeniseNeural"),
            VoiceInfo::new("fr-FR-HenriNeural", "Henri", "French", "Male", "fr-FR", "fr-FR-HenriNeural"),
            
            // Spanish
            VoiceInfo::new("es-ES-ElviraNeural", "Elvira", "Spanish", "Female", "es-ES", "es-ES-ElviraNeural"),
            VoiceInfo::new("es-ES-AlvaroNeural", "Alvaro", "Spanish", "Male", "es-ES", "es-ES-AlvaroNeural"),
            
            // Italian
            VoiceInfo::new("it-IT-ElsaNeural", "Elsa", "Italian", "Female", "it-IT", "it-IT-ElsaNeural"),
            VoiceInfo::new("it-IT-DiegoNeural", "Diego", "Italian", "Male", "it-IT", "it-IT-DiegoNeural"),
            
            // Russian
            VoiceInfo::new("ru-RU-SvetlanaNeural", "Svetlana", "Russian", "Female", "ru-RU", "ru-RU-SvetlanaNeural"),
            VoiceInfo::new("ru-RU-DmitryNeural", "Dmitry", "Russian", "Male", "ru-RU", "ru-RU-DmitryNeural"),
            
            // Greek
            VoiceInfo::new("el-GR-AthinaNeural", "Athina", "Greek", "Female", "el-GR", "el-GR-AthinaNeural"),
            VoiceInfo::new("el-GR-NestorNeural", "Nestor", "Greek", "Male", "el-GR", "el-GR-NestorNeural"),
            
            // German
            VoiceInfo::new("de-DE-KatjaNeural", "Katja", "German", "Female", "de-DE", "de-DE-KatjaNeural"),
            VoiceInfo::new("de-DE-ConradNeural", "Conrad", "German", "Male", "de-DE", "de-DE-ConradNeural"),
            
            // Hindi
            VoiceInfo::new("hi-IN-SwaraNeural", "Swara", "Hindi", "Female", "hi-IN", "hi-IN-SwaraNeural"),
            VoiceInfo::new("hi-IN-MadhurNeural", "Madhur", "Hindi", "Male", "hi-IN", "hi-IN-MadhurNeural"),
            
            // Arabic
            VoiceInfo::new("ar-SA-ZariyahNeural", "Zariyah", "Arabic", "Female", "ar-SA", "ar-SA-ZariyahNeural"),
            VoiceInfo::new("ar-SA-HamedNeural", "Hamed", "Arabic", "Male", "ar-SA", "ar-SA-HamedNeural"),
            
            // Japanese
            VoiceInfo::new("ja-JP-NanamiNeural", "ななみ", "Japanese", "Female", "ja-JP", "ja-JP-NanamiNeural"),
            VoiceInfo::new("ja-JP-KeitaNeural", "けいた", "Japanese", "Male", "ja-JP", "ja-JP-KeitaNeural"),
            
            // Korean
            VoiceInfo::new("ko-KR-SunHiNeural", "Sun-Hi", "Korean", "Female", "ko-KR", "ko-KR-SunHiNeural"),
            VoiceInfo::new("ko-KR-InJoonNeural", "InJoon", "Korean", "Male", "ko-KR", "ko-KR-InJoonNeural"),

            // Chinese
            VoiceInfo::new("zh-CN-XiaoxiaoNeural", "Xiaoxiao", "Chinese", "Female", "zh-CN", "zh-CN-XiaoxiaoNeural"),
            VoiceInfo::new("zh-CN-YunxiNeural", "Yunxi", "Chinese", "Male", "zh-CN", "zh-CN-YunxiNeural"),
        ]
    }

    pub fn get_available_voices(&self) -> &Vec<VoiceInfo> {
        &self.voices
    }

    pub async fn get_voices_by_language(&self) -> HashMap<String, Vec<String>> {
        // Try to get real voices from Edge TTS
        match EdgeTTSClient::new().await {
            Ok(client) => {
                println!("✅ Using real Edge TTS voices");
                client.get_voices_by_language()
            },
            Err(e) => {
                println!("⚠️ Failed to load Edge TTS voices ({}), using fallback", e);
                self.get_fallback_voices()
            }
        }
    }

    fn get_fallback_voices(&self) -> HashMap<String, Vec<String>> {
        let mut voices_map = HashMap::new();
        
        voices_map.insert("English".to_string(), vec![
            "en-US-AriaNeural (Aria, Female, Confident & Positive)".to_string(),
            "en-US-AndrewNeural (Andrew, Male, Warm & Confident)".to_string(),
        ]);
        
        voices_map.insert("French".to_string(), vec![
            "fr-FR-DeniseNeural (Denise, Female, Elegant)".to_string(),
            "fr-FR-HenriNeural (Henri, Male, Steady)".to_string(),
        ]);

        voices_map.insert("Spanish".to_string(), vec![
            "es-ES-ElviraNeural (Elvira, Female, Lively)".to_string(),
            "es-ES-AlvaroNeural (Alvaro, Male, Mature)".to_string(),
        ]);

        voices_map.insert("Italian".to_string(), vec![
            "it-IT-ElsaNeural (Elsa, Female, Warm)".to_string(),
            "it-IT-DiegoNeural (Diego, Male, Friendly)".to_string(),
        ]);

        voices_map.insert("Russian".to_string(), vec![
            "ru-RU-SvetlanaNeural (Svetlana, Female, Gentle)".to_string(),
            "ru-RU-DmitryNeural (Dmitry, Male, Deep)".to_string(),
        ]);

        voices_map.insert("Greek".to_string(), vec![
            "el-GR-AthinaNeural (Athina, Female, Clear)".to_string(),
            "el-GR-NestorNeural (Nestor, Male, Authoritative)".to_string(),
        ]);

        voices_map.insert("German".to_string(), vec![
            "de-DE-KatjaNeural (Katja, Female, Professional)".to_string(),
            "de-DE-ConradNeural (Conrad, Male, Reliable)".to_string(),
        ]);

        voices_map.insert("Hindi".to_string(), vec![
            "hi-IN-SwaraNeural (Swara, Female, Sweet)".to_string(),
            "hi-IN-MadhurNeural (Madhur, Male, Magnetic)".to_string(),
        ]);

        voices_map.insert("Arabic".to_string(), vec![
            "ar-SA-ZariyahNeural (Zariyah, Female, Elegant)".to_string(),
            "ar-SA-HamedNeural (Hamed, Male, Steady)".to_string(),
        ]);

        voices_map.insert("Japanese".to_string(), vec![
            "ja-JP-NanamiNeural (ななみ, Female, Gentle)".to_string(),
            "ja-JP-KeitaNeural (けいた, Male, Natural)".to_string(),
        ]);

        voices_map.insert("Korean".to_string(), vec![
            "ko-KR-SunHiNeural (Sun-Hi, Female, Bright)".to_string(),
            "ko-KR-InJoonNeural (InJoon, Male, Mature)".to_string(),
        ]);

        voices_map.insert("Chinese".to_string(), vec![
            "zh-CN-XiaoxiaoNeural (Xiaoxiao, Female, Warm)".to_string(),
            "zh-CN-YunxiNeural (Yunxi, Male, Lively)".to_string(),
        ]);

        voices_map
    }

    // Voice selection moved inline to synthesize_speech_desktop

    /// Safe text truncation that respects UTF-8 boundaries
    fn safe_truncate(text: &str, max_len: usize) -> String {
        if text.chars().count() <= max_len {
            text.to_string()
        } else {
            text.chars().take(max_len).collect::<String>() + "..."
        }
    }


    
    /// Select voice for specific language
    fn select_voice_for_language(&self, language: &str) -> VoiceInfo {
        // Find matching voice or return default English voice
        for voice in &self.voices {
            if voice.language.to_lowercase() == language.to_lowercase() {
                return voice.clone();
            }
        }
        
        // Default to first English voice or first available voice
        for voice in &self.voices {
            if voice.language.to_lowercase() == "english" {
                return voice.clone();
            }
        }
        
        // Fallback to first available voice or create default
        self.voices.first().cloned().unwrap_or_else(|| {
            VoiceInfo::new(
                "en-US-AriaNeural",
                "Aria (English US)",
                "English",
                "Female",
                "en-US",
                "en-US-AriaNeural"
            )
        })
    }
    
    /// Generate cache key for TTS request
    fn generate_cache_key(&self, text: &str, voice: &str) -> String {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        
        let mut hasher = DefaultHasher::new();
        text.hash(&mut hasher);
        voice.hash(&mut hasher);
        format!("tts_{}_{:x}", voice.replace("-", "_"), hasher.finish())
    }
    
    /// Get audio from cache
    async fn get_from_cache(&self, cache_key: &str) -> Option<Vec<u8>> {
        let cache_path = self.cache_dir.join(format!("{}.wav", cache_key));
        if cache_path.exists() {
            if let Ok(data) = tokio::fs::read(&cache_path).await {
                println!("Cache hit: {}", cache_key);
                return Some(data);
            }
        }
        None
    }
    
    /// Save audio to cache
    async fn save_to_cache(&self, cache_key: &str, audio_data: &[u8]) -> Result<(), String> {
        // Ensure cache directory exists
        if let Err(e) = tokio::fs::create_dir_all(&self.cache_dir).await {
            return Err(format!("Failed to create cache directory: {}", e));
        }
        
        let cache_path = self.cache_dir.join(format!("{}.wav", cache_key));
        if let Err(e) = tokio::fs::write(&cache_path, audio_data).await {
            return Err(format!("Failed to save to cache: {}", e));
        }
        
        println!("Cached TTS audio: {}", cache_key);
        Ok(())
    }
    
    /// Pure Rust implementation of Edge TTS API
    /// This doesn't require edge-tts command line tool
    async fn synthesize_with_edge_tts_api(&self, text: &str, voice: &str) -> Result<Vec<u8>, String> {
        println!("🌐 [TTS-EDGE-API] Attempting Edge TTS API synthesis");
        println!("🌐 [TTS-EDGE-API] Voice: {}", voice);
        
        // Create Edge TTS client
        println!("🔧 [TTS-EDGE-API] Creating Edge TTS client...");
        let client = EdgeTTSClient::new().await
            .map_err(|e| {
                println!("❌ [TTS-EDGE-API] Failed to create client: {}", e);
                format!("Failed to create Edge TTS client: {}", e)
            })?;
        
        println!("✅ [TTS-EDGE-API] Client created successfully");
        
        // Find the voice or use a fallback
        println!("🔍 [TTS-EDGE-API] Looking for voice: {}", voice);
        let selected_voice = if let Some(voice_info) = client.find_voice_by_language(voice) {
            println!("✅ [TTS-EDGE-API] Found voice: {}", voice_info.short_name);
            voice_info.short_name.clone()
        } else {
            // Try to use the voice name directly
            println!("⚠️ [TTS-EDGE-API] Voice not found, trying direct name: {}", voice);
            voice.to_string()
        };
        
        println!("🎙️ [TTS-EDGE-API] Using Edge TTS voice: {}", selected_voice);
        
        // Perform synthesis
        println!("🔄 [TTS-EDGE-API] Starting synthesis...");
        let audio_data = client.synthesize(text, &selected_voice).await
            .map_err(|e| {
                println!("❌ [TTS-EDGE-API] Synthesis failed: {}", e);
                format!("Edge TTS synthesis failed: {}", e)
            })?;
            
        if audio_data.is_empty() {
            println!("❌ [TTS-EDGE-API] Empty audio data returned");
            return Err("Edge TTS returned empty audio data".to_string());
        }
        
        println!("✅ [TTS-EDGE-API] Synthesis successful: {} bytes", audio_data.len());
        Ok(audio_data)
    }

    /// Original edge-tts command line implementation (fallback)
    async fn synthesize_with_edge_tts_cli(&self, text: &str, voice: &str) -> Result<Vec<u8>, String> {
        println!("🔧 [TTS-EDGE-CLI] Attempting edge-tts CLI synthesis");
        println!("🔧 [TTS-EDGE-CLI] Voice: {}", voice);
        
        // Try Edge TTS command
        println!("🔧 [TTS-EDGE-CLI] Executing edge-tts command...");
        let output = tokio::process::Command::new("edge-tts")
            .args(&[
                "--voice", voice,
                "--text", text,
                "--write-media", "/dev/stdout"
            ])
            .output()
            .await;
            
        match output {
            Ok(result) => {
                println!("🔧 [TTS-EDGE-CLI] Command executed, status: {}", result.status);
                if result.status.success() && !result.stdout.is_empty() {
                    println!("✅ [TTS-EDGE-CLI] CLI synthesis successful, {} bytes generated", result.stdout.len());
                    Ok(result.stdout)
                } else {
                    let error_msg = String::from_utf8_lossy(&result.stderr);
                    println!("❌ [TTS-EDGE-CLI] CLI failed: {}", error_msg);
                    Err(format!("Edge TTS CLI failed: {}", error_msg))
                }
            }
            Err(e) => {
                println!("❌ [TTS-EDGE-CLI] Failed to execute command: {}", e);
                Err(format!("Failed to execute edge-tts: {}", e))
            }
        }
    }

    /// Synthesize speech with Edge TTS - tries API first, then CLI
    async fn synthesize_with_edge_tts(&self, text: &str, voice: &str) -> Result<Vec<u8>, String> {
        println!("🌐 [TTS-EDGE] Starting Edge TTS synthesis");
        println!("🌐 [TTS-EDGE] Voice: {}", voice);
        println!("🌐 [TTS-EDGE] Text length: {} chars", text.len());
        
        // Method 1: Try pure Rust API implementation (preferred)
        println!("🦀 [TTS-EDGE] Trying Rust API implementation...");
        match self.synthesize_with_edge_tts_api(text, voice).await {
            Ok(audio_data) => {
                println!("✅ [TTS-EDGE] Rust API synthesis successful");
                return Ok(audio_data);
            },
            Err(e) => {
                println!("⚠️ [TTS-EDGE] Rust API failed: {}, trying CLI fallback", e);
            }
        }
        
        // Method 2: Fallback to command line tool
        println!("🔧 [TTS-EDGE] Trying CLI fallback...");
        let result = self.synthesize_with_edge_tts_cli(text, voice).await;
        
        match &result {
            Ok(audio_data) => println!("✅ [TTS-EDGE] CLI synthesis successful: {} bytes", audio_data.len()),
            Err(e) => println!("❌ [TTS-EDGE] CLI synthesis failed: {}", e),
        }
        
        result
    }
    
    /// Synthesize speech with local TTS engine
    async fn synthesize_with_local_tts(&self, text: &str, locale: &str) -> Result<Vec<u8>, String> {
        println!("Attempting local TTS synthesis with locale: {}", locale);
        
        // Try espeak-ng first
        let output = tokio::process::Command::new("espeak-ng")
            .args(&[
                "-v", locale,
                "-s", "150",  // Speed
                "-a", "100",  // Amplitude
                "--stdout",
                text
            ])
            .output()
            .await;
            
        match output {
            Ok(result) => {
                if result.status.success() && !result.stdout.is_empty() {
                    println!("✅ Local TTS synthesis successful, {} bytes generated", result.stdout.len());
                    Ok(result.stdout)
                } else {
                    // Try flite as fallback
                    self.synthesize_with_flite(text).await
                }
            }
            Err(_) => {
                // Try flite as fallback
                self.synthesize_with_flite(text).await
            }
        }
    }
    
    /// Synthesize speech with Flite (fallback)
    async fn synthesize_with_flite(&self, text: &str) -> Result<Vec<u8>, String> {
        println!("Attempting Flite TTS synthesis as fallback");
        
        let output = tokio::process::Command::new("flite")
            .args(&["-t", text, "-o", "/dev/stdout"])
            .output()
            .await;
            
        match output {
            Ok(result) => {
                if result.status.success() && !result.stdout.is_empty() {
                    println!("✅ Flite TTS synthesis successful, {} bytes generated", result.stdout.len());
                    Ok(result.stdout)
                } else {
                    Err("All TTS engines failed".to_string())
                }
            }
            Err(e) => Err(format!("Failed to execute flite: {}", e))
        }
    }

    pub async fn synthesize_speech(&self, text: &str, language: &str) -> Result<Vec<u8>, String> {
        let display_text = Self::safe_truncate(text, 50);
        println!("🔊 [TTS-MAIN] Starting synthesis request");
        println!("🔊 [TTS-MAIN] Language: {}", language);
        println!("🔊 [TTS-MAIN] Text length: {} chars", text.chars().count());
        println!("🔊 [TTS-MAIN] Content preview: '{}'", display_text);
        println!("🔊 [TTS-MAIN] Cache directory: {:?}", self.cache_dir);

        // Basic text validation
        if text.trim().is_empty() {
            println!("❌ [TTS-MAIN] Error: Empty text provided");
            return Err("Cannot synthesize empty text".to_string());
        }

        // Check network connectivity for Edge TTS
        println!("🌐 [TTS-MAIN] Checking network connectivity for Edge TTS...");
        match self.check_network_connectivity().await {
            Ok(()) => println!("✅ [TTS-MAIN] Network connectivity OK"),
            Err(e) => println!("⚠️ [TTS-MAIN] Network connectivity issue: {}", e),
        }

        // Unified TTS approach for all platforms
        println!("🔄 [TTS-MAIN] Starting unified synthesis...");
        let result = self.synthesize_unified(text, language).await;
        
        match &result {
            Ok(data) => println!("✅ [TTS-MAIN] Synthesis successful: {} bytes", data.len()),
            Err(e) => println!("❌ [TTS-MAIN] Synthesis failed: {}", e),
        }
        
        result
    }

    /// Unified TTS synthesis that works on all platforms
    async fn synthesize_unified(&self, text: &str, language: &str) -> Result<Vec<u8>, String> {
        // Use the language parameter directly as specified by the user interface
        // This prevents incorrect auto-detection (e.g., Japanese text with kanji being detected as Chinese)
        let final_language = language.to_string();
        
        println!("🎯 [TTS-UNIFIED] Using specified language: {}", final_language);

        let selected_voice = self.select_voice_for_language(&final_language);
        println!("🎙️ [TTS-UNIFIED] Selected voice: {} ({}) for language: {}", 
                 selected_voice.edge_voice, selected_voice.display_name, final_language);

        // Generate cache key
        let cache_key = self.generate_cache_key(text, &selected_voice.edge_voice);
        println!("🔑 [TTS-UNIFIED] Cache key: {}", cache_key);
        
        // Try to get from cache first
        println!("💾 [TTS-UNIFIED] Checking cache...");
        if let Some(cached_audio) = self.get_from_cache(&cache_key).await {
            println!("💾 [TTS-UNIFIED] Cache hit! Using cached audio, size: {} bytes", cached_audio.len());
            return Ok(cached_audio);
        }

        println!("🔄 [TTS-UNIFIED] Cache miss, starting TTS synthesis...");
        
        // Try different TTS methods in order of preference
        let audio_data = self.try_tts_methods(text, &selected_voice).await?;

        // Save result to cache
        println!("💾 [TTS-UNIFIED] Saving to cache...");
        if let Err(e) = self.save_to_cache(&cache_key, &audio_data).await {
            println!("⚠️ [TTS-UNIFIED] Failed to save TTS cache: {}", e);
        } else {
            println!("✅ [TTS-UNIFIED] Successfully saved to cache");
        }

        Ok(audio_data)
    }

    /// Try different TTS methods in order of preference
    async fn try_tts_methods(&self, text: &str, voice: &VoiceInfo) -> Result<Vec<u8>, String> {
        println!("🚀 [TTS-METHODS] Starting TTS method attempts...");
        
        // Method 1: Try Edge TTS (best quality, works on all platforms if installed)
        println!("🌟 [TTS-METHODS] Method 1: Trying Edge TTS...");
        match self.synthesize_with_edge_tts(text, &voice.edge_voice).await {
            Ok(audio_data) => {
                println!("✅ [TTS-METHODS] Edge TTS synthesis successful, {} bytes generated", audio_data.len());
                return Ok(audio_data);
            },
            Err(e) => {
                println!("❌ [TTS-METHODS] Edge TTS failed: {}", e);
            }
        }

        // Method 2: Try local TTS engines (espeak-ng, flite)
        println!("🔧 [TTS-METHODS] Method 2: Trying local TTS engines...");
        match self.synthesize_with_local_tts(text, &voice.locale).await {
            Ok(audio_data) => {
                println!("✅ [TTS-METHODS] Local TTS synthesis successful, {} bytes generated", audio_data.len());
                return Ok(audio_data);
            },
            Err(e) => {
                println!("❌ [TTS-METHODS] Local TTS failed: {}", e);
            }
        }

        // Method 3: Platform-specific fallbacks
        #[cfg(target_os = "android")]
        {
            println!("📱 [TTS-METHODS] Method 3: Trying Android-specific TTS...");
            match self.try_android_tts_fallback(text, &voice.locale).await {
                Ok(audio_data) => {
                    println!("✅ [TTS-METHODS] Android TTS synthesis successful, {} bytes generated", audio_data.len());
                    return Ok(audio_data);
                },
                Err(e) => {
                    println!("❌ [TTS-METHODS] Android TTS failed: {}", e);
                }
            }
        }

        #[cfg(target_os = "macos")]
        {
            println!("🍎 [TTS-METHODS] Method 3: Trying macOS TTS...");
            match self.try_macos_tts(text, &voice.locale).await {
                Ok(audio_data) => {
                    println!("✅ [TTS-METHODS] macOS TTS synthesis successful, {} bytes generated", audio_data.len());
                    return Ok(audio_data);
                },
                Err(e) => {
                    println!("❌ [TTS-METHODS] macOS TTS failed: {}", e);
                }
            }
        }

        #[cfg(target_os = "windows")]
        {
            println!("🪟 [TTS-METHODS] Method 3: Trying Windows TTS...");
            match self.try_windows_tts(text, &voice.locale).await {
                Ok(audio_data) => {
                    println!("✅ [TTS-METHODS] Windows TTS synthesis successful, {} bytes generated", audio_data.len());
                    return Ok(audio_data);
                },
                Err(e) => {
                    println!("❌ [TTS-METHODS] Windows TTS failed: {}", e);
                }
            }
        }

        // All methods failed
        println!("🚫 [TTS-METHODS] All TTS methods failed");
        Err(format!(
            "🚫 All TTS methods failed for text: '{}', language: '{}'.\n\
            🌐 Primary method: Edge TTS WebSocket API (requires internet)\n\
            🔧 Fallback method: Local TTS engines (espeak-ng, flite)\n\
            💻 Platform method: System TTS\n\
            💡 Recommendations:\n\
            • Check internet connection for Edge TTS API\n\
            • Ensure network access to speech.platform.bing.com\n\
            • Install local TTS: apt install espeak-ng (Linux) or brew install espeak (macOS)\n\
            • Enable system TTS in device settings",
            Self::safe_truncate(text, 50), voice.language
        ))
    }

    /// Check network connectivity for Edge TTS
    async fn check_network_connectivity(&self) -> Result<(), String> {
        println!("🌐 [TTS-NETWORK] Testing connection to Edge TTS servers...");
        
        // Test DNS resolution first
        match tokio::net::lookup_host("speech.platform.bing.com:443").await {
            Ok(addrs) => {
                let addr_list: Vec<_> = addrs.collect();
                println!("✅ [TTS-NETWORK] DNS resolution successful: {} addresses", addr_list.len());
                for addr in addr_list.iter().take(3) {
                    println!("🔍 [TTS-NETWORK] Address: {}", addr);
                }
            }
            Err(e) => {
                println!("❌ [TTS-NETWORK] DNS resolution failed: {}", e);
                return Err(format!("DNS resolution failed: {}", e));
            }
        }
        
        // Test HTTP connectivity
        let client = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(10))
            .build()
            .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
            
        let test_url = "https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4";
        
        println!("🌐 [TTS-NETWORK] Testing HTTP connectivity to: {}", test_url);
        
        match client.get(test_url).send().await {
            Ok(response) => {
                println!("✅ [TTS-NETWORK] HTTP request successful");
                println!("🔍 [TTS-NETWORK] Response status: {}", response.status());
                println!("🔍 [TTS-NETWORK] Response headers: {:?}", response.headers());
                
                if response.status().is_success() {
                    println!("✅ [TTS-NETWORK] Edge TTS API is accessible");
                    Ok(())
                } else {
                    let error_msg = format!("Edge TTS API returned status: {}", response.status());
                    println!("❌ [TTS-NETWORK] {}", error_msg);
                    Err(error_msg)
                }
            }
            Err(e) => {
                println!("❌ [TTS-NETWORK] HTTP request failed: {}", e);
                Err(format!("HTTP request failed: {}", e))
            }
        }
    }

    /// Try different TTS methods in order of preference
    pub async fn play_audio_from_bytes(&self, audio_data: &[u8]) -> Result<(), String> {
        if audio_data.is_empty() {
            println!("❌ [TTS-PLAY] Audio data is empty - nothing to play");
            return Err("Audio data is empty - nothing to play".to_string());
        }
        
        println!("🔊 [TTS-PLAY] Starting audio playback, data size: {} bytes", audio_data.len());
        
        // Use rodio to play audio (works on all desktop platforms)
        #[cfg(not(target_os = "android"))]
        {
            println!("🖥️ [TTS-PLAY] Using desktop audio playback (rodio)");
            
            use std::sync::mpsc;
            
            // Create audio data copy for the blocking task
            let audio_vec = audio_data.to_vec();
            
            // Run audio playback in a blocking task to avoid Send issues
            let (tx, rx) = mpsc::channel();
            
            tokio::task::spawn_blocking(move || {
                println!("🎵 [TTS-PLAY] Starting blocking audio task");
                let result = (|| -> Result<(), String> {
                    println!("🎵 [TTS-PLAY] Creating audio output stream...");
                    let (_stream, stream_handle) = OutputStream::try_default()
                        .map_err(|e| {
                            println!("❌ [TTS-PLAY] Failed to create audio output stream: {}", e);
                            format!("Failed to create audio output stream: {}", e)
                        })?;

                    println!("🎵 [TTS-PLAY] Creating audio sink...");
                    let sink = Sink::try_new(&stream_handle)
                        .map_err(|e| {
                            println!("❌ [TTS-PLAY] Failed to create audio player: {}", e);
                            format!("Failed to create audio player: {}", e)
                        })?;

                    println!("🎵 [TTS-PLAY] Decoding audio data...");
                    let cursor = Cursor::new(audio_vec);
                    let source = Decoder::new(cursor)
                        .map_err(|e| {
                            println!("❌ [TTS-PLAY] Failed to decode audio: {}", e);
                            format!("Failed to decode audio data: {}. This might indicate corrupted audio or unsupported format.", e)
                        })?;

                    println!("🎵 [TTS-PLAY] Starting playback...");
                    sink.append(source);
                    
                    // Wait for playback to complete with timeout
                    let play_duration = std::time::Duration::from_secs(30);
                    let start_time = std::time::Instant::now();
                    
                    while !sink.empty() && start_time.elapsed() < play_duration {
                        std::thread::sleep(std::time::Duration::from_millis(100));
                    }
                    
                    if start_time.elapsed() >= play_duration {
                        println!("⏰ [TTS-PLAY] Playback timeout - stopping playback");
                        sink.stop();
                        return Err("TTS playback timeout".to_string());
                    }

                    println!("✅ [TTS-PLAY] Playback completed successfully");
                    Ok(())
                })();
                
                let _ = tx.send(result);
            });
            
            // Wait for the result
            match rx.recv() {
                Ok(result) => {
                    result?;
                    println!("✅ [TTS-PLAY] Audio playback completed successfully");
                    Ok(())
                }
                Err(_) => {
                    println!("❌ [TTS-PLAY] Audio playback task failed");
                    Err("Audio playback task failed".to_string())
                }
            }
        }
        
        // On Android, try to play using system commands
        #[cfg(target_os = "android")]
        {
            println!("📱 [TTS-PLAY] Using Android audio playback");
            self.play_audio_android(audio_data).await
        }
    }

    /// Android-specific audio playback
    #[cfg(target_os = "android")]
    async fn play_audio_android(&self, audio_data: &[u8]) -> Result<(), String> {
        use std::process::Command;
        
        // Write audio data to temporary file
        let temp_file = format!("/tmp/tts_audio_{}.wav", std::process::id());
        
        if let Err(e) = tokio::fs::write(&temp_file, audio_data).await {
            return Err(format!("Failed to write audio file: {}", e));
        }
        
        // Try different Android audio players
        let players = ["termux-media-player", "play", "aplay", "paplay"];
        
        for player in &players {
            let result = Command::new(player)
                .args(&[&temp_file])
                .output();
                
            match result {
                Ok(output) => {
                    if output.status.success() {
                        // Wait for playback to complete
                        tokio::time::sleep(std::time::Duration::from_millis(
                            std::cmp::min(audio_data.len() / 1000, 10000) as u64
                        )).await;
                        
                        // Clean up temp file
                        let _ = tokio::fs::remove_file(&temp_file).await;
                        
                        println!("✅ Android audio playback completed with {}", player);
                        return Ok(());
                    }
                }
                Err(_) => continue,
            }
        }
        
        // Clean up temp file
        let _ = tokio::fs::remove_file(&temp_file).await;
        
        Err("No working audio player found on Android".to_string())
    }

    /// Android-specific TTS fallback
    #[cfg(target_os = "android")]
    async fn try_android_tts_fallback(&self, text: &str, _locale: &str) -> Result<Vec<u8>, String> {
        
        // Try to use termux-tts if available (for Termux environment)
        let termux_result = tokio::process::Command::new("termux-tts-speak")
            .args(&[text])
            .output()
            .await;
            
        if let Ok(output) = termux_result {
            if output.status.success() {
                // Wait for speech to complete
                tokio::time::sleep(std::time::Duration::from_millis(
                    std::cmp::min(text.len() * 100, 5000) as u64
                )).await;
                
                // Return success indicator (no audio file for termux-tts-speak)
                return Ok(b"TTS_SUCCESS_TERMUX".to_vec());
            }
        }
        
        // Try festival TTS if available
        let festival_result = tokio::process::Command::new("festival")
            .args(&["--tts", "--language", _locale])
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn();
            
        if let Ok(mut child) = festival_result {
            if let Some(mut stdin) = child.stdin.take() {
                use tokio::io::AsyncWriteExt;
                if stdin.write_all(text.as_bytes()).await.is_ok() {
                    drop(stdin);
                    if let Ok(output) = child.wait_with_output().await {
                        if output.status.success() && !output.stdout.is_empty() {
                            return Ok(output.stdout);
                        }
                    }
                }
            }
        }
        
        Err("No working Android TTS fallback found".to_string())
    }

    /// macOS-specific TTS using system 'say' command
    #[cfg(target_os = "macos")]
    async fn try_macos_tts(&self, text: &str, locale: &str) -> Result<Vec<u8>, String> {
        
        // Create temporary file for audio output
        let temp_file = format!("/tmp/tts_macos_{}.aiff", std::process::id());
        
        // Improved locale to macOS voice mapping
        let voice = match locale {
            // English
            "en-US" | "English" => "Alex",
            "en-GB" => "Daniel",
            "en-AU" => "Karen",
            
            // Spanish  
            "es-ES" | "Spanish" => "Monica",
            "es-MX" => "Paulina",
            
            // French
            "fr-FR" | "French" => "Thomas",
            "fr-CA" => "Amelie",
            
            // German
            "de-DE" | "German" => "Anna",
            
            // Italian
            "it-IT" | "Italian" => "Alice",
            
            // Japanese
            "ja-JP" | "Japanese" => "Kyoko",
            
            // Chinese
            "zh-CN" | "Chinese" => "Ting-Ting",
            "zh-TW" => "Mei-Jia",
            "zh-HK" => "Sin-ji",
            
            // Portuguese
            "pt-BR" => "Luciana",
            "pt-PT" => "Joana",
            
            // Russian
            "ru-RU" | "Russian" => "Milena",
            
            // Korean
            "ko-KR" | "Korean" => "Yuna",
            
            // Dutch
            "nl-NL" => "Ellen",
            "nl-BE" => "Ellen",
            
            // Polish
            "pl-PL" => "Zosia",
            
            // Swedish
            "sv-SE" => "Alva",
            
            // Norwegian
            "nb-NO" => "Nora",
            
            // Danish
            "da-DK" => "Sara",
            
            // Finnish
            "fi-FI" => "Satu",
            
            // Czech
            "cs-CZ" => "Zuzana",
            
            // Hungarian
            "hu-HU" => "Mariska",
            
            // Romanian
            "ro-RO" => "Ioana",
            
            // Slovak
            "sk-SK" => "Laura",
            
            // Croatian
            "hr-HR" => "Lana",
            
            // Arabic
            "ar-SA" | "Arabic" => "Maged",
            
            // Hindi
            "hi-IN" | "Hindi" => "Lekha",
            
            // Thai
            "th-TH" => "Kanya",
            
            // Turkish
            "tr-TR" => "Yelda",
            
            // Greek
            "el-GR" | "Greek" => "Melina",
            
            // Hebrew
            "he-IL" => "Carmit",
            
            // Default to Alex for unknown languages/locales
            _ => {
                println!("⚠️ Unknown locale '{}', using default English voice 'Alex'", locale);
                "Alex"
            }
        };
        
        println!("🍎 macOS TTS: Using voice '{}' for locale '{}'", voice, locale);
        
        let result = tokio::process::Command::new("say")
            .args(&[
                "-v", voice,
                "-o", &temp_file,
                text
            ])
            .output()
            .await;
            
        match result {
            Ok(output) => {
                if output.status.success() {
                    // Read the generated audio file
                    if let Ok(audio_data) = tokio::fs::read(&temp_file).await {
                        // Clean up temp file
                        let _ = tokio::fs::remove_file(&temp_file).await;
                        println!("✅ macOS TTS synthesis successful: {} bytes", audio_data.len());
                        return Ok(audio_data);
                    } else {
                        let _ = tokio::fs::remove_file(&temp_file).await;
                        return Err("Failed to read generated audio file".to_string());
                    }
                } else {
                    let error_msg = String::from_utf8_lossy(&output.stderr);
                    let _ = tokio::fs::remove_file(&temp_file).await;
                    return Err(format!("macOS say command failed: {}", error_msg));
                }
            }
            Err(e) => {
                let _ = tokio::fs::remove_file(&temp_file).await;
                return Err(format!("Failed to execute macOS say command: {}", e));
            }
        }
    }

    /// Windows-specific TTS using PowerShell
    #[cfg(target_os = "windows")]
    async fn try_windows_tts(&self, text: &str, _locale: &str) -> Result<Vec<u8>, String> {
        
        // Create temporary file for audio output
        let temp_file = format!("C:\\temp\\tts_windows_{}.wav", std::process::id());
        
        // PowerShell script to use Windows Speech API
        let ps_script = format!(
            r#"
            Add-Type -AssemblyName System.Speech
            $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
            $synth.SetOutputToWaveFile('{}')
            $synth.Speak('{}')
            $synth.Dispose()
            "#,
            temp_file,
            text.replace("'", "''") // Escape single quotes
        );
        
        let result = tokio::process::Command::new("powershell")
            .args(&["-Command", &ps_script])
            .output()
            .await;
            
        match result {
            Ok(output) => {
                if output.status.success() {
                    // Read the generated audio file
                    if let Ok(audio_data) = tokio::fs::read(&temp_file).await {
                        // Clean up temp file
                        let _ = tokio::fs::remove_file(&temp_file).await;
                        return Ok(audio_data);
                    }
                }
                let error_msg = String::from_utf8_lossy(&output.stderr);
                Err(format!("Windows PowerShell TTS failed: {}", error_msg))
            }
            Err(e) => Err(format!("Failed to execute Windows PowerShell TTS: {}", e))
        }
    }

    /// Play TTS for given text and language
    pub async fn play_tts(&self, text: &str, language: &str) -> Result<(), String> {
        println!("🎵 [TTS-PLAY-TTS] Starting TTS playback");
        println!("🎵 [TTS-PLAY-TTS] Text: '{}'", Self::safe_truncate(text, 50));
        println!("🎵 [TTS-PLAY-TTS] Language: {}", language);
        
        println!("🔄 [TTS-PLAY-TTS] Calling synthesize_speech...");
        let audio_data = self.synthesize_speech(text, language).await?;
        
        // Check for special success indicators from platform-specific TTS
        if let Ok(response_str) = String::from_utf8(audio_data.clone()) {
            if response_str == "TTS_SUCCESS_TERMUX" {
                println!("✅ [TTS-PLAY-TTS] Termux TTS completed successfully (audio played directly)");
                return Ok(());
            }
        }

        // For all other cases, we should have actual audio data to play
        println!("🔄 [TTS-PLAY-TTS] Calling play_audio_from_bytes...");
        self.play_audio_from_bytes(&audio_data).await
    }
}
