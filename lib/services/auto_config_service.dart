import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import 'llm_config_service.dart';
import '../constants/app_constants.dart';

/// 自动配置服务，负责应用启动时的自动连接和配置
class AutoConfigService {
  final LLMConfigService _llmConfigService = LLMConfigService();

  /// 自动配置LLM连接
  Future<LLMConfig?> autoConfigureLLM() async {
    try {
      debugPrint('🔄 Starting automatic LLM configuration...');

      // 创建默认配置
      final defaultConfig = LLMConfig(
        provider: 'ollama',
        serverUrl: AppConstants.defaultOllamaUrl,
        selectedModel: '',
      );

      // 测试连接到Ollama服务器
      debugPrint('🔍 Testing connection to Ollama...');
      final connectionResult = await _llmConfigService.testConnection(defaultConfig);
      
      if (!connectionResult['success']) {
        debugPrint('❌ Failed to connect to Ollama: ${connectionResult['message']}');
        return null;
      }

      final availableModels = connectionResult['models'] as List<String>?;
      if (availableModels == null || availableModels.isEmpty) {
        debugPrint('❌ No models available on Ollama server');
        return null;
      }

      debugPrint('✅ Connected to Ollama. Available models: ${availableModels.join(', ')}');

      // 选择模型：优先选择默认模型，否则选择备用模型，最后选择第一个可用模型
      String selectedModel;
      if (availableModels.contains(AppConstants.defaultModel)) {
        selectedModel = AppConstants.defaultModel;
        debugPrint('✅ Using preferred model: $selectedModel');
      } else if (availableModels.contains(AppConstants.fallbackModel)) {
        selectedModel = AppConstants.fallbackModel;
        debugPrint('⚠️ Preferred model not found, using fallback: $selectedModel');
      } else {
        selectedModel = availableModels.first;
        debugPrint('⚠️ Neither preferred nor fallback model found, using: $selectedModel');
      }

      final finalConfig = LLMConfig(
        provider: 'ollama',
        serverUrl: AppConstants.defaultOllamaUrl,
        selectedModel: selectedModel,
      );

      debugPrint('🎉 Auto-configuration completed successfully with model: $selectedModel');
      return finalConfig;
    } catch (error) {
      debugPrint('💥 Auto-configuration failed: $error');
      return null;
    }
  }
}
