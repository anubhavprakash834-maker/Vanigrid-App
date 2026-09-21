import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../providers/network_provider.dart';
import 'transceiver_dashboard_screen.dart';
import 'hardware_pairing_sheet.dart';

class NetworkRadarScreen extends ConsumerStatefulWidget {
  const NetworkRadarScreen({super.key});

  @override
  ConsumerState<NetworkRadarScreen> createState() => _NetworkRadarScreenState();
}

class _NetworkRadarScreenState extends ConsumerState<NetworkRadarScreen> {
  String _myCallsign = "LOADING...";
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadMyIdentity();
  }

  Future<void> _loadMyIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myCallsign = prefs.getString('user_callsign') ?? "UNKNOWN NODE";
    });
  }

  void _toggleScan() {
    setState(() => _isScanning = !_isScanning);
    if (_isScanning) {
      ref.read(networkProvider.notifier).startScanning();
    } else {
      ref.read(networkProvider.notifier).stopScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoveredUnits = ref.watch(networkProvider);
    final isEmergencyActive = ref.watch(emergencyStatusProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final bool shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
            title: Text(
              'SEVER CONNECTION?',
              style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            content: Text(
              'This will drop your node from the mesh network and shut down the offline transceivers.',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('STAY ONLINE', style: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('DISCONNECT', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ?? false;

        if (shouldExit) {
          ref.read(networkProvider.notifier).stopScanning();
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'OMNI-BEARER MESH',
            style: GoogleFonts.rajdhani(
              color: const Color(0xFFFFBF00),
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.memory, color: Color(0xFFF59E0B)),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => const HardwarePairingSheet(),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Color(0xFF070814)],
                ),
              ),
            ),

            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/radar_grid.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Local Identity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isEmergencyActive ? const Color(0xFF450A0A) : const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEmergencyActive ? const Color(0xFFEF4444) : const Color(0xFFFFBF00).withOpacity(0.3),
                        width: isEmergencyActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEmergencyActive ? 'BROADCASTING EMERGENCY BEACON' : 'LOCAL BROADCAST ID',
                              style: GoogleFonts.inter(
                                color: isEmergencyActive ? const Color(0xFFFCA5A5) : Colors.grey[400],
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isEmergencyActive ? 'VG-SOS-$_myCallsign' : _myCallsign,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Icon(
                          isEmergencyActive ? Icons.warning_amber_rounded : Icons.broadcast_on_personal,
                          color: isEmergencyActive ? const Color(0xFFEF4444) : const Color(0xFFFFBF00),
                          size: 28,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // RADAR & EMERGENCY SOS CLUSTER
                  SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Radar Circle
                        GestureDetector(
                          onTap: _toggleScan,
                          child: Container(
                            height: 190,
                            width: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isEmergencyActive 
                                    ? const Color(0xFFEF4444) 
                                    : (_isScanning ? const Color(0xFFD2691E) : Colors.grey[800]!),
                                width: 2,
                              ),
                              boxShadow: [
                                if (_isScanning || isEmergencyActive)
                                  BoxShadow(
                                    color: (isEmergencyActive ? const Color(0xFFEF4444) : const Color(0xFFD2691E)).withOpacity(0.2),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEmergencyActive 
                                        ? Icons.emergency 
                                        : (_isScanning ? Icons.radar : Icons.power_settings_new_rounded),
                                    color: isEmergencyActive 
                                        ? const Color(0xFFEF4444) 
                                        : (_isScanning ? const Color(0xFFD2691E) : Colors.grey[600]),
                                    size: 46,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isEmergencyActive 
                                        ? 'SOS ACTIVE' 
                                        : (_isScanning ? 'SCANNING...' : 'TAP TO SCAN'),
                                    style: GoogleFonts.inter(
                                      color: isEmergencyActive 
                                          ? const Color(0xFFEF4444) 
                                          : (_isScanning ? const Color(0xFFD2691E) : Colors.grey[600]),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // SOS / HELP BUTTON (Upper Right Quadrant)
                        Positioned(
                          top: 4,
                          right: 8,
                          child: GestureDetector(
                            onTap: () async {
                              final current = ref.read(emergencyStatusProvider);
                              await ref.read(networkProvider.notifier).setEmergencyMode(!current);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isEmergencyActive ? const Color(0xFFEF4444) : const Color(0xFF1F2937),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isEmergencyActive ? Colors.white : const Color(0xFFEF4444),
                                  width: 1.5,
                                ),
                                boxShadow: isEmergencyActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFEF4444).withOpacity(0.5),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEmergencyActive ? Icons.warning_rounded : Icons.sos_rounded,
                                    color: isEmergencyActive ? Colors.white : const Color(0xFFEF4444),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isEmergencyActive ? 'SOS ON' : 'Help',
                                    style: GoogleFonts.rajdhani(
                                      color: isEmergencyActive ? Colors.white : const Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Discovered Units Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DISCOVERED UNITS (${discoveredUnits.length})',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Unit List (Priority SOS units at the top)
                  Expanded(
                    child: ListView.builder(
                      itemCount: discoveredUnits.length,
                      itemBuilder: (context, index) {
                        final unit = discoveredUnits[index];
                        final isSos = unit.isEmergency;

                        Color protocolColor = const Color(0xFFFFBF00);
                        IconData protocolIcon = Icons.wifi;

                        if (unit.protocol == 'BLE') {
                          protocolColor = const Color(0xFF3B82F6);
                          protocolIcon = Icons.bluetooth;
                        } else if (unit.protocol == 'LoRa') {
                          protocolColor = const Color(0xFFF59E0B);
                          protocolIcon = Icons.satellite_alt;
                        }

                        if (isSos) {
                          protocolColor = const Color(0xFFEF4444);
                          protocolIcon = Icons.warning_rounded;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSos ? const Color(0xFF2E0808) : const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSos ? const Color(0xFFEF4444) : Colors.transparent,
                              width: isSos ? 1.5 : 0,
                            ),
                            boxShadow: isSos
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: protocolColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(protocolIcon, color: protocolColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            unit.callsign,
                                            style: GoogleFonts.inter(
                                              color: isSos ? const Color(0xFFFCA5A5) : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSos) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'URGENT',
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      isSos ? '🚨 EMERGENCY ACTIVE • ${unit.signalStrength}dBm' : '[${unit.protocol}] Signal: ${unit.signalStrength}dBm',
                                      style: GoogleFonts.inter(
                                        color: isSos ? const Color(0xFFEF4444) : protocolColor,
                                        fontSize: 12,
                                        fontWeight: isSos ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSos ? const Color(0xFFEF4444) : const Color(0xFFFBBF24),
                                  foregroundColor: isSos ? Colors.white : Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TransceiverDashboardScreen(
                                        peerName: unit.callsign,
                                        connectionType: unit.protocol,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  isSos ? 'COMM' : 'PAIR',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}