import 'dart:convert';

class TransmissionPacket {
  final String text;
  final String translatedText;
  final String spokenLang;
  final String outputLang;
  final double lat;
  final double lon;
  final String senderId;
  final bool isSos;
  final int sentTimestamp; // NEW: For latency calculation
  final int packetSizeBytes; // NEW: For compression telemetry

  TransmissionPacket({
    required this.text,
    required this.translatedText,
    required this.spokenLang,
    required this.outputLang,
    required this.lat,
    required this.lon,
    required this.senderId,
    this.isSos = false,
    required this.sentTimestamp,
    required this.packetSizeBytes,
  });

  String toJsonString() {
    return jsonEncode({
      't': text,
      'tr': translatedText,
      'sl': spokenLang,
      'ol': outputLang,
      'la': lat,
      'lo': lon,
      'id': senderId,
      'sos': isSos ? 1 : 0,
      'ts': sentTimestamp,
    });
  }

  factory TransmissionPacket.fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr);
    return TransmissionPacket(
      text: map['t'] ?? '',
      translatedText: map['tr'] ?? '',
      spokenLang: map['sl'] ?? 'English',
      outputLang: map['ol'] ?? 'English',
      lat: (map['la'] ?? 0.0).toDouble(),
      lon: (map['lo'] ?? 0.0).toDouble(),
      senderId: map['id'] ?? 'Unknown',
      isSos: map['sos'] == 1,
      sentTimestamp: map['ts'] ?? DateTime.now().millisecondsSinceEpoch,
      packetSizeBytes: jsonStr.length, // Byte size of the received JSON string
    );
  }
}