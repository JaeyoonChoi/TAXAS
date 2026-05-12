import 'package:flutter/material.dart';

/// Taxas 앱 컬러 팔레트 (네이비 기반)
class AppColors {
  AppColors._();

  // ── Primary: 딥 미드나잇 네이비 ─────────────────────
  // 더 깊고 채도가 낮은 네이비 — 프라이빗 뱅킹 톤.
  static const Color navyDeep    = Color(0xFF0B1020);
  static const Color navyDark    = Color(0xFF131A2E);
  static const Color navyMid     = Color(0xFF1A243F);
  static const Color navyBase    = Color(0xFF1F2D54);
  static const Color navyLight   = Color(0xFF334270);
  static const Color navyBright  = Color(0xFF4E608C);

  // ── Accent: 샴페인 골드 ──────────────────────────────
  static const Color goldDeep    = Color(0xFFA07A0F);
  static const Color goldBase    = Color(0xFFC19A2D);
  static const Color goldLight   = Color(0xFFD8B863);
  static const Color goldPale    = Color(0xFFF5EBC8);

  // ── Surface ─────────────────────────────────────────
  static const Color white       = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFF6F7FA);
  static const Color surfaceAlt  = Color(0xFFEBEEF4);
  static const Color cardBg      = Color(0xFFFFFFFF);

  // ── Text ────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0B1020);
  static const Color textSecondary = Color(0xFF4A5468);
  static const Color textTertiary  = Color(0xFF8995AB);
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
