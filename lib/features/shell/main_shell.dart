import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

/// 메인 쉘 — BottomNavigationBar 포함
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(route: AppRoutes.dashboard,  icon: Icons.home_outlined,         activeIcon: Icons.home,                label: '홈'),
    _TabItem(route: AppRoutes.taxResult,  icon: Icons.calculate_outlined,    activeIcon: Icons.calculate,           label: '계산'),
    _TabItem(route: AppRoutes.community,  icon: Icons.forum_outlined,        activeIcon: Icons.forum,               label: '커뮤니티'),
    _TabItem(route: AppRoutes.info,       icon: Icons.article_outlined,      activeIcon: Icons.article,             label: '콘텐츠'),
    _TabItem(route: AppRoutes.portfolio,  icon: Icons.pie_chart_outline,     activeIcon: Icons.pie_chart,           label: '포트폴리오'),
  ];

  int _indexFromLocation(String location) {
    if (location == AppRoutes.taxResult) return 1;
    if (location.startsWith(AppRoutes.community)) return 2;
    if (location.startsWith(AppRoutes.info)) return 3;
    if (location.startsWith(AppRoutes.portfolio)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: _TaxasBottomNav(
        currentIndex: currentIndex,
        tabs: _tabs,
        onTap: (i) {
          switch (i) {
            case 0: context.go(AppRoutes.dashboard); break;
            case 1: context.go(AppRoutes.taxResult); break;
            case 2: context.go(AppRoutes.community); break;
            case 3: context.go(AppRoutes.info); break;
            case 4: context.go(AppRoutes.portfolio); break;
          }
        },
      ),
    );
  }
}

class _TabItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _TaxasBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _TaxasBottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.navyBase.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          size: 22,
                          color: isActive
                              ? AppColors.navyBase
                              : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.navyBase
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
