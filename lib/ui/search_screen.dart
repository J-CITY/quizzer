import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quizzer/l10n/app_localizations.dart';
import 'edit_word_screen.dart';
import 'package:quizzer/data/services/database_service.dart';
import 'package:quizzer/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/glow_button.dart';
import 'widgets/acrylic_card.dart';
import 'widgets/language_selector.dart';
import '../utils/language_utils.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _translator = GoogleTranslator();

  final _sourceController = TextEditingController();
  final _targetController = TextEditingController();

  String _sourceLanguage = 'ru-RU';
  String _targetLanguage = 'ja-JP';

  bool _isLoading = false;
  String? _translatedText;
  String? _reading;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguages();
  }

  Future<void> _loadSavedLanguages() async {
    final settings = await ref.read(databaseServiceProvider).getSettings();
    if (mounted) {
      setState(() {
        _sourceLanguage = settings.searchSourceLanguage;
        _targetLanguage = settings.searchTargetLanguage;
        _sourceController.text = _sourceLanguage;
        _targetController.text = _targetLanguage;
      });
    }
  }

  Future<void> _saveLanguages() async {
    final db = ref.read(databaseServiceProvider);
    final settings = await db.getSettings();
    settings.searchSourceLanguage = _sourceController.text.trim();
    settings.searchTargetLanguage = _targetController.text.trim();
    await db.saveSettings(settings);
  }

  Future<void> _translate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _translatedText = null;
      _reading = null;
    });

    final db = ref.read(databaseServiceProvider);
    final src = _sourceController.text.trim();
    final tgt = _targetController.text.trim();

    final isSrcValid = await LanguageUtils.validateAndSaveCustomLanguage(src, db);
    final isTgtValid = await LanguageUtils.validateAndSaveCustomLanguage(tgt, db);

    if (!isSrcValid || !isTgtValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorNetwork ?? 'Invalid or unsupported language!'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    _saveLanguages();

    try {
      final translation = await _translator.translate(
        text,
        from: src.split('-').first,
        to: tgt.split('-').first,
      );

      _translatedText = translation.text;

      // If translating TO Japanese, fetch reading
      if (tgt.split('-').first == 'ja') {
        _reading = await _fetchReading(_translatedText!);
      } else if (src.split('-').first == 'ja') {
        // If from Japanese, the original text might have reading
        _reading = await _fetchReading(text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _fetchReading(String word) async {
    try {
      final url = Uri.parse('https://jisho.org/api/v1/search/words?keyword=${Uri.encodeComponent(word)}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          final firstResult = data['data'][0];
          if (firstResult['japanese'] != null && firstResult['japanese'].isNotEmpty) {
            final japanese = firstResult['japanese'][0];
            return japanese['reading']; // Might be null if it's hiragana only
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceController.text;
      _sourceController.text = _targetController.text;
      _targetController.text = temp;
    });
    _saveLanguages();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: LanguageSelector(
                    label: '',
                    controller: _sourceController,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _swapLanguages,
                ),
                Expanded(
                  child: LanguageSelector(
                    label: '',
                    controller: _targetController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchWordHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _translatedText = null;
                      _reading = null;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _translate(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GlowButton(
                onPressed: _isLoading ? null : _translate,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppLocalizations.of(context)!.searchBtn),
              ),
            ),
            const SizedBox(height: 32),
            if (_translatedText != null)
              Expanded(
                child: SingleChildScrollView(
                  child: AcrylicCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _targetController.text.split('-').first == 'ja' ? _translatedText! : _controller.text.trim(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          if (_reading != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _reading!,
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            _targetController.text.split('-').first == 'ja' ? _controller.text.trim() : _translatedText!,
                            style: const TextStyle(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          GlowButton(
                            onPressed: () {
                              final isJaTarget = _targetController.text.split('-').first == 'ja';
                              final japText = isJaTarget ? _translatedText : _controller.text.trim();
                              final readingToPass = (_reading != null && _reading != japText) ? _reading : '';
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditWordScreen(
                                    initialJapanese: japText,
                                    initialTranslation: isJaTarget ? _controller.text.trim() : _translatedText,
                                    initialReading: readingToPass,
                                  ),
                                ),
                              );
                            },
                            child: Text(AppLocalizations.of(context)!.addWordTitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
