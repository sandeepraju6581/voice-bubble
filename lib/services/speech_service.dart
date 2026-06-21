import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../utils/smart_mix_processor.dart';
import 'dictionary_service.dart';

class SpeechService {
  SpeechService._internal();
  static final SpeechService instance = SpeechService._internal();

  final SpeechToText _speech = SpeechToText();
  
  final ValueNotifier<bool> isAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<String> transcribedText = ValueNotifier<String>("");
  final ValueNotifier<String> status = ValueNotifier<String>("Idle");
  final ValueNotifier<double> soundLevel = ValueNotifier<double>(0.0);
  final ValueNotifier<String> currentLocale = ValueNotifier<String>("en_US");

  bool _isInitialized = false;

  Future<bool> checkPermissions() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> initialize() async {
    if (_isInitialized) return isAvailable.value;

    try {
      await DictionaryService.instance.loadDictionary();
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) {
          status.value = "Microphone Permission Denied";
          return false;
        }
      }

      bool available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: true,
      );

      isAvailable.value = available;
      _isInitialized = true;
      if (available) {
        status.value = "Ready";
      } else {
        status.value = "Speech Recognition Unavailable";
      }
      return available;
    } catch (e) {
      status.value = "Init Error: $e";
      isAvailable.value = false;
      return false;
    }
  }

  void _onStatus(String statusVal) {
    status.value = statusVal;
    if (statusVal == 'listening') {
      isListening.value = true;
    } else {
      isListening.value = false;
      soundLevel.value = 0.0;
    }
  }

  void _onError(SpeechRecognitionError error) {
    status.value = "Error: ${error.errorMsg}";
    isListening.value = false;
    soundLevel.value = 0.0;
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function(String status) onStatusChanged,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return;
    }

    if (isListening.value) return;

    transcribedText.value = "";
    status.value = "listening";
    isListening.value = true;

    final targetLocale = localeId ?? currentLocale.value;
    final isMixMode = targetLocale == "te_IN_mix";
    final recognizerLocale = isMixMode ? "te_IN" : targetLocale;

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          String processedText = result.recognizedWords;
          if (isMixMode) {
            processedText = SmartMixProcessor.process(processedText);
          }
          transcribedText.value = processedText;
          onResult(processedText);
          if (result.finalResult) {
            isListening.value = false;
            soundLevel.value = 0.0;
            status.value = "Done";
          }
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          localeId: recognizerLocale,
        ),
        onSoundLevelChange: (level) {
          // Normalize sound level for UI animations (usually ranges from -2 to 10+)
          // We map it to a scale of 0.0 to 1.0
          double normalized = (level + 2.0) / 12.0;
          if (normalized < 0.0) normalized = 0.0;
          if (normalized > 1.0) normalized = 1.0;
          soundLevel.value = normalized;
        },
      );
    } catch (e) {
      status.value = "Listen Error: $e";
      isListening.value = false;
      soundLevel.value = 0.0;
    }
  }

  Future<void> stopListening() async {
    if (!isListening.value) return;
    await _speech.stop();
    isListening.value = false;
    soundLevel.value = 0.0;
    status.value = "Stopped";
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
    isListening.value = false;
    soundLevel.value = 0.0;
    status.value = "Cancelled";
  }
}
