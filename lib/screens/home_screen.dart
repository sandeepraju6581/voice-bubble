import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:local_clipboard/local_clipboard.dart';
import '../services/speech_service.dart';
import '../services/overlay_service_wrapper.dart';
import '../widgets/draggable_in_app_bubble.dart';
import '../utils/telugu_transliterator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _micPermissionGranted = false;
  bool _overlayPermissionGranted = false;
  bool _inAppBubbleActive = false;
  bool _systemOverlayActive = false;
  String _testTranscribedText = "";
  String _bgOverlayEventLog = "Waiting for background events...";

  // For testing mic on Home screen
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<double> _testWaveformHeights = List.filled(7, 4.0);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkPermissions();

    // Listen for events from background overlay (Android)
    if (Platform.isAndroid) {
      OverlayServiceWrapper.instance.registerListener((data) {
        if (mounted) {
          final dataStr = data.toString();
          if (dataStr.startsWith("COPY_FALLBACK:")) {
            final textToCopy = dataStr.substring("COPY_FALLBACK:".length);
            LocalClipboard.copy(textToCopy);
            setState(() {
              _bgOverlayEventLog = "Main App Copied Text (Fallback Backup)";
            });
            return;
          }
          setState(() {
            _bgOverlayEventLog = "Bg Event received: $data";
            if (dataStr.contains("copied") || dataStr.contains("Text")) {
              _testTranscribedText = dataStr;
            }
          });
        }
      });

      _checkSystemOverlayActive();
    }

    SpeechService.instance.soundLevel.addListener(_updateTestWaveform);
  }

  @override
  void dispose() {
    SpeechService.instance.soundLevel.removeListener(_updateTestWaveform);
    _pulseController.dispose();
    super.dispose();
  }

  void _updateTestWaveform() {
    if (!mounted || !SpeechService.instance.isListening.value) return;
    double level = SpeechService.instance.soundLevel.value;
    setState(() {
      for (int i = 0; i < _testWaveformHeights.length; i++) {
        double multiplier = (i == 3) ? 1.0 : (i == 2 || i == 4) ? 0.7 : (i == 1 || i == 5) ? 0.4 : 0.2;
        _testWaveformHeights[i] = 4.0 + (level * 60.0 * multiplier);
      }
    });
  }

  Future<void> _checkPermissions() async {
    final micGranted = await SpeechService.instance.checkPermissions();
    bool overlayGranted = false;
    if (Platform.isAndroid) {
      overlayGranted = await OverlayServiceWrapper.instance.checkPermission();
    }

    setState(() {
      _micPermissionGranted = micGranted;
      _overlayPermissionGranted = overlayGranted;
    });
  }

  Future<void> _checkSystemOverlayActive() async {
    bool active = await OverlayServiceWrapper.instance.isActive();
    setState(() {
      _systemOverlayActive = active;
    });
  }

  Future<void> _requestMicPermission() async {
    final granted = await SpeechService.instance.requestPermissions();
    setState(() {
      _micPermissionGranted = granted;
    });
    if (granted) {
      SpeechService.instance.initialize();
    }
  }

  Future<void> _requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    final granted = await OverlayServiceWrapper.instance.requestPermission();
    setState(() {
      _overlayPermissionGranted = granted;
    });
  }

  void _toggleInAppBubble(bool value) {
    setState(() {
      _inAppBubbleActive = value;
    });

    if (value) {
      InAppBubbleOverlay.show(context);
    } else {
      InAppBubbleOverlay.hide();
    }
  }

  Future<void> _toggleSystemOverlay(bool value) async {
    if (!Platform.isAndroid) return;

    if (value) {
      // Ensure we have permissions first
      if (!_overlayPermissionGranted) {
        await _requestOverlayPermission();
        if (!_overlayPermissionGranted) return;
      }
      await OverlayServiceWrapper.instance.showOverlay();
    } else {
      await OverlayServiceWrapper.instance.closeOverlay();
    }

    setState(() {
      _systemOverlayActive = value;
    });
  }

  void _toggleTestListening() {
    final speech = SpeechService.instance;
    if (speech.isListening.value) {
      speech.stopListening();
      _pulseController.stop();
    } else {
      _testTranscribedText = "";
      _pulseController.repeat(reverse: true);
      speech.startListening(
        onResult: (text) {
          setState(() {
            _testTranscribedText = text;
          });
        },
        onStatusChanged: (status) {
          setState(() {});
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = SpeechService.instance;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "VOICE BUBBLE",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
            fontFamily: 'Outfit',
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0B21), // Midnight Dark Blue
              Color(0xFF14123A), // Deep Indigo
              Color(0xFF1F124C), // Purple Tone
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 20),
                _buildPermissionsCard(),
                const SizedBox(height: 20),
                _buildOverlayControlsCard(),
                const SizedBox(height: 20),
                _buildTestAreaCard(speech),
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 20),
                  _buildEventLogsCard(),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.cyan.withValues(alpha: 0.15),
            Colors.indigo.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            size: 50,
            color: Colors.cyan[400],
          ),
          const SizedBox(height: 12),
          const Text(
            "Speech to Text Anywhere",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Platform.isAndroid
                ? "Activate floating overlays to record audio and dictate text directly over other applications."
                : "Toggle the floating bubble to transcribe text smoothly while navigating the application.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white60,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return _buildGlassCard(
      title: "Permissions Configuration",
      icon: Icons.security_rounded,
      child: Column(
        children: [
          _buildPermissionTile(
            title: "Microphone Access",
            subtitle: "Required for recording speech",
            isGranted: _micPermissionGranted,
            onRequest: _requestMicPermission,
          ),
          if (Platform.isAndroid) ...[
            const Divider(color: Colors.white12, height: 20),
            _buildPermissionTile(
              title: "System Overlay",
              subtitle: "Required to draw over other apps",
              isGranted: _overlayPermissionGranted,
              onRequest: _requestOverlayPermission,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: isGranted ? null : onRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: isGranted ? Colors.transparent : Colors.cyan[600],
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.greenAccent[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isGranted ? Colors.greenAccent[400]!.withValues(alpha: 0.5) : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text(
            isGranted ? "Granted" : "Grant",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isGranted ? Colors.greenAccent[400] : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayControlsCard() {
    return _buildGlassCard(
      title: "Floating Controls",
      icon: Icons.layers_outlined,
      child: Column(
        children: [
          _buildToggleTile(
            title: "In-App Floating Bubble",
            subtitle: "Display bubble overlay inside the application",
            value: _inAppBubbleActive,
            onChanged: _toggleInAppBubble,
            activeColor: Colors.cyan,
          ),
          if (Platform.isAndroid) ...[
            const Divider(color: Colors.white12, height: 20),
            _buildToggleTile(
              title: "System Overlay Window",
              subtitle: "Display bubble on top of other applications",
              value: _systemOverlayActive,
              onChanged: (val) => _toggleSystemOverlay(val),
              activeColor: Colors.deepPurpleAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor,
          activeTrackColor: activeColor.withValues(alpha: 0.4),
          inactiveThumbColor: Colors.white30,
          inactiveTrackColor: Colors.white10,
        ),
      ],
    );
  }

  Widget _buildTestAreaCard(SpeechService speech) {
    return _buildGlassCard(
      title: "Speech Transcription Test",
      icon: Icons.keyboard_voice_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Language", style: TextStyle(color: Colors.white60, fontSize: 13)),
              ValueListenableBuilder<String>(
                valueListenable: speech.currentLocale,
                builder: (context, locale, _) {
                  final isEnglish = locale == "en_US";
                  return Row(
                    children: [
                      _buildLanguageButton("🇺🇸 EN", isEnglish, () => speech.currentLocale.value = "en_US"),
                      const SizedBox(width: 8),
                      _buildLanguageButton("🇮🇳 TE (తెలుగు)", !isEnglish, () => speech.currentLocale.value = "te_IN"),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: SingleChildScrollView(
              child: _testTranscribedText.isEmpty
                  ? const Text(
                      "Tap microphone below and say something...",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _testTranscribedText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (TeluguTransliterator.transliterate(_testTranscribedText) != _testTranscribedText) ...[
                          const SizedBox(height: 8),
                          Text(
                            TeluguTransliterator.transliterate(_testTranscribedText),
                            style: TextStyle(
                              color: Colors.cyan[300],
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Waveform
          ValueListenableBuilder<bool>(
            valueListenable: speech.isListening,
            builder: (context, listening, _) {
              if (listening) {
                return Container(
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_testWaveformHeights.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 50),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 3.5,
                        height: _testWaveformHeights[index] * 0.5,
                        decoration: BoxDecoration(
                          color: Colors.cyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Speech Status: ${speech.status.value}",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_all_rounded, color: Colors.white60),
                    onPressed: () async {
                      if (_testTranscribedText.isNotEmpty) {
                        final transliterated = TeluguTransliterator.transliterate(_testTranscribedText);
                        final success = await LocalClipboard.copy(transliterated);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Copied to clipboard!")),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: speech.isListening,
                    builder: (context, listening, _) {
                      return AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: listening
                                  ? [
                                      BoxShadow(
                                        color: Colors.cyan.withValues(alpha: 0.3),
                                        blurRadius: _pulseAnimation.value,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: CircleAvatar(
                              backgroundColor: listening ? Colors.cyan : Colors.white10,
                              child: IconButton(
                                icon: Icon(
                                  listening ? Icons.stop_rounded : Icons.mic_rounded,
                                  color: listening ? Colors.black : Colors.white,
                                ),
                                onPressed: _toggleTestListening,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventLogsCard() {
    return _buildGlassCard(
      title: "System Overlay Events",
      icon: Icons.terminal_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              _bgOverlayEventLog,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.cyan[300], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildLanguageButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.cyan : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
