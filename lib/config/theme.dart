import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoxoraColors {
  static const primary = Color(0xFFFF3D66);
  static const primaryStrong = Color(0xFFC4214A);
  static const cyan = Color(0xFF00A6A6);
  static const lime = Color(0xFFFFD166);
  static const coral = Color(0xFFFF7A3D);
  static const danger = Color(0xFFD92D20);
  static const warning = Color(0xFFB54708);
  static const success = Color(0xFF2FBF71);
  static const purple = Color(0xFF7C5DFA);

  static const bg = Color(0xFF0E1117);
  static const surface = Color(0xFF161B22);
  static const surfaceLight = Color(0xFF1C2333);
  static const surfaceStrong = Color(0xFF0D1117);
  static const text = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFFC9D1D9);
  static const muted = Color(0xFF8B949E);
  static const line = Color(0xFF30363D);
  static const lineLight = Color(0xFF21262D);

  static const sidebarDark = Color(0xFF0D1117);
  static const sidebarAccent = Color(0xFF0E1B2A);

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
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: VoxoraColors.text,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: VoxoraColors.text,
          letterSpacing: -0.3,
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
          color: VoxoraColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: VoxoraColors.textSecondary,
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
          letterSpacing: 1.2,
          color: VoxoraColors.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VoxoraColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VoxoraColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VoxoraColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: VoxoraColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: VoxoraColors.muted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: VoxoraColors.muted.withValues(alpha: 0.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VoxoraColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
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
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VoxoraColors.surfaceLight,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: VoxoraColors.textSecondary),
        side: const BorderSide(color: VoxoraColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static BoxDecoration get panelDecoration => BoxDecoration(
        color: VoxoraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VoxoraColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get glassPanelDecoration => BoxDecoration(
        color: VoxoraColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VoxoraColors.line.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      );

  static BoxDecoration get gradientButtonDecoration => BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [VoxoraColors.primary, Color(0xFFE91E63), VoxoraColors.coral],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: VoxoraColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
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
          colors: [VoxoraColors.lime, Color(0xFFFFF176)],
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
            VoxoraColors.primary.withValues(alpha: 0.15),
            VoxoraColors.cyan.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: VoxoraColors.primary.withValues(alpha: 0.2)),
      );
}
