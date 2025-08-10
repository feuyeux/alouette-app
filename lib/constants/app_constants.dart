import '../models/app_models.dart';

/// 语言常量
class LanguageConstants {
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'zh-CN', name: '中文', flag: '🇨🇳'),
    LanguageOption(code: 'en-US', name: 'English', flag: '🇺🇸'),
    LanguageOption(code: 'ja-JP', name: '日本語', flag: '🇯🇵'),
    LanguageOption(code: 'ko-KR', name: '한국어', flag: '🇰🇷'),
    LanguageOption(code: 'fr-FR', name: 'Français', flag: '🇫🇷'),
    LanguageOption(code: 'de-DE', name: 'Deutsch', flag: '🇩🇪'),
    LanguageOption(code: 'es-ES', name: 'Español', flag: '🇪🇸'),
    LanguageOption(code: 'it-IT', name: 'Italiano', flag: '🇮🇹'),
    LanguageOption(code: 'ru-RU', name: 'Русский', flag: '🇷🇺'),
    LanguageOption(code: 'ar-SA', name: 'العربية', flag: '🇸🇦'),
    LanguageOption(code: 'hi-IN', name: 'हिंदी', flag: '🇮🇳'),
    LanguageOption(code: 'el-GR', name: 'Ελληνικά', flag: '🇬🇷'),
  ];

  static const LanguageOption defaultLanguage = 
    LanguageOption(code: 'zh-CN', name: '中文', flag: '🇨🇳');

  /// 根据语言代码获取语言选项
  static LanguageOption? getLanguageByCode(String code) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  /// 获取翻译用语言名称映射
  static final Map<String, String> translationLanguageNames = {
    'zh-CN': 'Chinese',
    'en-US': 'English', 
    'ja-JP': 'Japanese',
    'ko-KR': 'Korean',
    'fr-FR': 'French',
    'de-DE': 'German',
    'es-ES': 'Spanish',
    'it-IT': 'Italian',
    'ru-RU': 'Russian',
    'ar-SA': 'Arabic',
    'hi-IN': 'Hindi',
    'el-GR': 'Greek',
  };
}

/// 应用常量
class AppConstants {
  static const String appName = 'Alouette App';
  static const String appVersion = '1.0.0+1';
  
  // LLM默认配置
  static const String defaultOllamaUrl = 'http://localhost:11434';
  static const String defaultLMStudioUrl = 'http://localhost:1234/v1';
  static const String defaultModel = 'qwen2.5:latest';
  static const String fallbackModel = 'qwen2.5:1.5b';
  
  // API路径
  static const String ollamaApiPath = '/api/generate';
  static const String lmStudioApiPath = '/chat/completions';
  
  // TTS默认值
  static const double defaultSpeechRate = 1.0; // 修改默认语速为1.0
  static const double defaultVolume = 1.0;
  static const double defaultPitch = 1.0;
}

/// 翻译语言常量
class TranslationLanguages {
  static const List<String> supportedLanguages = [
    'Chinese',
    'English',
    'Japanese',
    'Korean',
    'French',
    'German',
    'Spanish',
    'Italian',
    'Russian',
    'Arabic',
    'Hindi',
    'Greek',
  ];

  static const List<String> defaultSelectedLanguages = [
    'English',
  ];
}
