import '../services/dictionary_service.dart';

class SmartMixProcessor {
  // Telugu script phonetics mapped to their correct English spellings
  static const Map<String, String> _teluguToEnglish = {
    // Education / Institution
    'కాలేజీ': 'college',
    'కలేజీ': 'college',
    'కాలేజ్': 'college',
    'కలేజ్': 'college',
    'స్కూల్': 'school',
    'స్కూలు': 'school',
    'ఆఫీస్': 'office',
    'ఆఫీసు': 'office',
    'క్లాస్': 'class',
    'క్లాసు': 'class',
    'బుక్': 'book',
    'బుక్కు': 'book',
    'పెన్': 'pen',
    'పెన్ను': 'pen',
    'పేపర్': 'paper',
    'పేపరు': 'paper',
    'లైబ్రరీ': 'library',
    'ఎగ్జామ్': 'exam',
    'ఎగ్జాము': 'exam',

    // Transport / Motion
    'బస్సు': 'bus',
    'బస్': 'bus',
    'ట్రైన్': 'train',
    'ట్రైను': 'train',
    'రోడ్డు': 'road',
    'రోడ్': 'road',
    'కారు': 'car',
    'కార్': 'car',
    'బైక్': 'bike',
    'బైకు': 'bike',
    'టికెట్': 'ticket',
    'టికెట్టు': 'ticket',
    'టిక్కెట్': 'ticket',
    'టిక్కెట్టు': 'ticket',
    'స్టేషన్': 'station',
    'స్టేషను': 'station',
    'మెట్రో': 'metro',
    'ఫ్లైట్': 'flight',
    'ఫ్లైటు': 'flight',
    'ఏరోప్లేన్': 'aeroplane',

    // Communication / Tech
    'ఫోన్': 'phone',
    'ఫోను': 'phone',
    'మొబైల్': 'mobile',
    'కంప్యూటర్': 'computer',
    'కంప్యూటరు': 'computer',
    'లాప్టాప్': 'laptop',
    'లాప్టాపు': 'laptop',
    'ఇంటర్నెట్': 'internet',
    'నెట్': 'net',
    'నెట్టు': 'net',
    'మెసేజ్': 'message',
    'మెసేజు': 'message',
    'కాల్': 'call',
    'కాలు': 'call',
    'వీడియో': 'video',
    'ఆడియో': 'audio',
    'ఫోటో': 'photo',
    'ఫొటో': 'photo',
    'పాస్వర్డ్': 'password',
    'పాస్వర్డు': 'password',
    'యూజర్': 'user',
    'లింక్': 'link',
    'లింకు': 'link',
    'యాప్': 'app',
    'యాపు': 'app',
    'వెబ్సైట్': 'website',
    'మెయిల్': 'mail',
    'ఈమెయిల్': 'email',

    // Common places / Business
    'హాస్పిటల్': 'hospital',
    'హాస్పిటలు': 'hospital',
    'డాక్టర్': 'doctor',
    'డాక్టరు': 'doctor',
    'బ్యాంక్': 'bank',
    'బ్యాంకు': 'bank',
    'హోటల్': 'hotel',
    'హోటలు': 'hotel',
    'రెస్టారెంట్': 'restaurant',
    'రూమ్': 'room',
    'రూము': 'room',
    'షాప్': 'shop',
    'షాపు': 'shop',
    'మార్కెట్': 'market',
    'మార్కెట్టు': 'market',
    'థియేటర్': 'theater',
    'థియేటరు': 'theater',
    'పోలీస్': 'police',
    'పోలీసు': 'police',
    'కోర్ట్': 'court',
    'కోర్టు': 'court',

    // Everyday Objects
    'టేబుల్': 'table',
    'టేబులు': 'table',
    'చైర్': 'chair',
    'చైరు': 'chair',
    'సోప్': 'soap',
    'సోపు': 'soap',
    'లైట్': 'light',
    'లైటు': 'light',
    'ఫ్యాన్': 'fan',
    'గ్లాస్': 'glass',
    'గ్లాసు': 'glass',
    'వాటర్': 'water',
    'వాటరు': 'water',
    'కీ': 'key',
    'డోర్': 'door',
    'డోరు': 'door',
    'గేట్': 'gate',
    'గేటు': 'gate',
    'బ్యాటరీ': 'battery',
    'ఛార్జ్': 'charge',
    'ఛార్జర్': 'charger',
    'ఛార్జరు': 'charger',
    'టీవీ': 'tv',
    'టెలివిజన్': 'television',
    'స్విచ్': 'switch',
    'స్విచ్చు': 'switch',
    'బల్బ్': 'bulb',
    'బల్బు': 'bulb',

    // Expressions / Status
    'సూపర్': 'super',
    'గ్రేట్': 'great',
    'కరెక్ట్': 'correct',
    'రాంగ్': 'wrong',
    'హ్యాపీ': 'happy',
    'శాడ్': 'sad',
    'టెన్షన్': 'tension',
    'ప్రాబ్లమ్': 'problem',
    'ప్రాబ్లము': 'problem',
    'డౌట్': 'doubt',
    'డౌటు': 'doubt',
    'హెల్ప్': 'help',
    'సారీ': 'sorry',
    'ప్లీజ్': 'please',
    'థాంక్స్': 'thanks',
    'థాంక్యూ': 'thank you',
    'ఓకే': 'ok',
    'ఒకే': 'ok',
    'హలో': 'hello',
    'హాయ్': 'hi',
    'బై': 'bye',
    'గుడ్': 'good',
    'మార్నింగ్': 'morning',
    'నైట్': 'night',
    'లంచ్': 'lunch',
    'డిన్నర్': 'dinner',
    'బిజీ': 'busy',
    'ఫ్రీ': 'free',
    'టైమ్': 'time',
    'టైం': 'time',
    'టైము': 'time',
    'మనీ': 'money',
    'లవ్': 'love',

    // Verbs / Actions
    'కాపీ': 'copy',
    'పేస్ట్': 'paste',
    'ఎడిట్': 'edit',
    'డిలీట్': 'delete',
    'సేవ్': 'save',
    'షేర్': 'share',
    'సెండ్': 'send',
    'ఓపెన్': 'open',
    'క్లోజ్': 'close',
    'స్టార్ట్': 'start',
    'స్టాప్': 'stop',
    'స్టాపు': 'stop',
    'ప్లే': 'play',
    'పాజ్': 'pause',
    'నెక్స్ట్': 'next',
    'బ్యాక్': 'back',
    'సెర్చ్': 'search',
    'క్లిక్': 'click',
    'క్లిక్కు': 'click',
    'సెలెక్ట్': 'select',
    'డౌన్లోడ్': 'download',
    'అప్లోడ్': 'upload',
  };

