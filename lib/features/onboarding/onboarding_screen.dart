import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.account_balance_wallet_outlined,
      title: '세금은 국가가\n알아서 깎아주지 않습니다.',
      subtitle: '증여·상속세를 정확히 계산하고\n최적의 절세 전략을 찾아드립니다.',
      tag: '자산 최적화',
    ),
    _OnboardingData(
      icon: Icons.calculate_outlined,
      title: '복잡한 세법,\nTaxas가 대신합니다',
      subtitle: '2026년 최신 세법 기준으로\n공제 항목을 자동 적용합니다.',
      tag: '자동 계산',
    ),
    _OnboardingData(
      icon: Icons.shield_outlined,
      title: '내 정보는\n내 기기에만 저장',
      subtitle: '입력하신 자산 정보는 서버로 전송되지 않고\n기기 내에만 안전하게 보관됩니다.',
      tag: '보안 저장',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  void _onSkip() => context.go(AppRoutes.dashboard);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Stack(
        children: [
          // ── 배경 장식 ──────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.navyBright.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldBase.withOpacity(0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip 버튼
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),

                // ── 페이지 내용 ────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(data: _pages[index]);
                    },
                  ),
                ),

                // ── 인디케이터 + 버튼 ──────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24, 0, 24, MediaQuery.of(context).padding.bottom + 32,
                  ),
                  child: Column(
                    children: [
                      // 점 인디케이터
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == i
                                  ? AppColors.goldBase
                                  : Colors.white24,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      // CTA 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldBase,
                            foregroundColor: AppColors.navyDeep,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _onNext,
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? '절세 시작하기 →'
                                : '다음',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 컨테이너
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navyMid, AppColors.navyLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyBright.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(data.icon, size: 52, color: AppColors.goldBase),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),

          // 태그
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.goldBase.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.goldBase.withOpacity(0.4)),
            ),
            child: Text(
              data.tag,
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),

          // 제목
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.35,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),

          // 설명
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}
