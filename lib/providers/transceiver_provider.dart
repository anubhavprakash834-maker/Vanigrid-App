import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_engine_service.dart';
import '../services/mesh_network_service.dart';
import '../models/transmission_packet.dart';

final aiEngineProvider = Provider<AIEngineService>((ref) => AIEngineService());
final meshNetworkProvider = Provider<MeshNetworkService>((ref) => MeshNetworkService());

TranslateLanguage _getMlKitLanguage(String lang) {
  switch (lang) {
    case 'Hindi': return TranslateLanguage.hindi;
    case 'Gujarati': return TranslateLanguage.gujarati;
    case 'Marathi': return TranslateLanguage.marathi;
    case 'Kannada': return TranslateLanguage.kannada;
    case 'Tamil': return TranslateLanguage.tamil;
    case 'Telugu': return TranslateLanguage.telugu;
    case 'Bengali': return TranslateLanguage.bengali;
    case 'English': 
    default: 
      return TranslateLanguage.english;
  }
}

class TransceiverState {
  final bool isRecording;
  final bool isTransmitting;
  final String liveText;
  final List<TransmissionPacket> chatLogs;
  final double peerDistance; 
  final double peerBearing;  
  final String systemLanguage; 
  final double currentVolume; // Powers the Active Call Waveform

  TransceiverState({
    this.isRecording = false,
    this.isTransmitting = false,
    this.liveText = "",
    this.chatLogs = const [],
    this.peerDistance = 0.0,
    this.peerBearing = 0.0,
    this.systemLanguage = 'Hindi',
    this.currentVolume = 0.0,
  });

  TransceiverState copyWith({
    bool? isRecording,
    bool? isTransmitting,
    String? liveText,
    List<TransmissionPacket>? chatLogs,
    double? peerDistance,
    double? peerBearing,
    String? systemLanguage,
    double? currentVolume,
  }) {
    return TransceiverState(
      isRecording: isRecording ?? this.isRecording,
      isTransmitting: isTransmitting ?? this.isTransmitting,
      liveText: liveText ?? this.liveText,
      chatLogs: chatLogs ?? this.chatLogs,
      peerDistance: peerDistance ?? this.peerDistance,
      peerBearing: peerBearing ?? this.peerBearing,
      systemLanguage: systemLanguage ?? this.systemLanguage,
      currentVolume: currentVolume ?? this.currentVolume,
    );
  }
}

class TransceiverNotifier extends Notifier<TransceiverState> {
  StreamSubscription? _packetSubscription;
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micStreamSub;
  final List<double> _pcmFloatBuffer = [];
  
  bool _isHandsFreeActive = false;

  @override
  TransceiverState build() {
    final network = ref.read(meshNetworkProvider);
    
    _packetSubscription = network.incomingPackets.listen((packet) {
      _handleIncomingPacket(packet);
    });

    ref.onDispose(() {
      _packetSubscription?.cancel();
      _micStreamSub?.cancel();
      _audioRecorder.dispose();
    });

    return TransceiverState();
  }

  void setSystemLanguage(String lang) {
    state = state.copyWith(systemLanguage: lang);
  }

  Future<Position?> _resolveOfflinePosition() async {
    try {
      Position? cached = await Geolocator.getLastKnownPosition();
      if (cached != null) return cached;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(milliseconds: 1200),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleIncomingPacket(TransmissionPacket packet) async {
    String finalTranslated = packet.text;

    if (packet.spokenLang != state.systemLanguage) {
      try {
        final sourceLang = _getMlKitLanguage(packet.spokenLang);
        final targetLang = _getMlKitLanguage(state.systemLanguage);

        if (sourceLang != targetLang) {
          final translator = OnDeviceTranslator(sourceLanguage: sourceLang, targetLanguage: targetLang);
          finalTranslated = await translator.translateText(packet.text);
          await translator.close();
        }
      } catch (e) {
        debugPrint("TRANSLATION ERROR: $e");
      }
    }

    final localizedPacket = TransmissionPacket(
      text: packet.text,
      translatedText: finalTranslated,
      spokenLang: packet.spokenLang,
      outputLang: state.systemLanguage,
      lat: packet.lat,
      lon: packet.lon,
      senderId: packet.senderId,
    );

    ref.read(aiEngineProvider).synthesizeTextToSpeech(finalTranslated, state.systemLanguage);
    
    double newDist = state.peerDistance;
    double newBearing = state.peerBearing;

    final myPos = await _resolveOfflinePosition();
    if (myPos != null && packet.lat != 0.0 && packet.lon != 0.0) {
      newDist = Geolocator.distanceBetween(myPos.latitude, myPos.longitude, packet.lat, packet.lon) / 1000.0;
      newBearing = Geolocator.bearingBetween(myPos.latitude, myPos.longitude, packet.lat, packet.lon);
    }

    state = state.copyWith(
      chatLogs: [...state.chatLogs, localizedPacket],
      peerDistance: newDist,
      peerBearing: newBearing,
    );
  }

  // ============================================================================
  // HANDS-FREE ACTIVE CALL LOGIC (VAD)
  // ============================================================================
  
  Future<void> startHandsFreeCall(String peerName, String lang) async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    _isHandsFreeActive = true;
    state = state.copyWith(isRecording: true);
    
    List<double> sentenceBuffer = [];
    bool isSpeaking = false;
    int silenceFrames = 0;

    final stream = await _audioRecorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));

