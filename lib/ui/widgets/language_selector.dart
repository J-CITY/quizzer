import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/database_service.dart';
import '../../utils/language_utils.dart';

class LanguageSelector extends ConsumerStatefulWidget {
  final String label;
  final TextEditingController controller;

  const LanguageSelector({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  ConsumerState<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends ConsumerState<LanguageSelector> {
  List<String> _allLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadCustomLanguages();
  }

  Future<void> _loadCustomLanguages() async {
    final settings = await ref.read(databaseServiceProvider).getSettings();
    if (mounted) {
      setState(() {
        _allLanguages = [
          ...LanguageUtils.defaultLanguages,
          ...settings.customLanguages,
        ].toSet().toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      controller: widget.controller,
      label: Text(widget.label),
      enableFilter: true,
      dropdownMenuEntries: _allLanguages.map((lang) {
        return DropdownMenuEntry<String>(
          value: lang,
          label: lang,
        );
      }).toList(),
      onSelected: (val) {
        if (val != null) {
          widget.controller.text = val;
        }
      },
    );
  }
}
