import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/user_info_provider.dart';
import '../../shared/providers/tax_result_provider.dart';
import '../../shared/providers/ai_report_provider.dart';
import '../../shared/models/ai_report.dart';
import '../../shared/widgets/common_widgets.dart';
import 'strategy_simulator.dart';

/// 리포트 탭 — 자산 현황, 예상 세액 + 계산 상세 내역, 절세 시뮬레이터, AI 맞춤 분석.
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
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Report',
          style: AppText.appBarTitle(),
        ),
        actions: [
          if (hasData)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => context.go(AppRoutes.step1Family),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text(
                  '정보 수정',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: !hasData
          ? _EmptyState(onTap: () => context.go(AppRoutes.step1Family))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _SectionTitle('자산 현황', index: '01'),
                const SizedBox(height: 16),
                _AssetVizCard(userInfo: userInfo),
                const SizedBox(height: 40),

                _SectionTitle('예상 세액', index: '02'),
                const SizedBox(height: 16),
                _PlanningHero(result: result),
                const SizedBox(height: 12),
                _DetailedTaxBreakdown(result: result),
                const SizedBox(height: 40),

                _SectionTitle('절세 시뮬레이터', index: '03'),
                const SizedBox(height: 16),
                const StrategySimulator(),
                const SizedBox(height: 40),

                _SectionTitle('AI 맞춤 분석', index: '04'),
                const SizedBox(height: 16),
                const _AiAnalysisSection(),
                const SizedBox(height: 16),
                _AgentCta(),
                const SizedBox(height: 40),

                // 5. 세무사와 공유하기
                _SectionTitle('세무사와 공유', index: '05'),
                const SizedBox(height: 16),
                _ShareCard(userInfo: userInfo, result: result),
                const SizedBox(height: 32),

                // 면책 고지 — 차분한 톤
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),
                const Text(
                  '본 리포트는 입력값 기준 단순화된 시뮬레이션입니다. '
                  '실제 신고 시 가업·영농·동거주택 추가 공제, 부동산 평가 방법 등으로 '
                  '결과가 달라질 수 있어 세무사 상담을 권장합니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    height: 1.7,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );
  }
}

// ── 공통 ─────────────────────────────────────────────────

