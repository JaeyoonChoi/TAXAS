import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/tax_result_provider.dart';
import '../../shared/providers/user_info_provider.dart';
import '../../shared/widgets/common_widgets.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

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
        title: const Text('절세 포트폴리오'),
      ),
      body: !hasData
          ? _EmptyPortfolioState(onTap: () => context.go(AppRoutes.step1Family))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── 자산 구성 파이 차트 ──────────────────────
                  _AssetPieCard(
                    realEstate: userInfo.assets.realEstate,
                    financial: userInfo.assets.financial,
                    other: userInfo.assets.other,
                    formatter: formatter,
                  ).animate().fadeIn(duration: 600.ms),

                  const SizedBox(height: 16),

                  // ── 사전증여 vs 상속 비교 바 차트 ─────────────
                  _SimulationBarCard(
                    inheritanceOnlyTax:
                        result.inheritanceTax + result.savingsVsInheritanceOnly,
                    withGiftTax: result.totalTax,
                    savings: result.savingsVsInheritanceOnly,
                    formatter: formatter,
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                  const SizedBox(height: 16),

                  // ── 절세 전략 카드들 ───────────────────────────
                  _StrategySection(
                    formatter: formatter,
                    recommendedGift: result.recommendedGiftAmount,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

// ── 파이 차트 ─────────────────────────────────────────────

class _AssetPieCard extends StatefulWidget {
  final int realEstate;
  final int financial;
  final int other;
  final NumberFormat formatter;

  const _AssetPieCard({
    required this.realEstate,
    required this.financial,
    required this.other,
    required this.formatter,
  });

  @override
  State<_AssetPieCard> createState() => _AssetPieCardState();
}

class _AssetPieCardState extends State<_AssetPieCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.realEstate + widget.financial + widget.other;
    if (total == 0) return const SizedBox.shrink();

    final sections = [
      if (widget.realEstate > 0)
        _PieData('부동산', widget.realEstate, AppColors.navyBase),
      if (widget.financial > 0)
        _PieData('금융', widget.financial, AppColors.goldBase),
      if (widget.other > 0)
        _PieData('기타', widget.other, const Color(0xFF6366F1)),
    ];

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
            '자산 구성',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      sections: List.generate(sections.length, (i) {
                        final d = sections[i];
                        final isTouched = i == _touchedIndex;
                        final pct = (d.value / total * 100).round();
                        return PieChartSectionData(
                          color: d.color,
                          value: d.value.toDouble(),
                          title: '$pct%',
                          radius: isTouched ? 65 : 55,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((d) {
                    final pct = (d.value / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: d.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                formatKoreanCurrency(d.value),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieData {
  final String label;
  final int value;
  final Color color;
  const _PieData(this.label, this.value, this.color);
}

// ── 비교 바 차트 ─────────────────────────────────────────

class _SimulationBarCard extends StatelessWidget {
  final int inheritanceOnlyTax;
  final int withGiftTax;
  final int savings;
  final NumberFormat formatter;

  const _SimulationBarCard({
    required this.inheritanceOnlyTax,
    required this.withGiftTax,
    required this.savings,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = inheritanceOnlyTax > 0
        ? inheritanceOnlyTax.toDouble()
        : 1.0;

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
            '사전증여 vs 상속 비교',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '사전증여 활용 시 세부담 비교',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['전액 상속', '사전증여\n활용'];
                        if (value.toInt() >= titles.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            titles[value.toInt()],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: inheritanceOnlyTax.toDouble(),
                        color: AppColors.navyBase,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: withGiftTax.toDouble(),
                        color: AppColors.success,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 절세 효과 강조
          if (savings > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_down,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '절세 효과: ${formatKoreanCurrency(savings)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                      fontSize: 14,
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

// ── 절세 전략 섹션 ────────────────────────────────────────

class _StrategySection extends StatelessWidget {
  final NumberFormat formatter;
  final int recommendedGift;

  const _StrategySection({
    required this.formatter,
    required this.recommendedGift,
  });

  @override
  Widget build(BuildContext context) {
    final strategies = [
      _Strategy(
        icon: Icons.family_restroom,
        color: AppColors.navyBase,
        title: '10년 주기 증여 활용',
        description: '자녀에게 10년마다 5,000만원(미성년 2,000만원) 비과세 증여 가능',
      ),
      _Strategy(
        icon: Icons.account_balance,
        color: AppColors.info,
        title: '배우자 증여공제',
        description: '배우자에게 6억원까지 10년 주기로 비과세 증여 가능',
      ),
      _Strategy(
        icon: Icons.home_work_outlined,
        color: AppColors.goldDeep,
        title: '부동산 공시지가 활용',
        description: '시세 대비 낮은 공시지가 기준으로 증여하면 세부담 절감',
      ),
      _Strategy(
        icon: Icons.timer_outlined,
        color: AppColors.success,
        title: '상속세 연부연납',
        description: '상속세를 최대 10년에 걸쳐 분납하여 자금 부담 완화',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '절세 전략',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...strategies.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _StrategyCard(strategy: s),
        )),
      ],
    );
  }
}

class _Strategy {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _Strategy({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class _StrategyCard extends StatelessWidget {
  final _Strategy strategy;
  const _StrategyCard({required this.strategy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: strategy.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(strategy.icon, color: strategy.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strategy.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strategy.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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

class _EmptyPortfolioState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyPortfolioState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: AppColors.textTertiary.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            const Text(
              '자산 정보를 입력하면\n포트폴리오 분석이 시작됩니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.5,
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
