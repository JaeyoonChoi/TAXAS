import 'package:flutter/material.dart';

/// Taxas 앱 컬러 팔레트 (네이비 기반)
class AppColors {
  AppColors._();

  // ── Primary: 네이비 ──────────────────────────────────
  static const Color navyDeep    = Color(0xFF0A1628);
  static const Color navyDark    = Color(0xFF0D1F3C);
  static const Color navyMid     = Color(0xFF1A3560);
  static const Color navyBase    = Color(0xFF1E4080);
  static const Color navyLight   = Color(0xFF2E5FA3);
  static const Color navyBright  = Color(0xFF3B72C0);

  // ── Accent: 골드 ────────────────────────────────────
  static const Color goldDeep    = Color(0xFFB8860B);
  static const Color goldBase    = Color(0xFFD4A017);
  static const Color goldLight   = Color(0xFFE8BE45);
  static const Color goldPale    = Color(0xFFFFF3CD);

  // ── Surface ─────────────────────────────────────────
  static const Color white       = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFF7F9FC);
  static const Color surfaceAlt  = Color(0xFFEDF1F7);
  static const Color cardBg      = Color(0xFFFFFFFF);

  // ── Text ────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textTertiary  = Color(0xFF8A9BB0);
  static const Color textInverse   = Color(0xFFFFFFFF);

  // ── Semantic ────────────────────────────────────────
  static const Color success     = Color(0xFF00875A);
  static const Color successBg   = Color(0xFFE3F9EC);
  static const Color warning     = Color(0xFFD97706);
  static const Color warningBg   = Color(0xFFFEF3C7);
  static const Color error       = Color(0xFFDC2626);
  static const Color errorBg     = Color(0xFFFEE2E2);
  static const Color info        = Color(0xFF2563EB);
  static const Color infoBg      = Color(0xFFEFF6FF);

  // ── Border / Divider ────────────────────────────────
  static const Color border      = Color(0xFFDDE3EE);
  static const Color divider     = Color(0xFFEEF2F8);

  // ── 차트 팔레트 ─────────────────────────────────────
  static const List<Color> chartPalette = [
    navyBase,
    goldBase,
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  // ── 그라디언트 ──────────────────────────────────────
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navyBase],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldDeep, goldLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navyDeep, navyMid],
  );
}
