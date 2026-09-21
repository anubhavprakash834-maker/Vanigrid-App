import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'performance_metrics_screen.dart';
import 'active_call_screen.dart';
import 'tactical_radar_widget.dart';
import 'transceiver_chat_bubble.dart';
import '../providers/transceiver_provider.dart';

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
  String _myLanguage = 'Hindi'; // Unified System Language

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
                      onChanged: (val) async { // <-- 1. Added 'async' here
                        if (val == null) return;
                        setState(() => _myLanguage = val);
                        ref.read(transceiverControllerProvider.notifier).setSystemLanguage(val);
                        
                        // HOT-SWAP THE NEURAL ENGINE NATIVELY
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Hot-Swapping Neural Engine to $val...'),
                          backgroundColor: const Color(0xFF3B82F6),
                        ));
                        
                        // Tells C++ to drop the English weights and load the regional pack
                        await ref.read(aiEngineProvider).initializeModels(val);
                        
                        if (!mounted || !context.mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$val Engine Online.'),
                          backgroundColor: const Color(0xFFD2691E),
                        ));
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

          // Massive Walkie-Talkie Button Area
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
            ),
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => ref.read(transceiverControllerProvider.notifier).startRecording(),
                onTapUp: (_) => ref.read(transceiverControllerProvider.notifier).stopAndTransmit(widget.peerName, _myLanguage, _myLanguage),
                onTapCancel: () => ref.read(transceiverControllerProvider.notifier).stopAndTransmit(widget.peerName, _myLanguage, _myLanguage),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: transceiverState.isRecording ? 110 : 130,
                  width: transceiverState.isRecording ? 110 : 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: transceiverState.isRecording ? const Color(0xFFD2691E) : const Color(0xFF0B0F19),
                    border: Border.all(
                      color: transceiverState.isRecording ? const Color(0xFFD2691E) : const Color(0xFF6366F1),
                      width: 4,
                    ),
                    boxShadow: transceiverState.isRecording
                        ? [BoxShadow(color: const Color(0xFFD2691E).withOpacity(0.6), blurRadius: 30, spreadRadius: 10)]
                        : [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.mic,
                      size: 48,
                      color: transceiverState.isRecording ? Colors.black : const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
        ],
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