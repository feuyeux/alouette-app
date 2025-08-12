import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_lib_tts.dart';
import '../constants/app_constants.dart';

class TTSConfigDialog extends StatefulWidget {
  final TTSService? ttsService;

  const TTSConfigDialog({
    super.key,
    this.ttsService,
  });

  @override
  State<TTSConfigDialog> createState() => _TTSConfigDialogState();
}

class _TTSConfigDialogState extends State<TTSConfigDialog> {
  double _speechRate = AppConstants.defaultSpeechRate;
  double _volume = AppConstants.defaultVolume;
  double _pitch = AppConstants.defaultPitch;
  bool _isInitialized = false;
  final String _selectedLanguage = 'en-US';

  @override
  void initState() {
    super.initState();
    _initializeTTSSettings();
  }

  Future<void> _initializeTTSSettings() async {
    if (widget.ttsService != null) {
      try {
        // 获取当前TTS设置
        final currentRate = widget.ttsService!.getSpeechRate();
        final currentVolume = widget.ttsService!.getVolume();
        final currentPitch = widget.ttsService!.getPitch();
        await widget.ttsService!.getLanguages();
        
        if (mounted) {
          setState(() {
            _speechRate = currentRate;
            _volume = currentVolume;
            _pitch = currentPitch;
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
    if (widget.ttsService == null) return;
    
    try {
      await widget.ttsService!.speak(
        text: "Hello, this is a test of the text to speech settings.",
        languageCode: _selectedLanguage,
        speechRate: _speechRate,
        volume: _volume,
        pitch: _pitch,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS Test Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopTTS() async {
    if (widget.ttsService == null) return;
    await widget.ttsService!.stop();
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _speechRate = AppConstants.defaultSpeechRate;
      _volume = AppConstants.defaultVolume;
      _pitch = AppConstants.defaultPitch;
    });
    
    // 应用设置到TTS服务
    if (widget.ttsService != null) {
      await widget.ttsService!.setSpeechRate(_speechRate);
      await widget.ttsService!.setVolume(_volume);
      await widget.ttsService!.setPitch(_pitch);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
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
            
            const SizedBox(height: 24),
            
            if (!_isInitialized)
              const Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              // TTS状态
              Container(
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
                      widget.ttsService != null 
                        ? Icons.check_circle 
                        : Icons.warning,
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
              ),
              
              const SizedBox(height: 24),
              
              // 语音速度
              _buildSliderSetting(
                'Speech Rate',
                _speechRate,
                0.1,
                2.0,
                (value) async {
                  setState(() => _speechRate = value);
                  if (widget.ttsService != null) {
                    await widget.ttsService!.setSpeechRate(value);
                  }
                },
                Icons.speed,
                '${_speechRate.toStringAsFixed(1)}x',
              ),
              
              const SizedBox(height: 16),
              
              // 音量
              _buildSliderSetting(
                'Volume',
                _volume,
                0.0,
                1.0,
                (value) async {
                  setState(() => _volume = value);
                  if (widget.ttsService != null) {
                    await widget.ttsService!.setVolume(value);
                  }
                },
                Icons.volume_up,
                '${(_volume * 100).toInt()}%',
              ),
              
              const SizedBox(height: 16),
              
              // 音调
              _buildSliderSetting(
                'Pitch',
                _pitch,
                0.5,
                2.0,
                (value) async {
                  setState(() => _pitch = value);
                  if (widget.ttsService != null) {
                    await widget.ttsService!.setPitch(value);
                  }
                },
                Icons.tune,
                _pitch.toStringAsFixed(1),
              ),
              
              const SizedBox(height: 24),
              
              // 测试和控制按钮
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.ttsService != null ? _testTTS : null,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  ElevatedButton.icon(
                    onPressed: widget.ttsService != null ? _stopTTS : null,
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  TextButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 说明文本
              Text(
                'Note: These settings will apply to all TTS playback in the application.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
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
