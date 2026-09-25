import 'dart:io';
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AIEngineService {
  bool isInitialized = false;
  OfflineRecognizer? _sttRecognizer;
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> initializeModels(String language) async {
    try {
      initBindings();
      OfflineRecognizerConfig config;

      final dir = await getApplicationDocumentsDirectory();
      final langDir = '${dir.path}/models/$language';

      if (language == 'English') {
        // Validate Moonshine architecture
        if (!await File('$langDir/encode.int8.onnx').exists()) {
           throw Exception("English Neural weights missing from edge storage.");
        }

        config = OfflineRecognizerConfig(
          model: OfflineModelConfig(
            moonshine: OfflineMoonshineModelConfig(
              preprocessor: '$langDir/preprocess.onnx',
              encoder: '$langDir/encode.int8.onnx',
              uncachedDecoder: '$langDir/uncached_decode.int8.onnx',
              cachedDecoder: '$langDir/cached_decode.int8.onnx',
            ),
            tokens: '$langDir/tokens.txt',
            numThreads: 2, 
            debug: false,
          ),
        );
      } else {
        // Validate Indic-Conformer architecture
        String modelPath = '$langDir/model.onnx';
        String tokensPath = '$langDir/tokens.txt';

        if (!await File(modelPath).exists()) {
          throw Exception("$language models not found. Download required.");
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
      isInitialized = false;
      rethrow;
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
    
    await _flutterTts.speak(text);
  }
}