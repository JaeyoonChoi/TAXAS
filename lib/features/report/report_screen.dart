import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/tax_constants.dart';
import '../../shared/providers/user_info_provider.dart';
import '../../shared/providers/tax_result_provider.dart';
import '../../shared/providers/ai_report_provider.dart';
import '../../shared/models/ai_report.dart';
import '../../shared/widgets/common_widgets.dart';
import '../tax_calculator/tax_result_screen.dart';

/// 리포트 탭 — 자산 시각화·예상 세액·자녀별 증여 현황·절세 정보·시뮬레이터.
///
/// 기존 계산 결과 화면 + 포트폴리오 차트를 한 곳에 통합하고, 그 위에
/// 핵심 절세 방법·자녀 증여 분석 같은 신규 위젯을 얹은 화면.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    final result = ref.watch(taxResultProvider);
    final hasData = userInfo.assets.totalGross > 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('리포트'),
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
          ? _EmptyState(onTap: () => context.go(AppRoutes.step1Family))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 0. AI 맞춤 분석
                const _AiAnalysisSection(),
                const SizedBox(height: 24),

                // 1. 자산 정보 시각화
                _SectionTitle('1. 자산 현황', emoji: '📊'),
                const SizedBox(height: 10),
                _AssetVizCard(userInfo: userInfo),
                const SizedBox(height: 24),

                // 2. 핵심 절세 방법
                _SectionTitle('2. 핵심 절세 방법', emoji: '⚡'),
                const SizedBox(height: 10),
                _KeyStrategiesCard(userInfo: userInfo, result: result),
                const SizedBox(height: 24),

                // 3. 자녀별 증여 현황 분석
                if (userInfo.family.childCount > 0) ...[
                  _SectionTitle('3. 자녀별 증여 공제 현황', emoji: '👨‍👩‍👧'),
                  const SizedBox(height: 10),
                  _ChildGiftAnalysisCard(userInfo: userInfo),
                  const SizedBox(height: 24),
                ],

                // 4. 구체적 절세 정보 (기존 결과 화면 통째로 reuse)
                _SectionTitle('4. 예상 세액 & 절세 시뮬레이션', emoji: '💰'),
                const SizedBox(height: 10),
                _PlanningHero(result: result),
                const SizedBox(height: 16),
                _DetailedTaxBreakdown(result: result),
                const SizedBox(height: 24),

                // 5. 절세 시뮬레이터 (간단 버전)
                _SectionTitle('5. 절세 시뮬레이터', emoji: '🎯'),
                const SizedBox(height: 10),
                _SimulatorCard(userInfo: userInfo, result: result),
                const SizedBox(height: 24),

                // 면책 고지
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '⚠️ 본 리포트는 입력값 기준 단순화된 시뮬레이션입니다. '
                    '실제 신고 시 가업·영농·동거주택 추가 공제, 부동산 평가 방법 등으로 '
                    '결과가 달라질 수 있어 세무사 상담을 권장합니다.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ── 공통 ─────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String emoji;
  const _SectionTitle(this.title, {required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              '자산 정보를 입력하면\n맞춤 리포트가 만들어져요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
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

// ── 1. 자산 시각화 ────────────────────────────────────────

class _AssetVizCard extends StatelessWidget {
  final dynamic userInfo;
  const _AssetVizCard({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    final assets = userInfo.assets;
    final items = <_AssetItem>[
      _AssetItem('부동산', assets.realEstate as int, AppColors.navyBase),
      _AssetItem('금융자산', assets.financial as int, AppColors.goldBase),
      _AssetItem('기타자산', assets.other as int, AppColors.info),
    ].where((i) => i.value > 0).toList();
    final total = items.fold<int>(0, (s, i) => s + i.value);
    final debt = assets.debt as int;

    if (items.isEmpty) {
      return _Card(
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('자산 정보를 입력하세요.',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
        ),
      );
    }

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 48,
                            startDegreeOffset: -90,
                            sections: items
                                .map((i) => PieChartSectionData(
                                      value: i.value.toDouble(),
                                      color: i.color,
                                      radius: 26,
                                      title:
                                          '${(i.value * 100 / total).round()}%',
                                      titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('순자산',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary)),
                            const SizedBox(height: 2),
                            Text(
                              formatKoreanCurrency(
                                  (total - debt).clamp(0, total)),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyDeep,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: items.map((i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: i.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    i.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatKoreanCurrency(i.value),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (debt > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.remove_circle_outline,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Text('채무',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      '− ${formatKoreanCurrency(debt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssetItem {
  final String label;
  final int value;
  final Color color;
  const _AssetItem(this.label, this.value, this.color);
}

// ── 2. 핵심 절세 방법 ─────────────────────────────────────

class _KeyStrategiesCard extends StatelessWidget {
  final dynamic userInfo;
  final dynamic result;

  const _KeyStrategiesCard({required this.userInfo, required this.result});

  @override
  Widget build(BuildContext context) {
    final strategies = <_Strategy>[];
    final family = userInfo.family;

    if (family.hasSpouse) {
      strategies.add(const _Strategy(
        icon: Icons.favorite,
        color: AppColors.error,
        title: '배우자 증여 6억 비과세 활용',
        body: '배우자에게 6억까지 증여세 0원. 자산을 분산시켜 상속 시 누진세율을 피할 수 있습니다.',
      ));
    }
    if (family.adultChildCount > 0) {
      strategies.add(_Strategy(
        icon: Icons.child_care,
        color: AppColors.navyBase,
        title: '성인 자녀 ${family.adultChildCount}명 × 5천만원 분산',
        body: '자녀당 10년마다 5천만원까지 비과세. 시기를 분산해 같은 한도를 여러 번 활용하세요.',
      ));
    }
    if (family.minorChildCount > 0) {
      strategies.add(_Strategy(
        icon: Icons.escalator_warning,
        color: AppColors.goldDeep,
        title: '미성년 자녀 ${family.minorChildCount}명 × 2천만원 활용',
        body: '미성년자 공제 한도(1인 2천만원)는 흔히 놓치는 절세 포인트입니다.',
      ));
    }
    if (userInfo.assets.financial > 0) {
      strategies.add(const _Strategy(
        icon: Icons.savings,
        color: AppColors.success,
        title: '금융재산 공제 (최대 2억)',
        body: '금융자산의 20%를 추가 공제. 자동 적용되니 자산 입력만 정확히 해두면 됩니다.',
      ));
    }
    if (strategies.isEmpty) {
      strategies.add(const _Strategy(
        icon: Icons.lightbulb_outline,
        color: AppColors.info,
        title: '먼저 가족 정보를 입력하세요',
        body: '배우자·자녀 수에 따라 활용 가능한 절세 전략이 달라집니다.',
      ));
    }

    return Column(
      children: [
        for (final s in strategies)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: s.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.body,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Strategy {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Strategy({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

// ── 3. 자녀별 증여 공제 현황 ─────────────────────────────

class _ChildGiftAnalysisCard extends StatelessWidget {
  final dynamic userInfo;
  const _ChildGiftAnalysisCard({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    final family = userInfo.family;
    final ages = (family.childAges as List).cast<int>();
    final history = userInfo.giftHistory as List;

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < ages.length; i++)
              _ChildRow(
                index: i + 1,
                age: ages[i],
                given: _givenToChild(history, i),
              ),
          ],
        ),
      ),
    );
  }

  /// 임시 휴리스틱 — 수증자 이름이 비어 있으니 자녀 인덱스로 매핑할 수 없음.
  /// 일단 0으로 표시하고, 추후 자녀별 식별 가능해지면 교체.
  int _givenToChild(List history, int childIdx) => 0;
}

class _ChildRow extends StatelessWidget {
  final int index;
  final int age;
  final int given;

  const _ChildRow({
    required this.index,
    required this.age,
    required this.given,
  });

  @override
  Widget build(BuildContext context) {
    final isMinor = age < 19;
    final limit = isMinor
        ? TaxConstants.giftToMinorChild
        : TaxConstants.giftToAdultChild;
    final remaining = (limit - given).clamp(0, limit);
    final pct = limit == 0 ? 0.0 : (given / limit).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMinor
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.navyBase.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isMinor ? '미성년' : '성인',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isMinor ? AppColors.warning : AppColors.navyBase,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '자녀 $index ($age세)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '잔여 ${formatKoreanCurrency(remaining)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.navyBase),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '한도 ${formatKoreanCurrency(limit)} · 사용 ${formatKoreanCurrency(given)}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. 예상 세액 & 시뮬레이션 (재사용 위젯) ───────────────

class _PlanningHero extends StatelessWidget {
  final dynamic result;
  const _PlanningHero({required this.result});

  @override
  Widget build(BuildContext context) {
    final noPlan = result.noPlanningTax as int;
    final withPlan = result.withPlanningTax as int;
    final savings = result.planningSavings as int;
    final pct = (noPlan > 0) ? (savings * 100 / noPlan).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '대비 X 시 예상 상속세',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatKoreanCurrency(noPlan),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '계획 시 납부세액',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatKoreanCurrency(withPlan),
                      style: const TextStyle(
                        color: AppColors.goldBase,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (savings > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.goldBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '−$pct%',
                    style: const TextStyle(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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

class _DetailedTaxBreakdown extends ConsumerWidget {
  final dynamic result;
  const _DetailedTaxBreakdown({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    return _Card(
      child: ExpansionTile(
        title: const Row(
          children: [
            Icon(Icons.menu_book_outlined,
                size: 18, color: AppColors.navyBase),
            SizedBox(width: 8),
            Text(
              '계산 과정 자세히 보기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDeep,
              ),
            ),
          ],
        ),
        children: [
          // tax_result_screen에서 정의된 _ExplanationBody는 private — 대신 간단 요약 표시
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('상속세 과세표준',
                    formatKoreanCurrency(result.inheritanceTaxableBase as int)),
                _row('상속세 공제 합계',
                    '− ${formatKoreanCurrency(result.inheritanceTotalDeduction as int)}'),
                _row(
                  '예상 상속세',
                  formatKoreanCurrency(result.inheritanceTax as int),
                  bold: true,
                ),
                if ((result.giftTax as int) > 0) ...[
                  const SizedBox(height: 8),
                  _row('사전 증여세',
                      formatKoreanCurrency(result.giftTax as int)),
                ],
                const SizedBox(height: 12),
                _moreLink(context, userInfo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.navyBase : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreLink(BuildContext context, dynamic userInfo) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const TaxResultScreen(),
        ),
      ),
      child: const Row(
        children: [
          Text(
            '결과 화면에서 단계별 설명 보기',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.navyBase,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 14, color: AppColors.navyBase),
        ],
      ),
    );
  }
}

// ── 5. 절세 시뮬레이터 (간단 UI) ─────────────────────────

class _SimulatorCard extends StatefulWidget {
  final dynamic userInfo;
  final dynamic result;
  const _SimulatorCard({required this.userInfo, required this.result});

  @override
  State<_SimulatorCard> createState() => _SimulatorCardState();
}

class _SimulatorCardState extends State<_SimulatorCard> {
  // 시뮬레이션 변수: 사전증여 활용률(0-100%) + 생존 가정 연수(0-30)
  double _giftPct = 100;
  double _years = 15;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final noPlan = result.noPlanningTax as int;
    final withPlan = result.withPlanningTax as int;
    final fullSavings = result.planningSavings as int;

    // 사전증여 활용률을 적용
    final adjustedSavings = (fullSavings * (_giftPct / 100)).round();
    // 생존 연수가 10년 미만이면 사전증여가 합산되어 효과 사라짐
    final effectiveSavings =
        _years >= 10 ? adjustedSavings : (adjustedSavings * 0.2).round();
    final adjustedTax = (noPlan - effectiveSavings).clamp(0, noPlan);

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '변수를 조절해 절감액 변화를 확인',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _SliderRow(
              label: '사전증여 활용률',
              valueLabel: '${_giftPct.round()}%',
              value: _giftPct,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) => setState(() => _giftPct = v),
            ),
            const SizedBox(height: 8),
            _SliderRow(
              label: '증여 후 생존 연수',
              valueLabel: '${_years.round()}년',
              value: _years,
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: (v) => setState(() => _years = v),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _result('대비 X 시', formatKoreanCurrency(noPlan), false),
            _result('100% 활용 + 10년+ 생존',
                formatKoreanCurrency(withPlan), false, sub: true),
            const SizedBox(height: 6),
            _result('내 시뮬레이션 결과',
                formatKoreanCurrency(adjustedTax), true),
            if (_years < 10)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ 사망 전 10년 내 증여는 상속재산에 합산되어 절세 효과가 거의 사라집니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _result(String label, String value, bool highlight,
      {bool sub = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: sub ? 11 : 12,
                color: highlight
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 16 : 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.navyBase : AppColors.textSecondary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.navyBase,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.navyBase,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── 공통 카드 셸 ─────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ── AI 맞춤 분석 섹션 ─────────────────────────────────────

class _AiAnalysisSection extends ConsumerWidget {
  const _AiAnalysisSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiReportControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle('AI 맞춤 분석', emoji: '✨'),
            const Spacer(),
            if (state is AiReportReady)
              TextButton.icon(
                onPressed: () =>
                    ref.read(aiReportControllerProvider.notifier).regenerate(),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('재생성'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _AiBody(state: state),
      ],
    );
  }
}

class _AiBody extends StatelessWidget {
  final AiReportState state;
  const _AiBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AiReportDisabled() => _disabled(),
      AiReportIdle() || AiReportLoading() => _loading(),
      AiReportError(message: final m) => _error(m),
      AiReportReady(report: final r, fromCache: final c) =>
        _ready(report: r, fromCache: c),
    };
  }

  Widget _disabled() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI 분석 기능은 관리자가 API 키 설정 후 활성화됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12),
            Text(
              '입력하신 정보로 맞춤 분석을 만들고 있어요…',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI 분석 실패: $msg',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ready({required AiReport report, required bool fromCache}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyDeep.withValues(alpha: 0.04),
            AppColors.goldBase.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navyBase.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤드라인
          Text(
            report.headline,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDeep,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          // 요약
          Text(
            report.summary,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          if (report.strengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _bullets('잘하고 계신 점', report.strengths, AppColors.success),
          ],
          if (report.weaknesses.isNotEmpty) ...[
            const SizedBox(height: 12),
            _bullets('개선 여지', report.weaknesses, AppColors.warning),
          ],
          if (report.actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '다음 액션',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            for (final a in report.actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _actionCard(a),
              ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 11, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Claude Haiku로 생성${fromCache ? ' · 캐시됨' : ''}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bullets(String label, List<String> items, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        for (final t in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: accent, fontSize: 12)),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _actionCard(AiAction a) {
    final color = switch (a.priority) {
      'high' => AppColors.error,
      'low' => AppColors.textTertiary,
      _ => AppColors.navyBase,
    };
    final label = switch (a.priority) {
      'high' => '우선',
      'low' => '참고',
      _ => '권장',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.55,
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
