import 'package:flutter/material.dart';

/// TTS状态指示器组件
class TTSStatusIndicator extends StatelessWidget {
  final bool isPlaying;

  const TTSStatusIndicator({
    super.key,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPlaying ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // 状态图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlaying ? Colors.green.shade100 : Colors.grey.shade100,
            ),
            child: Icon(
              isPlaying ? Icons.volume_up : Icons.volume_off,
              color: isPlaying ? Colors.green.shade700 : Colors.grey.shade600,
              size: 18,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 状态文本和动画
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlaying ? 'Speaking...' : 'Ready to speak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPlaying ? Colors.green.shade800 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPlaying 
                      ? 'Tap pause to stop speaking'
                      : 'Enter text and tap play to start',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPlaying ? Colors.green.shade600 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          
          // 动画指示器
          if (isPlaying)
            SizedBox(
              width: 24,
              height: 24,
              child: _buildSpeakingAnimation(),
            ),
        ],
      ),
    );
  }

  /// 构建说话动画
  Widget _buildSpeakingAnimation() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 1),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final barHeight = 4.0 + (8.0 * 
              ((value + index * 0.3) % 1.0).clamp(0.0, 1.0));
            
            return Container(
              width: 3,
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
      onEnd: () {
        // 重新开始动画
      },
    );
  }
}
