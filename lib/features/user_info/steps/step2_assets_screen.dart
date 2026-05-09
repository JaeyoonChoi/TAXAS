import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_info_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class Step2AssetsScreen extends ConsumerStatefulWidget {
  const Step2AssetsScreen({super.key});

  @override
  ConsumerState<Step2AssetsScreen> createState() => _Step2AssetsScreenState();
}

class _Step2AssetsScreenState extends ConsumerState<Step2AssetsScreen> {
  int _realEstate = 0;
  int _financial = 0;
  int _other = 0;
  int _debt = 0;

  @override
  void initState() {
    super.initState();
    final assets = ref.read(userInfoProvider).assets;
    _realEstate = assets.realEstate;
    _financial = assets.financial;
    _other = assets.other;
    _debt = assets.debt;
  }

  void _onNext() {
    final notifier = ref.read(userInfoProvider.notifier);
    notifier.setRealEstate(_realEstate);
    notifier.setFinancial(_financial);
    notifier.setOther(_other);
    notifier.setDebt(_debt);
    context.go(AppRoutes.step3Gift);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    final total = _realEstate + _financial + _other;
    final net = (total - _debt).clamp(0, total);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('정보 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go(AppRoutes.step1Family),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: StepProgressBar(
              totalSteps: 3,
              currentStep: 1,
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
                    '보유 자산을\n입력해주세요',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '공시지가 기준으로 입력하세요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // ── 합계 카드 ──────────────────────────────
                  _TotalAssetCard(
                    total: total,
                    net: net,
                    formatter: formatter,
                  ),
                  const SizedBox(height: 24),

                  // ── 자산 항목 입력 ─────────────────────────
                  CurrencyTextField(
                    label: '부동산 (공시지가)',
                    hint: '예: 500,000,000',
                    initialValue: _realEstate,
                    helperText: '아파트·토지·건물의 공시지가 합계',
                    onChanged: (v) => setState(() => _realEstate = v),
                  ),
                  const SizedBox(height: 14),

                  CurrencyTextField(
                    label: '금융자산',
                    hint: '예: 200,000,000',
                    initialValue: _financial,
                    helperText: '예금·주식·펀드·보험 해지환급금 합계',
                    onChanged: (v) => setState(() => _financial = v),
                  ),
                  const SizedBox(height: 14),

                  CurrencyTextField(
                    label: '기타자산',
                    hint: '예: 50,000,000',
                    initialValue: _other,
                    helperText: '차량·골프회원권·유가증권 등',
                    onChanged: (v) => setState(() => _other = v),
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 12),

                  CurrencyTextField(
                    label: '채무 (-)  ',
                    hint: '예: 100,000,000',
                    initialValue: _debt,
                    helperText: '대출금·미납세금·장례비용 등 공제 가능 채무',
                    onChanged: (v) => setState(() => _debt = v),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          BottomCta(
            primaryLabel: '다음 — 증여 이력',
            onPrimary: _onNext,
            secondaryLabel: '이전',
            onSecondary: () => context.go(AppRoutes.step1Family),
          ),
        ],
      ),
    );
  }
}

class _TotalAssetCard extends StatelessWidget {
  final int total;
  final int net;
  final NumberFormat formatter;

  const _TotalAssetCard({
    required this.total,
    required this.net,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '총 자산',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatKoreanCurrency(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '순 자산 (채무 차감)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatKoreanCurrency(net),
                  style: const TextStyle(
                    color: AppColors.goldBase,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
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
