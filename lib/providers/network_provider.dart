import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'transceiver_provider.dart';

/// Represents a peer node on the mesh
class DiscoveredUnit {
  final String id;
  final String callsign;
  final String protocol;
  final int signalStrength;
  final bool isEmergency; // Flag for priority triage

  DiscoveredUnit({
    required this.id,
    required this.callsign,
    required this.protocol,
    required this.signalStrength,
    this.isEmergency = false,
  });
}

class EmergencyStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setEmergency(bool value) => state = value;
  void toggle() => state = !state;
}

final emergencyStatusProvider = NotifierProvider<EmergencyStatusNotifier, bool>(
  () {
    return EmergencyStatusNotifier();
  },
);

class NetworkNotifier extends Notifier<List<DiscoveredUnit>> {
  final String _serviceId = "com.sih.vanigrid.mesh";
  bool _isWifiActive = false;
  bool _isBleActive = false;

  @override
  List<DiscoveredUnit> build() {
    return [];
  }

  List<DiscoveredUnit> _sortEmergencyFirst(List<DiscoveredUnit> list) {
    final copy = List<DiscoveredUnit>.from(list);
    copy.sort((a, b) {
      if (a.isEmergency && !b.isEmergency) return -1;
      if (!a.isEmergency && b.isEmergency) return 1;
      return b.signalStrength.compareTo(a.signalStrength);
    });
    return copy;
  }

  Future<void> setEmergencyMode(bool active) async {
    ref.read(emergencyStatusProvider.notifier).setEmergency(active);
    if (_isWifiActive || _isBleActive) {
      await stopScanning();
      await startScanning();
    }
  }

  Future<void> startScanning() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCallsign = prefs.getString('user_callsign') ?? "Unknown Unit";
    final isSos = ref.read(emergencyStatusProvider);

    // If SOS is active, prepend VG-SOS- so peers and drones parse it immediately
    final broadcastCallsign = isSos ? "VG-SOS-$rawCallsign" : "VG-$rawCallsign";

    await [
      Permission.location,
      Permission.nearbyWifiDevices,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    state = [];

    await _startWifiMesh(broadcastCallsign);
    await _startBleMesh(broadcastCallsign);
  }

  Future<void> _startWifiMesh(String broadcastCallsign) async {
    try {
      _isWifiActive = true;
      await Nearby().startAdvertising(
        broadcastCallsign,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (id, info) {
          ref.read(meshNetworkProvider).acceptIncomingConnection(id);
        },
        onConnectionResult: (id, status) {},
        onDisconnected: (id) {},
        serviceId: _serviceId,
      );

      await Nearby().startDiscovery(
        broadcastCallsign,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          if (state.any((unit) => unit.id == id)) return;

          final upperName = name.toUpperCase();
          final bool isEmergency =
              upperName.contains('SOS') ||
              upperName.contains('HELP') ||
              upperName.contains('VG-SOS-');

          final newUnit = DiscoveredUnit(
            id: id,
            callsign: name,
            protocol: 'WiFi',
            signalStrength: -45,
            isEmergency: isEmergency,
          );
          state = _sortEmergencyFirst([...state, newUnit]);
        },
        onEndpointLost: (id) {
          state = state.where((unit) => unit.id != id).toList();
        },
        serviceId: _serviceId,
      );
      debugPrint("SYSTEM LOG: Wi-Fi Direct Mesh Active ($broadcastCallsign).");
    } catch (e) {
      debugPrint("SYSTEM ERROR: Wi-Fi Mesh failed - $e");
    }
  }

  Future<void> _startBleMesh(String broadcastCallsign) async {
    try {
      _isBleActive = true;
      await FlutterBluePlus.startScan(continuousUpdates: true);

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          String deviceName = r.advertisementData.advName;
          if (deviceName.isEmpty) deviceName = r.device.platformName;

          if (deviceName.isNotEmpty) {
            final upperName = deviceName.toUpperCase();

            // Allow VaniGrid nodes, LoRa hardware, SOS broadcasts, or Drone relays
            if (upperName.contains('VANI') ||
                upperName.contains('VG-') ||
                upperName.contains('LORA') ||
                upperName.contains('SOS') ||
                upperName.contains('DRN_') ||
                deviceName.toLowerCase().contains('drn_')) {
              final bool isEmergency =
                  upperName.contains('SOS') ||
                  upperName.contains('HELP') ||
                  upperName.contains('VG-SOS-');

              final existingIndex = state.indexWhere(
                (unit) => unit.id == r.device.remoteId.str,
              );

              if (existingIndex >= 0) {
                final updatedState = [...state];
                updatedState[existingIndex] = DiscoveredUnit(
                  id: updatedState[existingIndex].id,
                  callsign: updatedState[existingIndex].callsign,
                  protocol: updatedState[existingIndex].protocol,
                  signalStrength: r.rssi,
                  isEmergency:
                      isEmergency || updatedState[existingIndex].isEmergency,
                );
                state = _sortEmergencyFirst(updatedState);
              } else {
                final newUnit = DiscoveredUnit(
                  id: r.device.remoteId.str,
                  callsign: deviceName,
                  protocol: 'BLE',
                  signalStrength: r.rssi,
                  isEmergency: isEmergency,
                );
                state = _sortEmergencyFirst([...state, newUnit]);
              }
            }
          }
        }
      });
      debugPrint("SYSTEM LOG: BLE Mesh Active.");
    } catch (e) {
      debugPrint("SYSTEM ERROR: BLE Scanner failed - $e");
    }
  }

  Future<void> stopScanning() async {
    if (_isWifiActive) {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      _isWifiActive = false;
    }

    if (_isBleActive) {
      await FlutterBluePlus.stopScan();
      _isBleActive = false;
    }

    state = [];
    debugPrint("SYSTEM LOG: All Mesh Radios Offline.");
  }
}

final networkProvider = NotifierProvider<NetworkNotifier, List<DiscoveredUnit>>(
  () {
    return NetworkNotifier();
  },
);
