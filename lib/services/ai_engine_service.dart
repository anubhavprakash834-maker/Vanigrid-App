import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class AIEngineService {
  bool isInitialized = false;
  OfflineRecognizer? _sttRecognizer;
  final FlutterTts _flutterTts = FlutterTts();

  Future<String> _extractModelToStorage(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${assetPath.split('/').last}');

    if (!await file.exists()) {
      await file.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
    }
    return file.path;
  }

  /// Initializes the Sherpa-ONNX engine with Hybrid Architecture Support
  Future<void> initializeModels(String language) async {
    try {
      initBindings();
      OfflineRecognizerConfig config;

      if (language == 'English') {
        // 1. ARCHITECTURE: ZIPFORMER TRANSDUCER (For English)
        String encoderPath = await _extractModelToStorage('assets/models/encoder.onnx');
        String decoderPath = await _extractModelToStorage('assets/models/decoder.onnx');
        String joinerPath = await _extractModelToStorage('assets/models/joiner.onnx');
        String tokensPath = await _extractModelToStorage('assets/models/tokens.txt');

        config = OfflineRecognizerConfig(
          model: OfflineModelConfig(
            transducer: OfflineTransducerModelConfig(
              encoder: encoderPath,
              decoder: decoderPath,
              joiner: joinerPath,
            ),
            tokens: tokensPath,
            numThreads: 2, 
            debug: false,
          ),
        );
      } else {
        // 2. ARCHITECTURE: INDIC-CONFORMER CTC (For SIH Indic Languages)
        final dir = await getApplicationDocumentsDirectory();
        final langDir = '${dir.path}/models/$language';
        
        String modelPath = '$langDir/model.onnx';
        String tokensPath = '$langDir/tokens.txt';

        if (!await File(modelPath).exists()) {
          debugPrint("SYSTEM ERROR: $language models not found. Reverting to English.");
          return await initializeModels('English'); 
        }

        config = OfflineRecognizerConfig(
          model: OfflineModelConfig(
            nemoCtc: OfflineNemoEncDecCtcModelConfig(
              model: modelPath,
            ),
            tokens: tokensPath,
            numThreads: 2, 
            debug: false,
          ),
        );
      }
      
      _sttRecognizer = OfflineRecognizer(config);
      isInitialized = true;
      debugPrint("SYSTEM LOG: Engine Hot-Swapped to $language.");
      
    } catch (e) {
      debugPrint("SYSTEM ERROR: Failed to allocate .onnx weights - $e");
    }
  }

  Future<String> transcribeAudioStream(List<double> pcmData) async {
    if (!isInitialized) return "Error: Engine offline.";
    
    if (_sttRecognizer != null && pcmData.isNotEmpty) {
      final stream = _sttRecognizer!.createStream();
      stream.acceptWaveform(sampleRate: 16000, samples: Float32List.fromList(pcmData));
      
      _sttRecognizer!.decode(stream);
      final result = _sttRecognizer!.getResult(stream);
      
      stream.free(); 
      return result.text;
    }
    
    return "No audio data received.";
  }

  Future<void> synthesizeTextToSpeech(String text, String language) async {
    String languageCode = 'en-US';
    if (language == 'Hindi') languageCode = 'hi-IN';
    if (language == 'Tamil') languageCode = 'ta-IN';
    
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setSpeechRate(0.5); 
    await _flutterTts.setVolume(1.0);
    
    debugPrint("SYSTEM LOG: Speaking '$text' in $languageCode.");
    await _flutterTts.speak(text);
  }
}