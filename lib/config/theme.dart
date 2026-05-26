import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoxoraColors {
  static const brand = Color(0xFFFF3D6E);
  static const brandDark = Color(0xFFFF7AA2);
  static const electric = Color(0xFF2563EB);
  static const teal = Color(0xFF06B6D4);
  static const orange = Color(0xFFFF8A3D);
  static const rose = Color(0xFFE11D48);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFFACC15);
  static const violet = Color(0xFF7C3AED);
  static const ink = Color(0xFF101322);
  static const slate = Color(0xFF64748B);
  static const line = Color(0xFFE7EAF3);
  static const softBg = Color(0xFFF6F7FB);
  static const darkBg = Color(0xFF0D111A);
  static const darkSurface = Color(0xFF161B27);
  static const darkLine = Color(0xFF2A3242);
}

class VoxoraTheme {
  static ThemeData light() => _theme(
    brightness: Brightness.light,
    seed: VoxoraColors.brand,
    scaffold: VoxoraColors.softBg,
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
      surfaceTint: seed,
    );
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
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
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.45,
          letterSpacing: 0,
          color: onSurface.withValues(alpha: 0.84),
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          height: 1.35,
          letterSpacing: 0,
          color: onSurface.withValues(alpha: 0.62),
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
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
            ? Colors.white.withValues(alpha: 0.055)
            : const Color(0xFFFBFCFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: outline.withValues(alpha: 0.82)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: outline.withValues(alpha: 0.82)),
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
          textStyle: GoogleFonts.plusJakartaSans(
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
          side: BorderSide(color: outline.withValues(alpha: 0.95)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.72),
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
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scaffold,
        foregroundColor: onSurface,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: onSurface,
        ),
      ),
    );
  }
}
