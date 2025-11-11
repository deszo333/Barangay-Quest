// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- NEW: Colors from the inspiration image ---
  static const Color bg = Color(0xFF1C1E2D); // Dark background
  static const Color bg2 = Color(0xFF25283E); // Lighter card background
  static const Color card = Color(0xFF3B3E5B); // Lighter card/border
  static const Color accent = Color(0xFF007BFF); // Example blue
  static const Color accent2 = Color(0xFFFFA500); // Example orange
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFA0A3BD);
  // --- END NEW ---

  static ThemeData dark() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final colorScheme = const ColorScheme.dark(
      primary: accent,
      onPrimary: white,
      secondary: accent2,
      onSecondary: bg,
      surface: bg, // Use bg for surface
      surfaceContainerHighest: bg2, // Use bg2 for cards
      surfaceContainerHigh: bg2,
      surfaceContainer: bg2,
      surfaceContainerLow: bg2,
      surfaceContainerLowest: bg2,
      onSurface: white,
      outline: card,
      outlineVariant: Color(0xFF2A2D43),
      scrim: Colors.black54,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme.apply(
      bodyColor: muted, // Default text is muted
      displayColor: white, // Headlines are white
    ));

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      
      // --- NEW AppBarTheme ---
      appBarTheme: AppBarTheme(
        backgroundColor: bg, // Match scaffold
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: white,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: bg2,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: white,
        textColor: white,
      ),
      dividerTheme: const DividerThemeData(color: card, thickness: 1, space: 1),
      
      // --- NEW Button Themes ---
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          foregroundColor: WidgetStateProperty.all(white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accent.withAlpha(100);
            }
            return accent;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            const BorderSide(color: card),
          ),
          foregroundColor: WidgetStateProperty.all(white),
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(white),
        ),
      ),
    );
  }
}