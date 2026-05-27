import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoxoraColors {
  // Futuristic Neon Colors
  static const neonCyan = Color(0xFF00F0FF);
  static const neonPink = Color(0xFFFF0055);
  static const neonPurple = Color(0xFF9D00FF);
  
  // Semantic Colors mapped to futuristic tones
  static const rose = Color(0xFFFF0055); // Maps to neonPink
  static const teal = Color(0xFF00F0FF); // Maps to neonCyan
  static const brand = Color(0xFF9D00FF); // Maps to neonPurple
  static const amber = Color(0xFFFFC000); 
  static const green = Color(0xFF00FF66);
  static const orange = Color(0xFFFF6600);
  static const slate = Color(0xFF6B7280);

  // Dark Theme Colors
  static const darkSpace = Color(0xFF050814); // Deep space black
  static const darkPanel = Color(0xFF0D1326); // Slightly lighter for cards
  static const darkBorder = Color(0xFF1A2642); 

  // Light Theme Colors (Clean, high-tech white)
  static const lightVoid = Color(0xFFF0F4F8);
  static const lightPanel = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFD1D9E6);
}

class VoxoraTheme {
  static ThemeData light() => _buildTheme(
        brightness: Brightness.light,
        scaffold: VoxoraColors.lightVoid,
        surface: VoxoraColors.lightPanel,
        onSurface: const Color(0xFF1A1A24),
        primary: VoxoraColors.neonPurple,
        secondary: VoxoraColors.neonCyan,
        border: VoxoraColors.lightBorder,
      );

  static ThemeData dark() => _buildTheme(
        brightness: Brightness.dark,
        scaffold: VoxoraColors.darkSpace,
        surface: VoxoraColors.darkPanel,
        onSurface: const Color(0xFFE2E8F0),
        primary: VoxoraColors.neonCyan,
        secondary: VoxoraColors.neonPink,
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
      error: VoxoraColors.neonPink,
    );

    // Using Space Grotesk for a futuristic, geometric look
    final textTheme = GoogleFonts.spaceGroteskTextTheme(
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
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          height: 1.5,
          color: onSurface.withValues(alpha: 0.85),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 8,
        shadowColor: primary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: brightness == Brightness.dark ? VoxoraColors.darkSpace : Colors.white,
          elevation: 10,
          shadowColor: primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurface.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: VoxoraColors.darkSpace,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 12,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
