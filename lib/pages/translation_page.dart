import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../models/app_models.dart';
import '../services/llm_config_service.dart';
import '../services/translation_service.dart';
import '../services/auto_config_service.dart';
import '../widgets/llm_config_dialog.dart';
import '../widgets/tts_config_dialog.dart';
import '../widgets/translation_input_widget.dart';
import '../widgets/translation_result_widget.dart';
import '../constants/app_constants.dart';

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final LLMConfigService _llmConfigService = LLMConfigService();
  final TranslationService _translationService = TranslationService();
  final AutoConfigService _autoConfigService = AutoConfigService();
  final AlouetteTTSService _ttsService = AlouetteTTSService();

  LLMConfig _llmConfig = const LLMConfig(
    provider: 'ollama',
    serverUrl: AppConstants.defaultOllamaUrl,
    selectedModel: '',
  );

  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedLanguages = [];
  bool _isConfigured = false;
  bool _isAutoConfiguring = false;
  String _autoConfigStatus = '';
  bool _isTTSInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguages.addAll(TranslationLanguages.defaultSelectedLanguages);
    _performAutoConfiguration();
    _initializeTTS();
  }

  @override
  void dispose() {
    _textController.dispose();
    // AlouetteTTSService 不需要手动dispose
    super.dispose();
  }

  /// 初始化TTS服务
  Future<void> _initializeTTS() async {
    try {
      debugPrint('TTS: Starting initialization...');
      await _ttsService.initialize(
        onStart: () {
          // TTS开始播放时的回调
          debugPrint('TTS: Started playing');
        },
        onComplete: () {
          // TTS播放完成时的回调
          debugPrint('TTS: Completed playing');
        },
        onError: (message) {
          debugPrint('TTS Error in callback: $message');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('TTS Error: $message'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        config: AlouetteTTSConfig.defaultConfig(),
      );
      setState(() {
        _isTTSInitialized = true;
      });
      debugPrint('TTS: Successfully initialized');
    } catch (error) {
      debugPrint('Failed to initialize TTS: $error');
      debugPrint('TTS Error Type: ${error.runtimeType}');
      if (error is Exception) {
        debugPrint('TTS Error toString: ${error.toString()}');
      }
      setState(() {
        _isTTSInitialized = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS initialization failed: $error'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// 执行自动配置
  Future<void> _performAutoConfiguration() async {
    if (mounted) {
      setState(() {
        _isAutoConfiguring = true;
        _autoConfigStatus = 'Connecting to local AI service...';
      });
    }

    try {
      final autoConfig = await _autoConfigService.autoConfigureLLM();
      if (mounted) {
        if (autoConfig != null) {
          setState(() {
            _llmConfig = autoConfig;
            _isConfigured = true;
            _isAutoConfiguring = false;
            _autoConfigStatus =
                'Successfully connected to ${autoConfig.selectedModel}';
          });

          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Auto-configured with model: ${autoConfig.selectedModel}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          setState(() {
            _isAutoConfiguring = false;
            _autoConfigStatus =
                'Auto-configuration failed. Please configure manually.';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAutoConfiguring = false;
          _autoConfigStatus = 'Auto-configuration error: $error';
        });
      }
    }
  }

  /// 显示LLM配置对话框
  Future<void> _showConfigDialog() async {
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: _llmConfig,
        llmConfigService: _llmConfigService,
      ),
    );

    if (result != null) {
      setState(() {
        _llmConfig = result;
        _isConfigured = result.selectedModel.isNotEmpty;
      });
    }
  }

  /// 显示TTS配置对话框
  Future<void> _showTTSConfigDialog() async {
    await showDialog(
      context: context,
      builder: (context) =>
          TTSConfigDialog(ttsService: _isTTSInitialized ? _ttsService : null),
    );
  }

  /// 执行翻译
  Future<void> _performTranslation() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text to translate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one target language'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure LLM settings first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _translationService.translateText(
        _textController.text,
        _selectedLanguages,
        _llmConfig,
      );

      setState(() {
        // 触发UI更新以显示翻译结果
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 配置状态栏
        _buildConfigurationStatus(),

        // 主要内容区域
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 翻译输入区域 - 固定较小高度
                SizedBox(
                  height: 250, // 进一步减小高度避免溢出
                  child: TranslationInputWidget(
                    textController: _textController,
                    selectedLanguages: _selectedLanguages,
                    onTranslate: _performTranslation,
                    isTranslating: _translationService.isTranslating,
                  ),
                ),

                const SizedBox(height: 16),

                // 翻译结果区域 - 占用剩余空间
                Expanded(
                  child: TranslationResultWidget(
                    translationService: _translationService,
                    ttsService: _isTTSInitialized ? _ttsService : null,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 配置按钮区域
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _showTTSConfigDialog,
                icon: const Icon(Icons.record_voice_over, size: 18),
                label: const Text('TTS Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: _isTTSInitialized
                      ? null
                      : Colors.grey.shade300,
                  foregroundColor: _isTTSInitialized
                      ? null
                      : Colors.grey.shade600,
                ),
              ),

              const SizedBox(width: 12),

              ElevatedButton.icon(
                onPressed: _showConfigDialog,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('LLM Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建配置状态栏
  Widget _buildConfigurationStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: _isConfigured ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border(
          bottom: BorderSide(
            color: _isConfigured
                ? Colors.green.shade200
                : Colors.orange.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConfigured ? Icons.check_circle : Icons.warning,
            color: _isConfigured
                ? Colors.green.shade600
                : Colors.orange.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isAutoConfiguring
                  ? _autoConfigStatus
                  : _isConfigured
                  ? 'Model: ${_llmConfig.selectedModel} (${_llmConfig.provider})'
                  : 'LLM not configured. Please click the settings button.',
              style: TextStyle(
                color: _isConfigured
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isAutoConfiguring)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
