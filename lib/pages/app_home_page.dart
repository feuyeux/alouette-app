import 'package:flutter/material.dart';
import 'translation_page.dart';
import '../widgets/alouette_app_bar.dart';

/// 应用主页面，专注于翻译功能
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AlouetteAppBar(),
      body: TranslationPage(),
    );
  }
}
