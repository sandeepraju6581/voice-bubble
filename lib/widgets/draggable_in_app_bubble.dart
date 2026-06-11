import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:local_clipboard/local_clipboard.dart';
import '../services/speech_service.dart';
import '../utils/telugu_transliterator.dart';

class InAppBubbleOverlay {
  static OverlayEntry? _overlayEntry;
  static bool get isVisible => _overlayEntry != null;

  static void show(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => const DraggableInAppBubble(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class DraggableInAppBubble extends StatefulWidget {
  const DraggableInAppBubble({super.key});

  @override
  State<DraggableInAppBubble> createState() => _DraggableInAppBubbleState();
}

class _DraggableInAppBubbleState extends State<DraggableInAppBubble>
    with TickerProviderStateMixin {
  Offset _position = const Offset(20, 150);
  bool _isExpanded = false;

  // Snapping animation
  late AnimationController _snapController;
  late Animation<Offset> _snapAnimation;

  // Pulse glow animation for bubble
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Waveform heights
  final List<double> _waveformHeights = List.filled(7, 4.0);

  @override
  void initState() {
    super.initState();

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial position logic after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _position = Offset(size.width - 80, size.height * 0.4);
      });
    });

    // Listen to sound levels to animate waveform
    SpeechService.instance.soundLevel.addListener(_updateWaveform);
  }

  @override
  void dispose() {
    SpeechService.instance.soundLevel.removeListener(_updateWaveform);
    _snapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateWaveform() {
    if (!mounted) return;
    double level = SpeechService.instance.soundLevel.value;
    setState(() {
      for (int i = 0; i < _waveformHeights.length; i++) {
        // Create a organic wave shape based on the sound level
        double multiplier = (i == 3) ? 1.0 : (i == 2 || i == 4) ? 0.7 : (i == 1 || i == 5) ? 0.4 : 0.2;
        _waveformHeights[i] = 4.0 + (level * 40.0 * multiplier);
      }
    });
  }

  void _snapToEdge(Size screenSize) {
    double bubbleWidth = _isExpanded ? 280.0 : 68.0;
    double bubbleHeight = _isExpanded ? 320.0 : 68.0;

    double targetX;
    // Limit Y bounds
    double targetY = _position.dy.clamp(50.0, screenSize.height - bubbleHeight - 50.0);

    if (_isExpanded) {
      // For expanded, keep it padded inside the screen
      targetX = _position.dx.clamp(20.0, screenSize.width - bubbleWidth - 20.0);
    } else {
      // Snap to left or right edge
      if (_position.dx + (bubbleWidth / 2) < screenSize.width / 2) {
        targetX = 16.0; // Left padding
      } else {
        targetX = screenSize.width - bubbleWidth - 16.0; // Right padding
      }
    }

    _snapAnimation = Tween<Offset>(
      begin: _position,
      end: Offset(targetX, targetY),
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutBack,
    ));

    _snapController.forward(from: 0.0).then((_) {
      _position = Offset(targetX, targetY);
    });

    _snapController.addListener(() {
      if (_snapController.isAnimating) {
        setState(() {
          _position = _snapAnimation.value;
        });
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        // Stop speech if collapsing
        SpeechService.instance.stopListening();
      }
    });

    // Post frame snap to ensure bounds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _snapToEdge(MediaQuery.of(context).size);
    });
  }

  void _toggleListening() {
    final speech = SpeechService.instance;
    if (speech.isListening.value) {
      speech.stopListening();
    } else {
      speech.startListening(
        onResult: (text) {
          // Re-render
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
    final size = MediaQuery.of(context).size;
    final speech = SpeechService.instance;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (details) {
          _snapToEdge(size);
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutBack,
                width: _isExpanded ? 280.0 : 68.0,
                height: _isExpanded ? 320.0 : 68.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_isExpanded ? 24.0 : 34.0),
                  boxShadow: [
                    BoxShadow(
                      color: speech.isListening.value
                          ? Colors.cyan.withValues(alpha: 0.4)
                          : Colors.indigo.withValues(alpha: 0.3),
                      blurRadius: _isExpanded ? 16 : _pulseAnimation.value,
                      spreadRadius: speech.isListening.value ? 2 : 1,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_isExpanded ? 24.0 : 34.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(_isExpanded ? 24.0 : 34.0),
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
          borderRadius: BorderRadius.circular(34.0),
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
                  size: 28,
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
      padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(width: 8),
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      );
                    },
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                onPressed: _toggleExpanded,
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),

          // Transcription text box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
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
                          fontSize: 14,
                          height: 1.4,
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
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (hasTransliteration) ...[
                          const SizedBox(height: 8),
                          Text(
                            transliterated,
                            style: TextStyle(
                              color: Colors.cyan[300],
                              fontSize: 12,
                              height: 1.4,
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
          const SizedBox(height: 12),

          // Waveform Visualizer
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: speech.isListening,
              builder: (context, listening, _) {
                if (!listening) {
                  return const Center(
                    child: Text(
                      "Visualizer Idle",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_waveformHeights.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 4,
                      height: _waveformHeights[index],
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withValues(alpha: 0.3),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Actions
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
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Copied to clipboard!"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              ),
              // Mic Toggle Button (Floating Cyan button)
              ValueListenableBuilder<bool>(
                valueListenable: speech.isListening,
                builder: (context, listening, _) {
                  return InkWell(
                    onTap: _toggleListening,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: listening ? Colors.cyan : Colors.white10,
                        boxShadow: listening
                            ? [
                                BoxShadow(
                                  color: Colors.cyan.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        listening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: listening ? Colors.black : Colors.white,
                        size: 26,
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
        icon: Icon(icon, color: Colors.white70),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
