import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'performance_metrics_screen.dart';
import 'active_call_screen.dart';
import 'tactical_radar_widget.dart';
import 'transceiver_chat_bubble.dart';
import '../providers/language_pack_provider.dart';
import '../providers/transceiver_provider.dart';
import '../providers/network_provider.dart';

class TransceiverDashboardScreen extends ConsumerStatefulWidget {
  final String peerName;
  final String connectionType; // 'wifi' or 'ble'

  const TransceiverDashboardScreen({
    super.key,
    required this.peerName,
    required this.connectionType,
  });

  @override
  ConsumerState<TransceiverDashboardScreen> createState() => _TransceiverDashboardScreenState();
}

class _TransceiverDashboardScreenState extends ConsumerState<TransceiverDashboardScreen> {
  // The 10 SIH Mandated Languages
  final List<String> _languages = [
    'English', 'Hindi', 'Gujarati', 'Marathi', 'Kannada', 
    'Malayalam', 'Tamil', 'Telugu', 'Odia', 'Bengali'
  ];
  
  // Local UI state for the dropdowns
  String _myLanguage = 'English'; // Unified System Language

  @override
  void initState() {
    super.initState();

    // NEW: Auto-select the first language the user actually downloaded
    try {
      final packStates = ref.read(languagePackProvider); // FIXED: Lowercase 'l'
      final defaultLang = packStates.entries.firstWhere((e) => e.value == -1.0).key;
      _myLanguage = defaultLang; // FIXED: Added the missing underscore '_'
    } catch (_) {} // Fallback to whatever _myLanguage is initially set to
    
    // Trigger the hardware socket handshake when the UI opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // FIX: Synchronize the backend provider immediately to the UI's 'English' default
      ref.read(transceiverControllerProvider.notifier).setSystemLanguage(_myLanguage);
      if (widget.connectionType.toLowerCase() == 'wifi') {
        final units = ref.read(networkProvider);
        
        // Locate the exact network ID of the peer we tapped on
        final targetUnit = units.firstWhere(
          (u) => u.callsign == widget.peerName,
          orElse: () => DiscoveredUnit(id: '', callsign: '', protocol: '', signalStrength: 0),
        );
        
        if (targetUnit.id.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final myCallsign = prefs.getString('user_callsign') ?? "Unknown Unit";
          
          // Command the Wi-Fi radio to bridge the gap
          ref.read(meshNetworkProvider).connectToPeer(myCallsign, targetUnit.id);
        }
      }
    });
  }
  // The SOS Override Panel
  void _showDistressSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DISTRESS OVERRIDE',
                  style: GoogleFonts.rajdhani(
                    color: const Color(0xFFFFFFFF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'These payloads will force the receiving device to play synthetic speech at MAXIMUM volume, bypassing Do Not Disturb.',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 24),
            _EmergencyButton(label: 'BROADCAST SOS', color: const Color(0xFFEF4444)),
            const SizedBox(height: 12),
            _EmergencyButton(label: 'REQUEST MEDICAL AVALANCHE', color: Colors.orange),
            const SizedBox(height: 12),
            _EmergencyButton(label: 'REPORT STRUCTURAL FIRE', color: Colors.deepOrange),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // THIS LINE LISTENS TO THE GLOBAL NERVOUS SYSTEM (RIVERPOD)
    final transceiverState = ref.watch(transceiverControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Column(
          children: [
            Text(
              'LINK SECURED',
              style: GoogleFonts.inter(color: const Color(0xFFD2691E), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0),
            ),
            Text(
              widget.peerName,
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // PHONE MODE BUTTON
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFFD2691E)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveCallScreen(
                    peerName: widget.peerName,
                    connectionType: widget.connectionType,
                  ),
                ),
              );
            },
          ),
          // TELEMETRY BUTTON
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Color(0xFFFFBF00)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PerformanceMetricsScreen()),
              );
            },
          ),
          // SOS BUTTON
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Color(0xFFEF4444)),
            onPressed: _showDistressSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // IMAGE PLACEHOLDER (Search internet for: "Faint military compass watermark PNG")
          Positioned.fill(child: Opacity(opacity: 0.04, child: Image.asset('assets/images/tactical_watermark.png', fit: BoxFit.contain, alignment: Alignment.center, errorBuilder: (c,e,s) => const SizedBox.shrink()))),
      Column(
        children: [
          // Connection Status Bar
          Container(
            width: double.infinity,
            color: widget.connectionType == 'wifi' ? const Color(0xFFFFBF00).withOpacity(0.1) : const Color(0xFF3B82F6).withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.connectionType == 'wifi' ? Icons.wifi : Icons.bluetooth,
                  size: 14,
                  color: widget.connectionType == 'wifi' ? const Color(0xFFFFBF00) : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Transmitting via ${widget.connectionType == 'wifi' ? 'Wi-Fi Direct' : 'BLE'} Protocol',
                  style: GoogleFonts.inter(
                    color: widget.connectionType == 'wifi' ? const Color(0xFFFFBF00) : const Color(0xFF3B82F6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Language Routing Configuration
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: Color(0xFFFFBF00), size: 22),
                      const SizedBox(width: 12),
                      Text('System Language', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _myLanguage,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF93C5FD), size: 28),
                      dropdownColor: const Color(0xFF111827),
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      items: _languages.map((lang) {
                        return DropdownMenuItem(value: lang, child: Text(lang));
                      }).toList(),
                      onChanged: (val) { 
                        if (val == null) return;
                        setState(() => _myLanguage = val);
                        ref.read(transceiverControllerProvider.notifier).setSystemLanguage(val);
                        
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Hot-Swapping Neural Engine to $val...'),
                          backgroundColor: const Color(0xFF3B82F6),
                          duration: const Duration(milliseconds: 1500),
                        ));
                        
                        
                        // Run heavy AI loading in the background so the dropdown closes instantly
                        Future.microtask(() async {
                          await ref.read(aiEngineProvider).initializeModels(val);
                          
                          // Modern lint-safe check for the async gap
                          if (!context.mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('$val Engine Online.'),
                            backgroundColor: const Color(0xFFD2691E),
                          ));
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // INJECTED TACTICAL RADAR WIDGET
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TacticalRadarWidget(
              distanceKm: transceiverState.peerDistance, // LIVE HARDWARE DISTANCE
              bearingDegrees: transceiverState.peerBearing, // LIVE HARDWARE BEARING
              targetName: widget.peerName,
            ),
          ),
          const SizedBox(height: 8),

          // HYBRID CHAT LOG UI
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F19),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: transceiverState.isRecording ? const Color(0xFFD2691E) : Colors.grey[800]!,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Tactical Header
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'ENCRYPTED TRANSCRIPT LOG',
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  // The Scrollable Chat History driven by Riverpod
                  Expanded(
                    child: ListView.builder(
                      reverse: true, // Auto-scrolls by pinning the list to the bottom
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: transceiverState.chatLogs.length,
                      itemBuilder: (context, index) {
                        final packet = transceiverState.chatLogs[index];
                        final time = "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
                        
                        return TransceiverChatBubble(
                          text: packet.text,
                          translatedText: packet.translatedText,
                          isSentByMe: packet.senderId == "Me",
                          time: time,
                        );
                      },
                    ),
                  ),

                  // Transmission indicator
                  if (transceiverState.isTransmitting)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Compressing to bytes...',
                            style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Symmetrical Tactical Console
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Silent Text Chat Terminal Button
                _buildConsoleButton(
                  icon: Icons.keyboard_alt_outlined,
                  label: 'CHAT',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _showManualTextInputSheet(),
                ),

                // 2. Quick Incident Presets Cloud Button
                _buildConsoleButton(
                  icon: Icons.cloud_sync_outlined,
                  label: 'QUICK',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _showQuickIncidentPresetsSheet(),
                ),

                // 3. Center Push-To-Talk Master Mic
                GestureDetector(
                  onTapDown: (_) {
                    if (!transceiverState.isRecording) {
                      ref.read(transceiverControllerProvider.notifier).startRecording();
                    }
                  },
                  onTapUp: (_) => ref.read(transceiverControllerProvider.notifier).stopAndTransmit(widget.peerName, _myLanguage, _myLanguage),
                  onTapCancel: () => ref.read(transceiverControllerProvider.notifier).stopAndTransmit(widget.peerName, _myLanguage, _myLanguage),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: transceiverState.isRecording ? 100 : 110,
                    width: transceiverState.isRecording ? 100 : 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: transceiverState.isRecording ? const Color(0xFFD2691E) : const Color(0xFF0B0F19),
                      border: Border.all(
                        color: transceiverState.isRecording ? const Color(0xFFD2691E) : const Color(0xFF6366F1),
                        width: 4,
                      ),
                      boxShadow: transceiverState.isRecording
                          ? [BoxShadow(color: const Color(0xFFD2691E).withOpacity(0.6), blurRadius: 25, spreadRadius: 8)]
                          : [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 15, spreadRadius: 3)],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mic,
                        size: 44,
                        color: transceiverState.isRecording ? Colors.black : const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ),

                // 4. VOX Automated Silence-Gated Send
                _buildConsoleButton(
                  icon: Icons.graphic_eq,
                  label: 'VOX',
                  color: transceiverState.isRecording ? const Color(0xFF10B981) : Colors.grey[700]!,
                  isActive: transceiverState.isRecording,
                  onTap: () {
                    if (transceiverState.isRecording) {
                      ref.read(transceiverControllerProvider.notifier).stopHandsFreeCall();
                    } else {
                      // FIXED: Calling the separated one-shot VOX method
                      ref.read(transceiverControllerProvider.notifier).startVoxMode(widget.peerName, _myLanguage);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
  Widget _buildConsoleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : const Color(0xFF1F2937),
              border: Border.all(color: color.withOpacity(0.6), width: 1.5),
            ),
            child: Icon(icon, color: isActive ? Colors.white : color, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showManualTextInputSheet() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DISPATCH SILENT TEXT',
              style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter mission payload...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0B0F19),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: Text('BEAM TO MESH', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (textController.text.trim().isNotEmpty) {
                    ref.read(transceiverControllerProvider.notifier).sendTextMessage(
                      textController.text.trim(),
                      widget.peerName,
                      _myLanguage,
                    );
                    Navigator.pop(sheetContext);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickIncidentPresetsSheet() {
    // EDIT THESE STRINGS TO CUSTOMIZE YOUR QUICK MESSAGES
    final presets = [
      'Help me',
      'I am injured',
      'I am dying',
      'Lost the way to out',
      'Trapped under debris',
      'Need Medical Extract',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TACTICAL PRESET PAYLOADS',
                  style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5),
                ),
                const Icon(Icons.bolt, color: Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 12),
            ...presets.map((msg) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    side: BorderSide(color: Colors.grey[800]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    ref.read(transceiverControllerProvider.notifier).sendTextMessage(
                      msg,
                      widget.peerName,
                      _myLanguage,
                    );
                    Navigator.pop(sheetContext);
                  },
                  child: Text(msg, style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// Helper widget for the red SOS buttons
class _EmergencyButton extends StatelessWidget {
  final String label;
  final Color color;

  const _EmergencyButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Navigator.pop(context); // Close the sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label Payload injected into network.'), backgroundColor: color),
          );
        },
        child: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }
}