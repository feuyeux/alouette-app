import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../constants/app_constants.dart';

/// 语言选择器组件
class LanguageSelector extends StatelessWidget {
  final LanguageOption selectedLanguage;
  final ValueChanged<LanguageOption> onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<LanguageOption>(
              value: selectedLanguage,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              items: LanguageConstants.supportedLanguages.map((language) {
                return DropdownMenuItem<LanguageOption>(
                  value: language,
                  child: Row(
                    children: [
                      Text(
                        language.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          language.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        language.code,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (LanguageOption? value) {
                if (value != null) {
                  onLanguageChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
