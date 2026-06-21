import 'package:flutter_test/flutter_test.dart';
import 'package:viocebubble/utils/smart_mix_processor.dart';
import 'package:viocebubble/services/dictionary_service.dart';

void main() {
  group('SmartMixProcessor Tests', () {
    test('Empty sentence returns empty', () {
      expect(SmartMixProcessor.process(''), equals(''));
    });

    test('Non-matching Telugu text remains unchanged', () {
      final input = 'నేను రేపు వస్తాను';
      expect(SmartMixProcessor.process(input), equals(input));
    });

    test('Exact match Telugu phonetic words', () {
      expect(SmartMixProcessor.process('కాలేజీ'), equals('college'));
      expect(SmartMixProcessor.process('స్కూల్'), equals('school'));
      expect(SmartMixProcessor.process('ఆఫీస్'), equals('office'));
    });

    test('Prefix match with Telugu suffixes', () {
      expect(SmartMixProcessor.process('కాలేజీకి'), equals('collegeకి'));
      expect(SmartMixProcessor.process('ఆఫీసులో'), equals('officeలో'));
      expect(SmartMixProcessor.process('బస్సుతో'), equals('busతో'));
      expect(SmartMixProcessor.process('హాస్పిటల్లో'), equals('hospitalలో'));
    });

    test('Should not match incorrect prefixes (no false positives)', () {
      // "కార్యం" starts with "కార్" (car). It should NOT be converted to "carయం" because "యం" is not a suffix.
      expect(SmartMixProcessor.process('కార్యం'), equals('కార్యం'));
    });

    test('Exact match Latin phonetic words', () {
      expect(SmartMixProcessor.process('kalajee'), equals('college'));
      expect(SmartMixProcessor.process('kalejee'), equals('college'));
      expect(SmartMixProcessor.process('schoolu'), equals('school'));
      expect(SmartMixProcessor.process('officeu'), equals('office'));
    });

    test('Prefix match Latin words with suffixes', () {
      expect(SmartMixProcessor.process('kalajeeki'), equals('collegeki'));
      expect(SmartMixProcessor.process('officelo'), equals('officelo'));
      expect(SmartMixProcessor.process('bussuto'), equals('busto')); // "bussu" + "to"
    });

    test('Preserve casing for Latin phonetic words', () {
      expect(SmartMixProcessor.process('Kalajee'), equals('College'));
      expect(SmartMixProcessor.process('Schoolu'), equals('School'));
    });

    test('Bilingual sentence processing', () {
      final input = 'నేను రేపు కాలేజీకి వెళ్తాను, ఆ తర్వాత ఆఫీసులో ఉంటాను.';
      final expected = 'నేను రేపు collegeకి వెళ్తాను, ఆ తర్వాత officeలో ఉంటాను.';
      expect(SmartMixProcessor.process(input), equals(expected));
    });

    test('Bilingual sentence with Latin phonetics', () {
      final input = 'Nenu repu kalajeeki veltanu, aa tarvata office lo untanu.';
      final expected = 'Nenu repu collegeki veltanu, aa tarvata office lo untanu.';
      expect(SmartMixProcessor.process(input), equals(expected));
    });

    test('Custom dictionary mappings add and resolve correctly', () async {
      final service = DictionaryService.instance;
      
      // Initialize dictionary
      await service.loadDictionary();

      // Add custom entries
      await service.addEntry('daddy', 'డాడీ');
      await service.addEntry('mummy', 'మమ్మీ');

      // Verify custom Telugu matches
      expect(SmartMixProcessor.process('డాడీ కి ఫోన్ చేయి'), equals('daddy కి phone చేయి')); // Note: 'ఫోన్' is mapped to 'phone' built-in
      expect(SmartMixProcessor.process('మమ్మీతో మాట్లాడాను'), equals('mummyతో మాట్లాడాను'));

      // Verify custom Latin matches
      expect(SmartMixProcessor.process('dadee'), equals('daddy'));
      expect(SmartMixProcessor.process('dadeeki'), equals('daddyki'));
      expect(SmartMixProcessor.process('nenu mammeeto matladanu'), equals('nenu mummyto matladanu'));

      // Clean up custom entries
      await service.removeEntry('daddy');
      await service.removeEntry('mummy');

      // Verify they no longer match
      expect(SmartMixProcessor.process('డాడీ'), equals('డాడీ'));
      expect(SmartMixProcessor.process('daadee'), equals('daadee'));
    });
  });
}
