import 'package:flutter/foundation.dart';
import '../../shared/models/user_info_state.dart';
import '../constants/tax_constants.dart';

/// 세금 계산 결과
@immutable
class TaxResult {
  // ── 상속세 ────────────────────────────────────────────
  final int inheritanceTaxableBase;   // 과세표준
  final int inheritanceTax;           // 납부세액
  final int inheritanceTotalDeduction; // 적용 공제 합계
  final Map<String, int> inheritanceDeductions; // 공제 항목별

  // ── 증여세 (사전증여 기준) ────────────────────────────
  final int giftTaxableBase;
  final int giftTax;
  final int giftTotalDeduction;

  // ── 절세 시뮬레이션 ────────────────────────────────────
  final int savingsVsInheritanceOnly; // 사전증여 없을 때 vs 있을 때 차이
  final int recommendedGiftAmount;    // 절세 최적 증여 추천액

  // ── 대비 X vs 대비 O 비교 (지금부터 계획 시나리오) ─────
  /// 대비를 안 할 때: 현재 자산 전부 상속세로 납부 (과거 증여 합산)
  final int noPlanningTax;
  /// 대비를 할 때: 가능한 증여 공제 활용 후 남은 자산에 상속세 + 신규 증여세
  final int withPlanningTax;
  /// 절감 가능 금액
  final int planningSavings;
  /// 권장 증여 분배 (수증자 라벨 → 금액)
  final Map<String, int> optimalGiftPlan;

  const TaxResult({
    required this.inheritanceTaxableBase,
    required this.inheritanceTax,
    required this.inheritanceTotalDeduction,
    required this.inheritanceDeductions,
    required this.giftTaxableBase,
    required this.giftTax,
    required this.giftTotalDeduction,
    required this.savingsVsInheritanceOnly,
    required this.recommendedGiftAmount,
    required this.noPlanningTax,
    required this.withPlanningTax,
    required this.planningSavings,
    required this.optimalGiftPlan,
  });

  /// 총 납부세액 (상속세 + 증여세 합산)
  int get totalTax => inheritanceTax + giftTax;
}

/// 세금 계산 서비스 (순수 함수)
class TaxCalculatorService {
  const TaxCalculatorService._();

  /// 메인 계산 진입점
  static TaxResult calculate(UserInfoState userInfo) {
    final family = userInfo.family;
    final assets = userInfo.assets;
    final gifts = userInfo.giftHistory;

    // ── 상속세 계산 ───────────────────────────────────
    final deductions = _calcInheritanceDeductions(family, assets);
    final totalDeductionAmount = deductions.values.fold(0, (a, b) => a + b);
    final netAsset = assets.totalNet;

    // 상속재산에서 사전증여 합산 (10년)
    final priorGiftTotal = gifts.fold(0, (sum, r) => sum + r.amount);
    final inheritanceBase =
        (netAsset + priorGiftTotal - totalDeductionAmount).clamp(0, double.maxFinite.toInt());

    final inheritanceTax = _applyBracket(inheritanceBase);

    // ── 증여세 계산 ───────────────────────────────────
    // 증여세 공제: 수증자별로 관계에 따라 공제 적용
    int giftTaxableBase = 0;
    int giftTaxTotal = 0;
    int giftDeductionTotal = 0;

    final grouped = <String, List<GiftRecord>>{};
    for (final g in gifts) {
      grouped.putIfAbsent(g.recipientName, () => []).add(g);
    }

    for (final entry in grouped.entries) {
      final recipGifts = entry.value;
      final totalAmount = recipGifts.fold(0, (s, r) => s + r.amount);
      final relationship = recipGifts.first.relationship;
      final deductionAmt = _giftDeduction(
        relationship,
        recipGifts.any((r) => _isMinor(family, r)),
      );
      final taxable = (totalAmount - deductionAmt).clamp(0, totalAmount);
      giftTaxableBase += taxable;
      giftTaxTotal += _applyBracket(taxable);
      giftDeductionTotal += deductionAmt;
    }

    // ── 절세 시뮬 ─────────────────────────────────────
    // 사전증여 없이 전액 상속 시 세액
    final inheritanceOnlyBase =
        (netAsset - totalDeductionAmount).clamp(0, netAsset);
    final inheritanceOnlyTax = _applyBracket(inheritanceOnlyBase);

    // 현재 총 세액 vs 사전증여 없는 세액
    final savings = inheritanceOnlyTax - (inheritanceTax + giftTaxTotal);

    // 최적 증여 추천: 세율 구간 고려 5천만 단위
    final recommendedGift = _recommendedGiftAmount(netAsset, family);

    // ── 대비 X vs 대비 O 시뮬레이션 (지금부터 계획) ─────
    final planningSim = _simulatePlanning(
      family: family,
      netAsset: netAsset,
      priorGiftTotal: priorGiftTotal,
      inheritanceDeductions: totalDeductionAmount,
    );

    return TaxResult(
      inheritanceTaxableBase: inheritanceBase,
      inheritanceTax: inheritanceTax,
      inheritanceTotalDeduction: totalDeductionAmount,
      inheritanceDeductions: deductions,
      giftTaxableBase: giftTaxableBase,
      giftTax: giftTaxTotal,
      giftTotalDeduction: giftDeductionTotal,
      savingsVsInheritanceOnly: savings.clamp(0, inheritanceOnlyTax),
      recommendedGiftAmount: recommendedGift,
      noPlanningTax: planningSim.noPlanningTax,
      withPlanningTax: planningSim.withPlanningTax,
      planningSavings: planningSim.savings,
      optimalGiftPlan: planningSim.optimalGiftPlan,
    );
  }

