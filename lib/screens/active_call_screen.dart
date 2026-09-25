import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;

import '../providers/transceiver_provider.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final String peerName;
  final String connectionType;

  const ActiveCallScreen({
    super.key,
    required this.peerName,
    required this.connectionType,
  });

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // IGNITE THE HANDS-FREE VAD PIPELINE ON BOOT
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = ref.read(transceiverControllerProvider).systemLanguage;
      // FIX: Use the Continuous Duplex method so the mic doesn't turn off after 1 sentence
      ref.read(transceiverControllerProvider.notifier).startContinuousCall(widget.peerName, lang);
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDurationSeconds++);
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _waveformController.dispose();
    super.dispose();
  }

  void _endCall() {
    ref.read(transceiverControllerProvider.notifier).stopHandsFreeCall();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('P2P Call Terminated. Transcript saved to Dashboard.')),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live microphone volume from the VAD engine
    final currentVolume = ref.watch(transceiverControllerProvider).currentVolume;
    
    // Scale the RMS value (usually 0.0 to 0.1) to an amplitude multiplier for the UI
    final visualAmplitude = (currentVolume * 15).clamp(0.2, 2.5);

   return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Kills the microphone hardware stream when swiping back or closing the call
        ref.read(transceiverControllerProvider.notifier).stopHandsFreeCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                    onPressed: _endCall,
                  ),
                  Row(
                    children: [
                      Icon(
                        widget.connectionType == 'wifi' ? Icons.wifi : Icons.bluetooth,
                        color: const Color(0xFFFFBF00),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ENCRYPTED P2P',
                        style: GoogleFonts.inter(color: const Color(0xFFFFFFFF), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32), 
                ],
              ),
            ),

            const SizedBox(height: 40),

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFBF00).withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(currentVolume > 0.03 && !_isMuted ? 0.6 : 0.1), 
                    blurRadius: 30, 
                    spreadRadius: 5
                  )
                ],
              ),
              child: const Icon(Icons.person, size: 64, color: Colors.white),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 24),
            
            Text(
              widget.peerName,
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_callDurationSeconds),
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 16, letterSpacing: 2.0),
            ),

            const Spacer(),

            // LIVE HARDWARE AUDIO WAVEFORM
            SizedBox(
              height: 100,
              child: AnimatedBuilder(
                animation: _waveformController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ContinuousWaveformPainter(
                      progress: _waveformController.value,
                      amplitude: _isMuted ? 0.1 : visualAmplitude,
                      color: _isMuted ? Colors.grey[600]! : const Color(0xFFD2691E),
                    ),
                    size: const Size(double.infinity, 100),
                  );
                },
              ),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.white : Colors.grey[800]!,
                    iconColor: _isMuted ? Colors.black : Colors.white,
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      if (_isMuted) {
                        ref.read(transceiverControllerProvider.notifier).stopHandsFreeCall();
                      } else {
                        final lang = ref.read(transceiverControllerProvider).systemLanguage;
                        ref.read(transceiverControllerProvider.notifier).startContinuousCall(widget.peerName, lang);
                      }
                    },
                  ),
                  
                  _buildCallButton(
                    icon: Icons.call_end,
                    color: const Color(0xFFEF4444),
                    iconColor: Colors.white,
                    size: 72,
                    iconSize: 36,
                    onTap: _endCall,
                  ),

                  _buildCallButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    color: _isSpeakerOn ? Colors.white : Colors.grey[800]!,
                    iconColor: _isSpeakerOn ? Colors.black : Colors.white,
                    onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon, 
    required Color color, 
    required Color iconColor,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

class _ContinuousWaveformPainter extends CustomPainter {
  final double progress;
  final double amplitude;
  final Color color;

  _ContinuousWaveformPainter({required this.progress, required this.amplitude, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    
    for (double i = 0; i <= size.width; i += 10) {
      final xOffset = (i / size.width) * math.pi * 4;
      final timeOffset = progress * math.pi * 2;
      
      // Multiplied by the live hardware amplitude
      double wave1 = math.sin(xOffset - timeOffset) * 20 * amplitude;
      double wave2 = math.cos((xOffset * 1.5) - timeOffset * 1.2) * 10 * amplitude;
      
      double taper = 1.0 - (2 * (i / size.width - 0.5).abs());
      final y = centerY + ((wave1 + wave2) * taper);

      if (i == 0) {
        path.moveTo(i, y);
      } else {
        path.lineTo(i, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ContinuousWaveformPainter oldDelegate) => 
    oldDelegate.progress != progress || oldDelegate.amplitude != amplitude; 
}