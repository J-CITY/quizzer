const Map<String, List<String>> defaultConfusableCharacters = {
  // English
  'i': ['e'],
  'e': ['i'],
  'o': ['a'],
  'a': ['o'],
  'c': ['k'],
  'k': ['c'],

  // Japanese - Hiragana & Katakana
  'あ': ['お'],
  'お': ['あ'],
  'い': ['り'],
  'り': ['い'],
  'さ': ['き', 'ち'],
  'き': ['さ', 'ち'],
  'ち': ['さ', 'き', 'ら'],
  'め': ['ぬ'],
  'ぬ': ['め'],
  'ね': ['れ', 'わ'],
  'れ': ['ね', 'わ'],
  'わ': ['ね', 'れ'],
  'は': ['ほ'],
  'ほ': ['は'],
  'ア': ['マ'],
  'マ': ['ア'],
  'シ': ['ツ'],
  'ツ': ['シ'],
  'ソ': ['ン'],
  'ン': ['ソ'],
  'ウ': ['ワ'],
  'ワ': ['ウ'],
  'ク': ['ケ'],
  'ケ': ['ク'],

  // Japanese - Kanji
  '大': ['犬', '太'],
  '犬': ['大', '太'],
  '太': ['大', '犬'],
  '日': ['曰', '目'],
  '曰': ['日', '目'],
  '目': ['日', '曰'],
  '人': ['入'],
  '入': ['人'],
  '木': ['本'],
  '本': ['木'],
  '王': ['玉'],
  '玉': ['王'],
};

/// Builds a complete map of confusable characters by merging the default map
/// with custom groups loaded from settings.
Map<String, List<String>> buildConfusableMap(List<String> customGroups) {
  final map = Map<String, List<String>>.from(defaultConfusableCharacters);

  for (final group in customGroups) {
    // If group is "さきち", chars are 'さ', 'き', 'ち'
    final chars = group.runes.map((r) => String.fromCharCode(r)).toList();

    for (int i = 0; i < chars.length; i++) {
      final current = chars[i];
      if (!map.containsKey(current)) {
        map[current] = [];
      }

      for (int j = 0; j < chars.length; j++) {
        if (i == j) continue;
        final other = chars[j];
        if (!map[current]!.contains(other)) {
          map[current]!.add(other);
        }
      }
    }
  }

  return map;
}
