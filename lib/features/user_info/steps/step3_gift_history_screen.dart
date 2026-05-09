import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/models/user_info_state.dart';
import '../../../shared/providers/user_info_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class Step3GiftHistoryScreen extends ConsumerStatefulWidget {
  const Step3GiftHistoryScreen({super.key});

  @override
  ConsumerState<Step3GiftHistoryScreen> createState() =>
      _Step3GiftHistoryScreenState();
}

class _Step3GiftHistoryScreenState
    extends ConsumerState<Step3GiftHistoryScreen> {
  final NumberFormat _formatter = NumberFormat('#,###', 'ko_KR');
  final int _currentYear = DateTime.now().year;

  void _showAddDialog() {
    String recipientName = '';
    String relationship = '자녀';
    int amount = 0;
    int year = _currentYear;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddGiftSheet(
        currentYear: _currentYear,
        onSave: (name, rel, amt, yr) {
          final record = GiftRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            recipientName: name,
            relationship: rel,
            amount: amt,
            year: yr,
          );
          ref.read(userInfoProvider.notifier).addGiftRecord(record);
        },
      ),
    );
  }

  void _deleteRecord(String id) {
    ref.read(userInfoProvider.notifier).removeGiftRecord(id);
  }

  void _onComplete() {
    context.go(AppRoutes.taxResult);
  }

  @override
  Widget build(BuildContext context) {
    final giftHistory = ref.watch(userInfoProvider).giftHistory;
    final totalGift =
        giftHistory.fold(0, (sum, r) => sum + r.amount);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('정보 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AppRoutes.step2Assets),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: StepProgressBar(
              totalSteps: 3,
              currentStep: 2,
              labels: const ['가족', '자산', '증여이력'],
            ),
          ),

          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          '최근 10년간\n증여 이력',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppColors.navyDeep,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '상속세 계산 시 10년 내 증여액이 합산됩니다.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        // 안내 배너
                        _InfoBanner(),
                        const SizedBox(height: 20),

                        // 합계
                        if (giftHistory.isNotEmpty) ...[
                          _TotalGiftCard(
                            total: totalGift,
                            formatter: _formatter,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 추가 버튼
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            side: const BorderSide(
                                color: AppColors.navyBase, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('증여 이력 추가'),
                          onPressed: _showAddDialog,
                        ),
                      ],
                    ),
                  ),
                ),

                // 이력 목록
                if (giftHistory.isEmpty)
                  const SliverToBoxAdapter(
                    child: _EmptyGiftState(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final record = giftHistory[i];
                        return _GiftRecordCard(
                          record: record,
                          formatter: _formatter,
                          onDelete: () => _deleteRecord(record.id),
                        );
                      },
                      childCount: giftHistory.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          BottomCta(
            primaryLabel: '계산 결과 보기',
            onPrimary: _onComplete,
            secondaryLabel: '이전',
            onSecondary: () => context.go(AppRoutes.step2Assets),
          ),
        ],
      ),
    );
  }
}

// ── 서브 위젯 ────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '증여 이력이 없는 경우 건너뛰어도 됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.info,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalGiftCard extends StatelessWidget {
  final int total;
  final NumberFormat formatter;

  const _TotalGiftCard({required this.total, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.navyBase.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navyBase.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '총 사전 증여액',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            formatKoreanCurrency(total),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.navyBase,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftRecordCard extends StatelessWidget {
  final GiftRecord record;
  final NumberFormat formatter;
  final VoidCallback onDelete;

  const _GiftRecordCard({
    required this.record,
    required this.formatter,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Dismissible(
        key: Key(record.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => onDelete(),
        child: Container(
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
                  color: AppColors.navyBase.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppColors.navyBase,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          record.recipientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: record.relationship,
                          color: AppColors.navyBase,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.year}년 · ${formatKoreanCurrency(record.amount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGiftState extends StatelessWidget {
  const _EmptyGiftState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: AppColors.textTertiary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              '증여 이력이 없습니다',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 추가 다이얼로그 ─────────────────────────────────────

class _AddGiftSheet extends StatefulWidget {
  final int currentYear;
  final Function(String name, String relationship, int amount, int year) onSave;

  const _AddGiftSheet({required this.currentYear, required this.onSave});

  @override
  State<_AddGiftSheet> createState() => _AddGiftSheetState();
}

class _AddGiftSheetState extends State<_AddGiftSheet> {
  final _nameController = TextEditingController();
  String _relationship = '자녀';
  int _amount = 0;
  int _year = 0;

  @override
  void initState() {
    super.initState();
    _year = widget.currentYear;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relationships = ['배우자', '자녀', '부모', '기타'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '증여 이력 추가',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '수증자 이름',
              hintText: '예: 홍길동',
            ),
          ),
          const SizedBox(height: 14),

          // 관계 선택
          const Text(
            '관계',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: relationships.map((r) {
              final isSelected = r == _relationship;
              return GestureDetector(
                onTap: () => setState(() => _relationship = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navyBase : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.navyBase : AppColors.border,
                    ),
                  ),
                  child: Text(
                    r,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          CurrencyTextField(
            label: '증여 금액',
            hint: '예: 50,000,000',
            initialValue: _amount,
            onChanged: (v) => setState(() => _amount = v),
          ),
          const SizedBox(height: 14),

          // 연도 선택
          DropdownButtonFormField<int>(
            value: _year,
            decoration: const InputDecoration(labelText: '증여 연도'),
            items: List.generate(10, (i) {
              final yr = widget.currentYear - i;
              return DropdownMenuItem(value: yr, child: Text('$yr년'));
            }),
            onChanged: (v) => setState(() => _year = v ?? _year),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && _amount > 0) {
                widget.onSave(
                  _nameController.text,
                  _relationship,
                  _amount,
                  _year,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('추가하기'),
          ),
        ],
      ),
    );
  }
}
