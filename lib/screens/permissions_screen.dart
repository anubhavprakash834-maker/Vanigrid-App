import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'model_setup_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

// We add WidgetsBindingObserver to detect when the app comes back to the foreground
// We add WidgetsBindingObserver to detect when the app comes back to the foreground
class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _micGranted = false;
  bool _nearbyGranted = false;
  bool _batteryGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExistingPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // FIX 1: Add a slight delay. Android OS sometimes takes a fraction of
      // a second to update its internal permission registry after you return.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkExistingPermissions();
      });
    }
  }

  Future<void> _checkExistingPermissions() async {
    _micGranted = await Permission.microphone.isGranted;

    // For Nearby, Location is the absolute mandatory requirement
    bool locationGranted = await Permission.location.isGranted;
    _nearbyGranted = locationGranted;

    _batteryGranted = await Permission.ignoreBatteryOptimizations.isGranted;

    if (mounted) setState(() {});
  }

  Future<void> _requestMicrophone() async {
    await Permission.microphone.request();
    _checkExistingPermissions();
  }

  Future<void> _requestNearbyDevices() async {
    await [
      Permission.location,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
    _checkExistingPermissions();
  }

  Future<void> _requestBatteryBypass() async {
    await Permission.ignoreBatteryOptimizations.request();
    // The lifecycle observer will catch it when they return,
    // but we can also trigger a check here just in case.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkExistingPermissions();
    });
  }

  // FIX 2: THE HACKATHON OVERRIDE
  // If the Android skin refuses to cooperate, a long-press will force it to true.
  void _forceBatteryGranted() {
    setState(() {
      _batteryGranted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Developer Override: Battery constraint bypassed.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _micGranted && _nearbyGranted && _batteryGranted;

    return Scaffold(
      backgroundColor: const Color(0xFF070814),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'INITIALIZATION',
          style: GoogleFonts.rajdhani(
            color: const Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. ADD OBSIDIAN GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF1E1B4B), Color(0xFF070814)],
              ),
            ),
          ),

          // 2. IMAGE OVERLAY (Using your verified .jpg file!)
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/mesh_bg_overlay.jpg',
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
                  'Hardware Access',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'VaniGrid requires direct hardware access to establish an offline neural mesh.',
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                _PermissionCard(
                  title: 'Microphone (STT)',
                  description:
                      'Required to capture voice for local AI transcription.',
                  icon: Icons.mic,
                  isGranted: _micGranted,
                  onRequest: _requestMicrophone,
                ),

                _PermissionCard(
                  title: 'Nearby Devices',
                  description: 'Required to beam text packets over offline Wi-Fi Direct & BLE.',
                  icon: Icons.cell_tower,
                  isGranted: _nearbyGranted,
                  onRequest: _requestNearbyDevices,
                ),

                // Pass the onLongPress override directly to this specific card
                _PermissionCard(
                  title: 'Background Execution',
                  description: 'Prevents Android from killing the app while waiting for distress signals.',
                  icon: Icons.battery_charging_full,
                  isGranted: _batteryGranted,
                  onRequest: _requestBatteryBypass,
                  onLongPress: _forceBatteryGranted, // <--- NEW OVERRIDE
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allGranted
                          ? const Color(0xFFFFFF00)
                          : Colors.grey[800],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: allGranted
                        ? () {
                            // Push to the Model Setup Screen smoothly
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ModelSetupScreen(),
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      'DEPLOY LOCAL LOOP',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 22,
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
}

class _PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onRequest;
  final VoidCallback? onLongPress; // <--- ADDED

  const _PermissionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isGranted,
    required this.onRequest,
    this.onLongPress, // <--- ADDED
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? const Color(0xFF10B981) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isGranted
                ? const Color(0xFF10B981)
                : const Color(0xFFFFBF00),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          isGranted
              ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
              // Wrap the button in a GestureDetector to catch long presses
              : GestureDetector(
                  onLongPress: onLongPress,
                  child: ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFBF00).withOpacity(0.2),
                      foregroundColor: const Color(0xFFFFBF00),
                      elevation: 0,
                    ),
                    child: const Text('ALLOW'),
                  ),
                ),
        ],
      ),
    );
  }
}
