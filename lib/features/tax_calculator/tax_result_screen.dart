import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/tax_result_provider.dart';
import '../../shared/providers/user_info_provider.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../core/services/tax_calculator_service.dart';
import '../../core/constants/tax_constants.dart';
import '../../shared/models/user_info_state.dart';

class TaxResultScreen extends ConsumerWidget {
  const TaxResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(taxResultProvider);
    final userInfo = ref.watch(userInfoProvider);
    final formatter = NumberFormat('#,###', 'ko_KR');
    final hasData = userInfo.assets.totalGross > 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('세금 계산'),
        actions: [
          if (hasData)
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.step1Family),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('정보 수정'),
            ),
        ],
      ),
      body: !hasData
          ? _EmptyResultState(onTap: () => context.go(AppRoutes.step1Family))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── 절세 시뮬레이션 (대비X vs 대비O) ──────
                  _PlanningComparisonCard(
                    noPlanningTax: result.noPlanningTax,
                    withPlanningTax: result.withPlanningTax,
                    savings: result.planningSavings,
                    formatter: formatter,
                  ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 16),

                  // ── 권장 증여 분배 ─────────────────────────
                  if (result.optimalGiftPlan.isNotEmpty &&
                      result.planningSavings > 0)
                    _OptimalGiftPlanCard(
                      plan: result.optimalGiftPlan,
                      formatter: formatter,
                    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1, end: 0),

                  if (result.optimalGiftPlan.isNotEmpty &&
                      result.planningSavings > 0)
                    const SizedBox(height: 16),

                  // ── 총 세금 히어로 ─────────────────────────
                  _HeroTaxCard(
                    totalTax: result.totalTax,
                    savings: result.savingsVsInheritanceOnly,
                    formatter: formatter,
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 16),

                  // ── 상속세 상세 ────────────────────────────
                  _TaxDetailCard(
                    title: '상속세',
                    icon: Icons.account_balance,
                    color: AppColors.navyBase,
                    taxableBase: result.inheritanceTaxableBase,
                    taxAmount: result.inheritanceTax,
                    deductions: result.inheritanceDeductions,
                    formatter: formatter,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // ── 증여세 상세 ────────────────────────────
                  if (result.giftTaxableBase > 0)
                    _TaxDetailCard(
                      title: '사전 증여세',
                      icon: Icons.card_giftcard,
                      color: AppColors.goldDeep,
                      taxableBase: result.giftTaxableBase,
                      taxAmount: result.giftTax,
                      deductions: {
                        '증여공제': result.giftTotalDeduction,
                      },
                      formatter: formatter,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // ── 공제 항목 ──────────────────────────────
                  _DeductionSummaryCard(
                    deductions: result.inheritanceDeductions,
                    formatter: formatter,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 12),

                  // ── 추천 ──────────────────────────────────
                  if (result.recommendedGiftAmount > 0)
                    _RecommendCard(
                      amount: result.recommendedGiftAmount,
                      formatter: formatter,
                    ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 16),

                  // ── 상세 계산 설명 (더보기) ───────────────
                  _DetailedExplanationCard(
                    userInfo: userInfo,
                    result: result,
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 20),

                  // 법적 고지
                  const _LegalDisclaimer(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ── 서브 위젯 ────────────────────────────────────────────

class _HeroTaxCard extends StatelessWidget {
  final int totalTax;
  final int savings;
  final NumberFormat formatter;

  const _HeroTaxCard({
    required this.totalTax,
    required this.savings,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '예상 총 납부세액',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            formatKoreanCurrency(totalTax),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined,
                    color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '사전증여 활용 시 절세 가능액',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      formatKoreanCurrency(savings),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxDetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int taxableBase;
  final int taxAmount;
  final Map<String, int> deductions;
  final NumberFormat formatter;

  const _TaxDetailCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.taxableBase,
    required this.taxAmount,
    required this.deductions,
    required this.formatter,
  });

  String _taxRate(int base) {
    if (base <= 100000000) return '10%';
    if (base <= 500000000) return '20%';
    if (base <= 1000000000) return '30%';
    if (base <= 3000000000) return '40%';
    return '50%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '세율 ${_taxRate(taxableBase)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _Row('과세표준', formatKoreanCurrency(taxableBase)),
          const SizedBox(height: 8),
          _Row(
            '납부세액',
            formatKoreanCurrency(taxAmount),
            valueStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _Row(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _DeductionSummaryCard extends StatelessWidget {
  final Map<String, int> deductions;
  final NumberFormat formatter;

  const _DeductionSummaryCard({
    required this.deductions,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    if (deductions.isEmpty) return const SizedBox.shrink();
    final total = deductions.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '적용 공제 항목',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...deductions.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.navyBase,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '- ${formatKoreanCurrency(e.value)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          )),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 공제',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '- ${formatKoreanCurrency(total)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final int amount;
  final NumberFormat formatter;

  const _RecommendCard({required this.amount, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldBase.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.goldDeep, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '절세 추천 사전증여액',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatKoreanCurrency(amount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldDeep,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '10년 주기 증여공제 한도를 최대 활용하는 추천 금액입니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.goldDeep,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDisclaimer extends StatelessWidget {
  const _LegalDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '⚠️ 본 계산은 참고 목적으로만 활용하시기 바랍니다. 실제 세액은 세무사와 상담하여 정확히 확인하시기 바랍니다. (2026년 세법 기준)',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textTertiary,
          height: 1.5,
        ),
      ),
    );
  }
}

/// 대비 X / 대비 O 비교 + 절세 가능 금액 강조 카드
class _PlanningComparisonCard extends StatelessWidget {
  final int noPlanningTax;
  final int withPlanningTax;
  final int savings;
  final NumberFormat formatter;

  const _PlanningComparisonCard({
    required this.noPlanningTax,
    required this.withPlanningTax,
    required this.savings,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final hasSavings = savings > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.goldBase, size: 18),
              const SizedBox(width: 8),
              Text(
                '절세 시뮬레이션',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 비교: 대비 X vs 대비 O ──────────────────
          Row(
            children: [
              Expanded(
                child: _ScenarioCell(
                  label: '대비 안 할 때',
                  amount: noPlanningTax,
                  formatter: formatter,
                  isWarning: true,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScenarioCell(
                  label: '지금부터 계획 시',
                  amount: withPlanningTax,
                  formatter: formatter,
                  isWarning: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),

          // ── 절세 가능 금액 강조 ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSavings
                          ? '지금부터 계획하면'
                          : '추가 절세 여지가 없어요',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasSavings
                          ? formatKoreanCurrency(savings)
                          : '0원',
                      style: const TextStyle(
                        color: AppColors.goldBase,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    if (hasSavings)
                      Text(
                        '절세할 수 있어요',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasSavings && noPlanningTax > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.goldBase.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.goldBase.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '−${(savings * 100 / noPlanningTax).round()}%',
                    style: const TextStyle(
                      color: AppColors.goldBase,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScenarioCell extends StatelessWidget {
  final String label;
  final int amount;
  final NumberFormat formatter;
  final bool isWarning;

  const _ScenarioCell({
    required this.label,
    required this.amount,
    required this.formatter,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isWarning ? const Color(0xFFFFB4A0) : AppColors.goldBase;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatKoreanCurrency(amount),
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 권장 증여 분배 상세 카드
class _OptimalGiftPlanCard extends StatelessWidget {
  final Map<String, int> plan;
  final NumberFormat formatter;

  const _OptimalGiftPlanCard({
    required this.plan,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final total = plan.values.fold<int>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navyBase.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share_outlined,
                  color: AppColors.navyBase,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '권장 사전증여 분배',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                  ),
                ),
              ),
              Text(
                '총 ${formatKoreanCurrency(total)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...plan.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.navyBase,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    formatKoreanCurrency(e.value),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyBase,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '증여 후 10년 이상 생존 시 상속재산에 합산되지 않습니다.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyResultState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 80,
              color: AppColors.textTertiary.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            const Text(
              '자산 정보를 먼저 입력해주세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onTap,
              child: const Text('정보 입력하기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "더보기" — 입력값 기반으로 계산 과정을 차근차근 설명.
class _DetailedExplanationCard extends StatefulWidget {
  final UserInfoState userInfo;
  final TaxResult result;

  const _DetailedExplanationCard({
    required this.userInfo,
    required this.result,
  });

  @override
  State<_DetailedExplanationCard> createState() =>
      _DetailedExplanationCardState();
}

class _DetailedExplanationCardState extends State<_DetailedExplanationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.navyBase.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book_outlined,
                        color: AppColors.navyBase, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '어떻게 계산했나요?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDeep,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '입력하신 값으로 계산 과정을 단계별로 풀어봅니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: _ExplanationBody(
              userInfo: widget.userInfo,
              result: widget.result,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}

class _ExplanationBody extends StatelessWidget {
  final UserInfoState userInfo;
  final TaxResult result;

  const _ExplanationBody({required this.userInfo, required this.result});

  @override
  Widget build(BuildContext context) {
    final assets = userInfo.assets;
    final family = userInfo.family;
    final priorGifts = userInfo.totalPastGifts;

    final gross = assets.totalGross;
    final net = assets.totalNet;
    final deductions = result.inheritanceDeductions;
    final totalDeduction =
        deductions.values.fold<int>(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),

          _Step(
            number: 1,
            title: '순자산 계산',
            children: [
              _Line('부동산 (공시지가)', formatKoreanCurrency(assets.realEstate)),
              _Line('금융자산', formatKoreanCurrency(assets.financial)),
              _Line('기타자산', formatKoreanCurrency(assets.other)),
              const _Divider(),
              _Line('총 자산', formatKoreanCurrency(gross), bold: true),
              _Line('− 채무', '− ${formatKoreanCurrency(assets.debt)}'),
              const _Divider(),
              _Line('순자산', formatKoreanCurrency(net), bold: true, accent: true),
            ],
          ),

          if (priorGifts > 0)
            _Step(
              number: 2,
              title: '사전증여 합산',
              note: '사망 전 10년 이내 상속인에게 증여한 재산은 상속재산에 합산됩니다.',
              children: [
                _Line('과거 10년 증여 합계',
                    formatKoreanCurrency(priorGifts), accent: true),
                _Line('합산 후 상속재산 = 순자산 + 사전증여',
                    formatKoreanCurrency(net + priorGifts), bold: true),
              ],
            ),

          _Step(
            number: priorGifts > 0 ? 3 : 2,
            title: '상속세 공제 적용',
            note: '여러 공제 중 큰 쪽을 적용해 과세 대상을 줄입니다.',
            children: [
              ...deductions.entries.map(
                (e) => _Line(_deductionLabel(e.key, family),
                    '− ${formatKoreanCurrency(e.value)}'),
              ),
              const _Divider(),
              _Line('공제 합계',
                  '− ${formatKoreanCurrency(totalDeduction)}', bold: true),
            ],
          ),

          _Step(
            number: priorGifts > 0 ? 4 : 3,
            title: '과세표준 → 세액 (대비 X)',
            note: '${TaxConstants.taxBrackets.length}단계 누진세율을 적용합니다.',
            children: [
              _Line(
                '과세표준 = ${priorGifts > 0 ? "(순자산 + 사전증여)" : "순자산"} − 공제',
                formatKoreanCurrency(result.inheritanceTaxableBase),
              ),
              _Line('적용 세율 + 누진공제',
                  _bracketLabel(result.inheritanceTaxableBase)),
              const _Divider(),
              _Line('상속세 (대비 X)',
                  formatKoreanCurrency(result.noPlanningTax),
                  bold: true, accent: true),
            ],
          ),

          if (result.planningSavings > 0)
            _Step(
              number: priorGifts > 0 ? 5 : 4,
              title: '대비 O 시뮬레이션',
              note: '가족별 증여공제 한도까지 사전증여하면, 그만큼 상속재산에서 차감됩니다 '
                  '(10년+ 생존 가정).',
              children: [
                ...result.optimalGiftPlan.entries.map(
                  (e) => _Line(e.key, formatKoreanCurrency(e.value)),
                ),
                const _Divider(),
                _Line(
                  '권장 증여 합계',
                  formatKoreanCurrency(
                    result.optimalGiftPlan.values
                        .fold<int>(0, (a, b) => a + b),
                  ),
                  bold: true,
                ),
                _Line('남은 상속재산 (= 순자산 − 권장 증여)',
                    formatKoreanCurrency(
                      (net -
                              result.optimalGiftPlan.values
                                  .fold<int>(0, (a, b) => a + b))
                          .clamp(0, net),
                    )),
                _Line('상속세 (대비 O)',
                    formatKoreanCurrency(result.withPlanningTax),
                    bold: true, accent: true),
              ],
            ),

          if (result.planningSavings > 0)
            _Step(
              number: priorGifts > 0 ? 6 : 5,
              title: '절감액',
              children: [
                _Line('대비 X 세액',
                    formatKoreanCurrency(result.noPlanningTax)),
                _Line('− 대비 O 세액',
                    '− ${formatKoreanCurrency(result.withPlanningTax)}'),
                const _Divider(),
                _Line(
                  '절감 가능 금액',
                  formatKoreanCurrency(result.planningSavings),
                  bold: true,
                  accent: true,
                ),
                if (result.noPlanningTax > 0)
                  _Line(
                    '절감 비율',
                    '−${(result.planningSavings * 100 / result.noPlanningTax).round()}%',
                  ),
              ],
            ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '본 설명은 입력값 기준 단순화된 계산입니다. '
                    '실제 신고 시에는 가업·영농·동거주택 등 추가 공제, 부동산 '
                    '평가 방법, 증여 시기 분산 등으로 결과가 달라질 수 있어 '
                    '세무사 상담을 권장드립니다.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _deductionLabel(String key, FamilyInfo family) {
    switch (key) {
      case '일괄공제':
        return '일괄공제 (5억)';
      case '배우자공제':
        return '배우자 공제 (5억~30억 범위)';
      case '금융재산공제':
        return '금융재산 공제 (금융자산의 20%, 최대 2억)';
      case '채무공제':
        return '채무 공제';
      default:
        return key;
    }
  }

  static String _bracketLabel(int taxableBase) {
    if (taxableBase <= 0) return '과세표준 0원 (세액 없음)';
    if (taxableBase <= 100000000) return '10% (1억 이하)';
    if (taxableBase <= 500000000) return '20% − 1천만 (1억~5억)';
    if (taxableBase <= 1000000000) return '30% − 6천만 (5억~10억)';
    if (taxableBase <= 3000000000) return '40% − 1억6천만 (10억~30억)';
    return '50% − 4억6천만 (30억 초과)';
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String? note;
  final List<Widget> children;

  const _Step({
    required this.number,
    required this.title,
    required this.children,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.navyBase,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDeep,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                note!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool accent;

  const _Line(this.label, this.value, {this.bold = false, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: accent
                  ? AppColors.navyBase
                  : (bold ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(height: 1, color: AppColors.divider),
    );
  }
}
