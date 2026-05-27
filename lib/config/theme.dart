import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoxoraColors {
  // Fun, solid, vibrant colors (No gradients!)
  static const primaryPop = Color(0xFFFF5A5F); // Watermelon Pink
  static const secondaryPop = Color(0xFF00A699); // Ocean Blue
  static const accentPop = Color(0xFFFFB400); // Sunshine Yellow
  static const warningPop = Color(0xFFFF4B4B); // Bright Red
  
  // Semantic Colors (required by app)
  static const rose = warningPop;
  static const teal = secondaryPop;
  static const brand = primaryPop;
  static const amber = accentPop;
  static const green = secondaryPop;
  static const orange = Color(0xFFFF8A00);
  static const slate = Color(0xFF64748B);

  // Soft Dark Theme Colors
  static const darkBg = Color(0xFF0B192C);
  static const darkCard = Color(0xFF1A2B45);
  static const darkBorder = Color(0xFF2E4057);

  // Soft Light Theme Colors
  static const lightBg = Color(0xFFFFF8F0);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFF1E3D3);
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
