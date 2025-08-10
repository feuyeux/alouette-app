import 'package:flutter/material.dart';

/// TTS控制按钮组件
class TTSControlButtons extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const TTSControlButtons({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 播放/暂停按钮
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPlaying
                  ? [Colors.orange.shade400, Colors.orange.shade600]
                  : [Colors.blue.shade400, Colors.blue.shade600],
            ),
            boxShadow: [
              BoxShadow(
                color: (isPlaying ? Colors.orange : Colors.blue).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: onPlayPause,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // 停止按钮
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onStop,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(
                  Icons.stop,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
