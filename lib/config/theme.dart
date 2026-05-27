import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoxoraColors {
  // Brand Colors Extracted from Logo
  static const primaryPop = Color(0xFF00D2D3); // Vibrant Cyan from Logo Chat Bubble
  static const secondaryPop = Color(0xFF7C4DFF); // Vibrant Purple from Logo Center
  static const accentPop = Color(0xFFFF5252); // Vibrant Coral from Logo Wave
  static const warningPop = Color(0xFFFF4B4B); // Bright Red
  
  // Semantic Colors (required by app)
  static const rose = accentPop;
  static const teal = primaryPop;
  static const brand = primaryPop;
  static const amber = Color(0xFFFFB400);
  static const green = Color(0xFF00C853);
  static const orange = Color(0xFFFF8A00);
  static const slate = Color(0xFF64748B);

  // Dark Theme Colors (Matched from Logo Background)
  static const darkBg = Color(0xFF1D242B); // Deep Slate from Dark Logo
  static const darkCard = Color(0xFF263038); // Slightly lighter slate for cards
  static const darkBorder = Color(0xFF333E48); // Subtle border

  // Light Theme Colors (Matched from Logo Background)
  static const lightBg = Color(0xFFFAF7F0); // Warm Cream from Light Logo
  static const lightCard = Color(0xFFFFFFFF); // Pure White cards for contrast
  static const lightBorder = Color(0xFFE8E5DF); // Subtle matching border
}

class VoxoraTheme {
  static ThemeData light() => _buildTheme(
        brightness: Brightness.light,
        scaffold: VoxoraColors.lightBg,
        surface: VoxoraColors.lightCard,
        onSurface: const Color(0xFF0F172A),
        primary: VoxoraColors.primaryPop,
        secondary: VoxoraColors.secondaryPop,
        border: VoxoraColors.lightBorder,
      );

  static ThemeData dark() => _buildTheme(
        brightness: Brightness.dark,
        scaffold: VoxoraColors.darkBg,
        surface: VoxoraColors.darkCard,
        onSurface: const Color(0xFFF8FAFC),
        primary: VoxoraColors.primaryPop,
        secondary: VoxoraColors.secondaryPop,
        border: VoxoraColors.darkBorder,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color primary,
    required Color secondary,
    required Color border,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: onSurface,
      error: VoxoraColors.warningPop,
    );

    // Nunito provides a very friendly, fun, rounded appearance
    final textTheme = GoogleFonts.nunitoTextTheme(
      brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.nunito(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface.withValues(alpha: 0.8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border, width: 2),
          backgroundColor: surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? VoxoraColors.darkBg : VoxoraColors.lightBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurface.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 2,
        space: 2,
      ),
    );
  }
}