  // Latin script phonetic variations mapped to their correct English spellings
  static const Map<String, String> _latinToEnglish = {
    'kalajee': 'college',
    'kalejee': 'college',
    'kaaleejee': 'college',
    'kaalejee': 'college',
    'colage': 'college',
    'clg': 'college',
    'schoolu': 'school',
    'school': 'school',
    'officeu': 'office',
    'office': 'office',
    'hospitalu': 'hospital',
    'hospital': 'hospital',
    'doctoru': 'doctor',
    'doctor': 'doctor',
    'policeu': 'police',
    'police': 'police',
    'busu': 'bus',
    'bussu': 'bus',
    'bus': 'bus',
    'trainu': 'train',
    'train': 'train',
    'roadu': 'road',
    'road': 'road',
    'caru': 'car',
    'car': 'car',
    'bikeu': 'bike',
    'bike': 'bike',
    'ticketu': 'ticket',
    'tickettu': 'ticket',
    'ticket': 'ticket',
    'phoneu': 'phone',
    'phone': 'phone',
    'mobileu': 'mobile',
    'mobile': 'mobile',
    'computeru': 'computer',
    'computer': 'computer',
    'banku': 'bank',
    'bank': 'bank',
    'classu': 'class',
    'class': 'class',
    'booku': 'book',
    'book': 'book',
    'penu': 'pen',
    'pennu': 'pen',
    'pen': 'pen',
    'paperu': 'paper',
    'paper': 'paper',
    'lightu': 'light',
    'light': 'light',
    'fanu': 'fan',
    'fan': 'fan',
    'glassu': 'glass',
    'glass': 'glass',
    'wateru': 'water',
    'water': 'water',
    'hotelu': 'hotel',
    'hotel': 'hotel',
    'roomu': 'room',
    'room': 'room',
    'keyu': 'key',
    'key': 'key',
    'dooru': 'door',
    'door': 'door',
    'gateu': 'gate',
    'gate': 'gate',
    'batteryu': 'battery',
    'battery': 'battery',
    'chargeu': 'charge',
    'chargeru': 'charger',
    'charge': 'charge',
    'charger': 'charger',
    'photo': 'photo',
    'video': 'video',
    'messageu': 'message',
    'message': 'message',
    'callu': 'call',
    'call': 'call',
    'netu': 'net',
    'net': 'net',
    'internetu': 'internet',
    'internet': 'internet',
    'movie': 'movie',
    'marketu': 'market',
    'market': 'market',
    'super': 'super',
    'great': 'great',
    'correct': 'correct',
    'wrong': 'wrong',
    'happy': 'happy',
    'table': 'table',
    'chair': 'chair',
    'soap': 'soap',
    'shop': 'shop',
    'current': 'current',
    'switch': 'switch',
    'post': 'post',
    'mail': 'mail',
    'password': 'password',
    'user': 'user',
    'card': 'card',
    'number': 'number',
    'address': 'address',
    'map': 'map',
    'search': 'search',
    'click': 'click',
    'copy': 'copy',
    'paste': 'paste',
    'edit': 'edit',
    'delete': 'delete',
    'save': 'save',
    'share': 'share',
    'send': 'send',
    'open': 'open',
    'close': 'close',
    'start': 'start',
    'stop': 'stop',
    'play': 'play',
    'pause': 'pause',
    'next': 'next',
    'back': 'back',
    'ok': 'ok',
    'okay': 'ok',
    'hello': 'hello',
    'hi': 'hi',
    'thanks': 'thanks',
    'sorry': 'sorry',
    'please': 'please',
    'bye': 'bye',
  };

