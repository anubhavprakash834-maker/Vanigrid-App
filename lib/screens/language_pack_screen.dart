import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_pack_provider.dart';

class LanguagePackScreen extends ConsumerWidget {
  const LanguagePackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the global map of download progress
    final downloadStates = ref.watch(languagePackProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFBF00), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NEURAL LANGUAGE PACKS',
          style: GoogleFonts.rajdhani(color: const Color(0xFFFFBF00), fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DYNAMIC EDGE ALLOCATION',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Download regional acoustic models directly to your local hardware. Models operate 100% offline via Sherpa-ONNX architecture once downloaded.',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 24),
            
            // The dynamic list of languages
            Expanded(
              child: ListView.builder(
                itemCount: downloadStates.keys.length,
                itemBuilder: (context, index) {
                  final language = downloadStates.keys.elementAt(index);
                  final progress = downloadStates[language]!;
                  
                  return _buildLanguageCard(context, ref, language, progress);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, WidgetRef ref, String language, double progress) {
    bool isCompleted = progress == -1.0;
    bool isDownloading = progress > 0.0 && progress < 1.0;
    bool isError = progress == -2.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? const Color(0xFFD2691E).withOpacity(0.5) : Colors.grey[800]!,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Dynamic Status Icon
              Icon(
                isCompleted ? Icons.memory : Icons.public,
                color: isCompleted ? const Color(0xFFD2691E) : Colors.grey[400],
                size: 24,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    isCompleted ? 'Allocated on Edge (~50MB)' : (isError ? 'Download Failed' : 'Cloud Repository (~50MB)'),
                    style: GoogleFonts.inter(color: isCompleted ? const Color(0xFFD2691E) : (isError ? Colors.red : Colors.grey[500]), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          // Action Area (Button, Progress Ring, or Checkmark)
          _buildActionArea(ref, language, progress, isCompleted, isDownloading),
        ],
      ),
    );
  }

  Widget _buildActionArea(WidgetRef ref, String language, double progress, bool isCompleted, bool isDownloading) {
    if (isCompleted) {
      return const Icon(Icons.check_circle_rounded, color: Color(0xFFD2691E), size: 28);
    } 
    
    if (isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.grey[800],
              color: const Color(0xFFFFBF00),
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.inter(color: const Color(0xFFFFBF00), fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    // Default Download Button
    return IconButton(
      icon: const Icon(Icons.cloud_download_outlined, color: Color(0xFFFFBF00), size: 28),
      onPressed: () {
        ref.read(languagePackProvider.notifier).downloadLanguagePack(language);
      },
    );
  }
}