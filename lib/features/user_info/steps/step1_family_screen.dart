import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_info_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class Step1FamilyScreen extends ConsumerStatefulWidget {
  const Step1FamilyScreen({super.key});

  @override
  ConsumerState<Step1FamilyScreen> createState() => _Step1FamilyScreenState();
}

class _Step1FamilyScreenState extends ConsumerState<Step1FamilyScreen> {
  late int _ownerAge;
  late bool _hasSpouse;
  late int _childCount;
  late List<int> _childAges;

  @override
  void initState() {
    super.initState();
    final family = ref.read(userInfoProvider).family;
    _ownerAge = family.ownerAge;
    _hasSpouse = family.hasSpouse;
    _childCount = family.childCount;
    _childAges = List<int>.from(family.childAges);
    if (_childAges.isEmpty && _childCount > 0) {
      _childAges = List.filled(_childCount, 30);
    }
  }

  void _setChildCount(int count) {
    setState(() {
      _childCount = count;
      while (_childAges.length < count) _childAges.add(30);
      while (_childAges.length > count) _childAges.removeLast();
    });
  }

  void _onNext() {
    final notifier = ref.read(userInfoProvider.notifier);
    notifier.setOwnerAge(_ownerAge);
    notifier.setHasSpouse(_hasSpouse);
    _setChildCount(_childCount);
    for (int i = 0; i < _childAges.length; i++) {
      notifier.setChildAge(i, _childAges[i]);
    }
    notifier.setChildCount(_childCount);
    context.go(AppRoutes.step2Assets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('정보 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AppRoutes.dashboard),
        ),
      ),
      body: Column(
        children: [
          // 진행 바
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: StepProgressBar(
              totalSteps: 3,
              currentStep: 0,
              labels: const ['가족', '자산', '증여이력'],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    '가족관계를\n알려주세요',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '공제 항목 계산에 사용됩니다.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  // ── 본인 나이 ────────────────────────────
                  _FieldLabel('본인(피상속인) 나이'),
                  const SizedBox(height: 10),
                  _AgeSlider(
                    value: _ownerAge,
                    min: 30,
                    max: 100,
                    onChanged: (v) => setState(() => _ownerAge = v),
                  ),
                  const SizedBox(height: 24),

                  // ── 배우자 ───────────────────────────────
                  _FieldLabel('배우자'),
                  const SizedBox(height: 10),
                  _ToggleSelector(
                    options: const ['없음', '있음'],
                    selectedIndex: _hasSpouse ? 1 : 0,
                    onChanged: (i) => setState(() => _hasSpouse = i == 1),
                  ),
                  const SizedBox(height: 24),

                  // ── 자녀 수 ──────────────────────────────
                  _FieldLabel('자녀 수'),
                  const SizedBox(height: 10),
                  _CountSelector(
                    value: _childCount,
                    min: 0,
                    max: 8,
                    onChanged: _setChildCount,
                  ),

                  // ── 자녀별 나이 ──────────────────────────
                  if (_childCount > 0) ...[
                    const SizedBox(height: 20),
                    _FieldLabel('자녀 나이'),
                    const SizedBox(height: 10),
                    ...List.generate(_childCount, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AgeSlider(
                          label: '${i + 1}번째 자녀',
                          value: _childAges[i],
                          min: 0,
                          max: 60,
                          onChanged: (v) =>
                              setState(() => _childAges[i] = v),
                          isMinorBadge: _childAges[i] < 19,
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── CTA ──────────────────────────────────────
          BottomCta(
            primaryLabel: '다음 — 자산 정보',
            onPrimary: _onNext,
            secondaryLabel: '홈으로',
            onSecondary: () => context.go(AppRoutes.dashboard),
          ),
        ],
      ),
    );
  }
}

// ── 서브 위젯 ────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _AgeSlider extends StatelessWidget {
  final String? label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool isMinorBadge;

  const _AgeSlider({
    this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.isMinorBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (label != null)
                Text(label!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              if (label != null) const Spacer(),
              Text(
                '$value세',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyBase,
                ),
              ),
              if (isMinorBadge) ...[
                const SizedBox(width: 8),
                const StatusBadge(label: '미성년', color: AppColors.warning),
              ],
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: AppColors.navyBase,
            inactiveColor: AppColors.surfaceAlt,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _ToggleSelector extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ToggleSelector({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final isSelected = i == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navyBase : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.navyBase : AppColors.border,
                ),
              ),
              child: Text(
                options[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CountSelector extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CountSelector({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.navyBase,
            disabledColor: AppColors.border,
          ),
          Text(
            '$value명',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.navyBase,
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.navyBase,
            disabledColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}
