import 'package:alouette_lib_trans/alouette_lib_trans.dart' as trans_lib;

/// LLM 配置服务，处理与 Ollama 和 LM Studio 的连接 - 使用 alouette-lib-trans 库
class LLMConfigService {
  final trans_lib.LLMConfigService _llmConfigService = trans_lib.LLMConfigService();

  /// 测试与 LLM 提供者的连接
  Future<Map<String, dynamic>> testConnection(trans_lib.LLMConfig config) async {
    try {
      final connectionStatus = await _llmConfigService.testConnection(config);
      
      if (connectionStatus.success) {
        final models = await _llmConfigService.getAvailableModels(config);
        return {
          'success': true,
          'message': connectionStatus.message,
          'models': models,
        };
      } else {
        return {
          'success': false,
          'message': connectionStatus.message,
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': error.toString(),
      };
    }
  }

  /// 获取可用模型列表
  Future<List<String>> getAvailableModels(trans_lib.LLMConfig config) async {
    return await _llmConfigService.getAvailableModels(config);
  }

  /// 测试连接状态
  Future<trans_lib.ConnectionStatus> getConnectionStatus(trans_lib.LLMConfig config) async {
    return await _llmConfigService.testConnection(config);
  }

  /// 保存配置
  Future<void> saveConfig(trans_lib.LLMConfig config) async {
    await _llmConfigService.saveConfig(config);
  }

  /// 加载配置
  Future<trans_lib.LLMConfig?> loadConfig() async {
    return await _llmConfigService.loadConfig();
  }

  /// 自动检测配置
  Future<trans_lib.LLMConfig?> autoDetectConfig() async {
    return await _llmConfigService.autoDetectConfig();
  }
}
