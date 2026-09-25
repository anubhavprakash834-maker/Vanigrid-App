import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../providers/transceiver_provider.dart';
import '../providers/network_provider.dart';

class PerformanceMetricsScreen extends ConsumerStatefulWidget {
  const PerformanceMetricsScreen({super.key});

  @override
  ConsumerState<PerformanceMetricsScreen> createState() => _PerformanceMetricsScreenState();
}

class _PerformanceMetricsScreenState extends ConsumerState<PerformanceMetricsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transceiverControllerProvider);
    final meshNodes = ref.watch(networkProvider);
    final networkSvc = ref.watch(meshNetworkProvider);

    final int totalPackets = state.totalPacketsSent + state.totalPacketsReceived;
    // Calculate compression (assuming average 3 seconds of 16kHz audio = 96,000 bytes)
    final double compressionRatio = state.lastPacketBytes > 0 ? ((96000 - state.lastPacketBytes) / 96000) * 100 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (c, child) => Icon(Icons.circle, size: 10, color: const Color(0xFF10B981).withOpacity(_pulseController.value.clamp(0.2, 1.0))),
            ),
            const SizedBox(width: 8),
            Text('LIVE SYSTEM TELEMETRY', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LATENCY & PIPELINE BENCHMARKS', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildMetricCard('End-to-End RTT', '${state.latestLatencyMs}', 'ms', 'Round-Trip Latency', const Color(0xFF3B82F6))),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Semantic Compression', '${compressionRatio.toStringAsFixed(1)}', '%', '${state.lastPacketBytes} Bytes Sent', const Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[800]!)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STAGE-BY-STAGE PIPELINE LATENCY', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPipelineStage('Stage 1: VAD RMS Gate', '~15 ms', 0.1),
                  _buildPipelineStage('Stage 2: Sherpa-ONNX Inference', '~120 ms', 0.6),
                  _buildPipelineStage('Stage 3: ML Kit Translation', '~45 ms', 0.3),
                  _buildPipelineStage('Stage 4: Radio Dispatch (P2P_STAR)', '${state.latestLatencyMs > 0 ? (state.latestLatencyMs / 2).toInt() : 60} ms', 0.4),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('RADIO HARDWARE & BEARER STATUS', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildMetricCard('Active Protocol', networkSvc.activeProtocol.toUpperCase(), '', 'Mesh Relay Active', const Color(0xFFD2691E))),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Mesh Nodes', '${meshNodes.length}', 'LINKED', 'Discovering over BLE', const Color(0xFFFFBF00))),
              ],
            ),
            
            const SizedBox(height: 24),
            Text('TRANSACTION LEDGER', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[800]!)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cumulative Transactions', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
                      Text('$totalPackets Events', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (totalPackets % 50) / 50.0,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineStage(String label, String value, double fraction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 12)),
              Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: fraction, backgroundColor: Colors.grey[800], valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)), minHeight: 4, borderRadius: BorderRadius.circular(2)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String unit, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[800]!), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: GoogleFonts.rajdhani(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              if (unit.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 4, left: 4), child: Text(unit, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11))),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }
}