/**
 * Pure Rust Edge TTS Implementation
 * Based on https://github.com/ganlvtech/edge-tts
 * Implements Microsoft Edge Text-to-Speech API without Python dependencies
 */

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tokio_tungstenite::{connect_async, tungstenite::Message};
use futures_util::{SinkExt, StreamExt};
use uuid::Uuid;
use reqwest;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EdgeVoice {
    pub name: String,
    pub short_name: String,
    pub gender: String,
    pub locale: String,
    pub suggested_codec: String,
    pub friendly_name: String,
    pub status: String,
}

#[derive(Debug)]
pub struct EdgeTTSClient {
    voices: Vec<EdgeVoice>,
    client: reqwest::Client,
}

impl EdgeTTSClient {
    /// Create a new Edge TTS client
    pub async fn new() -> Result<Self, String> {
        let client = reqwest::Client::builder()
            .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.66 Safari/537.36 Edg/103.0.1264.44")
            .build()
            .map_err(|e| format!("Failed to create HTTP client: {}", e))?;

        let mut edge_client = EdgeTTSClient {
            voices: Vec::new(),
            client,
        };

        // Load voices
        edge_client.load_voices().await?;
        Ok(edge_client)
    }

    /// Load available voices from Edge TTS API
    async fn load_voices(&mut self) -> Result<(), String> {
        let voices_url = "https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list?trustedclienttoken=6A5AA1D4EAFF4E9FB37E23D68491D6F4";
        
        println!("🌐 Loading Edge TTS voices...");
        
        let response = self.client
            .get(voices_url)
            .header("Authority", "speech.platform.bing.com")
            .header("Sec-Ch-Ua", "\" Not;A Brand\";v=\"99\", \"Microsoft Edge\";v=\"103\", \"Chromium\";v=\"103\"")
            .header("Sec-Ch-Ua-Mobile", "?0")
            .header("Sec-Ch-Ua-Platform", "\"Windows\"")
            .header("Sec-Fetch-Dest", "empty")
            .header("Sec-Fetch-Mode", "cors")
            .header("Sec-Fetch-Site", "none")
            .send()
            .await
            .map_err(|e| format!("Failed to fetch voices: {}", e))?;

        if !response.status().is_success() {
            return Err(format!("Failed to fetch voices, status: {}", response.status()));
        }

        let voices: Vec<EdgeVoice> = response
            .json()
            .await
            .map_err(|e| format!("Failed to parse voices JSON: {}", e))?;

        println!("✅ Loaded {} Edge TTS voices", voices.len());
        self.voices = voices;
        Ok(())
    }

    /// Get all available voices
    #[allow(dead_code)]
    pub fn get_voices(&self) -> &[EdgeVoice] {
        &self.voices
    }

    /// Find a voice by language
    pub fn find_voice_by_language(&self, language: &str) -> Option<&EdgeVoice> {
        let language_lower = language.to_lowercase();
        
        // Try exact locale match first
        for voice in &self.voices {
            if voice.locale.to_lowercase().contains(&language_lower) {
                return Some(voice);
            }
        }

        // Try language code match
        let language_mappings = [
            ("english", "en-US"),
            ("chinese", "zh-CN"),
            ("spanish", "es-ES"),
            ("french", "fr-FR"),
            ("german", "de-DE"),
            ("japanese", "ja-JP"),
            ("korean", "ko-KR"),
            ("russian", "ru-RU"),
            ("arabic", "ar-SA"),
            ("hindi", "hi-IN"),
        ];

        for (lang_name, locale_code) in language_mappings {
            if language_lower.contains(lang_name) {
                for voice in &self.voices {
                    if voice.locale.starts_with(locale_code) {
                        return Some(voice);
                    }
                }
            }
        }

        // Fallback to first English voice
        self.voices.iter().find(|v| v.locale.starts_with("en-"))
    }

