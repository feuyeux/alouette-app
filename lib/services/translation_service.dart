import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';

/// 翻译服务，处理文本翻译逻辑
class TranslationService {
  TranslationResult? _currentTranslation;
  bool _isTranslating = false;

  TranslationResult? get currentTranslation => _currentTranslation;
  bool get isTranslating => _isTranslating;

  /// 翻译文本到多个目标语言
  Future<TranslationResult> translateText(
    String inputText,
    List<String> targetLanguages,
    LLMConfig config,
  ) async {
    if (inputText.trim().isEmpty) {
      throw Exception('Please enter text to translate');
    }

    if (targetLanguages.isEmpty) {
      throw Exception('Please select at least one target language');
    }

    if (config.serverUrl.isEmpty || config.selectedModel.isEmpty) {
      throw Exception('Please configure LLM settings first');
    }

    _isTranslating = true;
    try {
      print('Starting translation request:');
      print('Text: $inputText');
      print('Target languages: $targetLanguages');
      print('Provider: ${config.provider}');
      print('Server URL: ${config.serverUrl}');
      print('Model: ${config.selectedModel}');

      final request = TranslationRequest(
        text: inputText.trim(),
        targetLanguages: targetLanguages,
        provider: config.provider,
        serverUrl: config.serverUrl,
        modelName: config.selectedModel,
        apiKey: config.apiKey,
      );

      final translations = <String, String>{};

      // 逐个语言进行翻译
      for (int i = 0; i < targetLanguages.length; i++) {
        final language = targetLanguages[i];
        print('Translating to $language (${i + 1}/${targetLanguages.length})...');

        String translation;
        switch (config.provider) {
          case 'ollama':
            translation = await _callOllamaTranslate(
              request.text,
              language,
              config.serverUrl,
              config.selectedModel,
            );
            break;
          case 'lmstudio':
            translation = await _callLMStudioTranslate(
              request.text,
              language,
              config.serverUrl,
              config.selectedModel,
              config.apiKey,
            );
            break;
          default:
            throw Exception('Unsupported provider: ${config.provider}');
        }

        translations[language] = translation;
        print('Successfully translated to $language: $translation');
      }

      _currentTranslation = TranslationResult(
        original: inputText.trim(),
        translations: translations,
        timestamp: DateTime.now(),
        languages: targetLanguages,
        config: config,
      );

      print('Translation completed successfully');
      return _currentTranslation!;
    } catch (error) {
      print('Translation failed: $error');
      // 提供更具体的错误信息
      final errorMsg = error.toString();
      if (errorMsg.contains('Connection refused') || errorMsg.contains('network')) {
        throw Exception(
            'Cannot connect to ${config.provider} server at ${config.serverUrl}. Please check if the server is running and accessible.');
      } else if (errorMsg.contains('Unauthorized') || errorMsg.contains('401')) {
        throw Exception('Authentication failed. Please check your API key.');
      } else if (errorMsg.contains('Not found') || errorMsg.contains('404')) {
        throw Exception(
            'Model "${config.selectedModel}" not found. Please check if the model is available.');
      } else if (errorMsg.contains('timeout')) {
        throw Exception('Translation request timed out. The server may be overloaded.');
      } else {
        rethrow;
      }
    } finally {
      _isTranslating = false;
    }
  }

  /// 调用 Ollama API 进行翻译
  Future<String> _callOllamaTranslate(
    String text,
    String targetLanguage,
    String serverUrl,
    String model,
  ) async {
    final url = Uri.parse('$serverUrl/api/generate');
    
    final prompt = '''
Translate the following text to $targetLanguage. Only return the translation, nothing else.

$text''';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'prompt': prompt,
        'stream': false,
        'options': {
          'temperature': 0.1,
          'num_ctx': 4096,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translatedText = data['response']?.toString().trim() ?? '';
      
      if (translatedText.isEmpty) {
        throw Exception('Empty translation response from Ollama');
      }
      
      return _cleanTranslationResult(translatedText);
    } else {
      throw Exception('Ollama API request failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// 调用 LM Studio API 进行翻译
  Future<String> _callLMStudioTranslate(
    String text,
    String targetLanguage,
    String serverUrl,
    String model,
    String? apiKey,
  ) async {
    final url = Uri.parse('$serverUrl/v1/chat/completions');
    
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional translator. Only return the translation, nothing else.',
          },
          {
            'role': 'user',
            'content': 'Translate to $targetLanguage:\n\n$text',
          },
        ],
        'temperature': 0.1,
        'max_tokens': 4096,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        final translatedText = message['content']?.toString().trim() ?? '';
        
        if (translatedText.isEmpty) {
          throw Exception('Empty translation response from LM Studio');
        }
        
        return _cleanTranslationResult(translatedText);
      } else {
        throw Exception('No translation choices returned from LM Studio');
      }
    } else {
      throw Exception('LM Studio API request failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// 清理翻译结果，移除不必要的前缀和后缀
  String _cleanTranslationResult(String result) {
    // 简化处理，只移除明显的前缀和多余空格
    String cleaned = result.trim();
    
    // 移除常见的翻译前缀
    final prefixes = [
      'Translation:',
      'Translated text:',
      'Here is the translation:',
      'The translation is:',
      'Answer:',
      'Response:',
    ];
    
    for (final prefix in prefixes) {
      if (cleaned.toLowerCase().startsWith(prefix.toLowerCase())) {
        cleaned = cleaned.substring(prefix.length).trim();
        break;
      }
    }

    // 移除前后的引号（但要小心处理阿拉伯语等复杂文本）
    if (cleaned.length > 2) {
      if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
          (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
        cleaned = cleaned.substring(1, cleaned.length - 1).trim();
      }
    }

    return cleaned;
  }

  /// 获取当前翻译结果
  TranslationResult? getCurrentTranslation() {
    return _currentTranslation;
  }

  /// 清除当前翻译
  void clearTranslation() {
    _currentTranslation = null;
  }

  /// 获取翻译状态
  Map<String, dynamic> getTranslationState() {
    return {
      'isTranslating': _isTranslating,
      'hasTranslation': _currentTranslation != null,
      'currentTranslation': _currentTranslation,
    };
  }

  /// 格式化翻译结果用于显示
  Map<String, dynamic>? formatForDisplay([TranslationResult? translation]) {
    final trans = translation ?? _currentTranslation;
    if (trans == null) return null;

    return {
      'original': trans.original,
      'translations': trans.translations,
      'languages': trans.languages,
      'timestamp': trans.timestamp.toLocal().toString(),
      'model': trans.config.selectedModel,
      'provider': trans.config.provider,
    };
  }
}
