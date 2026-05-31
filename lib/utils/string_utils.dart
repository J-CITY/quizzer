import 'dart:math';

/// Calculates the Levenshtein distance between two strings.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  List<int> v0 = List.filled(b.length + 1, 0);
  List<int> v1 = List.filled(b.length + 1, 0);

  for (int i = 0; i <= b.length; i++) {
    v0[i] = i;
  }

  for (int i = 0; i < a.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < b.length; j++) {
      int cost = (a[i] == b[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    for (int j = 0; j <= b.length; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[b.length];
}

/// Spoils a given word by replacing 1 or 2 characters with visually similar ones
/// using the provided confusableMap.
/// Returns null if the word cannot be spoiled (e.g. no replaceable characters found).
String? spoilWord(String word, Map<String, List<String>> confusableMap) {
  if (word.isEmpty) return null;

  final random = Random();
  final chars = word.runes.map((r) => String.fromCharCode(r)).toList();
  
  // Find indices of characters that can be replaced
  List<int> replaceableIndices = [];
  for (int i = 0; i < chars.length; i++) {
    if (confusableMap.containsKey(chars[i]) && confusableMap[chars[i]]!.isNotEmpty) {
      replaceableIndices.add(i);
    }
  }

  if (replaceableIndices.isEmpty) return null;

  // Determine how many characters to replace (1 or 2, up to max replaceable)
  int numToReplace = min(replaceableIndices.length, random.nextBool() ? 1 : 2);
  
  // Shuffle to pick random indices to replace
  replaceableIndices.shuffle(random);
  
  List<String> spoiledChars = List.from(chars);
  for (int i = 0; i < numToReplace; i++) {
    int idx = replaceableIndices[i];
    String originalChar = chars[idx];
    List<String> options = confusableMap[originalChar]!;
    String spoiledChar = options[random.nextInt(options.length)];
    spoiledChars[idx] = spoiledChar;
  }

  final result = spoiledChars.join('');
  if (result == word) return null; // Just in case
  
  return result;
}
