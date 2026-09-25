import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'network_radar_screen.dart';
import 'language_pack_screen.dart';
import '../providers/language_pack_provider.dart';
import '../providers/transceiver_provider.dart';

class ModelSetupScreen extends ConsumerStatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  ConsumerState<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends ConsumerState<ModelSetupScreen> {
  bool _isInitializing = false;
  bool _showTutorialOverlay = false;
  bool _isDownloadingCoreModels = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    
    if (isFirstLaunch) {
      setState(() {
        _showTutorialOverlay = true;
        _isDownloadingCoreModels = true; // Triggers the bottom popup
      });
      _downloadCoreSystemModels();
    }
  }

  // The background task that downloads the ML Kit Base Pivot Engine
  Future<void> _downloadCoreSystemModels() async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      // Silently fetches the core English translation dictionary from Google servers
      await modelManager.downloadModel(TranslateLanguage.english.bcpCode, isWifiRequired: false);
    } catch (e) {
      debugPrint("SYSTEM ERROR: Core base model download interrupted.");
    } finally {
      if (mounted) {
        setState(() => _isDownloadingCoreModels = false);
      }
    }
  }

  void _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    setState(() => _showTutorialOverlay = false);
  }

  Future<void> _deployNeuralWeights() async {
    // HARD VALIDATION: Force user to download at least one language pack
    final packStates = ref.read(languagePackProvider);
    final hasAnyLanguage = packStates.values.any((progress) => progress == -1.0);

    if (!hasAnyLanguage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must download at least one language to proceed.', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isInitializing = true);
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final aiEngine = ref.read(aiEngineProvider);
      // Automatically ignite the first available language the user downloaded
      final defaultLang = packStates.entries.firstWhere((e) => e.value == -1.0).key;
      await aiEngine.initializeModels(defaultLang);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NetworkRadarScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("UI ERROR: Failed to load models: $e");
      if (mounted) {
        setState(() => _isInitializing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hardware Load Failed: $e', style: GoogleFonts.inter()), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'NEURAL DEPLOYMENT',
          style: GoogleFonts.rajdhani(color: const Color(0xFFFFBF00), fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguagePackScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [Color(0xFF1E1B4B), Color(0xFF070814)],
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/images/chip_pattern.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox.shrink()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LOCALIZED INDIC LANGUAGES', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Optimized for Low-Power Edge Devices\n(Data payload reduction up to 99%)', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14)),
                
                const SizedBox(height: 40),

                _buildModelStatusRow(
                  'Edge VAD & Noise Gating',
                  'Embedded | RMS Heuristics',
                  true,
                ),
                const SizedBox(height: 24),
                _buildModelStatusRow(
                  'Neural STT & Translation',
                  'Dynamic Cloud Allocation',
                  true,
                ),
                const SizedBox(height: 24),
                _buildModelStatusRow(
                  'Native Speech Synthesizer',
                  'Embedded | OS Platform Engine',
                  true,
                ),

                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTelemetryStat('RAM Footprint', '~73MB'),
                      Container(height: 40, width: 1, color: Colors.grey[700]),
                      _buildTelemetryStat('Idle CPU Usage', '< 2%'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2691E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isInitializing ? null : _deployNeuralWeights,
                    child: _isInitializing
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text('EXTRACT & LOAD NEURAL WEIGHTS', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------
          // FIRST LAUNCH BLURRED TUTORIAL OVERLAY
          // -------------------------------------------------------------
          if (_showTutorialOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissTutorial,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Stack(
                      children: [
                        // Dialog Cloud pointing to the settings icon
                        Positioned(
                          top: 60,
                          right: 40,
                          child: Container(
                            width: 250,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                topRight: Radius.circular(4), 
                              ),
                              boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Download Regional Packs',
                                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the icon above to select and download your operational language models before proceeding.',
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // The arrow pointing up
                        const Positioned(
                          top: 40,
                          right: 25,
                          child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // -------------------------------------------------------------
          // BOTTOM POPUP: DOWNLOADING CORE MODELS
          // -------------------------------------------------------------
          if (_isDownloadingCoreModels)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFBF00), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, spreadRadius: 5),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFBF00),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Downloading required models...',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Securing core base engine',
                            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTelemetryStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
  Widget _buildModelStatusRow(String title, String subtitle, bool isLoaded) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLoaded ? const Color(0xFF10B981) : Colors.transparent,
            border: Border.all(
              color: isLoaded ? const Color(0xFF10B981) : Colors.grey[600]!,
              width: 2,
            ),
          ),
          child: isLoaded
              ? const Icon(Icons.check, color: Colors.black, size: 20)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}