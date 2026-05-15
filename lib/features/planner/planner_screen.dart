import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/providers/planner_state_provider.dart';
import '../../shared/providers/tax_result_provider.dart';
import '../../shared/providers/user_info_provider.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/paywall_gate.dart';

/// 플래너 — 사용자 리포트(가족·자산·세액) 기반 개인 맞춤 절세 할 일.
///
/// 무료: 진행도 카드까지 노출. 시기별 할 일은 프리미엄 게이트로 잠금.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

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
        title: Text('Planner', style: AppText.appBarTitle()),
      ),
      body: !hasData
          ? _EmptyState(onTap: () => context.go(AppRoutes.step1Family))
          : _buildContent(context, ref, userInfo, result),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, dynamic userInfo, dynamic result) {
    final done = ref.watch(plannerStateProvider);
    final sections = _buildPersonalizedSections(userInfo, result);
    final allTasks = sections.expand((s) => s.tasks).length;
    final doneCount =
        sections.expand((s) => s.tasks).where((t) => done.contains(t.id)).length;
    final pct = allTasks == 0 ? 0.0 : doneCount / allTasks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 진행도 — 무료 노출
        _ProgressCard(
          doneCount: doneCount,
          allTasks: allTasks,
          pct: pct,
        ),
        const SizedBox(height: 28),

        // 시기별 할 일 — 프리미엄 게이트
        PaywallGate(
          headerTitle: '내 정보 기반 맞춤 플래너',
          headerDesc: '입력하신 자산·가족·세액 데이터로 만든\n시기별 절세 액션 리스트',
          features: const [
            PaywallFeature(
              icon: Icons.event_note_outlined,
              title: '시기별 맞춤 할 일',
              desc: '이번 달 / 올해 / 3년 / 장기로 정리',
            ),
            PaywallFeature(
              icon: Icons.savings_outlined,
              title: '내 절감 가능 금액 표시',
              desc: '계산된 세액을 바로 액션에 반영',
            ),
            PaywallFeature(
              icon: Icons.check_circle_outline,
              title: '진행도 체크',
              desc: '완료한 항목을 추적해 관리',
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final section in sections) ...[
                _SectionLabel(section: section),
                const SizedBox(height: 8),
                for (final task in section.tasks)
                  _TaskRow(
                    task: task,
                    color: section.color,
                    done: done.contains(task.id),
                    onTap: () =>
                        ref.read(plannerStateProvider.notifier).toggle(task.id),
                  ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 사용자 리포트를 바탕으로 시기별 할 일 동적 생성.
  List<_PlannerSection> _buildPersonalizedSections(
      dynamic userInfo, dynamic result) {
    final family = userInfo.family;
    final assets = userInfo.assets;
    final priorGiftTotal = (userInfo.giftHistory as List)
        .fold<int>(0, (s, g) => s + (g.amount as int));
    final ownerAge = family.ownerAge as int;
    final hasSpouse = family.hasSpouse as bool;
    final childAges = family.childAges as List<int>;
    final adultChildren = childAges.where((a) => a >= 19).length;
    final minorChildren = childAges.where((a) => a < 19).length;
    final realEstate = assets.realEstate as int;
    final financial = assets.financial as int;
    final other = assets.other as int;
    final debt = assets.debt as int;
    final totalNet = assets.totalNet as int;
    final savings = result.planningSavings as int;
    final noPlan = result.noPlanningTax as int;
    final taxableBase = result.inheritanceTaxableBase as int;

    // 나이대별 긴급도 (60 미만/60-70/70+) — 같은 자산 프로필도 다른 액션 우선순위
    final urgencyLabel = ownerAge >= 70
        ? '시급'
        : ownerAge >= 60
            ? '권장'
            : '여유';

    final familySummary = [
      if (hasSpouse) '배우자',
      if (adultChildren > 0) '성인 자녀 ${adultChildren}명',
      if (minorChildren > 0) '미성년 자녀 ${minorChildren}명',
    ].join(' · ');

    final thisMonth = <_PlannerTask>[
      _PlannerTask(
        id: 'm_summary',
        title: '내 리포트 현황 점검 ($urgencyLabel)',
        desc: '${ownerAge}세 · ${familySummary.isEmpty ? "단독" : familySummary} · '
            '순자산 ${formatKoreanCurrency(totalNet)} · 예상 상속세 ${formatKoreanCurrency(noPlan)}',
      ),
      if (debt > 0)
        _PlannerTask(
          id: 'm_debt',
          title: '채무 ${formatKoreanCurrency(debt)} 증빙자료 확보',
          desc: '상속세 공제 적용 위해 채무 계약서·잔액증명서 미리 확보',
        ),
      if (priorGiftTotal == 0 && (hasSpouse || childAges.isNotEmpty))
        _PlannerTask(
          id: 'm_giftstart',
          title: '사전증여 0원 — 첫 증여 시점 결정',
          desc: '10년 합산 규칙상 빠를수록 효과. ${ownerAge}세 기준 '
              '${ownerAge < 60 ? "여유 있으나 일찍 시작 권장" : ownerAge < 70 ? "지금이 골든 타임" : "10년+ 생존 가능성 검토 필요"}',
        ),
      if (priorGiftTotal > 0)
        _PlannerTask(
          id: 'm_giftcheck',
          title: '기존 증여 ${formatKoreanCurrency(priorGiftTotal)} 합산 확인',
          desc: '최근 10년 증여는 상속재산에 합산. 누락 없이 입력했는지 [정보 수정]에서 점검',
        ),
      if (taxableBase > 0 && noPlan > 0)
        _PlannerTask(
          id: 'm_bracket',
          title: '과세표준 ${formatKoreanCurrency(taxableBase)} 구간 확인',
          desc: '리포트 탭 [계산 상세 내역]에서 적용 세율과 누진공제 단계별 확인',
        ),
    ];

    final thisYear = <_PlannerTask>[
      if (hasSpouse)
        _PlannerTask(
          id: 'y_spouse',
          title: '배우자 증여 6억 활용 ($urgencyLabel)',
          desc: '배우자 간 10년간 6억까지 비과세. '
              '현재 순자산 ${formatKoreanCurrency(totalNet)} 중 6억 분산 시 누진세율 회피',
        ),
      if (adultChildren > 0)
        _PlannerTask(
          id: 'y_adult',
          title: '성인 자녀 ${adultChildren}명에게 ${formatKoreanCurrency(adultChildren * 50000000)} 사전증여',
          desc: '1인당 5천만원 × ${adultChildren}명 = '
              '${formatKoreanCurrency(adultChildren * 50000000)} 비과세 (10년 단위 갱신)',
        ),
      if (minorChildren > 0)
        _PlannerTask(
          id: 'y_minor',
          title: '미성년 자녀 ${minorChildren}명에게 ${formatKoreanCurrency(minorChildren * 20000000)} 사전증여',
          desc: '1인당 2천만원 × ${minorChildren}명 = '
              '${formatKoreanCurrency(minorChildren * 20000000)}. '
              '성년 도달 시 한도가 5천만원으로 상향됨',
        ),
      if (financial >= 100000000)
        _PlannerTask(
          id: 'y_finance',
          title: '금융자산 ${formatKoreanCurrency(financial)} 공제 활용',
          desc: '금융재산공제는 금융자산의 20% (최대 2억) 자동 적용. '
              '예상 공제 ${formatKoreanCurrency((financial * 0.2).toInt().clamp(0, 200000000))}',
        ),
      if (savings > 0)
        _PlannerTask(
          id: 'y_savings',
          title: '절감 가능 ${formatKoreanCurrency(savings)} — 액션 플랜 수립',
          desc: '권장 분배대로 사전증여 시 절세 예상치. '
              '연간 ${formatKoreanCurrency(savings ~/ 10)} 분할 실행도 고려',
        ),
      _PlannerTask(
        id: 'y_consult',
        title: '세무사 1회 상담 (${ownerAge}세 기준)',
        desc: '리포트를 바탕으로 세무사 탭에서 전문가 매칭. '
            '${ownerAge >= 70 ? "사망 임박 대비 상속세 신고 준비도 검토" : "사전증여·평가전략 검증"}',
      ),
    ];

    final midTerm = <_PlannerTask>[
      if (realEstate >= 200000000)
        _PlannerTask(
          id: 't_realestate',
          title: '부동산 ${formatKoreanCurrency(realEstate)} 평가·이전 전략',
          desc: '시가 vs 공시지가, 증여세·취득세 종합 검토. '
              '${realEstate >= 1000000000 ? "10억+ 규모는 분할 증여나 부담부증여 검토 필수" : "공시지가 발표 전 사전증여 시 절세 효과 큼"}',
        ),
      _PlannerTask(
        id: 't_insurance',
        title: ownerAge >= 65
            ? '종신보험 가입 어려움 — 정기보험·연금 검토'
            : '생명보험 계약·수익자 설계',
        desc: ownerAge >= 65
            ? '${ownerAge}세 기준 종신보험 가입 제약 가능. 정기보험·기존 계약 수익자 재설계로 대체'
            : '계약자·수익자 설계에 따라 상속재산에서 제외 가능. 세금 납부 재원 확보용',
      ),
      if (other >= 500000000)
        _PlannerTask(
          id: 't_business',
          title: '기타자산 ${formatKoreanCurrency(other)} — 가업/영농 공제 검토',
          desc: '5억+ 규모는 가업승계공제(최대 600억) 적용 요건 확인 권장. '
              '10년 사후관리 의무 등 사전 검토 필수',
        ),
      if (totalNet >= 3000000000)
        _PlannerTask(
          id: 't_trust',
          title: '30억+ 자산 — 신탁 활용 검토',
          desc: '유언대용신탁·유언신탁으로 분쟁 예방 + 단계적 승계 설계 가능',
        ),
    ];

    final longTerm = <_PlannerTask>[
      _PlannerTask(
        id: 'l_repeat',
        title: ownerAge < 60
            ? '10년 단위 사전증여 2~3회 반복 가능'
            : ownerAge < 70
                ? '10년 사전증여 1~2회 가능 — 즉시 시작'
                : '10년 합산 회피 어려움 — 즉시 증여 + 보험 활용',
        desc: '같은 한도를 여러 번 활용해 절세 극대화. '
            '${ownerAge}세 기준 ${(85 - ownerAge) ~/ 10}회 가능성',
      ),
      if (minorChildren > 0) ...[
        for (int i = 0; i < childAges.length; i++)
          if (childAges[i] < 19)
            _PlannerTask(
              id: 'l_grow_$i',
              title: '자녀${i + 1} (${childAges[i]}세) → 19세 도달까지 ${19 - childAges[i]}년',
              desc: '성년 도달 시 비과세 한도 2천만원 → 5천만원 상향. '
                  '${19 - childAges[i]}년 후 추가 증여 가능',
            ),
      ],
      _PlannerTask(
        id: 'l_review',
        title: '매년 자산·가족 정보 갱신',
        desc: '${formatKoreanCurrency(totalNet)} 기준치에서 변동 시 절세 전략도 재조정 필요',
      ),
      _PlannerTask(
        id: 'l_will',
        title: ownerAge >= 65
            ? '유언장 작성 — 우선순위 높음'
            : '유언·신탁 승계 구조 설계',
        desc: ownerAge >= 65
            ? '${ownerAge}세 기준 유언장 작성 권장. 분쟁 예방 + 절세 효과 동시'
            : '단순 상속 외 옵션 검토. 신탁·유언대용신탁 활용',
      ),
    ];

    return [
      _PlannerSection(label: '이번 달 안에', color: AppColors.error, tasks: thisMonth),
      _PlannerSection(label: '올해 안에', color: AppColors.warning, tasks: thisYear),
      _PlannerSection(label: '3년 이내', color: AppColors.navyBase, tasks: midTerm),
      _PlannerSection(label: '장기 (10년+)', color: AppColors.success, tasks: longTerm),
    ];
  }
}

// ── 위젯 ─────────────────────────────────────────────────

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
            const Icon(Icons.event_note_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              '자산 정보를 입력하면\n맞춤 절세 플래너가 생성돼요',
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

class _ProgressCard extends StatelessWidget {
  final int doneCount;
  final int allTasks;
  final double pct;
  const _ProgressCard({
    required this.doneCount,
    required this.allTasks,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
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
          Text('내 절세 플래너 진행도', style: AppText.metaLabel),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$doneCount',
                style: AppText.bigNumber(
                  size: 32,
                  color: AppColors.textPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/ $allTasks 완료',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(pct * 100).round()}%',
                style: AppText.bigNumber(
                  size: 22,
                  color: AppColors.goldDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 3,
              backgroundColor: AppColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.goldBase),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerSection {
  final String label;
  final Color color;
  final List<_PlannerTask> tasks;
  const _PlannerSection({
    required this.label,
    required this.color,
    required this.tasks,
  });
}

class _PlannerTask {
  final String id;
  final String title;
  final String desc;
  const _PlannerTask({
    required this.id,
    required this.title,
    required this.desc,
  });
}

class _SectionLabel extends StatelessWidget {
  final _PlannerSection section;
  const _SectionLabel({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            color: section.color,
          ),
          const SizedBox(width: 8),
          Text(
            section.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final _PlannerTask task;
  final Color color;
  final bool done;
  final VoidCallback onTap;
  const _TaskRow({
    required this.task,
    required this.color,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: done ? color : Colors.transparent,
                    border: Border.all(
                      color: done ? color : AppColors.border,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: done
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          decoration: done ? TextDecoration.lineThrough : null,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.desc,
                        style: TextStyle(
                          fontSize: 12,
                          color: done
                              ? AppColors.textTertiary
                              : AppColors.textSecondary,
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
    );
  }
}
