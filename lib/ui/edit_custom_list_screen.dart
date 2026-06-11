import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/custom_list.dart';
import '../data/services/database_service.dart';
import '../data/services/google_sheets_service.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_tile.dart';
import 'widgets/modern_text_field.dart';

class EditCustomListScreen extends ConsumerStatefulWidget {
  final CustomList? customList; // If null, we are creating a new list
  final bool isLocalOnly;

  const EditCustomListScreen({
    super.key,
    this.customList,
    this.isLocalOnly = false,
  });

  @override
  ConsumerState<EditCustomListScreen> createState() =>
      _EditCustomListScreenState();
}

class _EditCustomListScreenState extends ConsumerState<EditCustomListScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emojiController;
  late TextEditingController _sheetIdController;
  late TextEditingController _sheetTabNameController;
  String _language = 'ja-JP';
  bool _syncOnStartup = false;
  bool _isSaving = false;

  bool _useCustomQuestionSettings = false;
  bool _questionWordToTranslate = true;
  bool _questionTranslateToWord = true;
  bool _questionWordToReading = true;
  bool _questionReadingToWord = true;
  bool _questionVoiceToTranslate = true;
  bool _questionVoiceToWord = true;
  bool _questionVoiceToWordInput = true;
  bool _questionVoiceToWordConstructor = true;
  bool _questionTranslateToWordInput = true;
  bool _questionTranslateToWordConstructor = true;
  bool _questionImageToWord = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.customList?.name ?? '',
    );
    _emojiController = TextEditingController(
      text: widget.customList?.emoji ?? '',
    );
    _sheetIdController = TextEditingController(
      text: widget.customList?.googleSheetId ?? '',
    );
    _sheetTabNameController = TextEditingController(
      text: widget.customList?.googleSheetTabName ?? '',
    );
    _language = widget.customList?.language ?? 'ja-JP';
    _syncOnStartup = widget.customList?.syncOnStartup ?? false;
    _useCustomQuestionSettings = widget.customList?.useCustomQuestionSettings ?? false;
    _questionWordToTranslate = widget.customList?.questionWordToTranslate ?? true;
    _questionTranslateToWord = widget.customList?.questionTranslateToWord ?? true;
    _questionWordToReading = widget.customList?.questionWordToReading ?? true;
    _questionReadingToWord = widget.customList?.questionReadingToWord ?? true;
    _questionVoiceToTranslate = widget.customList?.questionVoiceToTranslate ?? true;
    _questionVoiceToWord = widget.customList?.questionVoiceToWord ?? true;
    _questionVoiceToWordInput = widget.customList?.questionVoiceToWordInput ?? true;
    _questionVoiceToWordConstructor = widget.customList?.questionVoiceToWordConstructor ?? true;
    _questionTranslateToWordInput = widget.customList?.questionTranslateToWordInput ?? true;
    _questionTranslateToWordConstructor = widget.customList?.questionTranslateToWordConstructor ?? true;
    _questionImageToWord = widget.customList?.questionImageToWord ?? true;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    String name = _nameController.text.trim();
    final sheetId = _sheetIdController.text.trim();
    final sheetTabName = _sheetTabNameController.text.trim();

    if (name.isEmpty) {
      if (sheetId.isNotEmpty) {
        final result = await GoogleSheetsService.fetchSheetNameAndLanguage(sheetId);
        if (result != null && result.containsKey('name') && result['name']!.isNotEmpty) {
          name = result['name']!;
          _nameController.text = name;
          if (result.containsKey('language') && result['language']!.isNotEmpty) {
            _language = result['language']!;
          }
        } else {
          name = sheetId;
          _nameController.text = name;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorEmptyListName),
            ),
          );
          setState(() => _isSaving = false);
        }
        return;
      }
    }

    final db = ref.read(databaseServiceProvider);
    final list = widget.customList ?? CustomList();
    list.name = name;
    list.emoji = _emojiController.text.trim().isNotEmpty ? _emojiController.text.trim() : null;
    list.language = _language;

    if (sheetId.isNotEmpty) {
      list.googleSheetId = sheetId;
      list.googleSheetTabName = sheetTabName.isEmpty ? null : sheetTabName;
      list.syncOnStartup = _syncOnStartup;
    } else {
      list.googleSheetId = null;
      list.googleSheetTabName = null;
      list.syncOnStartup = false;
    }

    list.useCustomQuestionSettings = _useCustomQuestionSettings;
    list.questionWordToTranslate = _questionWordToTranslate;
    list.questionTranslateToWord = _questionTranslateToWord;
    list.questionWordToReading = _questionWordToReading;
    list.questionReadingToWord = _questionReadingToWord;
    list.questionVoiceToTranslate = _questionVoiceToTranslate;
    list.questionVoiceToWord = _questionVoiceToWord;
    list.questionVoiceToWordInput = _questionVoiceToWordInput;
    list.questionVoiceToWordConstructor = _questionVoiceToWordConstructor;
    list.questionTranslateToWordInput = _questionTranslateToWordInput;
    list.questionTranslateToWordConstructor = _questionTranslateToWordConstructor;
    list.questionImageToWord = _questionImageToWord;

    await db.saveCustomList(list);

    if (sheetId.isNotEmpty) {
      bool shouldSync = widget.customList == null ||
          widget.customList!.googleSheetId != sheetId ||
          widget.customList!.googleSheetTabName != (sheetTabName.isEmpty ? null : sheetTabName);

      if (shouldSync) {
        try {
          final words = await GoogleSheetsService.fetchWords(sheetId, sheetName: list.googleSheetTabName);
          await db.syncWordsForList(list, words);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.errorNetwork)),
            );
          }
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customList == null
              ? AppLocalizations.of(context)!.newListTitle
              : AppLocalizations.of(context)!.editListTitle,
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsGroup(
              title: AppLocalizations.of(context)!.listGroupMainInfo,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: ModernTextField(
                          controller: _emojiController,
                          labelText: 'Emoji',
                          maxLength: 1,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ModernTextField(
                          controller: _nameController,
                          labelText: AppLocalizations.of(context)!.listNameLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SettingsTile(
                  title: AppLocalizations.of(context)!.dictionaryLanguage,
                  showDivider: false,
                  trailing: DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'ja-JP', child: Text(AppLocalizations.of(context)!.langJapanese)),
                      DropdownMenuItem(value: 'en-US', child: Text(AppLocalizations.of(context)!.langEnglish)),
                      DropdownMenuItem(value: 'es-ES', child: Text(AppLocalizations.of(context)!.langSpanish)),
                      DropdownMenuItem(value: 'ru-RU', child: Text(AppLocalizations.of(context)!.langRussian)),
                      DropdownMenuItem(value: 'de-DE', child: Text(AppLocalizations.of(context)!.langGerman)),
                      DropdownMenuItem(value: 'fr-FR', child: Text(AppLocalizations.of(context)!.langFrench)),
                      DropdownMenuItem(value: 'it-IT', child: Text(AppLocalizations.of(context)!.langItalian)),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _language = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (!widget.isLocalOnly) ...[
              const SizedBox(height: 16),
              SettingsGroup(
                title: AppLocalizations.of(context)!.listGroupSync,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ModernTextField(
                                controller: _sheetIdController,
                                labelText: AppLocalizations.of(context)!.settingsSheetId,
                                hintText: AppLocalizations.of(context)!.settingsSheetIdHint,
                                onChanged: (val) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.sheetFormatHintTitle),
                                    content: Text(AppLocalizations.of(context)!.sheetFormatHintDesc),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      ModernTextField(
                        controller: _sheetTabNameController,
                        labelText: AppLocalizations.of(context)!.listNameOptional,
                        hintText: AppLocalizations.of(context)!.exampleSheetName,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SettingsTile(
                  title: AppLocalizations.of(context)!.syncOnStartup,
                  showDivider: false,
                  trailing: Switch(
                    value: _syncOnStartup,
                    onChanged: _sheetIdController.text.trim().isNotEmpty
                        ? (val) {
                            setState(() {
                              _syncOnStartup = val;
                            });
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
            SettingsGroup(
              title: AppLocalizations.of(context)!.listGroupQuestions,
              children: [
                SettingsTile(
                  title: AppLocalizations.of(context)!.overrideQuestionSettings,
                  showDivider: _useCustomQuestionSettings,
                  trailing: Switch(
                    value: _useCustomQuestionSettings,
                    onChanged: (val) {
                      setState(() => _useCustomQuestionSettings = val);
                    },
                  ),
                ),
                if (_useCustomQuestionSettings) ...[
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionWordToTranslate),
                    value: _questionWordToTranslate,
                    onChanged: (val) => setState(() => _questionWordToTranslate = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionTranslateToWord),
                    value: _questionTranslateToWord,
                    onChanged: (val) => setState(() => _questionTranslateToWord = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionWordToReading),
                    value: _questionWordToReading,
                    onChanged: (val) => setState(() => _questionWordToReading = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionReadingToWord),
                    value: _questionReadingToWord,
                    onChanged: (val) => setState(() => _questionReadingToWord = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionVoiceToTranslate),
                    value: _questionVoiceToTranslate,
                    onChanged: (val) => setState(() => _questionVoiceToTranslate = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionVoiceToWord),
                    value: _questionVoiceToWord,
                    onChanged: (val) => setState(() => _questionVoiceToWord = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionVoiceToWordInput),
                    value: _questionVoiceToWordInput,
                    onChanged: (val) => setState(() => _questionVoiceToWordInput = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionVoiceToWordConstructor),
                    value: _questionVoiceToWordConstructor,
                    onChanged: (val) => setState(() => _questionVoiceToWordConstructor = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionTranslateToWordInput),
                    value: _questionTranslateToWordInput,
                    onChanged: (val) => setState(() => _questionTranslateToWordInput = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionTranslateToWordConstructor),
                    value: _questionTranslateToWordConstructor,
                    onChanged: (val) => setState(() => _questionTranslateToWordConstructor = val ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.questionImageToWord),
                    value: _questionImageToWord,
                    onChanged: (val) => setState(() => _questionImageToWord = val ?? true),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        setState(() => _useCustomQuestionSettings = false);
                      },
                      child: Text(AppLocalizations.of(context)!.resetToGeneralSettings),
                    ),
                  ),
                  const SizedBox(height: 8),
                ]
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
