import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoxoraColors {
  static const primary = Color(0xFF6C3CFF);
  static const primaryStrong = Color(0xFF4F26D9);
  static const cyan = Color(0xFF00B8D9);
  static const lime = Color(0xFFA7F432);
  static const coral = Color(0xFFFF5C7A);
  static const danger = Color(0xFFD92D20);
  static const warning = Color(0xFFB54708);

  static const bg = Color(0xFFF7F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceStrong = Color(0xFF10131F);
  static const text = Color(0xFF161925);
  static const muted = Color(0xFF687083);
  static const line = Color(0x1F23283D);

  static const sidebarDark = Color(0xFF10131F);
  static const sidebarAccent = Color(0xFF1A123A);
}

class VoxoraTheme {
  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: VoxoraColors.bg,
      colorScheme: ColorScheme.light(
        primary: VoxoraColors.primary,
        secondary: VoxoraColors.cyan,
        surface: VoxoraColors.surface,
        error: VoxoraColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: VoxoraColors.text,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: VoxoraColors.text,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: VoxoraColors.text,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: VoxoraColors.text,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: VoxoraColors.text,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: VoxoraColors.text,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: VoxoraColors.muted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: VoxoraColors.text,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: VoxoraColors.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VoxoraColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VoxoraColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: VoxoraColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: VoxoraColors.muted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: VoxoraColors.muted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VoxoraColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VoxoraColors.text,
          side: const BorderSide(color: VoxoraColors.line),
          minimumSize: const Size(0, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.78)),
        ),
      ),
    );
  }

  static BoxDecoration get panelDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F141828),
            blurRadius: 48,
            offset: Offset(0, 18),
          ),
        ],
      );

  static BoxDecoration get gradientButtonDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [VoxoraColors.primary, VoxoraColors.cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static BoxDecoration get limeButtonDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [VoxoraColors.lime, Color(0xFFFFF6B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static BoxDecoration get pulseCardDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFEFF4FF).withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F141828),
            blurRadius: 48,
            offset: Offset(0, 18),
          ),
        ],
      );
}
