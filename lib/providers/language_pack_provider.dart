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
    case 'English': 
    default: 
      return TranslateLanguage.english;
  }
}

class LanguagePackNotifier extends Notifier<Map<String, double>> {
  final Dio _dio = Dio();

  // Dynamic file mapping for Hugging Face raw URLs
  final Map<String, Map<String, String>> _modelUrls = {
    'English': {
      'preprocess.onnx': 'https://huggingface.co/csukuangfj/sherpa-onnx-moonshine-tiny-en-int8/resolve/main/preprocess.onnx',
      'encode.int8.onnx': 'https://huggingface.co/csukuangfj/sherpa-onnx-moonshine-tiny-en-int8/resolve/main/encode.int8.onnx',
      'uncached_decode.int8.onnx': 'https://huggingface.co/csukuangfj/sherpa-onnx-moonshine-tiny-en-int8/resolve/main/uncached_decode.int8.onnx',
      'cached_decode.int8.onnx': 'https://huggingface.co/csukuangfj/sherpa-onnx-moonshine-tiny-en-int8/resolve/main/cached_decode.int8.onnx',
      'tokens.txt': 'https://huggingface.co/csukuangfj/sherpa-onnx-moonshine-tiny-en-int8/resolve/main/tokens.txt',
    },
    'Hindi': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Marathi': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Gujarati': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Kannada': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Malayalam': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Tamil': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Telugu': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Odia': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
    'Bengali': {
      'model.onnx': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/model.int8.onnx',
      'tokens.txt': 'https://huggingface.co/meetsync/indic-conformer-onnx-sherpa/resolve/main/tokens.txt',
    },
  };

  @override
  Map<String, double> build() {
    Future.microtask(() => _verifyExistingDownloads());
    
    // English is no longer bundled by default
    return {
      'English': 0.0, 
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

  Future<void> _verifyExistingDownloads() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelManager = OnDeviceTranslatorModelManager();
    Map<String, double> updatedState = Map.from(state);

    for (String lang in _modelUrls.keys) {
      final langDir = Directory('${dir.path}/models/$lang');
      bool hasAllFiles = true;

      // Ensure every single required file exists for the specific architecture
      for (String fileName in _modelUrls[lang]!.keys) {
        if (!await File('${langDir.path}/$fileName').exists()) {
          hasAllFiles = false;
          break;
        }
      }

      final mlKitLang = _getMlKitLanguage(lang);
      bool hasText = true;
      if (mlKitLang != TranslateLanguage.english) {
        hasText = await modelManager.isModelDownloaded(mlKitLang.bcpCode);
      }

      if (hasAllFiles && hasText) {
        updatedState[lang] = -1.0; 
      }
    }
    
    state = updatedState;
  }

  Future<void> downloadLanguagePack(String language) async {
    if (!_modelUrls.containsKey(language)) return;

    state = {...state, language: 0.01}; 
    final filesToDownload = _modelUrls[language]!;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final langDir = Directory('${dir.path}/models/$language');
      if (!await langDir.exists()) await langDir.create(recursive: true);

      int filesCompleted = 0;
      int totalFiles = filesToDownload.length;

      // Iteratively download all required .onnx and token files
      for (var entry in filesToDownload.entries) {
        String fileName = entry.key;
        String url = entry.value;

        await _dio.download(
          url,
          '${langDir.path}/$fileName',
          onReceiveProgress: (rec, total) {
            if (total != -1) {
              double fileProgress = rec / total;
              double overallProgress = ((filesCompleted + fileProgress) / totalFiles) * 0.70;
              state = {...state, language: overallProgress};
            }
          },
        );
        filesCompleted++;
      }

      state = {...state, language: 0.85}; 
      final modelManager = OnDeviceTranslatorModelManager();
      
      Future<void> ensureModelReady(TranslateLanguage lang) async {
        final bcpCode = lang.bcpCode;
        if (!await modelManager.isModelDownloaded(bcpCode)) {
          final success = await modelManager.downloadModel(bcpCode, isWifiRequired: false)
            .timeout(const Duration(seconds: 60), onTimeout: () => false);
          if (!success) throw Exception("OS Blocked Translation Download.");
        }
      }

      await ensureModelReady(TranslateLanguage.english);
      final mlKitLang = _getMlKitLanguage(language);
      if (mlKitLang != TranslateLanguage.english) await ensureModelReady(mlKitLang);
      
      state = {...state, language: -1.0}; 

    } catch (e) {
      debugPrint("SYSTEM ERROR: Failed to download $language pack -> $e");
      state = {...state, language: -2.0}; 
    }
  }
}

final languagePackProvider = NotifierProvider<LanguagePackNotifier, Map<String, double>>(() {
  return LanguagePackNotifier();
});