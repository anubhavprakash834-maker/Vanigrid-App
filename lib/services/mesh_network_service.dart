import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/transmission_packet.dart';

class MeshNetworkService {
  String activeProtocol = 'wifi'; // 'wifi', 'ble', or 'lora'
  
  final _incomingPacketController = StreamController<TransmissionPacket>.broadcast();
  Stream<TransmissionPacket> get incomingPackets => _incomingPacketController.stream;

  // --- HARDWARE ABSTRACTION LAYER VARIABLES ---
  final List<String> _connectedWifiEndpoints = [];
  
  // --- ESP32 GROUND LORA BRIDGE VARIABLES ---
  BluetoothDevice? _esp32Bridge;
  BluetoothCharacteristic? _loraWriteChar; 
  BluetoothCharacteristic? _loraReadChar;  

  // --- ESP32 AIRBORNE DRONE RELAY VARIABLES ---
  BluetoothDevice? _droneBridge;
  BluetoothCharacteristic? _droneWriteChar;
  BluetoothCharacteristic? _droneReadChar;
  bool isDroneConnected = false;

  // Standard Nordic UART UUIDs
  final String _uartServiceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String _uartRxUuid      = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; 
  final String _uartTxUuid      = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; 

  // ==============================================================================
  // 1. WI-FI DIRECT MESH LAYER
  // ==============================================================================

  Future<void> connectToPeer(String myCallsign, String targetEndpointId) async {
    try {
      await Nearby().requestConnection(
        myCallsign,
        targetEndpointId,
        onConnectionInitiated: (id, info) async => await _acceptAndListen(id),
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED && !_connectedWifiEndpoints.contains(id)) {
            _connectedWifiEndpoints.add(id);
          }
        },
        onDisconnected: (id) => _connectedWifiEndpoints.remove(id),
      );
    } catch (e) {
      debugPrint("NETWORK ERROR: Wi-Fi Connection failed - $e");
    }
  }

  Future<void> acceptIncomingConnection(String endpointId) async {
    await _acceptAndListen(endpointId);
  }

  Future<void> _acceptAndListen(String endpointId) async {
    await Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (id, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          _handleIncomingBytes(payload.bytes!);
        }
      },
      onPayloadTransferUpdate: (id, update) {},
    );
  }

  // ==============================================================================
  // 2. ESP32 GROUND LORA BRIDGE LAYER
  // ==============================================================================

  Future<void> connectToLoRaBridge(BluetoothDevice device) async {
    try {
      debugPrint("HARDWARE LOG: Initiating BLE handshake with Ground LoRa Bridge...");
      await device.connect(license: License.nonprofit);
      _esp32Bridge = device;

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == _uartServiceUuid.toUpperCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == _uartRxUuid.toUpperCase()) {
              _loraWriteChar = characteristic;
            } else if (characteristic.uuid.toString().toUpperCase() == _uartTxUuid.toUpperCase()) {
              _loraReadChar = characteristic;
              await _loraReadChar!.setNotifyValue(true);
              _loraReadChar!.onValueReceived.listen((List<int> value) {
                _handleIncomingBytes(Uint8List.fromList(value));
              });
            }
          }
        }
      }

      if (_loraWriteChar != null && _loraReadChar != null) {
        debugPrint("HARDWARE LOG: ESP32 LoRa Ground Bridge Armed.");
        activeProtocol = 'lora';
      } else {
        throw Exception("UART Characteristics not found on LoRa device.");
      }
    } catch (e) {
      debugPrint("HARDWARE ERROR: Failed to bridge ESP32 - $e");
      await device.disconnect();
      rethrow;
    }
  }

  // ==============================================================================
  // 3. AIRBORNE DRONE RELAY LAYER (drn_)
  // ==============================================================================

  Future<void> connectToDroneBridge(BluetoothDevice device) async {
    try {
      debugPrint("HARDWARE LOG: Handshaking with Airborne Drone Relay...");
      await device.connect(license: License.nonprofit);
      _droneBridge = device;

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == _uartServiceUuid.toUpperCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == _uartRxUuid.toUpperCase()) {
              _droneWriteChar = characteristic;
            } else if (characteristic.uuid.toString().toUpperCase() == _uartTxUuid.toUpperCase()) {
              _droneReadChar = characteristic;
              await _droneReadChar!.setNotifyValue(true);
              _droneReadChar!.onValueReceived.listen((List<int> value) {
                // Packets captured in mid-air and streamed down to the app
                _handleIncomingBytes(Uint8List.fromList(value));
              });
            }
          }
        }
      }

      if (_droneWriteChar != null && _droneReadChar != null) {
        isDroneConnected = true;
        debugPrint("HARDWARE LOG: Airborne Drone Bridge Successfully Linked.");
      } else {
        throw Exception("UART Characteristics not found on Drone module.");
      }
    } catch (e) {
      debugPrint("HARDWARE ERROR: Failed to bridge Drone ESP32 - $e");
      await device.disconnect();
      rethrow;
    }
  }

  // ==============================================================================
  // 4. MULTI-LINK PACKET DISPATCH
  // ==============================================================================

  Future<void> transmitPacket(TransmissionPacket packet) async {
    final jsonString = packet.toJsonString();
    final bytes = utf8.encode(jsonString);

    // Relay via ground LoRa if active
    if (activeProtocol == 'lora' && _loraWriteChar != null) {
      await _loraWriteChar!.write(bytes, withoutResponse: true);
      debugPrint("NETWORK LOG: Transmitted ${bytes.length} bytes to Ground LoRa.");
    }

    // Mirror to airborne drone if connected to rebroadcast over altitude
    if (_droneWriteChar != null) {
      await _droneWriteChar!.write(bytes, withoutResponse: true);
      debugPrint("NETWORK LOG: Transmitted ${bytes.length} bytes to Airborne Drone.");
    }

    // Wi-Fi fallback
    if (activeProtocol == 'wifi' && _connectedWifiEndpoints.isNotEmpty) {
      for (String endpointId in _connectedWifiEndpoints) {
        await Nearby().sendBytesPayload(endpointId, Uint8List.fromList(bytes));
      }
    }
  }

  void _handleIncomingBytes(Uint8List data) {
    try {
      final jsonString = utf8.decode(data);
      debugPrint("NETWORK LOG: Packet intercepted -> $jsonString");
      final packet = TransmissionPacket.fromJsonString(jsonString);
      _incomingPacketController.add(packet);
    } catch (e) {
      debugPrint("NETWORK ERROR: Corrupted byte packet received.");
    }
  }
  
  void dispose() {
    Nearby().stopAllEndpoints();
    _connectedWifiEndpoints.clear();
    _esp32Bridge?.disconnect();
    _droneBridge?.disconnect();
    _incomingPacketController.close();
  }
}