/// 에디토리얼 섹션 헤더 — 작은 번호(메타라벨) + 세리프 타이틀 + 골드 디바이더.
class _SectionTitle extends StatelessWidget {
  final String title;
  final String index;
  const _SectionTitle(this.title, {required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('— $index', style: AppText.metaLabel),
        const SizedBox(height: 6),
        Text(title, style: AppText.sectionTitle()),
        const SizedBox(height: 10),
        Container(
          width: 32,
          height: 2,
          color: AppColors.goldBase,
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 골드 얇은 룰
          Container(width: 24, height: 1.5, color: AppColors.goldBase),
          const SizedBox(height: 14),
          Text(
            '대비하지 않을 경우 예상 상속세',
            style: AppText.metaLabel,
          ),
          const SizedBox(height: 8),
          Text(
            formatKoreanCurrency(noPlan),
            style: AppText.bigNumber(
              size: 32,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사전 계획 시',
                      style: AppText.metaLabel.copyWith(letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatKoreanCurrency(withPlan),
                      style: AppText.bigNumber(
                        size: 20,
                        color: AppColors.navyBase,
                      ),
                    ),
                  ],
                ),
              ),
              if (savings > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '절감',
                      style: AppText.metaLabel.copyWith(letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '−$pct%',
                      style: AppText.bigNumber(
                        size: 20,
                        color: AppColors.goldDeep,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 계산 상세 내역 — 4개 카테고리(순 상속재산·상속공제·산출세액·납부세액) + 최종 납부세액.
///
/// ExpansionTile로 접혀 있다가 사용자가 탭하면 전체 펼침. 카테고리별 헤더에
/// 총액이 보이고 그 아래 세부 항목이 들여쓰기되어 표시된다.
class _DetailedTaxBreakdown extends ConsumerWidget {
  final dynamic result;
  const _DetailedTaxBreakdown({required this.result});

  /// 한국 표준 장례비용 공제 (정액).
  static const int _funeralCost = 5000000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    final assets = userInfo.assets;
    final priorGiftTotal = userInfo.giftHistory.fold<int>(0, (s, g) => s + g.amount);

    // 순 상속 재산 = 총 자산 − 채무 − 장례비용 + 사전증여재산
    final netInheritance =
        (assets.totalGross - assets.debt - _funeralCost + priorGiftTotal)
            .clamp(0, assets.totalGross + priorGiftTotal);

    // 상속공제 — 채무공제 제외 (위에서 이미 차감했으므로)
    final deductions = (result.inheritanceDeductions as Map<String, int>);
    final lumpSum = deductions['일괄공제'] ?? 0;
    final spouse = deductions['배우자공제'] ?? 0;
    final financial = deductions['금융재산공제'] ?? 0;
    final deductionTotal = lumpSum + spouse + financial;

    // 산출세액
    final taxableBase = result.inheritanceTaxableBase as int;
    final inheritanceTax = result.inheritanceTax as int;
    final taxRate = _taxRateLabel(taxableBase);

    // 납부세액 — 증여·신고세액공제는 현재 계산에 미포함 (0원 표시)
    const giftCredit = 0;
    const reportCredit = 0;
    final finalTax = (inheritanceTax - giftCredit - reportCredit).clamp(0, inheritanceTax);

    return _Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 18, color: AppColors.navyBase),
              SizedBox(width: 8),
              Text(
                '계산 상세 내역',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDeep,
                ),
              ),
            ],
          ),
          children: [
            // 1. 순 상속 재산
            _BreakdownGroup(
              title: '순 상속 재산',
              total: netInheritance,
              items: [
                _BreakdownItem('총 상속 재산', assets.totalGross),
                _BreakdownItem('채무 (대출·부채)', assets.debt),
                _BreakdownItem('장례비용', _funeralCost),
                _BreakdownItem('사전증여재산', priorGiftTotal),
              ],
            ),
            const SizedBox(height: 16),

            // 2. 상속공제
            _BreakdownGroup(
              title: '상속공제',
              total: deductionTotal,
              items: [
                _BreakdownItem('일괄공제', lumpSum),
                _BreakdownItem('배우자 공제', spouse),
                _BreakdownItem('금융자산 공제', financial),
              ],
            ),
            const SizedBox(height: 16),

            // 3. 산출세액
            _BreakdownGroup(
              title: '산출세액',
              total: inheritanceTax,
              showDivider: false,
              items: [
                _BreakdownItem('과세표준', taxableBase),
                _BreakdownItem.text('세율', taxRate),
                _BreakdownItem('산출세액', inheritanceTax),
              ],
            ),
            const SizedBox(height: 16),

            // 4. 납부세액
            _BreakdownGroup(
              title: '납부세액',
              total: finalTax,
              showDivider: false,
              items: [
                _BreakdownItem('산출세액', inheritanceTax),
                _BreakdownItem('증여세액공제', giftCredit),
                _BreakdownItem('신고세액공제', reportCredit),
              ],
            ),

            // 최종 납부세액
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.border, thickness: 1),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '혼자 신고 시 납부 세액',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  formatKoreanCurrency(finalTax),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyBase,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '※ 본 계산기는 참고용이며 실제 세액과 다를 수 있습니다.\n정확한 신고는 전문가 상담을 권장합니다.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _taxRateLabel(int base) {
    if (base <= 0) return '0%';
    if (base <= 100000000) return '10%';
    if (base <= 500000000) return '20%';
    if (base <= 1000000000) return '30%';
    if (base <= 3000000000) return '40%';
    return '50%';
  }
}

/// 계산 상세 내역의 한 그룹 (헤더 + 총액 + 세부 항목들).
class _BreakdownGroup extends StatelessWidget {
  final String title;
  final int total;
  final List<_BreakdownItem> items;
  final bool showDivider;

