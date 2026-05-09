/// 한국 세법 기반 상수 (2026년 기준)
class TaxConstants {
  TaxConstants._();

  // ── 상속세 / 증여세 세율 (과세표준 기준) ─────────────
  /// [하한, 상한, 세율, 누진공제액]
  static const List<List<int>> taxBrackets = [
    [0,          100000000,   10,          0],           // 1억 이하: 10%
    [100000001,  500000000,   20,  10000000],           // 5억 이하: 20%, 누진공제 1천만
    [500000001,  1000000000,  30,  60000000],           // 10억 이하: 30%, 누진공제 6천만
    [1000000001, 3000000000,  40, 160000000],           // 30억 이하: 40%, 누진공제 1억6천만
    [3000000001, 999999999999, 50, 460000000],          // 30억 초과: 50%, 누진공제 4억6천만
  ];

  // ── 상속세 공제 ───────────────────────────────────────
  /// 일괄공제 (상속)
  static const int inheritanceLumpSumDeduction  = 500000000;  // 5억원
  /// 기초공제
  static const int inheritanceBasicDeduction    = 200000000;  // 2억원
  /// 배우자 상속공제 최소
  static const int spouseInheritanceMin         = 500000000;  // 5억원
  /// 배우자 상속공제 최대
  static const int spouseInheritanceMax         = 3000000000; // 30억원
  /// 자녀 1인당 공제
  static const int childInheritanceDeduction    = 50000000;   // 5천만원
  /// 미성년자 공제 (1년당)
  static const int minorDeductionPerYear        = 10000000;   // 1천만원
  /// 장애인 공제 (1년당)
  static const int disabledDeductionPerYear     = 10000000;   // 1천만원
  /// 금융재산 공제 최대
  static const int financialAssetDeductionMax   = 200000000;  // 2억원
  /// 금융재산 공제 비율 (%)
  static const int financialAssetDeductionRate  = 20;         // 20%

  // ── 증여세 공제 (10년 합산) ────────────────────────────
  /// 직계비속(성인 자녀)
  static const int giftToAdultChild             = 50000000;   // 5천만원
  /// 직계비속(미성년 자녀)
  static const int giftToMinorChild             = 20000000;   // 2천만원
  /// 직계존속(부모)
  static const int giftToParent                 = 50000000;   // 5천만원
  /// 배우자
  static const int giftToSpouse                 = 600000000;  // 6억원
  /// 기타 친족
  static const int giftToRelative               = 10000000;   // 1천만원

  // ── 기타 ─────────────────────────────────────────────
  /// 증여세 합산기간 (년)
  static const int giftLookbackYears            = 10;
  /// 연부연납 최대 기간 (년)
  static const int installmentMaxYears          = 10;
  /// 물납 허용 비율 최대 (%)
  static const int paymentInKindMaxRate         = 100;
}
