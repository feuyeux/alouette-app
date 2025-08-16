// Re-export models from libraries for backward compatibility
export 'package:alouette_lib_tts/alouette_tts.dart'
    show AlouetteTTSConfig, AlouetteVoice, TTSState;
export 'package:alouette_lib_trans/alouette_lib_trans.dart'
    show LLMConfig, TranslationRequest, TranslationResult, ConnectionStatus;

// App-specific models
class LanguageOption {
  final String code;
  final String name;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}
