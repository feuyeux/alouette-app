import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import '../constants/app_constants.dart';

class TTSConfigDialog extends StatefulWidget {
  final AlouetteTTSService? ttsService;

  const TTSConfigDialog({super.key, this.ttsService});

  @override
  State<TTSConfigDialog> createState() => _TTSConfigDialogState();
}

class _TTSConfigDialogState extends State<TTSConfigDialog> {
  double _speechRate = AppConstants.defaultSpeechRate;
  double _volume = AppConstants.defaultVolume;
  double _pitch = AppConstants.defaultPitch;
  bool _isInitialized = false;
  String _selectedLanguage = 'en-US';
  String? _selectedVoiceId;
  Map<String, dynamic>? _engineInfo;

  @override
  void initState() {
    super.initState();
    _initializeTTSSettings();
  }

  Future<void> _initializeTTSSettings() async {
    if (widget.ttsService != null) {
      try {
        // 获取当前TTS配置
        final currentConfig = widget.ttsService!.currentConfig;

        // 获取TTS引擎信息
        final engineInfo = widget.ttsService!.getTTSEngineInfo();

        if (mounted) {
          setState(() {
            _speechRate = currentConfig.speechRate;
            _volume = currentConfig.volume;
            _pitch = currentConfig.pitch;
            _selectedLanguage = currentConfig.languageCode;
            _selectedVoiceId = currentConfig.voiceName;
            _engineInfo = engineInfo;
            _isInitialized = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _testTTS() async {
    if (widget.ttsService != null) {
      try {
        await widget.ttsService!.speak('Hello! This is a TTS test.');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('TTS test failed: $e')));
        }
      }
    }
  }

  Future<void> _updateConfig() async {
    if (widget.ttsService != null) {
      final defaultConfig = AlouetteTTSConfig(
        speechRate: _speechRate,
        volume: _volume,
        pitch: _pitch,
        languageCode: _selectedLanguage,
        voiceName: _selectedVoiceId,
      );
      await widget.ttsService!.updateConfig(defaultConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.85; // 最大高度为屏幕的85%

    return Dialog(
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 固定的标题栏
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'TTS Configuration',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // 可滚动的内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isInitialized)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      // TTS状态
                      _buildStatusCard(),

                      const SizedBox(height: 16),

                      // TTS引擎信息
                      if (_engineInfo != null) ...[
                        _buildEngineInfoCard(),
                        const SizedBox(height: 16),
                      ],

                      // 语音设置
                      _buildSliderSetting(
                        'Speech Rate',
                        _speechRate,
                        0.1,
                        2.0,
                        (value) async {
                          setState(() => _speechRate = value);
                          await _updateConfig();
                        },
                        Icons.speed,
                        '${(_speechRate * 100).round()}%',
                      ),

                      const SizedBox(height: 16),

                      _buildSliderSetting(
                        'Volume',
                        _volume,
                        0.0,
                        1.0,
                        (value) async {
                          setState(() => _volume = value);
                          await _updateConfig();
                        },
                        Icons.volume_up,
                        '${(_volume * 100).round()}%',
                      ),

                      const SizedBox(height: 16),

                      _buildSliderSetting(
                        'Pitch',
                        _pitch,
                        0.1,
                        2.0,
                        (value) async {
                          setState(() => _pitch = value);
                          await _updateConfig();
                        },
                        Icons.graphic_eq,
                        '${(_pitch * 100).round()}%',
                      ),

                      const SizedBox(height: 20),

                      // 测试按钮
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: widget.ttsService != null
                              ? _testTTS
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Test TTS'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.ttsService != null
            ? Colors.green.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.ttsService != null
              ? Colors.green.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.ttsService != null ? Icons.check_circle : Icons.warning,
            color: widget.ttsService != null
                ? Colors.green.shade600
                : Colors.orange.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            widget.ttsService != null
                ? 'TTS Service Available'
                : 'TTS Service Not Available',
            style: TextStyle(
              color: widget.ttsService != null
                  ? Colors.green.shade800
                  : Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_voice, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'TTS Engine Information',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildEngineInfoRow(
            'Engine',
            _engineInfo!['engineName'] ?? 'Unknown',
          ),
          _buildEngineInfoRow('Type', _engineInfo!['engineType'] ?? 'Unknown'),
          _buildEngineInfoRow(
            'Platform',
            _engineInfo!['platform'] ?? 'Unknown',
          ),
          if (_engineInfo!['description'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _engineInfo!['description'],
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEngineInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    IconData icon,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
