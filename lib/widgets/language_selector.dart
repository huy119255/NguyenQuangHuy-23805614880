import 'package:flutter/material.dart';

import '../services/translation_service.dart';

class LanguageSelector extends StatelessWidget {
  final TranslatorLanguage value;
  final ValueChanged<TranslatorLanguage> onChanged;

  const LanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey(value.code),
    initialValue: value.code,
    decoration: const InputDecoration(
      labelText: 'Ngôn ngữ',
      prefixIcon: Icon(Icons.language),
    ),
    items: TranslatorLanguage.values
        .map(
          (language) => DropdownMenuItem(
            value: language.code,
            child: Text(language.label),
          ),
        )
        .toList(),
    onChanged: (code) {
      final selected = TranslatorLanguage.values.firstWhere(
        (language) => language.code == code,
      );
      onChanged(selected);
    },
  );
}
