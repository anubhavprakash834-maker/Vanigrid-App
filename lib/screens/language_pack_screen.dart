import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/language_pack_provider.dart';

class LanguagePackScreen extends ConsumerStatefulWidget {
  const LanguagePackScreen({super.key});

  @override
  ConsumerState<LanguagePackScreen> createState() => _LanguagePackScreenState();
}

class _LanguagePackScreenState extends ConsumerState<LanguagePackScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _highlightedLang;

  @override
  void initState() {
    super.initState();
    _detectLocationAndSuggest();
  }

  Future<void> _detectLocationAndSuggest() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 2)));
      final lat = pos.latitude;
      final lon = pos.longitude;

      String suggested = 'English';

      if (lat >= 20.1 && lat <= 24.7 && lon >= 68.1 && lon <= 74.5) suggested = 'Gujarati';
      else if (lat >= 15.6 && lat <= 22.0 && lon >= 72.6 && lon <= 80.9) suggested = 'Marathi';
      else if (lat >= 8.0 && lat <= 13.5 && lon >= 76.2 && lon <= 80.3) suggested = 'Tamil';
      else if (lat >= 11.5 && lat <= 18.5 && lon >= 74.0 && lon <= 78.6) suggested = 'Kannada';
      else if (lat >= 12.6 && lat <= 19.9 && lon >= 76.7 && lon <= 84.8) suggested = 'Telugu';
      else if (lat >= 21.5 && lat <= 27.2 && lon >= 85.8 && lon <= 89.9) suggested = 'Bengali';
      else if (lat >= 17.8 && lat <= 22.6 && lon >= 81.4 && lon <= 87.5) suggested = 'Odia';
      else suggested = 'Hindi'; // Default fallback for Northern/Central states

      setState(() => _highlightedLang = suggested);

      // Auto-Scroll Math (Approximating item heights)
      final allLangs = ref.read(languagePackProvider).keys.toList();
      final index = allLangs.indexOf(suggested);
      if (index > 2) {
        _scrollController.animateTo(
          index * 90.0, 
          duration: const Duration(milliseconds: 800), 
          curve: Curves.easeOutCubic,
        );
      }

      // Remove the highlight glow after 2.5 seconds
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _highlightedLang = null);
      });
    } catch (_) {} // Ignore timeout gracefully
  }

  @override
  Widget build(BuildContext context) {
    final downloadStates = ref.watch(languagePackProvider);
    final languages = downloadStates.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFFBF00), size: 20), onPressed: () => Navigator.pop(context)),
        title: Text('NEURAL LANGUAGE PACKS', style: GoogleFonts.rajdhani(color: const Color(0xFFFFBF00), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DYNAMIC EDGE ALLOCATION', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text('Based on your offline GPS coordinates, the system auto-suggests regional phonetic models for your operating theater.', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final progress = downloadStates[language]!;
                  return _buildLanguageCard(context, language, progress, language == _highlightedLang);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, String language, double progress, bool isHighlighted) {
    bool isCompleted = progress == -1.0;
    bool isDownloading = progress > 0.0 && progress < 1.0;
    bool isError = progress == -2.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF1E3A8A) : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF3B82F6) : (isCompleted ? const Color(0xFFD2691E).withOpacity(0.5) : Colors.grey[800]!),
          width: isHighlighted ? 2.5 : 1.5,
        ),
        boxShadow: isHighlighted ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.4), blurRadius: 15, spreadRadius: 2)] : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isCompleted ? Icons.memory : Icons.public, color: isCompleted ? const Color(0xFFD2691E) : Colors.grey[400], size: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(language, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(isCompleted ? 'Allocated on Edge (~50MB)' : (isError ? 'Download Failed' : 'Cloud Repository (~50MB)'), style: GoogleFonts.inter(color: isCompleted ? const Color(0xFFD2691E) : (isError ? Colors.red : Colors.grey[500]), fontSize: 11)),
                ],
              ),
            ],
          ),
          _buildActionArea(language, progress, isCompleted, isDownloading),
        ],
      ),
    );
  }

  Widget _buildActionArea(String language, double progress, bool isCompleted, bool isDownloading) {
    if (isCompleted) return const Icon(Icons.check_circle_rounded, color: Color(0xFFD2691E), size: 28);
    if (isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(width: 32, height: 32, child: CircularProgressIndicator(value: progress, strokeWidth: 3, backgroundColor: Colors.grey[800], color: const Color(0xFFFFBF00))),
          Text('${(progress * 100).toInt()}%', style: GoogleFonts.inter(color: const Color(0xFFFFBF00), fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.cloud_download_outlined, color: Color(0xFFFFBF00), size: 28),
      onPressed: () => ref.read(languagePackProvider.notifier).downloadLanguagePack(language),
    );
  }
}