import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';

final googleSheetsServiceProvider = Provider<GoogleSheetsService>((ref) {
  return GoogleSheetsService();
});

class GoogleSheetsService {
  static Future<String?> fetchSheetName(String sheetId) async {
    try {
      final url = Uri.parse(
        'https://docs.google.com/spreadsheets/d/$sheetId/htmlview',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final regex = RegExp(r'<title>(.*?)</title>');
        final match = regex.firstMatch(response.body);
        if (match != null) {
          String title = match.group(1) ?? '';
          final googleIndex = title.indexOf(' - Google ');
          if (googleIndex != -1) {
            title = title.substring(0, googleIndex);
          }
          title = title.trim();
          if (title.isEmpty) {
            return 'Google Sheet';
          }
          return title;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Word>> fetchWords(String sheetId) async {
    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$sheetId/export?format=csv',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Decode with UTF-8 to handle Japanese and Russian characters properly
      final csvString = response.body;
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvString,
      );

      List<Word> words = [];

      // Determine if the first row is a header
      int startIdx = 0;
      if (rows.isNotEmpty && int.tryParse(rows[0][0].toString()) == null) {
        startIdx = 1;
      }

      for (int i = startIdx; i < rows.length; i++) {
        final row = rows[i];

        // We need at least ID, Japanese, and Translation (3 columns minimum)
        if (row.length < 3) continue;

        try {
          final word = Word()
            ..sheetId = int.parse(row[0].toString().trim())
            ..japanese = row[1].toString().trim();

          if (row.length == 3) {
            // Case where Hiragana column is completely omitted
            word.translation = row[2].toString().trim();
            word.reading = null;
          } else {
            // Normal case: ID, Japanese, Reading, Translation
            final readingStr = row[2].toString().trim();
            word.reading = readingStr.isEmpty ? null : readingStr;
            word.translation = row[3].toString().trim();
          }

          words.add(word);
        } catch (e) {
          // Skip rows that have unparseable ID or other errors
          continue;
        }
      }
      return words;
    } else {
      throw Exception(
        'Failed to load words. Status code: ${response.statusCode}',
      );
    }
  }
}
