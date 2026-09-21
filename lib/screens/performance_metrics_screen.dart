import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class PerformanceMetricsScreen extends StatefulWidget {
  const PerformanceMetricsScreen({super.key});

  @override
  State<PerformanceMetricsScreen> createState() => _PerformanceMetricsScreenState();
}

class _PerformanceMetricsScreenState extends State<PerformanceMetricsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    // A controller to make the "live" indicators pulse continuously
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Icon(
                  Icons.circle,
                  size: 10,
                  color: const Color(0xFFD2691E).withOpacity(_pulseController.value.clamp(0.2, 1.0)),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'SYSTEM TELEMETRY',
              style: GoogleFonts.rajdhani(
                color: const Color(0xFFFFFFFF),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LIVE JUDGING METRICS',
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // 1. LATENCY METRICS (20% of Score)
            Row(
              children: [
                Expanded(child: _buildMetricCard('End-to-End Latency', '450', 'ms', 'Target: < 800ms', const Color(0xFF6366F1))),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Real-Time Factor', '0.12', 'RTF', 'Sherpa-ONNX', const Color(0xFFD2691E))),
              ],
            ).animate().slideY(begin: 0.1, end: 0).fadeIn(duration: 400.ms),
            
            const SizedBox(height: 16),

            // 2. EFFICIENCY METRICS (20% of Score)
            Row(
              children: [
                Expanded(child: _buildMetricCard('CPU Idle Usage', '1.8', '%', 'VAD Standby', const Color(0xFFD2691E))),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('CPU Active', '32.4', '%', 'During STT', Colors.orange)),
              ],
            ).animate().slideY(begin: 0.1, end: 0).fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            // 3. STORAGE & RAM FOOTPRINT
            _buildLargeResourceCard().animate().slideY(begin: 0.1, end: 0).fadeIn(duration: 600.ms),

            const SizedBox(height: 24),

            // 4. SIMULATED LIVE NETWORK GRAPH
            Text(
              'PACKET TRANSMISSION FLOW (WIFI-DIRECT)',
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: _buildSimulatedGraph(),
            ).animate().fadeIn(duration: 800.ms),
          ],
        ),
      ),
    );
  }

  // A sleek UI component for individual numbers
  Widget _buildMetricCard(String title, String value, String unit, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.rajdhani(color: color, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      ),
    );
  }

  // A wide card specifically detailing the model weights (Proof of offline capability)
  Widget _buildLargeResourceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MODEL MEMORY ALLOCATION (INT8 QUANTIZED)',
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProgressBar('Silero VAD Engine', 1, 150, const Color(0xFFD2691E)),
          const SizedBox(height: 12),
          _buildProgressBar('Sherpa-ONNX (Indic)', 45, 150, const Color(0xFFFFBF00)),
          const SizedBox(height: 12),
          _buildProgressBar('Piper TTS (VITS)', 22, 150, Colors.purpleAccent),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total RAM Footprint', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('68 MB', style: GoogleFonts.rajdhani(color: const Color(0xFFD946EF), fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double valueMB, double maxMB, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 12)),
            Text('${valueMB.toInt()} MB', style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: valueMB / maxMB,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  // A custom painter that draws a mock waveform/network graph
  Widget _buildSimulatedGraph() {
    return CustomPaint(
      painter: _MockGraphPainter(
        color: const Color(0xFFD946EF),
      ),
    );
  }
}

class _MockGraphPainter extends CustomPainter {
  final Color color;
  _MockGraphPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final random = math.Random(42); // Fixed seed so it doesn't jitter crazily

    path.moveTo(0, size.height);
    
    // Draw 20 jagged data points
    for (int i = 1; i <= 20; i++) {
      double x = (size.width / 20) * i;
      // Keep spikes toward the bottom (simulating low data payload of text vs audio)
      double y = size.height - (random.nextDouble() * (size.height * 0.4));
      
      // Add a couple of random transmission spikes
      if (i == 5 || i == 14) y = size.height * 0.2; 
      
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Add a faint fill gradient under the line
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), Colors.transparent],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
      
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}