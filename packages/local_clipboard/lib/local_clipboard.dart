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

  /// Copies a list of file paths to the system clipboard as URIs.
  static Future<bool> copyFiles(List<String> filePaths) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('copyFiles', filePaths);
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Direct send to WhatsApp (or WhatsApp Business) for multiple image paths.
  static Future<bool> sendToWhatsApp(List<String> filePaths) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('sendToWhatsApp', filePaths);
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the accessibility service is active
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool? enabled = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return enabled ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens the system Accessibility settings screen
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } catch (e) {
      // Ignore
    }
  }

  /// Injects text directly into the focused input field using Accessibility Service
  static Future<bool> injectText(String text) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('injectText', text);
      return success ?? false;
    } catch (e) {
      return false;
    }
  }
}
