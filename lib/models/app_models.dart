/// 语言配置模型
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

/// LLM配置模型
class LLMConfig {
  final String provider;
  final String serverUrl;
  final String? apiKey;
  final String selectedModel;

  const LLMConfig({
    required this.provider,
    required this.serverUrl,
    this.apiKey,
    required this.selectedModel,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'server_url': serverUrl,
      'api_key': apiKey,
      'selected_model': selectedModel,
    };
  }

  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      provider: json['provider'] ?? 'ollama',
      serverUrl: json['server_url'] ?? 'http://localhost:11434',
      apiKey: json['api_key'],
      selectedModel: json['selected_model'] ?? '',
    );
  }

  LLMConfig copyWith({
    String? provider,
    String? serverUrl,
    String? apiKey,
    String? selectedModel,
  }) {
    return LLMConfig(
      provider: provider ?? this.provider,
      serverUrl: serverUrl ?? this.serverUrl,
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }
}

/// 翻译请求模型
class TranslationRequest {
  final String text;
  final List<String> targetLanguages;
  final String provider;
  final String serverUrl;
  final String modelName;
  final String? apiKey;

  const TranslationRequest({
    required this.text,
    required this.targetLanguages,
    required this.provider,
    required this.serverUrl,
    required this.modelName,
    this.apiKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'target_languages': targetLanguages,
      'provider': provider,
      'server_url': serverUrl,
      'model_name': modelName,
      'api_key': apiKey,
    };
  }
}

/// 翻译结果模型
class TranslationResult {
  final String original;
  final Map<String, String> translations;
  final List<String> languages;
  final DateTime timestamp;
  final LLMConfig config;

  const TranslationResult({
    required this.original,
    required this.translations,
    required this.languages,
    required this.timestamp,
    required this.config,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json, LLMConfig config) {
    return TranslationResult(
      original: json['original'] ?? '',
      translations: Map<String, String>.from(json['translations'] ?? {}),
      languages: List<String>.from(json['languages'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      config: config,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'translations': translations,
      'languages': languages,
      'timestamp': timestamp.toIso8601String(),
      'config': config.toJson(),
    };
  }
}

/// 连接状态模型
class ConnectionStatus {
  final bool success;
  final String message;
  final int? modelCount;
  final DateTime timestamp;

  const ConnectionStatus({
    required this.success,
    required this.message,
    this.modelCount,
    required this.timestamp,
  });
}
