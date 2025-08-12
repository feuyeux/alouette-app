# Alouette App

A unified Flutter application that combines AI-powered translation with integrated text-to-speech functionality. Built using the [alouette-lib-trans](../alouette-lib-trans) and [alouette-lib-tts](../alouette-lib-tts) libraries for consistent functionality across the Alouette ecosystem.

## Features

### 🌍 Translation Features
- **Local AI Translation** - Supports Ollama and LM Studio local AI models
- **Multi-language Support** - Supports Chinese, English, Japanese, Korean, French, German, Spanish, Italian, Russian, Arabic, Hindi, and Greek
- **Batch Translation** - Translate to multiple target languages at once
- **Auto-configuration** - Automatically detects and connects to local AI services
- **Model Selection** - Choose from available AI models
- **Copy Results** - Easy copy to clipboard functionality

### 🗣️ Integrated TTS Features
- **Translation Playback** - Play back translation results with text-to-speech
- **Multi-language TTS** - Support for all supported translation languages
- **Individual Control** - Play/stop TTS for each translation result independently
- **Automatic Language Mapping** - Seamless integration between translation and TTS languages
- **Voice Feedback** - Audio confirmation of translation results

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Platform-specific development tools (Android Studio, Xcode, etc.)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/feuyeux/alouette.git
cd alouette/alouette-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Configuration

### Translation Setup

The app will automatically attempt to connect to a local Ollama instance at startup. For manual configuration:

1. Ensure you have Ollama or LM Studio running locally
2. For Ollama: Default URL is `http://localhost:11434`
3. For LM Studio: Default URL is `http://localhost:1234/v1`
4. Tap the settings button (⚙️) to configure manually if auto-configuration fails

### Supported Models

The application supports various language models compatible with Ollama and LM Studio, including:
- Llama series (llama3.2, llama3.1, etc.)
- Qwen series (qwen2.5:latest, qwen2.5:1.5b, etc.)
- Mistral series
- Other OpenAI-compatible models

## Usage

### Translation with TTS
1. Enter text to translate in the input area
2. Select target languages using the filter chips
3. Tap "Translate" to get translation results
4. For each translation result:
   - Tap the 🔊 icon to play the translation with TTS
   - Tap the 🛑 icon to stop playback
   - Tap the 📋 icon to copy individual translations

### Features
- **Real-time Status**: Visual feedback showing connection status and model information
- **Language Selection**: Multi-select interface for choosing target languages
- **Audio Playback**: Integrated TTS for immediate audio feedback
- **Copy Functions**: Copy individual translations or all results

## Architecture

This application uses the Alouette library ecosystem for core functionality:

### Dependencies
- **[alouette-lib-trans](../alouette-lib-trans)**: AI translation functionality with support for Ollama and LM Studio
- **[alouette-lib-tts](../alouette-lib-tts)**: Text-to-speech functionality with multi-platform support

### Application Structure
```
lib/
├── main.dart                           # Application entry point
├── constants/
│   └── app_constants.dart              # Application constants and language mappings
├── models/
│   └── app_models.dart                 # Re-exports from alouette libraries
├── pages/
│   ├── app_home_page.dart              # Main application page
│   └── translation_page.dart           # Translation page with integrated TTS
├── services/                           # Service wrappers for library integration
│   ├── auto_config_service.dart        # Auto-configuration service wrapper
│   ├── llm_config_service.dart         # LLM configuration service wrapper
│   └── translation_service.dart        # Translation service wrapper
└── widgets/
    ├── llm_config_dialog.dart          # LLM configuration dialog
    ├── translation_input_widget.dart   # Translation input component
    ├── translation_result_widget.dart  # Translation results with TTS
    ├── language_selector.dart          # Language selection component
    ├── compact_slider.dart             # Compact slider component
    ├── tts_control_buttons.dart        # TTS control buttons
    ├── tts_status_indicator.dart       # TTS status indicator
    └── enhanced_volume_slider.dart     # Enhanced volume slider
```

## Language Support

### Translation Languages
- Chinese (中文)
- English
- Japanese (日本語)
- Korean (한국어)
- French (Français)
- German (Deutsch)
- Spanish (Español)
- Italian (Italiano)
- Russian (Русский)
- Arabic (العربية)
- Hindi (हिंदी)
- Greek (Ελληνικά)

### TTS Language Mapping
The app automatically maps translation language names to appropriate TTS language codes for seamless audio playback.

## Build Commands

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Linux
```bash
flutter build linux --release
```

## Related Projects

### Applications
- [alouette-translator](../alouette-translator): Standalone translation application
- [alouette-tts](../alouette-tts): Standalone text-to-speech application

### Libraries
- [alouette-lib-trans](../alouette-lib-trans): AI translation library
- [alouette-lib-tts](../alouette-lib-tts): Text-to-speech library

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Support

If you encounter any issues or have questions, please file an issue on the GitHub repository.
