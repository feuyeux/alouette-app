import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class TranslationInputWidget extends StatefulWidget {
  final TextEditingController textController;
  final List<String> selectedLanguages;
  final VoidCallback onTranslate;
  final bool isTranslating;

  const TranslationInputWidget({
    super.key,
    required this.textController,
    required this.selectedLanguages,
    required this.onTranslate,
    required this.isTranslating,
  });

  @override
  State<TranslationInputWidget> createState() => _TranslationInputWidgetState();
}

class _TranslationInputWidgetState extends State<TranslationInputWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.edit, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Text Input',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // 文本输入框 - 减小高度
            Container(
              height: 60, // 进一步减小高度
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: widget.textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Enter text to translate...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // 语言选择
            Expanded(
              child: _buildLanguageSelection(),
            ),
            
            const SizedBox(height: 6),
            
            // 翻译按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.isTranslating ? null : widget.onTranslate,
                icon: widget.isTranslating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate, size: 16),
                label: Text(
                  widget.isTranslating ? 'Translating...' : 'Translate',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建语言选择区域
  Widget _buildLanguageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.language, size: 16),
            const SizedBox(width: 4),
            Text(
              'Target Languages',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Spacer(),
            Text(
              'Selected: ${widget.selectedLanguages.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // 语言选择按钮 - 可滚动
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: TranslationLanguages.supportedLanguages.map((language) {
                final isSelected = widget.selectedLanguages.contains(language);
                return FilterChip(
                  label: Text(
                    language,
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        widget.selectedLanguages.add(language);
                      } else {
                        widget.selectedLanguages.remove(language);
                      }
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundColor: Colors.grey.shade100,
                );
              }).toList(),
            ),
          ),
        ),
        
        const SizedBox(height: 2),
        
        // 快速选择按钮 - 更紧凑
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  widget.selectedLanguages.clear();
                  widget.selectedLanguages.addAll(TranslationLanguages.defaultSelectedLanguages);
                });
              },
              icon: const Icon(Icons.refresh, size: 12),
              label: const Text('Reset', style: TextStyle(fontSize: 10)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            
            const SizedBox(width: 4),
            
            TextButton.icon(
              onPressed: () {
                setState(() {
                  widget.selectedLanguages.clear();
                  widget.selectedLanguages.addAll(TranslationLanguages.supportedLanguages);
                });
              },
              icon: const Icon(Icons.select_all, size: 12),
              label: const Text('All', style: TextStyle(fontSize: 10)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
