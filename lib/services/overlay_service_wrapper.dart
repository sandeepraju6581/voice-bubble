import 'dart:async';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayServiceWrapper {
  OverlayServiceWrapper._internal();
  static final OverlayServiceWrapper instance = OverlayServiceWrapper._internal();

  StreamSubscription? _listenerSubscription;

  Future<bool> checkPermission() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      return await FlutterOverlayWindow.requestPermission() ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isActive() async {
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (e) {
      return false;
    }
  }

  Future<void> showOverlay({int width = 85, int height = 85}) async {
    try {
      final isGranted = await checkPermission();
      if (!isGranted) {
        final requested = await requestPermission();
        if (!requested) return;
      }

      if (await isActive()) return;

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Voice Bubble",
        overlayContent: "Speech-to-Text Floating Bubble Active",
        width: width,
        height: height,
        alignment: OverlayAlignment.centerRight,
        flag: OverlayFlag.focusPointer,
      );
    } catch (e) {
      // Handle overlay launch failure
    }
  }

  Future<void> closeOverlay() async {
    try {
      if (await isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      // Handle close error
    }
  }

  Future<void> resize(int width, int height, [bool enableDrag = true]) async {
    try {
      if (await isActive()) {
        await FlutterOverlayWindow.resizeOverlay(width, height, enableDrag);
      }
    } catch (e) {
      // Handle resize error
    }
  }

  Future<void> sendData(dynamic data) async {
    try {
      await FlutterOverlayWindow.shareData(data);
    } catch (e) {
      // Handle send error
    }
  }

  void registerListener(void Function(dynamic data) onDataReceived) {
    _listenerSubscription?.cancel();
    _listenerSubscription = FlutterOverlayWindow.overlayListener.listen((event) {
      onDataReceived(event);
    });
  }

  void dispose() {
    _listenerSubscription?.cancel();
  }
}
