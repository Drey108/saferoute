import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg, vertical: lg);
}

class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 28;
}

class SafeRouteColors {
  // Light
  static const Color lightBg = Color(0xFFF7F8FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceTint = Color(0xFFF0F3FF);
  static const Color lightText = Color(0xFF0D1420);
  static const Color lightMuted = Color(0xFF516072);
  static const Color lightStroke = Color(0xFFDAE1EE);
  static const Color lightPrimary = Color(0xFF00897B);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFF00BFA6);
  static const Color lightError = Color(0xFFB42318);

  // Dark
  static const Color darkBg = Color(0xFF070B14);
  static const Color darkSurface = Color(0xFF0E1422);
  static const Color darkSurfaceTint = Color(0xFF121B2E);
  static const Color darkText = Color(0xFFEAF0FF);
  static const Color darkMuted = Color(0xFFAAB7CC);
  static const Color darkStroke = Color(0xFF1E2A42);
  static const Color darkPrimary = Color(0xFF26A69A);
  static const Color darkOnPrimary = Color(0xFF0A1020);
  static const Color darkSecondary = Color(0xFF2AF2D6);
  static const Color darkError = Color(0xFFFF6B5E);
}

TextTheme _textTheme(Color bodyColor) {
  // Body line-height guidance: 1.5
  final base = GoogleFonts.manrope();
  return TextTheme(
    titleLarge: base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.15, color: bodyColor),
    titleMedium: base.copyWith(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2, color: bodyColor),
    bodyMedium: base.copyWith(fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.55, color: bodyColor),
    bodySmall: base.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.5, color: bodyColor),
    labelLarge: base.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.2, color: bodyColor, letterSpacing: 0.2),
    labelSmall: base.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2, color: bodyColor, letterSpacing: 0.3),
  );
}

ThemeData get lightTheme {
  final scheme = ColorScheme.light(
    primary: SafeRouteColors.lightPrimary,
    onPrimary: SafeRouteColors.lightOnPrimary,
    secondary: SafeRouteColors.lightSecondary,
    onSecondary: SafeRouteColors.lightText,
    surface: SafeRouteColors.lightSurface,
    onSurface: SafeRouteColors.lightText,
    error: SafeRouteColors.lightError,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SafeRouteColors.lightBg,
    textTheme: _textTheme(SafeRouteColors.lightText),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
    dividerTheme: DividerThemeData(color: SafeRouteColors.lightStroke.withValues(alpha: 0.6), thickness: 0.6),
    cardTheme: CardThemeData(
      color: SafeRouteColors.lightSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: SafeRouteColors.lightStroke.withValues(alpha: 0.9), width: 1),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SafeRouteColors.lightText,
      contentTextStyle: _textTheme(Colors.white).bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
  );
}

ThemeData get darkTheme {
  final scheme = ColorScheme.dark(
    primary: SafeRouteColors.darkPrimary,
    onPrimary: SafeRouteColors.darkOnPrimary,
    secondary: SafeRouteColors.darkSecondary,
    onSecondary: SafeRouteColors.darkOnPrimary,
    surface: SafeRouteColors.darkSurface,
    onSurface: SafeRouteColors.darkText,
    error: SafeRouteColors.darkError,
    onError: SafeRouteColors.darkOnPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SafeRouteColors.darkBg,
    textTheme: _textTheme(SafeRouteColors.darkText),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
    dividerTheme: DividerThemeData(color: SafeRouteColors.darkStroke.withValues(alpha: 0.9), thickness: 0.6),
    cardTheme: CardThemeData(
      color: SafeRouteColors.darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: SafeRouteColors.darkStroke.withValues(alpha: 1), width: 1),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SafeRouteColors.darkSurfaceTint,
      contentTextStyle: _textTheme(SafeRouteColors.darkText).bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
  );
}

extension SafeRouteText on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}