  /// 대비 X vs 대비 O 시뮬레이션
  ///
  /// **대비 X**: 현재 순자산 + 과거 10년 증여액 → 전부 상속세
  /// **대비 O**: 증여 공제 한도까지 사전증여 (10년+ 생존 가정 — 합산 제외) →
  ///            남은 자산에 상속세
  static _PlanningSim _simulatePlanning({
    required FamilyInfo family,
    required int netAsset,
    required int priorGiftTotal,
    required int inheritanceDeductions,
  }) {
    // ── 대비 X: 사전증여 없이 모두 상속 ─────────────────
    final noPlanningBase =
        (netAsset + priorGiftTotal - inheritanceDeductions).clamp(0, netAsset + priorGiftTotal);
    final noPlanningTax = _applyBracket(noPlanningBase);

    // ── 대비 O: 가족별 증여 공제 한도까지 사전증여 ──────
    final optimalPlan = <String, int>{};
    int totalGifted = 0;

    if (family.hasSpouse) {
      final amt = TaxConstants.giftToSpouse;
      optimalPlan['배우자'] = amt;
      totalGifted += amt;
    }

    int adultIndex = 1;
    int minorIndex = 1;
    for (final age in family.childAges) {
      if (age < 19) {
        final amt = TaxConstants.giftToMinorChild;
        optimalPlan['미성년 자녀 $minorIndex'] = amt;
        totalGifted += amt;
        minorIndex++;
      } else {
        final amt = TaxConstants.giftToAdultChild;
        optimalPlan['성인 자녀 $adultIndex'] = amt;
        totalGifted += amt;
        adultIndex++;
      }
    }

    // 증여 가능액이 순자산보다 크면 자산 한도로 줄임
    if (totalGifted > netAsset) {
      final ratio = netAsset / totalGifted;
      totalGifted = 0;
      for (final key in optimalPlan.keys.toList()) {
        final scaled = (optimalPlan[key]! * ratio).toInt();
        optimalPlan[key] = scaled;
        totalGifted += scaled;
      }
    }

    // 대비 O 시 남은 상속재산 = 현재 순자산 − 신규 증여 (+ 과거 증여는 동일하게 합산)
    final remainingAsset = (netAsset - totalGifted).clamp(0, netAsset);
    final withPlanningBase =
        (remainingAsset + priorGiftTotal - inheritanceDeductions).clamp(0, remainingAsset + priorGiftTotal);
    final withPlanningInheritanceTax = _applyBracket(withPlanningBase);

    // 신규 증여는 공제 한도 내이므로 증여세 0원
    // (10년 합산 가정에서 totalGifted는 각 수증자별 공제 한도와 같음)
    final withPlanningTax = withPlanningInheritanceTax;

    final savings =
        (noPlanningTax - withPlanningTax).clamp(0, noPlanningTax);

    return _PlanningSim(
      noPlanningTax: noPlanningTax,
      withPlanningTax: withPlanningTax,
      savings: savings,
      optimalGiftPlan: optimalPlan,
    );
  }

