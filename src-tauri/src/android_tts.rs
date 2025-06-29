/**
 * Android-compatible TTS module
 * Uses Android's built-in TTS capabilities instead of external commands
 */

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AndroidTTSEngine {
    pub available_voices: Vec<AndroidVoice>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AndroidVoice {
    pub name: String,
    pub language: String,
    pub country: String,
    pub locale: String,
}

impl AndroidTTSEngine {
    pub fn new() -> Self {
        Self {
            available_voices: Self::init_android_voices(),
        }
    }

    fn init_android_voices() -> Vec<AndroidVoice> {
        vec![
            AndroidVoice {
                name: "en-US-default".to_string(),
                language: "English".to_string(),
                country: "US".to_string(),
                locale: "en-US".to_string(),
            },
            AndroidVoice {
                name: "es-ES-default".to_string(),
                language: "Spanish".to_string(),
                country: "ES".to_string(),
                locale: "es-ES".to_string(),
            },
            AndroidVoice {
                name: "fr-FR-default".to_string(),
                language: "French".to_string(),
                country: "FR".to_string(),
                locale: "fr-FR".to_string(),
            },
            AndroidVoice {
                name: "de-DE-default".to_string(),
                language: "German".to_string(),
                country: "DE".to_string(),
                locale: "de-DE".to_string(),
            },
            AndroidVoice {
                name: "it-IT-default".to_string(),
                language: "Italian".to_string(),
                country: "IT".to_string(),
                locale: "it-IT".to_string(),
            },
            AndroidVoice {
                name: "ru-RU-default".to_string(),
                language: "Russian".to_string(),
                country: "RU".to_string(),
                locale: "ru-RU".to_string(),
            },
            AndroidVoice {
                name: "zh-CN-default".to_string(),
                language: "Chinese".to_string(),
                country: "CN".to_string(),
                locale: "zh-CN".to_string(),
            },
            AndroidVoice {
                name: "ja-JP-default".to_string(),
                language: "Japanese".to_string(),
                country: "JP".to_string(),
                locale: "ja-JP".to_string(),
            },
            AndroidVoice {
                name: "ko-KR-default".to_string(),
                language: "Korean".to_string(),
                country: "KR".to_string(),
                locale: "ko-KR".to_string(),
            },
            AndroidVoice {
                name: "ar-SA-default".to_string(),
                language: "Arabic".to_string(),
                country: "SA".to_string(),
                locale: "ar-SA".to_string(),
            },
            AndroidVoice {
                name: "hi-IN-default".to_string(),
                language: "Hindi".to_string(),
                country: "IN".to_string(),
                locale: "hi-IN".to_string(),
            },
        ]
    }

    /// Android-compatible TTS synthesis
    /// This will be called from the frontend using Android WebView's TTS capabilities
    pub async fn synthesize_speech(&self, text: &str, language: &str) -> Result<String, String> {
        println!("Android TTS Debug - Text: '{}'", text);
        println!("Android TTS Debug - Language: '{}'", language);

        if text.trim().is_empty() {
            return Err("Cannot synthesize empty text".to_string());
        }

        // Validate text length
        if text.len() > 4000 {
            return Err("Text too long for TTS (max 4000 characters)".to_string());
        }

        // Enhanced language to voice mapping for Android TTS with better fallbacks
        let (voice_name, locale, pitch, rate) = match language.to_lowercase().as_str() {
            "english" => ("en-US-default", "en-US", 1.0, 1.0),
            "spanish" => ("es-ES-default", "es-ES", 1.0, 0.9),
            "french" => ("fr-FR-default", "fr-FR", 1.1, 0.9),
            "italian" => ("it-IT-default", "it-IT", 1.0, 0.9),
            "russian" => ("ru-RU-default", "ru-RU", 0.9, 0.8),
            "greek" => ("el-GR-default", "el-GR", 1.0, 0.9),
            "german" => ("de-DE-default", "de-DE", 0.9, 0.9),
            "hindi" => ("hi-IN-default", "hi-IN", 1.0, 0.8),
            "arabic" => ("ar-SA-default", "ar-SA", 1.0, 0.8),
            "japanese" => ("ja-JP-default", "ja-JP", 1.1, 0.9),
            "korean" => ("ko-KR-default", "ko-KR", 1.0, 0.9),
            "chinese" => ("zh-CN-default", "zh-CN", 1.0, 0.8),
            _ => ("en-US-default", "en-US", 1.0, 1.0), // Default fallback
        };

        println!("Android TTS Debug - Selected voice: {} ({}) - Pitch: {}, Rate: {}", 
                voice_name, locale, pitch, rate);

        // Enhanced TTS command with better configuration and error handling
        let tts_command = serde_json::json!({
            "type": "android_tts_command",
            "text": text,
            "voice": voice_name,
            "locale": locale,
            "language": language,
            "pitch": pitch,
            "rate": rate,
            "volume": 0.9,
            "timeout": 20000, // Increased timeout for Android
            "fallback_locales": self.get_fallback_locales(locale),
            "retry_count": 3,
            "use_queue": false,
            "android_engine": "com.google.android.tts",
            "android_specific": {
                "force_defaults": true,
                "check_voices": true,
                "wait_for_ready": 500
            }
        });

        println!("Android TTS Debug - Generated TTS command successfully");
        Ok(tts_command.to_string())
    }

    /// Get fallback locales for better voice matching
    fn get_fallback_locales(&self, primary_locale: &str) -> Vec<String> {
        let language_code = primary_locale.split('-').next().unwrap_or("en");
        match language_code {
            "en" => vec!["en-US".to_string(), "en-GB".to_string(), "en-AU".to_string()],
            "es" => vec!["es-ES".to_string(), "es-MX".to_string(), "es-AR".to_string()],
            "fr" => vec!["fr-FR".to_string(), "fr-CA".to_string(), "fr-BE".to_string()],
            "de" => vec!["de-DE".to_string(), "de-AT".to_string(), "de-CH".to_string()],
            "it" => vec!["it-IT".to_string(), "it-CH".to_string()],
            "zh" => vec!["zh-CN".to_string(), "zh-TW".to_string(), "zh-HK".to_string()],
            "ja" => vec!["ja-JP".to_string()],
            "ko" => vec!["ko-KR".to_string()],
            "ar" => vec!["ar-SA".to_string(), "ar-EG".to_string(), "ar-AE".to_string()],
            "hi" => vec!["hi-IN".to_string()],
            "ru" => vec!["ru-RU".to_string(), "ru-BY".to_string()],
            "el" => vec!["el-GR".to_string()],
            _ => vec![primary_locale.to_string(), "en-US".to_string()],
        }
    }
}
