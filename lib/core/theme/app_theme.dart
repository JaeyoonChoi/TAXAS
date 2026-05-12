import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Pretendard';

  // ── Light Theme ───────────────────────────────────────
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.navyBase,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.navyMid,
        onPrimaryContainer: AppColors.white,
        secondary: AppColors.goldBase,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.goldPale,
        onSecondaryContainer: AppColors.goldDeep,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceAlt,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.errorBg,
        onErrorContainer: AppColors.error,
        inverseSurface: AppColors.navyDeep,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.navyBright,
        shadow: Color(0x1A0A1628),
        scrim: Color(0x800A1628),
        tertiary: Color(0xFF6366F1),
        onTertiary: AppColors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: _appBarTheme(),
      cardTheme: _cardTheme(),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(),
      bottomNavigationBarTheme: _bottomNavTheme(),
      tabBarTheme: _tabBarTheme(),
      chipTheme: _chipTheme(),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      textTheme: _textTheme(),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navyBase,
        linearTrackColor: AppColors.surfaceAlt,
      ),
      snackBarTheme: _snackBarTheme(),
    );
  }

  // ── Dark Theme ────────────────────────────────────────
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.navyBright,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.navyMid,
        onPrimaryContainer: AppColors.white,
        secondary: AppColors.goldLight,
        onSecondary: AppColors.navyDeep,
        secondaryContainer: AppColors.goldDeep,
        onSecondaryContainer: AppColors.goldPale,
        surface: Color(0xFF0F1923),
        onSurface: AppColors.white,
        surfaceContainerHighest: Color(0xFF1A2535),
        onSurfaceVariant: AppColors.textTertiary,
        outline: Color(0xFF2E4060),
        outlineVariant: Color(0xFF1E3050),
        error: Color(0xFFEF5350),
        onError: AppColors.white,
        errorContainer: Color(0xFF4A1515),
        onErrorContainer: Color(0xFFFFCDD2),
        inverseSurface: AppColors.white,
        onInverseSurface: AppColors.navyDeep,
        inversePrimary: AppColors.navyBase,
        shadow: Color(0x40000000),
        scrim: Color(0x80000000),
        tertiary: Color(0xFF818CF8),
        onTertiary: AppColors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A1220),
    );
  }

  // ── Sub-themes ────────────────────────────────────────

  static AppBarTheme _appBarTheme() => const AppBarTheme(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    titleTextStyle: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    ),
  );

  static CardThemeData _cardTheme() => CardThemeData(
    color: AppColors.cardBg,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: AppColors.divider, width: 1),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    clipBehavior: Clip.antiAlias,
  );

  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyDeep,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navyDeep,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.navyDeep, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.navyBase,
      textStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme() => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.navyBase, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: const TextStyle(
      color: AppColors.textTertiary,
      fontSize: 14,
      fontFamily: _fontFamily,
    ),
    labelStyle: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontFamily: _fontFamily,
    ),
    floatingLabelStyle: const TextStyle(
      color: AppColors.navyBase,
      fontSize: 12,
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w500,
    ),
  );

  static BottomNavigationBarThemeData _bottomNavTheme() =>
      const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.navyBase,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 11,
        ),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      );

  static TabBarThemeData _tabBarTheme() => const TabBarThemeData(
    labelColor: AppColors.navyBase,
    unselectedLabelColor: AppColors.textTertiary,
    indicatorColor: AppColors.navyBase,
    indicatorSize: TabBarIndicatorSize.label,
    labelStyle: TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: _fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
  );

  static ChipThemeData _chipTheme() => ChipThemeData(
    backgroundColor: AppColors.surfaceAlt,
    selectedColor: AppColors.navyBase,
    labelStyle: const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 13,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    side: const BorderSide(color: AppColors.border),
  );

  static SnackBarThemeData _snackBarTheme() => SnackBarThemeData(
    backgroundColor: AppColors.navyDeep,
    contentTextStyle: const TextStyle(
      fontFamily: _fontFamily,
      color: AppColors.white,
      fontSize: 14,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
  );

  static TextTheme _textTheme() => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 57, fontWeight: FontWeight.w700,
      letterSpacing: -1.5, color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    displayMedium: TextStyle(
      fontSize: 45, fontWeight: FontWeight.w700,
      letterSpacing: -1.0, color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    displaySmall: TextStyle(
      fontSize: 36, fontWeight: FontWeight.w700,
      letterSpacing: -0.8, color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    headlineLarge: TextStyle(
      fontSize: 32, fontWeight: FontWeight.w700,
      letterSpacing: -0.5, color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    headlineMedium: TextStyle(
      fontSize: 28, fontWeight: FontWeight.w600,
      letterSpacing: -0.3, color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    headlineSmall: TextStyle(
      fontSize: 24, fontWeight: FontWeight.w600,
      letterSpacing: -0.2, color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    titleLarge: TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600,
      letterSpacing: -0.2, color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    titleMedium: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600,
      letterSpacing: -0.1, color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    titleSmall: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    bodyLarge: TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400,
      color: AppColors.textPrimary, fontFamily: _fontFamily, height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400,
      color: AppColors.textSecondary, fontFamily: _fontFamily, height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w400,
      color: AppColors.textTertiary, fontFamily: _fontFamily, height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary, fontFamily: _fontFamily,
    ),
    labelMedium: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w500,
      color: AppColors.textSecondary, fontFamily: _fontFamily,
    ),
    labelSmall: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w500,
      color: AppColors.textTertiary, fontFamily: _fontFamily,
      letterSpacing: 0.2,
    ),
  );
}
