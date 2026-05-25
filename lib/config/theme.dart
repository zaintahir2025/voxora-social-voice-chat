import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoxoraColors {
  static const primary = Color(0xFFB724FF);
  static const primaryStrong = Color(0xFF7C3AED);
  static const neon = Color(0xFF6FFF00);
  static const cream = Color(0xFFEFF4FF);
  static const cyan = Color(0xFF6DE7FF);
  static const lime = Color(0xFF6FFF00);
  static const coral = Color(0xFF7C3AED);
  static const danger = Color(0xFFD92D20);
  static const warning = Color(0xFFB54708);
  static const success = Color(0xFF6FFF00);
  static const purple = Color(0xFF7C5DFA);

  static const bg = Color(0xFF010828);
  static const surface = Color(0xFF07113A);
  static const surfaceLight = Color(0xFF0D1A4A);
  static const surfaceStrong = Color(0xFF020616);
  static const text = cream;
  static const textSecondary = Color(0xFFD7E2F8);
  static const muted = Color(0xFF8FA1CB);
  static const line = Color(0x334D5E99);
  static const lineLight = Color(0x224D5E99);

  static const sidebarDark = Color(0xFF020616);
  static const sidebarAccent = Color(0xFF061144);

  // Online status colors
  static const online = Color(0xFF3FB950);
  static const idle = Color(0xFFE3B341);
  static const dnd = Color(0xFFF85149);
}

class VoxoraTheme {
  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: VoxoraColors.bg,
      colorScheme: ColorScheme.dark(
        primary: VoxoraColors.primary,
        secondary: VoxoraColors.cyan,
        surface: VoxoraColors.surface,
        error: VoxoraColors.danger,
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: GoogleFonts.anton(
          fontSize: 32,
          color: VoxoraColors.text,
          letterSpacing: 0,
        ),
        headlineMedium: GoogleFonts.anton(
          fontSize: 24,
          color: VoxoraColors.text,
          letterSpacing: 0,
        ),
        titleLarge: GoogleFonts.anton(
          fontSize: 18,
          color: VoxoraColors.text,
          letterSpacing: 0,
        ),
        titleMedium: GoogleFonts.anton(
          fontSize: 16,
          color: VoxoraColors.text,
          letterSpacing: 0,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          color: VoxoraColors.textSecondary,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: VoxoraColors.textSecondary,
        ),
        bodySmall: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: VoxoraColors.muted,
        ),
        labelLarge: GoogleFonts.anton(
          fontSize: 14,
          color: VoxoraColors.text,
          letterSpacing: 0,
        ),
        labelSmall: GoogleFonts.anton(
          fontSize: 11,
          letterSpacing: 1.4,
          color: VoxoraColors.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: VoxoraColors.neon, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: VoxoraColors.muted,
        ),
        hintStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: VoxoraColors.muted.withValues(alpha: 0.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VoxoraColors.neon,
          foregroundColor: VoxoraColors.bg,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.anton(fontSize: 14, letterSpacing: 0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VoxoraColors.text,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.anton(fontSize: 14, letterSpacing: 0),
        ),
      ),
      cardTheme: CardThemeData(
        color: VoxoraColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: VoxoraColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: VoxoraColors.line,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VoxoraColors.surface,
        selectedItemColor: VoxoraColors.primary,
        unselectedItemColor: VoxoraColors.muted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VoxoraColors.surfaceLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          color: VoxoraColors.textSecondary,
        ),
        side: const BorderSide(color: VoxoraColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static BoxDecoration get panelDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.025),
    backgroundBlendMode: BlendMode.luminosity,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.07),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration get glassPanelDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.035),
    backgroundBlendMode: BlendMode.luminosity,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 32,
        offset: const Offset(0, 12),
      ),
    ],
  );

  static BoxDecoration get gradientButtonDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: const LinearGradient(
      colors: [VoxoraColors.neon, Color(0xFFD7FF7A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: VoxoraColors.neon.withValues(alpha: 0.32),
        blurRadius: 18,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get cyanButtonDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: const LinearGradient(
      colors: [VoxoraColors.cyan, Color(0xFF00BFA5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: VoxoraColors.cyan.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get limeButtonDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: const LinearGradient(
      colors: [VoxoraColors.neon, Color(0xFFD7FF7A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static BoxDecoration get pulseCardDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: VoxoraColors.line),
    gradient: LinearGradient(
      colors: [
        VoxoraColors.surfaceLight,
        VoxoraColors.surfaceLight.withValues(alpha: 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static BoxDecoration get accentGlow => BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: LinearGradient(
      colors: [
        VoxoraColors.neon.withValues(alpha: 0.12),
        VoxoraColors.primary.withValues(alpha: 0.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    border: Border.all(color: VoxoraColors.neon.withValues(alpha: 0.18)),
  );

  static TextStyle condiment({
    double fontSize = 32,
    Color color = VoxoraColors.neon,
  }) => GoogleFonts.condiment(fontSize: fontSize, color: color, height: 1);
}
