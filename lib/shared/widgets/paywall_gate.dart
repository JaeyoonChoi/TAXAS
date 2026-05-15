import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/subscription_provider.dart';

/// 프리미엄 콘텐츠 게이트 — 비구독 시 블러 + 상단 "구독하고 확인하기" CTA.
///
/// [title]/[desc]/[features]로 어떤 콘텐츠를 unlock하는지 카드 문구 커스터마이즈.
class PaywallGate extends ConsumerWidget {
  final Widget child;
  final String headerTitle;
  final String headerDesc;
  final List<PaywallFeature> features;

  const PaywallGate({
    super.key,
    required this.child,
    this.headerTitle = '절세 시뮬레이터, AI 분석,\n세무사 공유까지 한번에',
    this.headerDesc = '내 상황에 맞춘 단계별 절세 전략 + 에이전트 상담을\n프리미엄 구독으로 이용해보세요.',
    this.features = const [
      PaywallFeature(
        icon: Icons.tune,
        title: '맞춤 절세 시뮬레이터',
        desc: '전략별 절감 효과를 즉시 시뮬레이션',
      ),
      PaywallFeature(
        icon: Icons.auto_awesome,
        title: 'AI 맞춤 분석 + 에이전트',
        desc: '내 상황에 맞춘 단계별 절세 코칭',
      ),
      PaywallFeature(
        icon: Icons.share_outlined,
        title: '세무사 공유',
        desc: '리포트 요약을 카톡·메일로 즉시 전송',
      ),
    ],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubscribed = ref.watch(isSubscribedProvider);
    if (isSubscribed) return child;

    return Stack(
      children: [
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Opacity(opacity: 0.9, child: child),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withValues(alpha: 0.95),
                  AppColors.surface.withValues(alpha: 0.7),
                  AppColors.surface.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _PaywallCard(
              headerTitle: headerTitle,
              headerDesc: headerDesc,
              features: features,
            ),
          ),
        ),
      ],
    );
  }
}

class PaywallFeature {
  final IconData icon;
  final String title;
  final String desc;
  const PaywallFeature({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class _PaywallCard extends ConsumerWidget {
  final String headerTitle;
  final String headerDesc;
  final List<PaywallFeature> features;

  const _PaywallCard({
    required this.headerTitle,
    required this.headerDesc,
    required this.features,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldBase.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.lock_outline,
                color: AppColors.goldDeep, size: 20),
          ),
          const SizedBox(height: 14),
          Text('프리미엄 전용', style: AppText.metaLabel.copyWith(
            color: AppColors.goldDeep,
            letterSpacing: 1.6,
          )),
          const SizedBox(height: 8),
          Text(
            headerTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headerDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSubscribeSheet(context, ref),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('구독하고 확인하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscribeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 24, height: 1.5, color: AppColors.goldBase),
            const SizedBox(height: 14),
            Text('ATAX PREMIUM', style: AppText.metaLabel),
            const SizedBox(height: 8),
            Text('한 단계 더 깊은 절세 전략',
                style: AppText.sectionTitle(size: 20)),
            const SizedBox(height: 14),
            for (final f in features)
              _BenefitRow(icon: f.icon, title: f.title, desc: f.desc),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('월 구독', style: AppText.metaLabel),
                        const SizedBox(height: 4),
                        const Text(
                          '9,900원',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldBase.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '7일 무료 체험',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final ok = await ref
                      .read(isSubscribedProvider.notifier)
                      .activate();
                  if (!context.mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? '프리미엄 7일 무료 체험이 시작되었어요.'
                          : '구독 저장에 실패했어요. 새로고침 후 다시 시도해주세요.'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                ),
                child: const Text('무료로 시작하기'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '7일 후 자동 결제됩니다. 언제든 해지 가능.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.navyBase.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppColors.navyBase),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
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
