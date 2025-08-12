import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AlouetteAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AlouetteAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      title: Row(
        children: [
          // Alouette标题
          const Text(
            'Alouette',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icons/alouette_rounded.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.translate,
                      color: Colors.blue,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const Spacer(),
          
          // 系统信息
          _buildSystemInfo(),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    final platform = _getPlatformName();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPlatformIcon(),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            platform,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            'Flutter',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
    } catch (e) {
      // 如果Platform类不可用，默认返回Unknown
      return 'Unknown';
    }
    return 'Unknown';
  }

  IconData _getPlatformIcon() {
    if (kIsWeb) return Icons.web;
    try {
      if (Platform.isWindows) return Icons.desktop_windows;
      if (Platform.isMacOS) return Icons.desktop_mac;
      if (Platform.isLinux) return Icons.computer;
      if (Platform.isAndroid) return Icons.phone_android;
      if (Platform.isIOS) return Icons.phone_iphone;
    } catch (e) {
      // 如果Platform类不可用，默认返回通用图标
      return Icons.devices;
    }
    return Icons.devices;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
