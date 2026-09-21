import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../providers/transceiver_provider.dart';

class HardwarePairingSheet extends ConsumerStatefulWidget {
  const HardwarePairingSheet({super.key});

  @override
  ConsumerState<HardwarePairingSheet> createState() => _HardwarePairingSheetState();
}

class _HardwarePairingSheetState extends ConsumerState<HardwarePairingSheet> {
  bool _isScanning = false;
  bool _isConnecting = false;
  int _selectedTab = 0; // 0 = Ground LoRa, 1 = Airborne Drone
  List<ScanResult> _allDiscovered = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _startHardwareScan();
  }

  Future<void> _startHardwareScan() async {
    setState(() => _isScanning = true);
    _allDiscovered.clear();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() => _allDiscovered = results);
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    if (mounted) setState(() => _isScanning = false);
  }

  List<ScanResult> _getFilteredDevices() {
    return _allDiscovered.where((r) {
      final name = r.advertisementData.advName.isNotEmpty 
          ? r.advertisementData.advName 
          : r.device.platformName;
      if (name.isEmpty) return false;

      final upperName = name.toUpperCase();
      final isDrone = name.toLowerCase().contains('drn_') || upperName.contains('DRN_') || upperName.contains('DRONE');

      if (_selectedTab == 0) {
        // Ground LoRa: Reject drone prefixes, allow LoRa hardware
        return !isDrone && (
          upperName.contains('VANI') || 
          upperName.contains('ESP32') || 
          upperName.contains('LORA') || 
          upperName.contains('UART')
        );
      } else {
        // Airborne Drone: Require drn_ prefix
        return isDrone;
      }
    }).toList();
  }

  Future<void> _pairWithBridge(BluetoothDevice device, bool isDrone) async {
    setState(() => _isConnecting = true);
    await FlutterBluePlus.stopScan();

    try {
      final networkService = ref.read(meshNetworkProvider);
      
      if (isDrone) {
        await networkService.connectToDroneBridge(device);
      } else {
        await networkService.connectToLoRaBridge(device);
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDrone ? 'Airborne Drone Bridge Active. Aerial Relay sniffing beacons.' : 'ESP32 LoRa Ground Bridge Armed & Active.',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDrone ? const Color(0xFF06B6D4) : const Color(0xFFD2691E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Handshake failed: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = _getFilteredDevices();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HARDWARE BRIDGE',
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                  ),
                  Text(
                    _selectedTab == 0 ? 'Tactical Ground Transceiver' : 'Airborne Drone Aerial Relay (drn_)',
                    style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
              if (_isScanning && !_isConnecting)
                const SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(color: Color(0xFFF59E0B), strokeWidth: 2),
                )
              else if (!_isConnecting)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFFFFBF00)),
                  onPressed: _startHardwareScan,
                ),
            ],
          ),
          
          const SizedBox(height: 20),

          // DUAL-CHANNEL SELECTOR (Ground LoRa vs Drone Relay)
          Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  index: 0,
                  label: 'GROUND LORA',
                  icon: Icons.satellite_alt,
                  accentColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTabButton(
                  index: 1,
                  label: 'DRONE RELAY',
                  icon: Icons.flight_takeoff,
                  accentColor: const Color(0xFF06B6D4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1F2937), thickness: 2),
          const SizedBox(height: 12),

          if (_isConnecting)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: _selectedTab == 0 ? const Color(0xFFD2691E) : const Color(0xFF06B6D4)),
                    const SizedBox(height: 16),
                    Text('Securing UART Telemetry Channel...', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else if (filteredDevices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  _isScanning 
                      ? 'Scanning frequencies...' 
                      : (_selectedTab == 0 ? 'No ground LoRa modules found in range.' : 'No drone relay found (name must include "drn_").'),
                  style: GoogleFonts.inter(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredDevices.length,
                itemBuilder: (context, index) {
                  final result = filteredDevices[index];
                  final deviceName = result.advertisementData.advName.isNotEmpty 
                      ? result.advertisementData.advName 
                      : result.device.platformName;
                  final isDrone = _selectedTab == 1;
                  final accentColor = isDrone ? const Color(0xFF06B6D4) : const Color(0xFFF59E0B);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withOpacity(0.4)),
                    ),
                    child: ListTile(
                      leading: Icon(isDrone ? Icons.airplanemode_active : Icons.memory, color: accentColor),
                      title: Text(deviceName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(result.device.remoteId.str, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor.withOpacity(0.15),
                          foregroundColor: accentColor,
                          side: BorderSide(color: accentColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _pairWithBridge(result.device, isDrone),
                        child: const Text('PAIR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon, required Color accentColor}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.15) : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? accentColor : Colors.grey[800]!, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? accentColor : Colors.grey[500], size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.rajdhani(color: isSelected ? Colors.white : Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}