  const _BreakdownGroup({
    required this.title,
    required this.total,
    required this.items,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              formatKoreanCurrency(total),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
        ],
        const SizedBox(height: 4),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Text(
                  item.displayValue,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 세부 항목 (금액 또는 텍스트).
class _BreakdownItem {
  final String label;
  final String displayValue;

  _BreakdownItem(this.label, int amount)
      : displayValue = formatKoreanCurrency(amount);

  _BreakdownItem.text(this.label, this.displayValue);
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
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
        if (state is AiReportReady)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
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
          ),
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

// ── AI 에이전트 CTA ──────────────────────────────────────

/// AI 분석 결과 아래의 "진행하기" CTA — 채팅 기반 절세 에이전트로 진입.
class _AgentCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navyDeep,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.agent),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.goldBase.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.goldLight, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '절세 과정 전반을 함께',
                      style: AppText.metaLabel.copyWith(
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'AI 에이전트와 진행하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 세무사 공유 카드 ─────────────────────────────────────

/// 리포트 요약을 텍스트로 묶어 카카오톡·이메일 등으로 전송.
/// 클립보드 복사도 함께 지원 — 카카오톡 PC 등에서 붙여넣기 시 유용.
class _ShareCard extends StatelessWidget {
  final dynamic userInfo;
  final dynamic result;

  const _ShareCard({required this.userInfo, required this.result});

  @override
  Widget build(BuildContext context) {
    final text = _buildShareText(userInfo, result);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 24, height: 1.5, color: AppColors.goldBase),
          const SizedBox(height: 14),
          Text('상담을 위해 공유하세요', style: AppText.metaLabel),
          const SizedBox(height: 8),
          const Text(
            '리포트 요약을 카카오톡·이메일·메시지로 세무사에게 바로 보낼 수 있습니다.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('리포트 요약이 클립보드에 복사되었습니다.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('텍스트 복사'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Share.share(
                    text,
                    subject: 'ATAX 절세 시뮬레이션 결과',
                  ),
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text('공유하기'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
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

/// 사용자 정보 + 계산 결과를 세무사 상담용 텍스트로 포맷.
String _buildShareText(dynamic userInfo, dynamic result) {
  final f = userInfo.family;
  final a = userInfo.assets;
  final priorGiftTotal = (userInfo.giftHistory as List)
      .fold<int>(0, (s, g) => s + (g.amount as int));

  final children = (f.childAges as List<int>).asMap().entries.map((e) {
    final age = e.value;
    return '자녀${e.key + 1} ${age}세${age < 19 ? '(미성년)' : ''}';
  }).join(', ');

  final optimalPlan = (result.optimalGiftPlan as Map<String, int>)
      .entries
      .map((e) => '${e.key} ${formatKoreanCurrency(e.value)}')
      .join(', ');

  final buf = StringBuffer()
    ..writeln('[ATAX 절세 시뮬레이션 결과]')
    ..writeln('')
    ..writeln('● 가족 정보')
    ..writeln('- 본인 나이: ${f.ownerAge}세')
    ..writeln('- 배우자: ${f.hasSpouse ? "있음" : "없음"}')
    ..writeln('- 자녀: ${f.childCount}명${children.isNotEmpty ? " ($children)" : ""}')
    ..writeln('')
    ..writeln('● 자산')
    ..writeln('- 부동산: ${formatKoreanCurrency(a.realEstate)}')
    ..writeln('- 금융자산: ${formatKoreanCurrency(a.financial)}')
    ..writeln('- 기타자산: ${formatKoreanCurrency(a.other)}')
    ..writeln('- 채무: ${formatKoreanCurrency(a.debt)}')
    ..writeln('- 총자산(채무 차감 전): ${formatKoreanCurrency(a.totalGross)}')
    ..writeln('- 순자산: ${formatKoreanCurrency(a.totalNet)}')
    ..writeln('')
    ..writeln('● 사전증여 이력 (최근 10년)')
    ..writeln('- 합계: ${formatKoreanCurrency(priorGiftTotal)}')
    ..writeln('')
    ..writeln('● 예상 세액 (단순 시뮬레이션)')
    ..writeln('- 대비 X 시: ${formatKoreanCurrency(result.noPlanningTax)}')
    ..writeln('- 사전증여 활용 시: ${formatKoreanCurrency(result.withPlanningTax)}')
    ..writeln('- 절감 가능 금액: ${formatKoreanCurrency(result.planningSavings)}');

  if (optimalPlan.isNotEmpty) {
    buf
      ..writeln('')
      ..writeln('● 권장 사전증여 분배')
      ..writeln('- $optimalPlan');
  }

  buf
    ..writeln('')
    ..writeln('※ 본 결과는 ATAX의 단순화된 시뮬레이션이며,')
    ..writeln('실제 신고 시 전문가 상담이 필요합니다.')
    ..writeln('')
    ..writeln('https://taxas-bd85b.web.app');

  return buf.toString();
}
