import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../shared/providers/user_info_provider.dart';
import '../../shared/providers/tax_result_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../firebase_options.dart';
import '../admin/admin_card_news_list_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    final taxResult = ref.watch(taxResultProvider);
    final formatter = NumberFormat('#,###', 'ko_KR');
    final hasData = userInfo.assets.totalGross > 0;
    final userEmail = useFirebase
        ? ref.watch(authStateProvider).valueOrNull?.email
        : null;
    final isAdmin = useFirebase && ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── 헤더 ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 로고
                      Text(
                        'TAXAS',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                          height: 1.0,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '2026 세법 기준',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      if (useFirebase) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          tooltip: '계정',
                          icon: const Icon(
                            Icons.account_circle_outlined,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          onSelected: (value) async {
                            if (value == 'logout') {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signOut();
                            } else if (value == 'admin_card_news') {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminCardNewsListScreen(),
                                ),
                              );
                            }
                          },
                          itemBuilder: (ctx) => [
                            if (userEmail != null)
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  userEmail,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (isAdmin)
                              const PopupMenuItem<String>(
                                value: 'admin_card_news',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_note, size: 18,
                                        color: AppColors.navyBase),
                                    SizedBox(width: 10),
                                    Text('카드 뉴스 관리',
                                        style: TextStyle(
                                            color: AppColors.navyBase,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, size: 18,
                                      color: AppColors.error),
                                  SizedBox(width: 10),
                                  Text('로그아웃',
                                      style: TextStyle(
                                          color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 4),

                // ── 빠른 시작 / 세금 요약 ──────────────────
                if (!hasData) ...[
                  _StartGuideCard(context: context),
                ] else ...[
                  _TaxSummaryRow(
                    inheritanceTax: taxResult.noPlanningTax,
                    giftTax: taxResult.giftTax,
                    savings: taxResult.planningSavings,
                    formatter: formatter,
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),

                // ── 자산 요약 카드 ─────────────────────────
                if (hasData) ...[
                  _SectionTitle(title: '자산 현황'),
                  const SizedBox(height: 8),
                  _AssetSummaryCard(
                    userInfo: userInfo,
                    formatter: formatter,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 빠른 메뉴 ─────────────────────────────
                _SectionTitle(title: '빠른 메뉴'),
                const SizedBox(height: 8),
                _QuickMenuGrid(context: context),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 서브 위젯들 ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StartGuideCard extends StatelessWidget {
  final BuildContext context;
  const _StartGuideCard({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '지금 바로 시작하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '가족 정보와 자산 정보를 입력하면\n맞춤형 절세 전략을 제안해드려요.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldBase,
                    foregroundColor: AppColors.navyDeep,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.go(AppRoutes.step1Family),
                  child: const Text(
                    '정보 입력하기',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.15),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }
}

class _TaxSummaryRow extends StatelessWidget {
  final int inheritanceTax;
  final int giftTax;
  final int savings;
  final NumberFormat formatter;

  const _TaxSummaryRow({
    required this.inheritanceTax,
    required this.giftTax,
    required this.savings,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final hasSavings = savings > 0 && inheritanceTax > 0;
    final percent = hasSavings ? (savings * 100 / inheritanceTax).round() : 0;
    final withPlanningTax = (inheritanceTax - savings).clamp(0, inheritanceTax);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 예상 상속세 ──────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '예상 상속세',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatKoreanCurrency(inheritanceTax),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDeep,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.navyBase.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    size: 14,
                    color: AppColors.navyBase,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: AppColors.divider)),
            ],
          ),
          const SizedBox(height: 14),

          // ── 절세 가능액 ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.goldBase.withValues(alpha: 0.18),
                  AppColors.goldBase.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.goldBase.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined,
                    color: AppColors.goldDeep, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSavings
                            ? '절세 시 내야할 금액'
                            : '추가 절세 여지가 없습니다',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.goldDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatKoreanCurrency(withPlanningTax),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldDeep,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSavings)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.goldDeep,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '−$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}

class _AssetSummaryCard extends StatelessWidget {
  final dynamic userInfo;
  final NumberFormat formatter;

  const _AssetSummaryCard({required this.userInfo, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final items = <_AssetItem>[
      _AssetItem('부동산', userInfo.assets.realEstate as int,
          Icons.home_outlined, AppColors.navyBase),
      _AssetItem('금융자산', userInfo.assets.financial as int,
          Icons.savings_outlined, AppColors.goldBase),
      _AssetItem('기타자산', userInfo.assets.other as int,
          Icons.inventory_2_outlined, AppColors.info),
    ].where((i) => i.value > 0).toList();

    final total = items.fold<int>(0, (sum, i) => sum + i.value);
    final debt = userInfo.assets.debt as int;
    final net = (total - debt).clamp(0, total);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 도넛 차트 + 합계 ─────────────────────────
          if (items.isNotEmpty && total > 0)
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // 도넛
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            startDegreeOffset: -90,
                            sections: items.map((i) {
                              final pct = i.value * 100 / total;
                              return PieChartSectionData(
                                value: i.value.toDouble(),
                                color: i.color,
                                radius: 22,
                                title: pct >= 8 ? '${pct.round()}%' : '',
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '순자산',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatKoreanCurrency(net),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyDeep,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 범례
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((i) {
                          final pct = (i.value * 100 / total).round();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                                Text(
                                  i.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$pct%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const Spacer(),
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
          // ── 채무가 있으면 별도 표시 ──────────────────
          if (debt > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_circle_outline,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  const Text(
                    '채무',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '− ${formatKoreanCurrency(debt)}',
                    style: const TextStyle(
                      fontSize: 13,
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
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _AssetItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _AssetItem(this.label, this.value, this.icon, this.color);
}

class _QuickMenuGrid extends StatelessWidget {
  final BuildContext context;
  const _QuickMenuGrid({required this.context});

  @override
  Widget build(BuildContext context) {
    final menus = [
      _QuickMenu('정보 입력', Icons.edit_outlined, AppColors.navyBase,
          () => context.go(AppRoutes.step1Family)),
      _QuickMenu('세금 계산', Icons.receipt_long_outlined, AppColors.info,
          () => context.go(AppRoutes.taxResult)),
      _QuickMenu('포트폴리오', Icons.pie_chart_outline, AppColors.success,
          () => context.go(AppRoutes.portfolio)),
      _QuickMenu('기초 지식', Icons.menu_book_outlined, AppColors.goldDeep,
          () => context.go(AppRoutes.info)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: menus
          .asMap()
          .entries
          .map((e) => e.value
              .build(context)
              .animate()
              .fadeIn(delay: (400 + e.key * 60).ms)
              .slideY(begin: 0.2, end: 0))
          .toList(),
    );
  }
}

class _QuickMenu {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickMenu(this.label, this.icon, this.color, this.onTap);

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