    _micStreamSub = stream.listen((Uint8List data) {
      if (!_isHandsFreeActive) return;

      final byteData = ByteData.sublistView(data);
      List<double> chunkFloats = [];
      double energy = 0.0;

      for (int i = 0; i < byteData.lengthInBytes - 1; i += 2) {
        final sample = byteData.getInt16(i, Endian.little) / 32768.0;
        chunkFloats.add(sample);
        energy += sample * sample;
      }

      // Calculate Root Mean Square for Voice Activity Detection
      double rms = math.sqrt(energy / chunkFloats.length);
      state = state.copyWith(currentVolume: rms); // Power the UI Waveform

      // VAD Threshold Logic
      if (rms > 0.03) { 
        isSpeaking = true;
        silenceFrames = 0;
        sentenceBuffer.addAll(chunkFloats);
      } else {
        if (isSpeaking) {
          sentenceBuffer.addAll(chunkFloats);
          silenceFrames++;
          // ~1.5 seconds of silence detected, chop the sentence and send!
          if (silenceFrames > 8) {
            isSpeaking = false;
            final completedSentence = List<double>.from(sentenceBuffer);
            sentenceBuffer.clear();
            _processAndTransmitChunk(completedSentence, lang);
          }
        }
      }
    });
  }

  Future<void> stopHandsFreeCall() async {
    _isHandsFreeActive = false;
    await _micStreamSub?.cancel();
    await _audioRecorder.stop();
    state = state.copyWith(isRecording: false, currentVolume: 0.0);
  }

  Future<void> _processAndTransmitChunk(List<double> pcmData, String lang) async {
    if (pcmData.isEmpty) return;

    final aiEngine = ref.read(aiEngineProvider);
    final network = ref.read(meshNetworkProvider);

    final transcribedText = await aiEngine.transcribeAudioStream(pcmData);
    if (transcribedText.trim().isEmpty) return;

    double myLat = 0.0, myLon = 0.0;
    final myPos = await _resolveOfflinePosition();
    if (myPos != null) {
      myLat = myPos.latitude;
      myLon = myPos.longitude;
    }

    final prefs = await SharedPreferences.getInstance();
    final myCallsign = prefs.getString('user_callsign') ?? "Unknown Unit";

    final packet = TransmissionPacket(
      text: transcribedText,
      translatedText: transcribedText,
      spokenLang: lang,
      outputLang: lang,
      lat: myLat,
      lon: myLon,
      senderId: myCallsign,
    );

    await network.transmitPacket(packet);

    final localPacket = TransmissionPacket(
      text: transcribedText,
      translatedText: transcribedText,
      spokenLang: lang,
      outputLang: lang,
      lat: myLat,
      lon: myLon,
      senderId: "Me",
    );

    state = state.copyWith(chatLogs: [...state.chatLogs, localPacket]);
  }

  // ============================================================================
  // STANDARD WALKIE-TALKIE PTT LOGIC
  // ============================================================================

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    state = state.copyWith(isRecording: true, isTransmitting: false);
    _pcmFloatBuffer.clear();

    final stream = await _audioRecorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));

    _micStreamSub = stream.listen((Uint8List data) {
      final byteData = ByteData.sublistView(data);
      for (int i = 0; i < byteData.lengthInBytes - 1; i += 2) {
        _pcmFloatBuffer.add(byteData.getInt16(i, Endian.little) / 32768.0);
      }
    });
  }

  Future<void> stopAndTransmit(String peerName, String spokenLang, String outputLang) async {
    if (!state.isRecording) return;
    state = state.copyWith(isRecording: false, isTransmitting: true);
    await _micStreamSub?.cancel();
    await _audioRecorder.stop();
    await _processAndTransmitChunk(_pcmFloatBuffer, spokenLang);
    state = state.copyWith(isTransmitting: false);
  }
}

final transceiverControllerProvider = NotifierProvider<TransceiverNotifier, TransceiverState>(() {
  return TransceiverNotifier();
});