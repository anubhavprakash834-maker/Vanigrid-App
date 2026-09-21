import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NEW: Required for Hardware UI Control
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. FORCE IMMERSIVE STICKY MODE (Hides Nav/Status Bars)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const ProviderScope(child: VaniGridApp()));
}

class VaniGridApp extends StatelessWidget {
  const VaniGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaniGrid Transceiver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primaryColor: const Color(0xFFEC4899),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        // 2. PROFESSIONAL TACTICAL SCREEN ANIMATIONS
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(), 
    );
  }
}