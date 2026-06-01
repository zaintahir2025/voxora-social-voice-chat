import 'package:flutter/material.dart';

class VoxoraColors {
  static const primaryPop = Color(0xFF00B8D9);
  static const secondaryPop = Color(0xFF6D5DF7);
  static const accentPop = Color(0xFFFF5C7A);
  static const warningPop = Color(0xFFFF4B4B);

  // Semantic Colors (required by app)
  static const rose = accentPop;
  static const teal = primaryPop;
  static const brand = primaryPop;
  static const amber = Color(0xFFFFB400);
  static const green = Color(0xFF00C853);
  static const orange = Color(0xFFFF8A00);
  static const slate = Color(0xFF64748B);

  static const darkBg = Color(0xFF0E1117);
  static const darkCard = Color(0xFF171D27);
  static const darkBorder = Color(0xFF293241);

  static const lightBg = Color(0xFFF6F8FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);
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

    final textTheme =
        (brightness == Brightness.dark
                ? ThemeData.dark(useMaterial3: true).textTheme
                : ThemeData.light(useMaterial3: true).textTheme)
            .apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      colorScheme: scheme,
      textTheme: textTheme.copyWith(
        headlineMedium: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: onSurface.withValues(alpha: 0.8),
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: onSurface.withValues(alpha: 0.62),
        ),
        labelLarge: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF061014),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF061014),
          disabledBackgroundColor: border.withValues(alpha: 0.65),
          disabledForegroundColor: onSurface.withValues(alpha: 0.42),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border, width: 1),
          backgroundColor: surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? VoxoraColors.darkBg
            : VoxoraColors.lightBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onSurface),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide(color: border),
        labelStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.74),
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: TextStyle(
          color: surface,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.28),
        selectionHandleColor: primary,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 2, space: 2),
    );
  }
}
