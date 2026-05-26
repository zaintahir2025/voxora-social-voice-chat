import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoxoraColors {
  static const brand = Color(0xFF2563EB);
  static const brandDark = Color(0xFF60A5FA);
  static const teal = Color(0xFF0F766E);
  static const orange = Color(0xFFF97316);
  static const rose = Color(0xFFE11D48);
  static const green = Color(0xFF16A34A);
  static const amber = Color(0xFFEAB308);
  static const ink = Color(0xFF111827);
  static const slate = Color(0xFF4B5563);
  static const line = Color(0xFFE5E7EB);
  static const darkBg = Color(0xFF101418);
  static const darkSurface = Color(0xFF171C22);
  static const darkLine = Color(0xFF2A333D);
}

class VoxoraTheme {
  static ThemeData light() => _theme(
    brightness: Brightness.light,
    seed: VoxoraColors.brand,
    scaffold: const Color(0xFFF7F8FA),
    surface: Colors.white,
    onSurface: VoxoraColors.ink,
    outline: VoxoraColors.line,
  );

  static ThemeData dark() => _theme(
    brightness: Brightness.dark,
    seed: VoxoraColors.brandDark,
    scaffold: VoxoraColors.darkBg,
    surface: VoxoraColors.darkSurface,
    onSurface: const Color(0xFFF3F4F6),
    outline: VoxoraColors.darkLine,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color seed,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color outline,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: seed,
      secondary: VoxoraColors.teal,
      tertiary: VoxoraColors.orange,
      error: VoxoraColors.rose,
      surface: surface,
    );
    final textTheme = GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          height: 1.45,
          letterSpacing: 0,
          color: onSurface.withValues(alpha: 0.84),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          height: 1.35,
          letterSpacing: 0,
          color: onSurface.withValues(alpha: 0.62),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: seed, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: outline),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: outline),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: seed,
        unselectedItemColor: onSurface.withValues(alpha: 0.55),
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
