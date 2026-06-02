import 'package:flutter/material.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/custom_list.dart';
import '../data/services/database_service.dart';
import '../data/services/google_sheets_service.dart';

class EditCustomListScreen extends ConsumerStatefulWidget {
  final CustomList? customList; // If null, we are creating a new list

  const EditCustomListScreen({super.key, this.customList});

  @override
  ConsumerState<EditCustomListScreen> createState() =>
      _EditCustomListScreenState();
}

class _EditCustomListScreenState extends ConsumerState<EditCustomListScreen> {
  late TextEditingController _nameController;
  late TextEditingController _sheetIdController;
  late TextEditingController _sheetTabNameController;
  String _language = 'ja-JP';
  bool _syncOnStartup = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.customList?.name ?? '',
    );
    _sheetIdController = TextEditingController(
      text: widget.customList?.googleSheetId ?? '',
    );
    _sheetTabNameController = TextEditingController(
      text: widget.customList?.googleSheetTabName ?? '',
    );
    _language = widget.customList?.language ?? 'ja-JP';
    _syncOnStartup = widget.customList?.syncOnStartup ?? false;
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

    await db.saveCustomList(list);

    if (sheetId.isNotEmpty) {
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
            IconButton(icon: Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.listNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sheetIdController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.settingsSheetId,
                hintText: AppLocalizations.of(context)!.settingsSheetIdHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sheetTabNameController,
              decoration: const InputDecoration(
                labelText: 'Имя листа (опционально)',
                hintText: 'Например: Sheet1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: InputDecoration(
                labelText: 'Язык словаря (озвучка)',
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'ja-JP', child: Text('Японский (ja-JP)')),
                DropdownMenuItem(value: 'en-US', child: Text('Английский (en-US)')),
                DropdownMenuItem(value: 'es-ES', child: Text('Испанский (es-ES)')),
                DropdownMenuItem(value: 'ru-RU', child: Text('Русский (ru-RU)')),
                DropdownMenuItem(value: 'de-DE', child: Text('Немецкий (de-DE)')),
                DropdownMenuItem(value: 'fr-FR', child: Text('Французский (fr-FR)')),
                DropdownMenuItem(value: 'it-IT', child: Text('Итальянский (it-IT)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _language = val);
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.syncOnStartup),
              value: _syncOnStartup,
              onChanged: _sheetIdController.text.trim().isNotEmpty
                  ? (val) {
                      setState(() {
                        _syncOnStartup = val;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
