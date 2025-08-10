import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../constants/app_constants.dart';

/// TTS服务类
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  static const platform = MethodChannel('com.example.alouette_app/audio');
  
  // 存储当前TTS设置
  double _currentSpeechRate = AppConstants.defaultSpeechRate;
  double _currentVolume = AppConstants.defaultVolume;
  double _currentPitch = AppConstants.defaultPitch;

  /// 初始化TTS
  Future<void> initialize({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required void Function(dynamic message) onError,
  }) async {
    _flutterTts.setStartHandler(onStart);
    _flutterTts.setCompletionHandler(onComplete);
    _flutterTts.setErrorHandler(onError);

    // 设置默认值
    await _flutterTts.setSpeechRate(_currentSpeechRate);
    await _flutterTts.setVolume(_currentVolume);
    await _flutterTts.setPitch(_currentPitch);

    // Android 特定配置
    if (!kIsWeb && Platform.isAndroid) {
      await _configureAndroidAudio();
    }
  }

  /// 配置 Android 音频
  Future<void> _configureAndroidAudio() async {
    try {
      // 设置音频流类型为媒体音频流
      await platform.invokeMethod('setAudioStreamType');

      // 设置 TTS 引擎参数
      await _flutterTts.awaitSpeakCompletion(true);

      // 尝试设置 Android TTS 引擎选项
      await _flutterTts.setSharedInstance(true);

      // 获取并记录音量信息用于调试
      try {
        final maxVolume = await platform.invokeMethod('getMaxVolume');
        final currentVolume = await platform.invokeMethod('getCurrentVolume');
        if (kDebugMode) {
          debugPrint(
            'TTS Audio - Max Volume: $maxVolume, Current Volume: $currentVolume',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to get volume info: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to configure Android audio: $e');
      }
    }
  }

  /// 开始朗读
  Future<void> speak({
    required String text,
    required String languageCode,
    required double speechRate,
    required double volume,
    required double pitch,
  }) async {
    if (text.isEmpty) return;

    // 设置 TTS 参数
    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.setVolume(volume);
    await _flutterTts.setPitch(pitch);
    await _flutterTts.setLanguage(languageCode);

    await _flutterTts.speak(text);
  }

  /// 停止朗读
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// 获取当前语音速度
  Future<double?> getSpeechRate() async {
    return _currentSpeechRate;
  }

  /// 获取当前音量
  Future<double?> getVolume() async {
    return _currentVolume;
  }

  /// 获取当前音调
  Future<double?> getPitch() async {
    return _currentPitch;
  }

  /// 获取可用语言列表
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      if (languages != null && languages is List) {
        return languages.cast<String>();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get languages: $e');
      }
    }
    // 返回默认支持的语言列表
    return ['en-US', 'zh-CN', 'ja-JP', 'ko-KR', 'fr-FR', 'de-DE', 'es-ES', 'it-IT', 'ru-RU', 'ar-SA', 'hi-IN', 'el-GR'];
  }

  /// 设置语音速度
  Future<void> setSpeechRate(double rate) async {
    _currentSpeechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    _currentVolume = volume;
    await _flutterTts.setVolume(volume);
  }

  /// 设置音调
  Future<void> setPitch(double pitch) async {
    _currentPitch = pitch;
    await _flutterTts.setPitch(pitch);
  }

  /// 释放资源
  void dispose() {
    _flutterTts.stop();
  }
}
