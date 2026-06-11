import 'package:flutter/services.dart';

class LocalClipboard {
  static const MethodChannel _channel = MethodChannel('com.example.viocebubble/clipboard');

  /// Copies [text] to the clipboard via the native Android transparent activity.
  static Future<bool> copy(String text) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('copy', text);
      return success ?? false;
    } catch (e) {
      return false;
    }
  }
}
