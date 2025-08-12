// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alouette_app/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Set a larger screen size to avoid overflow issues during testing
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AlouetteApp());
    
    // Wait for the widget tree to settle
    await tester.pumpAndSettle();

    // Verify that the app builds without throwing exceptions
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Reset surface size
    await tester.binding.setSurfaceSize(null);
  });
}
