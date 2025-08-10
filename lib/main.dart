import 'package:flutter/material.dart';
import 'pages/app_home_page.dart';

void main() {
  runApp(const AlouetteApp());
}

class AlouetteApp extends StatelessWidget {
  const AlouetteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AppHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
