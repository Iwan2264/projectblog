import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D47A1), 
      brightness: Brightness.light,
      
      // --- Main Background Color ---
      surface: const Color.fromARGB(255, 211, 233, 255),
      onSurface: const Color(0xFF1C2A3A),
 

      // --- Primary Colors ---
      primary: const Color(0xFF0D47A1),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD1E0FF),
      onPrimaryContainer: const Color(0xFF001B3E),

      // --- Surface & Container Variants (Lowest to Highest) ---
      surfaceContainerLowest: const Color(0xFFF0F4F8),
      surfaceContainerLow: const Color(0xFFF5F8FA),
      surfaceContainer: const Color(0xFFFAFCFE),
      surfaceContainerHigh: const Color(0xFFFCFEFF),
      surfaceContainerHighest: const Color(0xFFFFFFFF),
    ),
  );

  // --- DARK THEME ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D47A1), 
      brightness: Brightness.dark,

      // --- Main Background Color ---
      surface: const Color(0xFF1A2238),
      onSurface: const Color(0xFFE2E8F0),

      // --- Primary Colors ---
      primary: const Color(0xFFA8C8FF),
      onPrimary: const Color(0xFF003062),
      primaryContainer: const Color(0xFF283A5E),
      onPrimaryContainer: const Color(0xFFD6E3FF),

      // --- Surface & Container Variants (Lowest to Highest) ---
      surfaceContainerLowest: const Color(0xFF1A2238),
      surfaceContainerLow: const Color(0xFF1C253B),
      surfaceContainer: const Color(0xFF1F283F),
      surfaceContainerHigh: const Color(0xFF242D44),
      surfaceContainerHighest: const Color(0xFF283248),
    ),
  );
}