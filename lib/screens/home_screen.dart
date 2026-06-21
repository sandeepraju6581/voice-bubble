import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:local_clipboard/local_clipboard.dart';
import '../services/speech_service.dart';
import '../services/overlay_service_wrapper.dart';
import '../widgets/draggable_in_app_bubble.dart';
import '../utils/telugu_transliterator.dart';
import 'category_vault_screen.dart';
import '../services/dictionary_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _micPermissionGranted = false;
  bool _overlayPermissionGranted = false;
  bool _accessibilityServiceActive = false;
  bool _inAppBubbleActive = false;
  bool _systemOverlayActive = false;
  String _testTranscribedText = "";
  String _bgOverlayEventLog = "Waiting for background events...";
  int _selectedTabIndex = 0;

  final TextEditingController _englishWordController = TextEditingController();
  final TextEditingController _teluguWordController = TextEditingController();

  // For testing mic on Home screen
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<double> _testWaveformHeights = List.filled(7, 4.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    WidgetsBinding.instance.removeObserver(this);
    SpeechService.instance.soundLevel.removeListener(_updateTestWaveform);
    _pulseController.dispose();
    _englishWordController.dispose();
    _teluguWordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
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
    bool accessibilityActive = false;
    if (Platform.isAndroid) {
      overlayGranted = await OverlayServiceWrapper.instance.checkPermission();
      accessibilityActive = await LocalClipboard.isAccessibilityServiceEnabled();
    }

    setState(() {
      _micPermissionGranted = micGranted;
      _overlayPermissionGranted = overlayGranted;
      _accessibilityServiceActive = accessibilityActive;
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
      appBar: _selectedTabIndex == 0
          ? AppBar(
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
            )
          : null,
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildDictationBody(speech),
          const CategoryVaultScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDictationBody(SpeechService speech) {
    return Container(
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
              const SizedBox(height: 20),
              _buildCustomDictionaryCard(),
              if (Platform.isAndroid) ...[
                const SizedBox(height: 20),
                _buildEventLogsCard(),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0B21).withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: BottomNavigationBar(
            currentIndex: _selectedTabIndex,
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.cyan[400],
            unselectedItemColor: Colors.white38,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit', fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 11),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.mic_none_rounded),
                activeIcon: Icon(Icons.mic_rounded),
                label: "Dictation",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_open_rounded),
                activeIcon: Icon(Icons.folder_shared_rounded),
                label: "Vault",
              ),
            ],
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
            const Divider(color: Colors.white12, height: 20),
            _buildPermissionTile(
              title: "Auto-Type Accessibility Service",
              subtitle: "Required to type dictated text directly",
              isGranted: _accessibilityServiceActive,
              onRequest: () async {
                await LocalClipboard.openAccessibilitySettings();
                Future.delayed(const Duration(seconds: 1), _checkPermissions);
              },
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
            const Divider(color: Colors.white12, height: 20),
            ValueListenableBuilder<bool>(
              valueListenable: SpeechService.instance.autoInjectEnabled,
              builder: (context, enabled, _) {
                return _buildToggleTile(
                  title: "Auto-Type Dictated Text",
                  subtitle: "Inject text directly into active input fields",
                  value: enabled,
                  onChanged: (val) async {
                    if (val) {
                      final active = await LocalClipboard.isAccessibilityServiceEnabled();
                      if (!active) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Enable the Auto-Type Accessibility Service first!"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        return;
                      }
                    }
                    SpeechService.instance.autoInjectEnabled.value = val;
                  },
                  activeColor: Colors.amberAccent,
                );
              },
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
                  return Row(
                    children: [
                      _buildLanguageButton("🇺🇸 EN", locale == "en_US", () => speech.currentLocale.value = "en_US"),
                      const SizedBox(width: 6),
                      _buildLanguageButton("🇮🇳 TE", locale == "te_IN", () => speech.currentLocale.value = "te_IN"),
                      const SizedBox(width: 6),
                      _buildLanguageButton("🔄 MIX", locale == "te_IN_mix", () => speech.currentLocale.value = "te_IN_mix"),
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

  Widget _buildCustomDictionaryCard() {
    final dictService = DictionaryService.instance;

    return _buildGlassCard(
      title: "Smart Mix Custom Dictionary",
      icon: Icons.book_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Map custom English words so they are correctly recognized in MIX mode instead of showing up as Telugu script or phonetic Latin script.",
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          
          // Row of inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _englishWordController,
                  decoration: InputDecoration(
                    labelText: "English Word",
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    hintText: "e.g. daddy",
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.cyan),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _teluguWordController,
                  decoration: InputDecoration(
                    labelText: "Telugu Script",
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    hintText: "e.g. డాడీ",
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.cyan),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Add Word button
          ElevatedButton.icon(
            onPressed: () async {
              final eng = _englishWordController.text.trim();
              final tel = _teluguWordController.text.trim();
              if (eng.isNotEmpty && tel.isNotEmpty) {
                await dictService.addEntry(eng, tel);
                _englishWordController.clear();
                _teluguWordController.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Added custom mapping: $eng ➔ $tel"),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text("Add Custom Word", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 18),

          // Quick Add Suggestions
          const Text(
            "Quick Suggestions",
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickAddChip("college", "కాలేజీ"),
              _buildQuickAddChip("phone", "ఫోన్"),
              _buildQuickAddChip("daddy", "డాడీ"),
              _buildQuickAddChip("mummy", "మమ్మీ"),
              _buildQuickAddChip("school", "స్కూల్"),
              _buildQuickAddChip("office", "ఆఫీస్"),
            ],
          ),
          const SizedBox(height: 18),

          // Custom words list
          const Text(
            "Active Custom Mappings",
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          AnimatedBuilder(
            animation: dictService,
            builder: (context, _) {
              final entries = dictService.entries;
              if (entries.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "No custom words added yet.",
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final phonetic = TeluguTransliterator.transliterate(entry.teluguWord);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: entry.englishWord,
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              children: [
                                const TextSpan(
                                  text: "  ➔  ",
                                  style: TextStyle(color: Colors.white38),
                                ),
                                TextSpan(
                                  text: entry.teluguWord,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: " [$phonetic]",
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          onPressed: () async {
                            await dictService.removeEntry(entry.englishWord);
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddChip(String english, String telugu) {
    final dictService = DictionaryService.instance;
    return ActionChip(
      label: Text("$english ➔ $telugu"),
      labelStyle: const TextStyle(fontSize: 11, color: Colors.white70),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white12),
      ),
      onPressed: () async {
        await dictService.addEntry(english, telugu);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Quick Added: $english ➔ $telugu"),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }
}
