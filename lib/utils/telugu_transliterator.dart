class TeluguTransliterator {
  static const Map<String, String> _vowels = {
    'అ': 'a',
    'ఆ': 'aa',
    'ఇ': 'i',
    'ఈ': 'ee',
    'ఉ': 'u',
    'ఊ': 'oo',
    'ఋ': 'ru',
    'ౠ': 'ruu',
    'ఎ': 'e',
    'ఏ': 'e',
    'ఐ': 'ai',
    'ఒ': 'o',
    'ఓ': 'o',
    'ఔ': 'au',
  };

  static const Map<String, String> _vowelSigns = {
    'ా': 'a',
    'ి': 'i',
    'ీ': 'ee',
    'ు': 'u',
    'ూ': 'oo',
    'ృ': 'ru',
    'ౄ': 'ruu',
    'ె': 'e',
    'ే': 'e',
    'ై': 'ai',
    'ొ': 'o',
    'ో': 'o',
    'ౌ': 'au',
  };

  static const Map<String, String> _consonants = {
    'క': 'k',
    'ఖ': 'kh',
    'గ': 'g',
    'ఘ': 'gh',
    'ఙ': 'ng',
    'చ': 'ch',
    'ఛ': 'chh',
    'జ': 'j',
    'ఝ': 'jh',
    'ఞ': 'ny',
    'ట': 't',
    'ఠ': 'th',
    'డ': 'd',
    'ఢ': 'dh',
    'ణ': 'n',
    'త': 't',
    'థ': 'th',
    'ద': 'd',
    'ధ': 'dh',
    'న': 'n',
    'ప': 'p',
    'ఫ': 'ph',
    'బ': 'b',
    'భ': 'bh',
    'మ': 'm',
    'య': 'y',
    'ర': 'r',
    'ల': 'l',
    'వ': 'v',
    'శ': 'sh',
    'ష': 'sh',
    'స': 's',
    'హ': 'h',
    'ళ': 'l',
    'ఱ': 'r',
  };

  static const Map<String, String> _modifiers = {
    'ం': 'm',
    'ః': 'ha',
    'ఁ': 'n',
  };

  /// Transliteates a Telugu script string to English phonetics (Latin script).
  /// Non-Telugu script characters are passed through unaltered.
  static String transliterate(String text) {
    if (text.isEmpty) return "";
    final runes = text.runes.toList();
    final buffer = StringBuffer();

    for (int i = 0; i < runes.length; i++) {
      final char = String.fromCharCode(runes[i]);

      if (_consonants.containsKey(char)) {
        final consonantMap = _consonants[char]!;
        
        // Look ahead to check for virama or dependent vowel signs
        if (i + 1 < runes.length) {
          final nextChar = String.fromCharCode(runes[i + 1]);
          if (nextChar == '్') {
            // Virama/Halant - suppresses inherent 'a' sound (e.g. conjunct start)
            buffer.write(consonantMap);
            i++; // consume virama
          } else if (_vowelSigns.containsKey(nextChar)) {
            // Vowel sign replaces the inherent 'a' sound
            buffer.write(consonantMap);
            buffer.write(_vowelSigns[nextChar]!);
            i++; // consume vowel sign
          } else {
            // No modifier/vowel sign following this consonant, append inherent 'a'
            buffer.write(consonantMap);
            buffer.write('a');
          }
        } else {
          // End of string, append consonant with inherent 'a'
          buffer.write(consonantMap);
          buffer.write('a');
        }
      } else if (_vowels.containsKey(char)) {
        buffer.write(_vowels[char]!);
      } else if (_modifiers.containsKey(char)) {
        buffer.write(_modifiers[char]!);
      } else if (char == '్') {
        // Standalone virama (should not happen normally) - skipped
      } else {
        // Non-Telugu characters are passed through as-is
        buffer.write(char);
      }
    }

    return buffer.toString();
  }
}
