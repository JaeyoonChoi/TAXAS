import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/tax_result_provider.dart';
import '../../shared/providers/user_info_provider.dart';
import '../../shared/widgets/common_widgets.dart';

/// 상속세 절세 시뮬레이터 — 3개 전략을 토글하며 실시간으로 세액 비교.
class StrategySimulator extends ConsumerStatefulWidget {
  const StrategySimulator({super.key});

  @override
  ConsumerState<StrategySimulator> createState() => _StrategySimulatorState();
}

class _StrategySimulatorState extends ConsumerState<StrategySimulator> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);
    final result = ref.watch(taxResultProvider);

    // 기준 세액 — 대비 안 할 때 (단순화: 상속세만)
    final baseTax = result.noPlanningTax;
    if (baseTax <= 0) {
      return _emptyState();
    }

    // 전략별 절감 가능액 계산
    final realEstate = userInfo.assets.realEstate;
    final strategies = <_Strategy>[
      _Strategy(
        id: 'gift',
        title: '사전 증여 활용',
        subtitle: '증여세 공제 한도 최대 활용',
        icon: Icons.account_balance_outlined,
        color: AppColors.navyBase,
        savings: result.planningSavings,
        detail: '배우자·자녀별 증여공제 한도를 최대한 활용해 상속재산을 미리 분산시킵니다. '
            '10년+ 생존 가정 하 합산 제외.',
        stats: {
          '권장 분배': result.optimalGiftPlan.entries
              .map((e) => '${e.key} ${formatKoreanCurrency(e.value)}')
              .take(2)
              .join(', '),
          if (result.optimalGiftPlan.isNotEmpty)
            '총 권장 증여': formatKoreanCurrency(
              result.optimalGiftPlan.values.fold<int>(0, (a, b) => a + b),
            ),
        },
      ),
      _Strategy(
        id: 'valuation',
        title: '재산 평가 전략',
        subtitle: '감정평가로 과표 최적화',
        icon: Icons.description_outlined,
        color: AppColors.success,
        // 부동산 비중에 비례, 기준 세액의 최대 22%
        savings: _clampSavings(
          (realEstate * 0.035).round() + (baseTax * 0.10).round(),
          baseTax,
          maxRatio: 0.22,
        ),
        detail: '부동산 평가를 공시지가 대신 감정평가로 진행하면 과세표준을 최적화할 수 있습니다. '
            '평가 시점·방식에 따라 큰 차이가 발생합니다.',
        stats: {
          '대상 부동산': formatKoreanCurrency(realEstate),
          '예상 평가 차익': '시가 대비 약 10~20%',
        },
      ),
      _Strategy(
        id: 'insurance',
        title: '보험 활용 전략',
        subtitle: '보험금 비과세 혜택 적용',
        icon: Icons.shield_outlined,
        color: const Color(0xFF7A5BBE), // 보라 톤
        savings: _clampSavings(
          (baseTax * 0.16).round(),
          baseTax,
          maxRatio: 0.18,
        ),
        detail: '피상속인이 보험료를 납부하더라도 수익자를 상속인으로 지정한 생명보험금은 '
            '상속세 과세 대상에서 최대 2억원까지 공제됩니다. 종신보험 가입을 통해 절세와 보장을 '
            '동시에 확보합니다.',
        stats: {
          '보험금 공제 한도': '2억 원',
          '가입 보험 종류': '종신보험',
          '과세 표준 감소': formatKoreanCurrency(
              _clampSavings((baseTax * 0.16).round(), baseTax, maxRatio: 0.18)),
        },
      ),
    ];

    final totalSavings = strategies
        .where((s) => _selected.contains(s.id))
        .fold<int>(0, (sum, s) => sum + s.savings)
        .clamp(0, baseTax);
    final finalTax = (baseTax - totalSavings).clamp(0, baseTax);
    final savingsPct = baseTax == 0 ? 0.0 : (totalSavings / baseTax * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 18),
          _summaryRow(
            baseTax: baseTax,
            savings: totalSavings,
            finalTax: finalTax,
            savingsPct: savingsPct,
            selectedCount: _selected.length,
          ),
          const SizedBox(height: 20),
          _strategyList(strategies),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          '자산 정보를 입력하면 시뮬레이션이 시작됩니다.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.navyBase.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  size: 12, color: AppColors.navyBase),
              SizedBox(width: 4),
              Text(
                'AI 절세 분석 리포트',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyBase,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '상속세 절세 시뮬레이션',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '전략을 선택하면 예상 절세 금액이 실시간으로 반영됩니다.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow({
    required int baseTax,
    required int savings,
    required int finalTax,
    required double savingsPct,
    required int selectedCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            label: '현재 예상 세액',
            value: formatKoreanCurrency(baseTax),
            sub: '상속세 신고 기준',
            background: AppColors.surface,
            valueColor: AppColors.textPrimary,
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            label: '예상 절세 금액',
            value: formatKoreanCurrency(savings),
            sub: '${savingsPct.toStringAsFixed(1)}% 절감',
            background: AppColors.navyBase,
            valueColor: Colors.white,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            label: '최종 납부 세액',
            value: formatKoreanCurrency(finalTax),
            sub: '$selectedCount개 전략 적용',
            background: AppColors.surface,
            valueColor: AppColors.success,
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required String sub,
    required Color background,
    required Color valueColor,
    required bool isPrimary,
  }) {
    final labelColor =
        isPrimary ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary;
    final subColor =
        isPrimary ? Colors.white.withValues(alpha: 0.7) : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: isPrimary ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPrimary)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.trending_down,
                      size: 12, color: Colors.white),
                ),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: subColor),
          ),
        ],
      ),
    );
  }

  Widget _strategyList(List<_Strategy> strategies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '절세 전략 선택',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        for (final s in strategies)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StrategyCard(
              strategy: s,
              baseTax: ref.read(taxResultProvider).noPlanningTax,
              selected: _selected.contains(s.id),
              onToggle: () => setState(() {
                if (!_selected.add(s.id)) _selected.remove(s.id);
              }),
            ),
          ),
      ],
    );
  }
}

