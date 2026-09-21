import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class TacticalRadarWidget extends StatelessWidget {
  final double distanceKm;
  final double bearingDegrees;
  final String targetName;

  const TacticalRadarWidget({
    super.key,
    required this.distanceKm,
    required this.bearingDegrees,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2691E).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Compass UI
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                ),
                // The pointing arrow based on GPS bearing
                Transform.rotate(
                  angle: bearingDegrees * (math.pi / 180),
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: Icon(Icons.navigation, color: Color(0xFFD2691E), size: 20),
                  ),
                ),
                const Icon(Icons.my_location, color: Colors.white, size: 12),
              ],
            ),
          ).animate().shimmer(duration: 2000.ms),
          
          const SizedBox(width: 16),
          
          // Distance & Coordinates Data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS LOCK: $targetName',
                  style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      distanceKm.toStringAsFixed(1),
                      style: GoogleFonts.rajdhani(color: const Color(0xFFD2691E), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('KM AWAY', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10)),
                    ),
                  ],
                ),
                Text(
                  'Heading: ${bearingDegrees.toInt()}° (Line of Sight)',
                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}