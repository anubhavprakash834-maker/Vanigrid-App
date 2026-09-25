import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String _getCardinalDirection(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'N';
    if (deg >= 22.5 && deg < 67.5) return 'NE';
    if (deg >= 67.5 && deg < 112.5) return 'E';
    if (deg >= 112.5 && deg < 157.5) return 'SE';
    if (deg >= 157.5 && deg < 202.5) return 'S';
    if (deg >= 202.5 && deg < 247.5) return 'SW';
    if (deg >= 247.5 && deg < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {
    final double normalizedBearing = (bearingDegrees % 360 + 360) % 360;
    final double rotationRadians = normalizedBearing * (math.pi / 180);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2691E).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD2691E).withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
        ],
      ),
      child: Row(
        children: [
          // 360-Degree Continuous Vector Dial
          SizedBox(
            height: 72,
            width: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Static outer dial
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[800]!, width: 2),
                    gradient: RadialGradient(
                      colors: [const Color(0xFF1F2937), const Color(0xFF0B0F19)],
                    ),
                  ),
                ),
                // Cardinal indicators
                Positioned(top: 4, child: Text('N', style: GoogleFonts.rajdhani(color: const Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold))),
                Positioned(bottom: 4, child: Text('S', style: GoogleFonts.rajdhani(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.bold))),
                Positioned(right: 4, child: Text('E', style: GoogleFonts.rajdhani(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.bold))),
                Positioned(left: 4, child: Text('W', style: GoogleFonts.rajdhani(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.bold))),
                
                // Live vector needle rotated by GPS bearing
                Transform.rotate(
                  angle: rotationRadians,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation, color: Color(0xFFD2691E), size: 24),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Center node point
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Distance & Bearings Data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TACTICAL BEARING: $targetName',
                      style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2691E).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getCardinalDirection(normalizedBearing),
                        style: GoogleFonts.rajdhani(color: const Color(0xFFD2691E), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      distanceKm.toStringAsFixed(2),
                      style: GoogleFonts.rajdhani(color: const Color(0xFFD2691E), fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('KM RANGE', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(
                  'Vector Azimuth: ${normalizedBearing.toInt()}° (Relative to True North)',
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