// ── 전략 카드 ─────────────────────────────────────────────

class _StrategyCard extends StatelessWidget {
  final _Strategy strategy;
  final int baseTax;
  final bool selected;
  final VoidCallback onToggle;

  const _StrategyCard({
    required this.strategy,
    required this.baseTax,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final pct = baseTax == 0 ? 0.0 : (strategy.savings / baseTax * 100);
    final bg = selected
        ? strategy.color.withValues(alpha: 0.08)
        : Colors.white;
    final borderColor =
        selected ? strategy.color : AppColors.border;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: strategy.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(strategy.icon,
                        color: strategy.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                strategy.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: strategy.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  strategy.subtitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: strategy.color,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '최대 절세 ${formatKoreanCurrency(strategy.savings)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· ${pct.toStringAsFixed(1)}% 감소',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: '정보',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textTertiary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? strategy.color : Colors.transparent,
                      border: Border.all(
                        color: selected ? strategy.color : AppColors.border,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            size: 12, color: Colors.white)
                        : null,
                  ),
                ],
              ),
              if (selected) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor:
                        strategy.color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(strategy.color),
                  ),
                ),
                if (strategy.detail.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    strategy.detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
                if (strategy.stats.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: strategy.stats.entries.map((e) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  e.key,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  e.value,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: strategy.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 모델 ──────────────────────────────────────────────────

class _Strategy {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int savings;
  final String detail;
  final Map<String, String> stats;

  const _Strategy({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.savings,
    required this.detail,
    required this.stats,
  });
}

int _clampSavings(int candidate, int baseTax, {required double maxRatio}) {
  final max = (baseTax * maxRatio).round();
  return candidate.clamp(0, max);
}