  // ── 상속세 공제 계산 ───────────────────────────────────
  static Map<String, int> _calcInheritanceDeductions(
    FamilyInfo family,
    AssetInfo assets,
  ) {
    final deductions = <String, int>{};

    // 일괄공제 (5억) vs 기초공제+인적공제 중 큰 쪽
    final basicDeduction = TaxConstants.inheritanceBasicDeduction;
    int humanDeduction = 0;
    humanDeduction +=
        family.childCount * TaxConstants.childInheritanceDeduction;
    // 미성년 추가 공제 (19세까지 남은 년수 × 1천만)
    for (final age in family.childAges) {
      if (age < 19) {
        humanDeduction += (19 - age) * TaxConstants.minorDeductionPerYear;
      }
    }
    final basicPlusHuman = basicDeduction + humanDeduction;
    final lumpSum = TaxConstants.inheritanceLumpSumDeduction;
    final appliedBasic = lumpSum > basicPlusHuman ? lumpSum : basicPlusHuman;
    deductions['일괄공제'] = lumpSum;

    // 배우자 공제
    if (family.hasSpouse) {
      // 배우자 법정상속분 (단순화: 순자산의 3/7)
      final spouseShare = (assets.totalNet * 3 ~/ 7);
      final spouseDeduction = spouseShare.clamp(
        TaxConstants.spouseInheritanceMin,
        TaxConstants.spouseInheritanceMax,
      );
      deductions['배우자공제'] = spouseDeduction;
    }

    // 금융재산 공제 (금융자산의 20%, 최대 2억)
    if (assets.financial > 0) {
      final finDeduction = (assets.financial * 0.2)
          .toInt()
          .clamp(0, TaxConstants.financialAssetDeductionMax);
      deductions['금융재산공제'] = finDeduction;
    }

    // 채무 공제
    if (assets.debt > 0) {
      deductions['채무공제'] = assets.debt;
    }

    return deductions;
  }

  // ── 세율 구간 적용 ────────────────────────────────────
  static int _applyBracket(int taxableBase) {
    if (taxableBase <= 0) return 0;
    for (final bracket in TaxConstants.taxBrackets.reversed) {
      if (taxableBase > bracket[0]) {
        final tax = (taxableBase * bracket[2] / 100) - bracket[3];
        return tax.round().clamp(0, double.maxFinite.toInt());
      }
    }
    return 0;
  }

  // ── 증여세 공제액 ────────────────────────────────────
  static int _giftDeduction(String relationship, bool isMinor) {
    switch (relationship) {
      case '배우자':
        return TaxConstants.giftToSpouse;
      case '자녀':
        return isMinor
            ? TaxConstants.giftToMinorChild
            : TaxConstants.giftToAdultChild;
      case '부모':
        return TaxConstants.giftToParent;
      default:
        return TaxConstants.giftToRelative;
    }
  }

  /// 해당 GiftRecord의 수증자가 미성년인지 확인
  static bool _isMinor(FamilyInfo family, GiftRecord record) {
    // 간단화: 자녀이고 평균 나이 < 19
    if (record.relationship != '자녀') return false;
    return family.minorChildCount > 0;
  }

  // ── 절세 추천 증여액 ──────────────────────────────────
  static int _recommendedGiftAmount(int netAsset, FamilyInfo family) {
    // 10년 주기 공제한도 활용 극대화
    int perChild = TaxConstants.giftToAdultChild; // 5천만
    int spouseGift = family.hasSpouse ? TaxConstants.giftToSpouse : 0; // 6억
    int totalRecommend =
        (family.adultChildCount * perChild) +
        (family.minorChildCount * TaxConstants.giftToMinorChild) +
        spouseGift;
    // 자산의 30% 또는 추천액 중 작은 쪽
    return (netAsset * 0.3).toInt().clamp(0, totalRecommend);
  }
}

/// 대비 X / 대비 O 시뮬레이션 결과
@immutable
class _PlanningSim {
  final int noPlanningTax;
  final int withPlanningTax;
  final int savings;
  final Map<String, int> optimalGiftPlan;

  const _PlanningSim({
    required this.noPlanningTax,
    required this.withPlanningTax,
    required this.savings,
    required this.optimalGiftPlan,
  });
}
