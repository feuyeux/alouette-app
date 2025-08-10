import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';

/// LLM 配置服务，处理与 Ollama 和 LM Studio 的连接
class LLMConfigService {
  List<String> _availableModels = [];
  ConnectionStatus? _connectionStatus;
  bool _isTestingConnection = false;

  List<String> get availableModels => _availableModels;
  ConnectionStatus? get connectionStatus => _connectionStatus;
  bool get isTestingConnection => _isTestingConnection;

  /// 测试与 LLM 提供者的连接
  Future<Map<String, dynamic>> testConnection(LLMConfig config) async {
    if (_isTestingConnection) {
      return {
        'success': false,
        'message': 'Connection test is already in progress',
      };
    }

    _isTestingConnection = true;
    try {
      print('Testing connection to ${config.provider}...');

      List<String> models;
      switch (config.provider) {
        case 'ollama':
          models = await _connectOllama(config.serverUrl);
          break;
        case 'lmstudio':
          models = await _connectLMStudio(config.serverUrl, config.apiKey);
          break;
        default:
          throw Exception('Unsupported provider: ${config.provider}');
      }

      _availableModels = models;
      _connectionStatus = ConnectionStatus(
        success: true,
        message: 'Successfully connected to ${config.provider}',
        modelCount: models.length,
        timestamp: DateTime.now(),
      );

      return {
        'success': true,
        'message': 'Connected successfully. Found ${models.length} models.',
        'models': models,
      };
    } catch (error) {
      _connectionStatus = ConnectionStatus(
        success: false,
        message: 'Failed to connect: $error',
        timestamp: DateTime.now(),
      );

      return {
        'success': false,
        'message': error.toString(),
      };
    } finally {
      _isTestingConnection = false;
    }
  }

  /// 连接到 Ollama
  Future<List<String>> _connectOllama(String serverUrl) async {
    final url = Uri.parse('$serverUrl/api/tags');
    
    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['models'] as List?;
      
      if (models != null) {
        return models.map((model) => model['name'].toString()).toList();
      } else {
        throw Exception('No models found in response');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// 连接到 LM Studio
  Future<List<String>> _connectLMStudio(String serverUrl, String? apiKey) async {
    final url = Uri.parse('$serverUrl/v1/models');
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.get(url, headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['data'] as List?;
      
      if (models != null) {
        return models.map((model) => model['id'].toString()).toList();
      } else {
        throw Exception('No models found in response');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please check your API key.');
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// 清除连接状态
  void clearConnectionStatus() {
    _connectionStatus = null;
    _availableModels.clear();
  }
}
