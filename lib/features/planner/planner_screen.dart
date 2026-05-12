import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 플래너 — 시기별 절세 할 일 체크리스트.
///
/// 정적 추천 항목 + 사용자별 완료 상태(SharedPreferences 로컬 저장).
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final Set<String> _done = {};
  static const _prefsKey = 'planner_done_v1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? const [];
    setState(() => _done.addAll(list));
  }

  Future<void> _toggle(String id) async {
    setState(() {
      if (!_done.add(id)) _done.remove(id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _done.toList());
  }

  static const _sections = <_PlannerSection>[
    _PlannerSection(
      label: '이번 달 안에',
      color: AppColors.error,
      tasks: [
        _PlannerTask(
          id: 'm1',
          title: '자산 정보 정확히 입력',
          desc: '부동산 공시지가·금융자산·기타·채무까지 한 번에 정리',
        ),
        _PlannerTask(
          id: 'm2',
          title: '가족 구성·자녀 나이 확인',
          desc: '미성년 vs 성인에 따라 공제 한도가 다름',
        ),
        _PlannerTask(
          id: 'm3',
          title: '최근 10년 증여 이력 빠짐없이 입력',
          desc: '상속세 합산 대상 — 누락하면 추징될 수 있음',
        ),
      ],
    ),
    _PlannerSection(
      label: '올해 안에',
      color: AppColors.warning,
      tasks: [
        _PlannerTask(
          id: 'y1',
          title: '배우자 증여 6억 활용 계획',
          desc: '배우자 간 6억까지 비과세. 자산 분산으로 누진세율 회피',
        ),
        _PlannerTask(
          id: 'y2',
          title: '자녀별 1차 사전증여 시행',
          desc: '성인 5천만 / 미성년 2천만 — 10년 갱신 주기 시작',
        ),
        _PlannerTask(
          id: 'y3',
          title: '세무사 1회 상담 받기',
          desc: '본 앱 결과를 바탕으로 전문가 검증',
        ),
      ],
    ),
    _PlannerSection(
      label: '3년 이내',
      color: AppColors.navyBase,
      tasks: [
        _PlannerTask(
          id: 'q1',
          title: '부동산 평가·이전 전략 수립',
          desc: '시가 vs 공시지가, 증여세·취득세까지 종합 검토',
        ),
        _PlannerTask(
          id: 'q2',
          title: '생명보험 계약·수익자 설계',
          desc: '상속재산 제외 가능성 — 전문가 상담 필수',
        ),
        _PlannerTask(
          id: 'q3',
          title: '가업·영농 등 특수공제 검토',
          desc: '적용 요건이 까다로워 미리 준비 필요',
        ),
      ],
    ),
    _PlannerSection(
      label: '장기 (10년+)',
      color: AppColors.success,
      tasks: [
        _PlannerTask(
          id: 'l1',
          title: '10년 단위 사전증여 분산 반복',
          desc: '같은 한도를 여러 번 활용해 절세 극대화',
        ),
        _PlannerTask(
          id: 'l2',
          title: '매년 자산·가족 정보 갱신',
          desc: '자녀 성년 진입, 재산 변동 등 반영',
        ),
        _PlannerTask(
          id: 'l3',
          title: '유언·신탁 등 승계 구조 설계',
          desc: '단순 상속 외 옵션도 검토',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final allTasks = _sections.expand((s) => s.tasks).length;
    final doneCount = _done.length;
    final pct = allTasks == 0 ? 0.0 : doneCount / allTasks;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Planner',
          style: AppText.appBarTitle(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 진행도
          Container(
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
          ),
          const SizedBox(height: 28),

          for (final section in _sections) ...[
            _SectionLabel(section: section),
            const SizedBox(height: 8),
            for (final task in section.tasks)
              _TaskRow(
                task: task,
                color: section.color,
                done: _done.contains(task.id),
                onTap: () => _toggle(task.id),
              ),
            const SizedBox(height: 20),
          ],
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
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: section.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          section.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: section.color,
            letterSpacing: 0.3,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? color : Colors.transparent,
                    border: Border.all(
                      color: done ? color : AppColors.border,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
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
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.desc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
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
