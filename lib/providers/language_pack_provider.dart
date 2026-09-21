import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

TranslateLanguage _getMlKitLanguage(String lang) {
  switch (lang) {
    case 'Hindi': return TranslateLanguage.hindi;
    case 'Gujarati': return TranslateLanguage.gujarati;
    case 'Marathi': return TranslateLanguage.marathi;
    case 'Kannada': return TranslateLanguage.kannada;
    case 'Tamil': return TranslateLanguage.tamil;
    case 'Telugu': return TranslateLanguage.telugu;
    case 'Bengali': return TranslateLanguage.bengali;
    // Note: Odia and Malayalam fallback to English to prevent crashes 
    // as they are not natively supported by offline ML Kit yet.
    case 'English': 
    default: 
      return TranslateLanguage.english;
  }
}

class LanguagePackNotifier extends Notifier<Map<String, double>> {
  final Dio _dio = Dio();

  final Map<String, Map<String, String>> _modelUrls = {
    'Hindi': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Marathi': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Gujarati': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Kannada': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Malayalam': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Tamil': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Telugu': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Odia': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Bengali': {
      'model': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
  };

  @override
  Map<String, double> build() {
    // Kicks off the background hard drive scan the second the app opens
    Future.microtask(() => _verifyExistingDownloads());
    
    return {
      'English': -1.0, 
      'Hindi': 0.0,
      'Marathi': 0.0,
      'Gujarati': 0.0,
      'Kannada': 0.0,
      'Malayalam': 0.0,
      'Tamil': 0.0,
      'Telugu': 0.0,
      'Odia': 0.0,
      'Bengali': 0.0,
    };
  }

  // NEW: Scans the physical storage to update the UI on app restart
  Future<void> _verifyExistingDownloads() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelManager = OnDeviceTranslatorModelManager();
    
    Map<String, double> updatedState = Map.from(state);

    for (String lang in _modelUrls.keys) {
      // 1. Check if the Hugging Face Audio Models exist on the hard drive
      final langDir = Directory('${dir.path}/models/$lang');
      final modelFile = File('${langDir.path}/model.onnx');
      final tokensFile = File('${langDir.path}/tokens.txt');
      
      bool hasAcoustic = await modelFile.exists() && await tokensFile.exists();

      // 2. Check if the Google ML Kit Text Models exist in the OS cache
      final mlKitLang = _getMlKitLanguage(lang);
      bool hasText = true;
      if (mlKitLang != TranslateLanguage.english) {
        hasText = await modelManager.isModelDownloaded(mlKitLang.bcpCode);
      }

      // If both physical files are found, instantly flip the UI to the Green Checkmark!
      if (hasAcoustic && hasText) {
        updatedState[lang] = -1.0; 
      }
    }
    
    state = updatedState;
  }

  Future<void> downloadLanguagePack(String language) async {
    if (!_modelUrls.containsKey(language)) {
      debugPrint("SYSTEM ERROR: No direct URLs mapped for $language.");
      return;
    }

    state = {...state, language: 0.01}; 
    final urls = _modelUrls[language]!;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final langDir = Directory('${dir.path}/models/$language');
      if (!await langDir.exists()) await langDir.create(recursive: true);

      // 1. Download IndicConformer Unified Model (INT8)
      await _dio.download(
        urls['model']!,
        '${langDir.path}/model.onnx',
        onReceiveProgress: (rec, total) {
          if (total != -1) {
            // Allocate 70% of the UI progress bar to the audio model
            state = {...state, language: (rec / total) * 0.70};
          }
        },
      );

      // 2. Download Tokens
      await _dio.download(
        urls['tokens']!,
        '${langDir.path}/tokens.txt',
      );

      // 3. Cache Google ML Kit Translation Models Offline
      state = {...state, language: 0.85}; 
      debugPrint("SYSTEM LOG: Verifying Google ML Kit translation weights for $language...");
      
      final modelManager = OnDeviceTranslatorModelManager();
      
      // Helper function to smartly handle the OS DownloadManager queue
      Future<void> ensureModelReady(TranslateLanguage lang) async {
        final bcpCode = lang.bcpCode;
        final isDownloaded = await modelManager.isModelDownloaded(bcpCode);
        
        if (!isDownloaded) {
          debugPrint("SYSTEM LOG: Instructing OS to download ML Kit model: $bcpCode...");
          
          // Execute download with a strict 60-second fallback
          final success = await modelManager.downloadModel(
            bcpCode, 
            isWifiRequired: false,
          ).timeout(
            const Duration(seconds: 60), 
            onTimeout: () => false, // Catch silent hangs
          );
          
          if (!success) {
            throw Exception("OS DownloadManager blocked the task. Check Data Saver/Wi-Fi.");
          }
        } else {
          debugPrint("SYSTEM LOG: ML Kit model $bcpCode already securely cached.");
        }
      }

      // Ensure the English pivot model is cached
      await ensureModelReady(TranslateLanguage.english);
      
      // Ensure the requested regional language model is cached
      final mlKitLang = _getMlKitLanguage(language);
      if (mlKitLang != TranslateLanguage.english) {
        await ensureModelReady(mlKitLang);
      }
      
      state = {...state, language: -1.0}; // 100% Complete
      debugPrint("SYSTEM LOG: $language Acoustic & Text Translation packs fully secured on edge storage.");

    } catch (e) {
      debugPrint("SYSTEM ERROR: Failed to download $language pack -> $e");
      state = {...state, language: -2.0}; // Flip UI to Red Error State
    }
  }
}

final languagePackProvider = NotifierProvider<LanguagePackNotifier, Map<String, double>>(() {
  return LanguagePackNotifier();
});