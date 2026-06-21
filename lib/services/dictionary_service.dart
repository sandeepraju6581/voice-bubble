import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/telugu_transliterator.dart';

class DictionaryEntry {
  final String englishWord;
  final String teluguWord;

  DictionaryEntry({required this.englishWord, required this.teluguWord});

  Map<String, dynamic> toJson() => {
    'englishWord': englishWord,
    'teluguWord': teluguWord,
  };

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      englishWord: json['englishWord'] ?? '',
      teluguWord: json['teluguWord'] ?? '',
    );
  }
}

class DictionaryService extends ChangeNotifier {
  DictionaryService._internal() {
    loadDictionary();
  }
  static final DictionaryService instance = DictionaryService._internal();

  List<DictionaryEntry> _entries = [];
  List<DictionaryEntry> get entries => _entries;

  final Map<String, String> customTeluguToEnglish = {};
  final Map<String, String> customLatinToEnglish = {};

  Future<File> get _file async {
    String? path;
    try {
      final docs = await getApplicationDocumentsDirectory();
      path = docs.path;
    } catch (e) {
      if (Platform.isAndroid) {
        path = '/data/user/0/com.example.viocebubble/app_flutter';
      } else {
        path = Directory.systemTemp.path;
      }
    }
    return File('$path/custom_dictionary.json');
  }

  Future<void> loadDictionary() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _entries = jsonList.map((e) => DictionaryEntry.fromJson(e)).toList();
      } else {
        _entries = [];
      }
      _rebuildMaps();
    } catch (e) {
      if (kDebugMode) print("Error loading dictionary: $e");
    }
  }

  void _rebuildMaps() {
    customTeluguToEnglish.clear();
    customLatinToEnglish.clear();

    for (final entry in _entries) {
      if (entry.englishWord.isEmpty || entry.teluguWord.isEmpty) continue;

      final eng = entry.englishWord.trim().toLowerCase();
      final tel = entry.teluguWord.trim();

      customTeluguToEnglish[tel] = eng;

      // Automatically generate the Latin transliterated phonetic version
      final latinPhonetic = TeluguTransliterator.transliterate(tel).toLowerCase();
      customLatinToEnglish[latinPhonetic] = eng;
      customLatinToEnglish[eng] = eng; // also map the English word to itself
    }
    notifyListeners();
  }

  Future<void> addEntry(String englishWord, String teluguWord) async {
    final cleanEnglish = englishWord.trim();
    final cleanTelugu = teluguWord.trim();
    if (cleanEnglish.isEmpty || cleanTelugu.isEmpty) return;

    // Remove existing if any (case-insensitive check)
    _entries.removeWhere((e) => e.englishWord.toLowerCase() == cleanEnglish.toLowerCase());

    _entries.add(DictionaryEntry(
      englishWord: cleanEnglish,
      teluguWord: cleanTelugu,
    ));

    await _save();
  }

  Future<void> removeEntry(String englishWord) async {
    _entries.removeWhere((e) => e.englishWord.toLowerCase() == englishWord.toLowerCase().trim());
    await _save();
  }

  Future<void> _save() async {
    try {
      final file = await _file;
      await file.writeAsString(jsonEncode(_entries.map((e) => e.toJson()).toList()));
      _rebuildMaps();
    } catch (e) {
      if (kDebugMode) print("Error saving dictionary: $e");
    }
  }
}
