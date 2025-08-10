import 'package:flutter/material.dart';

/// 增强音量滑块组件
class EnhancedVolumeSlider extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const EnhancedVolumeSlider({
    super.key,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getVolumeIcon(volume),
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Volume',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(volume * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // 音量滑块
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 18,
            ),
            activeTrackColor: _getVolumeColor(volume),
            thumbColor: _getVolumeColor(volume),
            overlayColor: _getVolumeColor(volume).withValues(alpha: 0.2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.volume_down,
                size: 18,
                color: Colors.grey.shade500,
              ),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: onVolumeChanged,
                ),
              ),
              Icon(
                Icons.volume_up,
                size: 18,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
        
        // 快速设置按钮
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuickVolumeButton(context, '25%', 0.25),
            const SizedBox(width: 8),
            _buildQuickVolumeButton(context, '50%', 0.5),
            const SizedBox(width: 8),
            _buildQuickVolumeButton(context, '75%', 0.75),
            const SizedBox(width: 8),
            _buildQuickVolumeButton(context, '100%', 1.0),
          ],
        ),
      ],
    );
  }

  /// 构建快速音量设置按钮
  Widget _buildQuickVolumeButton(BuildContext context, String label, double value) {
    final isSelected = (volume - value).abs() < 0.01;
    
    return GestureDetector(
      onTap: () => onVolumeChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  /// 根据音量获取图标
  IconData _getVolumeIcon(double volume) {
    if (volume == 0) {
      return Icons.volume_off;
    } else if (volume < 0.3) {
      return Icons.volume_mute;
    } else if (volume < 0.7) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }

  /// 根据音量获取颜色
  Color _getVolumeColor(double volume) {
    if (volume == 0) {
      return Colors.grey;
    } else if (volume < 0.3) {
      return Colors.orange;
    } else if (volume < 0.7) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }
}
