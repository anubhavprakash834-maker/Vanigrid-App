import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'identity_setup_screen.dart';
import 'model_setup_screen.dart'; // Routing to neural setup after identity check

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _executeBootSequence();
  }

  Future<void> _executeBootSequence() async {
    // A slight delay to allow the tactical UI to render for UX purposes
    await Future.delayed(const Duration(seconds: 2));

    // Check local hardware storage for an existing identity
    final prefs = await SharedPreferences.getInstance();
    final callsign = prefs.getString('user_callsign');

    if (!mounted) return;

    if (callsign != null && callsign.isNotEmpty) {
      // Identity exists -> Bypass setup and go straight to Neural Engine Initialization
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ModelSetupScreen()),
      );
    } else {
      // First time booting the app -> Route to Identity Setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IdentitySetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070814),
      body: Stack(
        children: [
          // 1. ADD OBSIDIAN GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF0F172A),
                  Color(0xFF070814),
                ],
              ),
            ),
          ),

          // 2. IMAGE PLACEHOLDER
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'assets/images/mesh_bg_overlay.png',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Radar Icon Simulation
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB8860B).withOpacity(0.05),
                    border: Border.all(
                      color: const Color(0xFFB8860B).withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.radar,
                    color: Color(0xFFFFBF00),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 32),

                // App Branding
                Text(
                  'VANIGRID',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SIH OFFLINE COMMUNICATION MESH',
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 10,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading Indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFBF00),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