  // List of common Telugu suffixes in Telugu script
  static const Set<String> _teluguSuffixes = {
    '', 'కి', 'కు', 'లో', 'ల్లో', 'ట్లో', 'తో', 'తోనే', 'నుంచి', 'నుండి',
    'పై', 'గా', 'ల', 'లు', 'ను', 'ని', 'నే', 'యొక్క', 'కూడా', 'యే'
  };

  // List of common Telugu suffixes in Latin script
  static const Set<String> _latinSuffixes = {
    '', 'ki', 'ku', 'lo', 'llo', 'tlo', 'to', 'tone', 'nunchi', 'nundi',
    'pai', 'ga', 'la', 'lu', 'nu', 'ni', 'ne', 'yokka', 'kooda', 'ye'
  };

  // Cached sorted keys for quick prefix matching
  static final List<String> _sortedTeluguKeys = _teluguToEnglish.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  static final List<String> _sortedLatinKeys = _latinToEnglish.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  /// Process input sentence to convert Telugu-script and Latin-script phonetics 
  /// of common English words into their correct English spellings.
  static String process(String sentence) {
    if (sentence.isEmpty) return sentence;

    // Load custom maps from DictionaryService
    final customTelugu = DictionaryService.instance.customTeluguToEnglish;
    final customLatin = DictionaryService.instance.customLatinToEnglish;

    // Sort custom keys by length descending to match longest prefix first
    final sortedCustomTeluguKeys = customTelugu.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final sortedCustomLatinKeys = customLatin.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // Matches contiguous blocks of Telugu or Latin characters (including numbers, ZWNJ/ZWJ)
    final wordRegex = RegExp(r'([a-zA-Z\u0C00-\u0C7F\u200c\u200d]+)');

    return sentence.replaceAllMapped(wordRegex, (match) {
      final word = match.group(0)!;
      final lowercaseWord = word.toLowerCase();

      // 1. Try matching Latin script words (e.g. "kalajee", "kalajeeki")
      if (RegExp(r'^[a-zA-Z]+$').hasMatch(word)) {
        // A. Check custom Latin map first
        for (final key in sortedCustomLatinKeys) {
          if (lowercaseWord.startsWith(key)) {
            final suffix = lowercaseWord.substring(key.length);
            if (_latinSuffixes.contains(suffix)) {
              final replacement = customLatin[key]!;
              if (word[0] == word[0].toUpperCase()) {
                final capitalized = replacement[0].toUpperCase() + replacement.substring(1);
                return capitalized + word.substring(key.length);
              }
              return replacement + word.substring(key.length);
            }
          }
        }

        // B. Check built-in Latin map
        for (final key in _sortedLatinKeys) {
          if (lowercaseWord.startsWith(key)) {
            final suffix = lowercaseWord.substring(key.length);
            if (_latinSuffixes.contains(suffix)) {
              final replacement = _latinToEnglish[key]!;
              // Attempt to preserve title case if the original was capitalized
              if (word[0] == word[0].toUpperCase()) {
                final capitalized = replacement[0].toUpperCase() + replacement.substring(1);
                return capitalized + word.substring(key.length);
              }
              return replacement + word.substring(key.length);
            }
          }
        }
      }

      // 2. Try matching Telugu script words (e.g. "కాలేజీ", "కాలేజీకి")
      // A. Check custom Telugu map first
      for (final key in sortedCustomTeluguKeys) {
        if (word.startsWith(key)) {
          final suffix = word.substring(key.length);
          if (_teluguSuffixes.contains(suffix)) {
            final replacement = customTelugu[key]!;
            return replacement + suffix;
          }
        }
      }

      // B. Check built-in Telugu map
      for (final key in _sortedTeluguKeys) {
        if (word.startsWith(key)) {
          final suffix = word.substring(key.length);
          if (_teluguSuffixes.contains(suffix)) {
            final replacement = _teluguToEnglish[key]!;
            return replacement + suffix;
          }
        }
      }

      // If no smart mix matches, return word unchanged
      return word;
    });
  }
}