    /// Synthesize speech using Edge TTS WebSocket API
    pub async fn synthesize(&self, text: &str, voice_name: &str) -> Result<Vec<u8>, String> {
        let voice = self.voices.iter()
            .find(|v| v.short_name == voice_name || v.name == voice_name)
            .ok_or_else(|| format!("Voice '{}' not found", voice_name))?;

        println!("🎙️ Synthesizing with voice: {} ({})", voice.friendly_name, voice.short_name);

        // Generate unique request ID
        let request_id = Uuid::new_v4().to_string().replace("-", "");
        let connection_id = Uuid::new_v4().to_string().replace("-", "");

        // Prepare WebSocket URL
        let ws_url = format!(
            "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?TrustedClientToken=6A5AA1D4EAFF4E9FB37E23D68491D6F4&ConnectionId={}",
            connection_id
        );

        println!("🔗 Connecting to Edge TTS WebSocket...");

        // Connect to WebSocket
        let (ws_stream, _) = connect_async(&ws_url)
            .await
            .map_err(|e| format!("Failed to connect to Edge TTS WebSocket: {}", e))?;

        let (mut ws_sender, mut ws_receiver) = ws_stream.split();

        // Send configuration message
        let config_message = format!(
            "X-Timestamp:{}\r\nContent-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n{{\"context\":{{\"synthesis\":{{\"audio\":{{\"metadataoptions\":{{\"sentenceBoundaryEnabled\":false,\"wordBoundaryEnabled\":false}},\"outputFormat\":\"audio-24khz-48kbitrate-mono-mp3\"}}}}}}}}",
            Self::get_timestamp()
        );

        ws_sender.send(Message::Text(config_message)).await
            .map_err(|e| format!("Failed to send config: {}", e))?;

        // Generate SSML
        let ssml = self.generate_ssml(text, voice);

        // Send synthesis request
        let synthesis_message = format!(
            "X-RequestId:{}\r\nContent-Type:application/ssml+xml\r\nX-Timestamp:{}\r\nPath:ssml\r\n\r\n{}",
            request_id,
            Self::get_timestamp(),
            ssml
        );

        ws_sender.send(Message::Text(synthesis_message)).await
            .map_err(|e| format!("Failed to send synthesis request: {}", e))?;

        // Collect audio data
        let mut audio_data = Vec::new();
        let mut synthesis_complete = false;

        while let Some(message) = ws_receiver.next().await {
            match message {
                Ok(Message::Text(text)) => {
                    if text.contains("Path:turn.end") {
                        synthesis_complete = true;
                        break;
                    }
                    if text.contains("Path:response") {
                        // Audio metadata, ignore for now
                        continue;
                    }
                }
                Ok(Message::Binary(data)) => {
                    // Check if this is audio data (skip headers)
                    if data.len() > 2 {
                        // Find audio data start (skip WebSocket headers)
                        if let Some(audio_start) = self.find_audio_start(&data) {
                            audio_data.extend_from_slice(&data[audio_start..]);
                        }
                    }
                }
                Ok(Message::Close(_)) => {
                    break;
                }
                Err(e) => {
                    return Err(format!("WebSocket error: {}", e));
                }
                _ => {}
            }
        }

        if !synthesis_complete {
            return Err("Synthesis did not complete properly".to_string());
        }

        if audio_data.is_empty() {
            return Err("No audio data received from Edge TTS".to_string());
        }

        println!("✅ Edge TTS synthesis completed, {} bytes generated", audio_data.len());
        Ok(audio_data)
    }

    /// Generate SSML for synthesis
    fn generate_ssml(&self, text: &str, voice: &EdgeVoice) -> String {
        let escaped_text = text
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;");

        format!(
            r#"<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='{}'><voice name='{}'>{}</voice></speak>"#,
            voice.locale,
            voice.short_name,
            escaped_text
        )
    }

    /// Find audio data start in binary message
    fn find_audio_start(&self, data: &[u8]) -> Option<usize> {
        // Look for the end of HTTP-style headers (double CRLF)
        for i in 0..data.len().saturating_sub(3) {
            if &data[i..i+4] == b"\r\n\r\n" {
                return Some(i + 4);
            }
        }
        
        // Fallback: look for MP3 header
        for i in 0..data.len().saturating_sub(2) {
            if data[i] == 0xFF && (data[i+1] & 0xE0) == 0xE0 {
                return Some(i);
            }
        }

        None
    }

    /// Get current timestamp in Edge TTS format
    fn get_timestamp() -> String {
        use chrono::Utc;
        Utc::now().format("%Y-%m-%dT%H:%M:%S.%3fZ").to_string()
    }

    /// Get voices grouped by language
    pub fn get_voices_by_language(&self) -> HashMap<String, Vec<String>> {
        let mut grouped = HashMap::new();

        for voice in &self.voices {
            let language = if voice.locale.starts_with("en-") {
                "English".to_string()
            } else if voice.locale.starts_with("zh-") {
                "Chinese".to_string()
            } else if voice.locale.starts_with("es-") {
                "Spanish".to_string()
            } else if voice.locale.starts_with("fr-") {
                "French".to_string()
            } else if voice.locale.starts_with("de-") {
                "German".to_string()
            } else if voice.locale.starts_with("ja-") {
                "Japanese".to_string()
            } else if voice.locale.starts_with("ko-") {
                "Korean".to_string()
            } else if voice.locale.starts_with("ru-") {
                "Russian".to_string()
            } else if voice.locale.starts_with("ar-") {
                "Arabic".to_string()
            } else if voice.locale.starts_with("hi-") {
                "Hindi".to_string()
            } else {
                voice.locale.clone()
            };

            grouped.entry(language).or_insert_with(Vec::new)
                .push(voice.friendly_name.clone());
        }

        grouped
    }
}

// Tests
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_load_voices() {
        let client = EdgeTTSClient::new().await.unwrap();
        assert!(!client.get_voices().is_empty());
    }

    #[tokio::test]
    async fn test_find_voice() {
        let client = EdgeTTSClient::new().await.unwrap();
        let voice = client.find_voice_by_language("English");
        assert!(voice.is_some());
        
        let voice = client.find_voice_by_language("Chinese");
        assert!(voice.is_some());
    }
}
