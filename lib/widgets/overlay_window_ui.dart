import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:local_clipboard/local_clipboard.dart';
import '../services/speech_service.dart';
import '../utils/telugu_transliterator.dart';

class OverlayWindowUI extends StatefulWidget {
  const OverlayWindowUI({super.key});

  @override
  State<OverlayWindowUI> createState() => _OverlayWindowUIState();
}

class _OverlayWindowUIState extends State<OverlayWindowUI>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  // Pulse glow animation for bubble
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Waveform heights
  final List<double> _waveformHeights = List.filled(7, 4.0);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Register sound level listener to animate waveform
    SpeechService.instance.soundLevel.addListener(_updateWaveform);
  }

  @override
  void dispose() {
    SpeechService.instance.soundLevel.removeListener(_updateWaveform);
    _pulseController.dispose();
    super.dispose();
  }

  void _updateWaveform() {
    if (!mounted) return;
    double level = SpeechService.instance.soundLevel.value;
    setState(() {
      for (int i = 0; i < _waveformHeights.length; i++) {
        double multiplier = (i == 3) ? 1.0 : (i == 2 || i == 4) ? 0.7 : (i == 1 || i == 5) ? 0.4 : 0.2;
        _waveformHeights[i] = 4.0 + (level * 40.0 * multiplier);
      }
    });
  }

  Future<void> _toggleExpanded() async {
    final newExpanded = !_isExpanded;
    
    if (newExpanded) {
      // Expand overlay window size: 300 width, 320 height
      await FlutterOverlayWindow.resizeOverlay(300, 320, true);
    } else {
      // Stop speech if listening
      await SpeechService.instance.stopListening();
      // Collapse overlay window size: 85 width, 85 height
      await FlutterOverlayWindow.resizeOverlay(85, 85, true);
    }

    setState(() {
      _isExpanded = newExpanded;
    });
  }

  void _toggleListening() {
    final speech = SpeechService.instance;
    if (speech.isListening.value) {
      speech.stopListening();
    } else {
      speech.startListening(
        onResult: (text) {
          // Share transcribed text with the main app if it is active/listening
          FlutterOverlayWindow.shareData(text);
          setState(() {});
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: _isExpanded ? 290.0 : 72.0,
                height: _isExpanded ? 310.0 : 72.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_isExpanded ? 24.0 : 36.0),
                  boxShadow: [
                    BoxShadow(
                      color: speech.isListening.value
                          ? Colors.cyan.withValues(alpha: 0.4)
                          : Colors.indigo.withValues(alpha: 0.3),
                      blurRadius: _isExpanded ? 14 : _pulseAnimation.value,
                      spreadRadius: speech.isListening.value ? 2 : 1,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_isExpanded ? 24.0 : 36.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(_isExpanded ? 24.0 : 36.0),
                        border: Border.all(
                          color: speech.isListening.value
                              ? Colors.cyan.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: _isExpanded ? _buildExpandedUI() : _buildCollapsedUI(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollapsedUI() {
    final speech = SpeechService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: speech.isListening,
      builder: (context, listening, _) {
        return InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(36.0),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (listening)
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                      backgroundColor: Colors.cyan.withValues(alpha: 0.1),
                    ),
                  ),
                Icon(
                  listening ? Icons.mic : Icons.mic_none_rounded,
                  color: listening ? Colors.cyan : Colors.white,
                  size: 26,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedUI() {
    final speech = SpeechService.instance;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: speech.isListening.value ? Colors.cyan : Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: speech.isListening.value ? Colors.cyan : Colors.amber,
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<String>(
                    valueListenable: speech.status,
                    builder: (context, statusStr, _) {
                      String displayStatus = statusStr;
                      if (statusStr == 'listening') displayStatus = 'Listening...';
                      if (statusStr == 'Ready') displayStatus = 'Voice Bubble';
                      return Text(
                        displayStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                onPressed: _toggleExpanded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Language",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              ValueListenableBuilder<String>(
                valueListenable: speech.currentLocale,
                builder: (context, locale, _) {
                  final isEnglish = locale == "en_US";
                  return Row(
                    children: [
                      _buildLanguageButton("🇺🇸 EN", isEnglish, () => speech.currentLocale.value = "en_US"),
                      const SizedBox(width: 6),
                      _buildLanguageButton("🇮🇳 TE", !isEnglish, () => speech.currentLocale.value = "te_IN"),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Transcription text box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ValueListenableBuilder<String>(
                  valueListenable: speech.transcribedText,
                  builder: (context, text, _) {
                    if (text.isEmpty) {
                      return const Text(
                        "Tap the mic and speak...",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      );
                    }
                    final transliterated = TeluguTransliterator.transliterate(text);
                    final hasTransliteration = transliterated != text;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                        if (hasTransliteration) ...[
                          const SizedBox(height: 6),
                          Text(
                            transliterated,
                            style: TextStyle(
                              color: Colors.cyan[300],
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Waveform visualizer
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: speech.isListening,
              builder: (context, listening, _) {
                if (!listening) {
                  return const Center(
                    child: Text(
                      "Visualizer Idle",
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_waveformHeights.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 3.5,
                      height: _waveformHeights[index] * 0.75, // Scaled down for overlay UI
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withValues(alpha: 0.3),
                            blurRadius: 3,
                          )
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Copy Button
              _buildActionButton(
                icon: Icons.copy_all_rounded,
                tooltip: "Copy Text",
                onPressed: () async {
                  final text = speech.transcribedText.value;
                  if (text.isNotEmpty) {
                    final transliterated = TeluguTransliterator.transliterate(text);
                    final success = await LocalClipboard.copy(transliterated);
                    if (success) {
                      FlutterOverlayWindow.shareData("Text copied from background bubble!");
                    } else {
                      FlutterOverlayWindow.shareData("COPY_FALLBACK:$transliterated");
                    }
                  }
                },
              ),
              // Mic Toggle Button
              ValueListenableBuilder<bool>(
                valueListenable: speech.isListening,
                builder: (context, listening, _) {
                  return InkWell(
                    onTap: _toggleListening,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: listening ? Colors.cyan : Colors.white10,
                        boxShadow: listening
                            ? [
                                BoxShadow(
                                  color: Colors.cyan.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        listening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: listening ? Colors.black : Colors.white,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
              // Clear Button
              _buildActionButton(
                icon: Icons.delete_outline_rounded,
                tooltip: "Clear Text",
                onPressed: () {
                  speech.transcribedText.value = "";
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      ),
    );
  }

  Widget _buildLanguageButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.cyan : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.cyan : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
