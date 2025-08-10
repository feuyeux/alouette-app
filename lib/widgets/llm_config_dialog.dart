import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/llm_config_service.dart';
import '../constants/app_constants.dart';

class LLMConfigDialog extends StatefulWidget {
  final LLMConfig initialConfig;
  final LLMConfigService llmConfigService;

  const LLMConfigDialog({
    super.key,
    required this.initialConfig,
    required this.llmConfigService,
  });

  @override
  State<LLMConfigDialog> createState() => _LLMConfigDialogState();
}

class _LLMConfigDialogState extends State<LLMConfigDialog> {
  late TextEditingController _serverUrlController;
  late TextEditingController _apiKeyController;
  String _selectedProvider = 'ollama';
  String _selectedModel = '';
  bool _isTestingConnection = false;
  String? _connectionMessage;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.initialConfig.provider;
    _serverUrlController = TextEditingController(text: widget.initialConfig.serverUrl);
    _apiKeyController = TextEditingController(text: widget.initialConfig.apiKey ?? '');
    _selectedModel = widget.initialConfig.selectedModel;

    // 如果已经有可用模型，标记连接成功
    if (widget.llmConfigService.availableModels.isNotEmpty) {
      _connectionSuccess = true;
      _connectionMessage = 'Connected. ${widget.llmConfigService.availableModels.length} models available.';
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  /// 测试连接
  Future<void> _testConnection() async {
    if (_isTestingConnection) return;

    setState(() {
      _isTestingConnection = true;
      _connectionMessage = null;
      _connectionSuccess = false;
    });

    final config = LLMConfig(
      provider: _selectedProvider,
      serverUrl: _serverUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
      selectedModel: '',
    );

    try {
      final result = await widget.llmConfigService.testConnection(config);
      
      setState(() {
        _connectionSuccess = result['success'];
        _connectionMessage = result['message'];
        if (_connectionSuccess && widget.llmConfigService.availableModels.isNotEmpty) {
          // 自动选择第一个可用模型
          _selectedModel = widget.llmConfigService.availableModels.first;
        }
      });
    } catch (error) {
      setState(() {
        _connectionSuccess = false;
        _connectionMessage = 'Connection failed: $error';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  /// 保存配置
  void _saveConfig() {
    if (!_connectionSuccess || _selectedModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please test connection and select a model first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final config = LLMConfig(
      provider: _selectedProvider,
      serverUrl: _serverUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
      selectedModel: _selectedModel,
    );

    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('LLM Configuration'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Selection
              Text(
                'Provider',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedProvider,
                items: const [
                  DropdownMenuItem(value: 'ollama', child: Text('Ollama')),
                  DropdownMenuItem(value: 'lmstudio', child: Text('LM Studio')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProvider = value;
                      // 根据提供者设置默认URL
                      if (value == 'ollama') {
                        _serverUrlController.text = AppConstants.defaultOllamaUrl;
                      } else if (value == 'lmstudio') {
                        _serverUrlController.text = AppConstants.defaultLMStudioUrl;
                      }
                      _connectionSuccess = false;
                      _connectionMessage = null;
                      _selectedModel = '';
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Server URL
              Text(
                'Server URL',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _serverUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'http://localhost:11434',
                ),
                onChanged: (_) {
                  setState(() {
                    _connectionSuccess = false;
                    _connectionMessage = null;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // API Key (for LM Studio)
              if (_selectedProvider == 'lmstudio') ...[
                Text(
                  'API Key (Optional)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'Leave empty if not required',
                  ),
                  obscureText: true,
                  onChanged: (_) {
                    setState(() {
                      _connectionSuccess = false;
                      _connectionMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Test Connection Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  icon: _isTestingConnection 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi),
                  label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Connection Status
              if (_connectionMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _connectionSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    border: Border.all(
                      color: _connectionSuccess ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _connectionSuccess ? Icons.check_circle : Icons.error,
                        color: _connectionSuccess ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _connectionMessage!,
                          style: TextStyle(
                            color: _connectionSuccess ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Model Selection
              if (_connectionSuccess && widget.llmConfigService.availableModels.isNotEmpty) ...[
                Text(
                  'Model',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedModel.isEmpty ? null : _selectedModel,
                  items: widget.llmConfigService.availableModels.map((model) {
                    return DropdownMenuItem(
                      value: model,
                      child: Text(
                        model,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedModel = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Select a model'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveConfig,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
