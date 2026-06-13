import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quizzer/l10n/app_localizations.dart';
import '../data/models/word.dart';
import '../data/models/custom_list.dart';
import '../data/services/database_service.dart';
import 'widgets/glow_button.dart';

class EditWordScreen extends ConsumerStatefulWidget {
  final Word? word;
  final CustomList? initialList;
  final String? initialJapanese;
  final String? initialTranslation;
  final String? initialReading;

  const EditWordScreen({
    super.key,
    this.word,
    this.initialList,
    this.initialJapanese,
    this.initialTranslation,
    this.initialReading,
  });

  @override
  ConsumerState<EditWordScreen> createState() => _EditWordScreenState();
}

class _EditWordScreenState extends ConsumerState<EditWordScreen> {
  final _japaneseController = TextEditingController();
  final _readingController = TextEditingController();
  final _translationController = TextEditingController();
  final _mnemonicController = TextEditingController();
  final _imageController = TextEditingController();

  CustomList? _selectedList;
  List<CustomList> _availableLists = [];
  bool _isLoadingLists = true;

  @override
  void initState() {
    super.initState();
    if (widget.word != null) {
      _japaneseController.text = widget.word!.japanese;
      _readingController.text = widget.word!.reading ?? '';
      _translationController.text = widget.word!.translation;
      _mnemonicController.text = widget.word!.mnemonic ?? '';
      _imageController.text = widget.word!.imageUrl ?? '';
    } else {
      _japaneseController.text = widget.initialJapanese ?? '';
      _translationController.text = widget.initialTranslation ?? '';
      _readingController.text = widget.initialReading ?? '';
    }

    _loadLists();
  }

  Future<void> _loadLists() async {
    final db = ref.read(databaseServiceProvider);
    final lists = await db.getCustomLists();
    setState(() {
      _availableLists = lists.where((l) => l.googleSheetId == null || l.googleSheetId!.isEmpty).toList();
      if (widget.initialList != null) {
        _selectedList = lists.cast<CustomList?>().firstWhere(
            (l) => l?.id == widget.initialList!.id, orElse: () => null);
      }
      if (_selectedList == null && _availableLists.isNotEmpty && widget.word == null) {
        _selectedList = _availableLists.first;
      }
      _isLoadingLists = false;
    });
  }

  @override
  void dispose() {
    _japaneseController.dispose();
    _readingController.dispose();
    _translationController.dispose();
    _mnemonicController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromDevice() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final docDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${docDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create();
      }
      final extension = pickedFile.path.split('.').last;
      final newPath = '${imagesDir.path}/${const Uuid().v4()}.$extension';
      await File(pickedFile.path).copy(newPath);
      
      setState(() {
        _imageController.text = newPath;
      });
    }
  }

  Future<void> _searchImagesWeb() async {
    final query = _translationController.text.isNotEmpty ? _translationController.text : _japaneseController.text;
    if (query.isEmpty) return;

    final url = Uri.parse('https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(query)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch browser')));
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _imageController.text = data.text!;
      });
    }
  }

  Future<void> _saveWord() async {
    if (_japaneseController.text.trim().isEmpty || _translationController.text.trim().isEmpty) {
      return; // Basic validation
    }

    if (widget.word == null && _selectedList == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorNoListSelected)),
        );
      }
      return; // Need a list to save to
    }

    final db = ref.read(databaseServiceProvider);

    if (widget.word != null) {
      widget.word!.japanese = _japaneseController.text.trim();
      widget.word!.reading = _readingController.text.trim();
      widget.word!.translation = _translationController.text.trim();
      widget.word!.mnemonic = _mnemonicController.text.trim();
      widget.word!.imageUrl = _imageController.text.trim();
      
      await db.updateWord(widget.word!);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      final newWord = Word()
        ..sheetId = DateTime.now().millisecondsSinceEpoch // mock ID for local
        ..japanese = _japaneseController.text.trim()
        ..reading = _readingController.text.trim()
        ..translation = _translationController.text.trim()
        ..mnemonic = _mnemonicController.text.trim()
        ..imageUrl = _imageController.text.trim()
        ..orderIndex = _selectedList!.words.length;

      await db.isar.writeTxn(() async {
        await db.isar.words.put(newWord);
        _selectedList!.words.add(newWord);
        await _selectedList!.words.save();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.wordSaved)),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _createNewList() async {
    final nameController = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createLocalList),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.listNameLabel,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: Text(AppLocalizations.of(context)!.addBtn),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final db = ref.read(databaseServiceProvider);
      final newList = CustomList()
        ..name = newName
        ..language = 'ja-JP';
        
      await db.isar.writeTxn(() async {
        await db.isar.customLists.put(newList);
      });
      
      await _loadLists();
      setState(() {
        _selectedList = _availableLists.firstWhere((l) => l.id == newList.id, orElse: () => _availableLists.first);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.word == null 
            ? AppLocalizations.of(context)!.addWordTitle 
            : AppLocalizations.of(context)!.editWordTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.word == null && !_isLoadingLists) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _availableLists.isEmpty
                        ? Text(
                            AppLocalizations.of(context)!.noLocalLists,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16,
                            ),
                          )
                        : DropdownButtonFormField<CustomList>(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.selectListForWord,
                              border: const OutlineInputBorder(),
                            ),
                            value: _selectedList,
                            items: _availableLists.map((l) => DropdownMenuItem(
                              value: l,
                              child: Text(l.name),
                            )).toList(),
                            onChanged: (val) {
                              setState(() => _selectedList = val);
                            },
                          ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_circle, size: 36, color: Theme.of(context).colorScheme.primary),
                    onPressed: _createNewList,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _japaneseController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.wordOriginalHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _readingController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.wordReadingHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _translationController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.wordTranslationHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mnemonicController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.wordMnemonicHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _imageController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.wordImageHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: AppLocalizations.of(context)!.pasteFromClipboard,
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImageFromDevice,
                  icon: const Icon(Icons.image, size: 28),
                  label: Text(AppLocalizations.of(context)!.selectImageFromDevice, style: const TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _searchImagesWeb,
                  icon: const Icon(Icons.travel_explore, size: 28),
                  label: Text(AppLocalizations.of(context)!.searchImageWeb, style: const TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            GlowButton(
              onPressed: _saveWord,
              child: Text(AppLocalizations.of(context)!.saveWord),
            ),
          ],
        ),
      ),
    );
  }
}

