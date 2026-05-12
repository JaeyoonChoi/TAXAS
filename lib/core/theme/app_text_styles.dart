import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 타이포그래피 — 모든 텍스트가 Pretendard 한 폰트로 통일.
///
/// 위계는 폰트가 아닌 **두께·크기·자간**으로 표현한다.
class AppText {
  AppText._();

  static const String _family = 'Pretendard';

  /// ATAX 브랜드 로고용 — 이롭게 바탕(Iropke Batang), 클래식 한글 세리프.
  /// 단일 두께(Medium)만 있어 [weight]는 미세 조절에만 영향.
  static TextStyle logo({
    double size = 28,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = -0.3,
  }) =>
      TextStyle(
        fontFamily: 'IropkeBatang',
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: 1.0,
      );

  /// AppBar 타이틀용 — Pretendard 모던 산세리프.
  static TextStyle appBarTitle({
    double size = 22,
    Color color = AppColors.textPrimary,
  }) =>
      TextStyle(
        fontFamily: _family,
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.0,
      );

  /// 섹션 타이틀.
  static TextStyle sectionTitle({
    double size = 22,
    Color color = AppColors.textPrimary,
  }) =>
      TextStyle(
        fontFamily: _family,
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      );

  /// 큰 금액 디스플레이 (히어로 카드 등).
  static TextStyle bigNumber({
    double size = 32,
    Color color = AppColors.textPrimary,
  }) =>
      TextStyle(
        fontFamily: _family,
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.05,
      );

  /// 작은 모노 라벨 — 카테고리/메타데이터.
  static const TextStyle metaLabel = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.8,
    color: AppColors.textTertiary,
  );

  /// 본문 — 차분한 톤.
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );
}
