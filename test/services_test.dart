
import 'package:flutter_test/flutter_test.dart';
import 'package:alouette_app/services/translation_service.dart';
import 'package:alouette_app/services/llm_config_service.dart';

void main() {
  group('Service Integration Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('Translation Service can be instantiated', () {
      final translationService = TranslationService();
      expect(translationService, isNotNull);
      expect(translationService.isTranslating, isFalse);
      expect(translationService.currentTranslation, isNull);
    });

    test('LLM Config Service can be instantiated', () {
      final llmConfigService = LLMConfigService();
      expect(llmConfigService, isNotNull);
    });
  });
}