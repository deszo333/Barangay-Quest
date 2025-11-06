import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors adapted from the website's CSS variables
  static const Color bg = Color(0xFF071B26); // --bg
  static const Color bg2 = Color(0xFF0B2736); // --bg-2
  static const Color card = Color(0xFF14394D); // --card
  static const Color muted = Color(0xFF90A9B9); // --muted
  static const Color accent = Color(0xFF1FB6FF); // --accent
  static const Color accent2 = Color(0xFFFF8A3D); // --accent-2
  static const Color white = Color(0xFFF7FBFF); // --white

  static ThemeData dark() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final colorScheme = const ColorScheme.dark(
      primary: accent,
      onPrimary: Color(0xFF052130),
      secondary: accent2,
      onSecondary: Color(0xFF1A1A1A),
      surface: bg2,
      surfaceContainerHighest: bg2,
      surfaceContainerHigh: bg2,
      surfaceContainer: bg2,
      surfaceContainerLow: bg2,
      surfaceContainerLowest: bg2,
      onSurface: white,
      background: bg,
      onBackground: white,
      outline: Color(0xFF274A60),
      outlineVariant: card,
      scrim: Colors.black54,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme.apply(
      bodyColor: white,
      displayColor: white,
    ));

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xE6081A24), // rgba(8,26,36,.9)
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: white,
        ),
      ),
      cardTheme: CardTheme(
        color: bg2,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: card, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: white,
        textColor: white,
      ),
      dividerTheme: const DividerThemeData(color: card, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          foregroundColor: WidgetStateProperty.all(const Color(0xFF052130)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accent.withOpacity(.5);
            }
            return accent;
          }),
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(.08)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            const BorderSide(color: Color(0x80FFFFFF)),
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
          overlayColor: WidgetStateProperty.all(Colors.white24),
        ),
      ),
    );
  }
}
