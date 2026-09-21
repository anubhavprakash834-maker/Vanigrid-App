import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_radar_screen.dart';
import 'language_pack_screen.dart';
import '../providers/transceiver_provider.dart';

class ModelSetupScreen extends ConsumerStatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  ConsumerState<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends ConsumerState<ModelSetupScreen> {
  bool _vadLoaded = false;
  bool _sttLoaded = false;
  bool _ttsLoaded = false;
  bool _allReady = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
  }

  // THIS IS THE CRITICAL FUNCTION
  Future<void> _deployNeuralWeights() async {
    setState(() => _isInitializing = true);

    try {
      // 1. Tell Riverpod to ignite the C++ Sherpa-ONNX Engine
      // This will naturally take 1-4 seconds on a real device as it extracts 
      // the ~45MB of physical files into the Android storage.
      final aiEngine = ref.read(aiEngineProvider);
      await aiEngine.initializeModels('English');

      // 2. Instantly arm all UI systems ONLY after the real extraction succeeds
      if (mounted) {
        setState(() {
          _vadLoaded = true;
          _sttLoaded = true;
          _ttsLoaded = true;
          _allReady = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint("UI ERROR: Failed to load models: $e");
      if (mounted) {
        setState(() => _isInitializing = false);
        // Expose real hardware errors to the operator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hardware Extraction Failed: $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
          ),
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
          style: GoogleFonts.rajdhani(
            color: const Color(0xFFFFBF00),
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguagePackScreen(),
                ),
              );
            },
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

          // IMAGE PLACEHOLDER (Search internet for: "Microchip circuit board traces transparent PNG")
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/chip_pattern.png',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOCALIZED INDIC LANGUAGES',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Optimized for Low-Power Edge Devices\n(Data payload reduction up to 99%)',
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),

                _buildModelStatusRow(
                  'Silero VAD (Pause Detection)',
                  'Footprint: ~1MB | INT8 Quantized',
                  _vadLoaded,
                ),
                const SizedBox(height: 24),
                _buildModelStatusRow(
                  'Sherpa-ONNX STT (Transcriber)',
                  'Footprint: ~45MB | Streaming Engine Ready',
                  _sttLoaded,
                ),
                const SizedBox(height: 24),
                _buildModelStatusRow(
                  'Piper TTS (Synthesizer)',
                  'Footprint: ~22MB | VITS Acoustic Model',
                  _ttsLoaded,
                ),

                const Spacer(),

                // Telemetry Box
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
                      _buildTelemetryStat('RAM Footprint', '~150MB'),
                      Container(height: 40, width: 1, color: Colors.grey[700]),
                      _buildTelemetryStat('Idle CPU Usage', '< 2%'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // THE TRIGGER BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _allReady
                          ? const Color(0xFFD2691E)
                          : const Color(0xFFFFBF00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isInitializing
                        ? null
                        : (_allReady
                              ? () => Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NetworkRadarScreen(),
                                  ),
                                  (route) => false, // NUKES THE ENTIRE BACKSTACK
                                )
                              : _deployNeuralWeights),
                    child: _isInitializing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _allReady
                                ? 'INITIALIZE P2P RADAR'
                                : 'EXTRACT & LOAD NEURAL WEIGHTS',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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

  Widget _buildTelemetryStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: const Color(0xFF10B981),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
