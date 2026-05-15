import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

/// 메인 쉘 — BottomNavigationBar 포함
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(route: AppRoutes.dashboard, icon: Icons.home_outlined,           activeIcon: Icons.home,            label: '홈'),
    _TabItem(route: AppRoutes.report,    icon: Icons.assessment_outlined,     activeIcon: Icons.assessment,      label: '리포트'),
    _TabItem(route: AppRoutes.planner,   icon: Icons.event_note_outlined,     activeIcon: Icons.event_note,      label: '플래너'),
    _TabItem(route: AppRoutes.community, icon: Icons.forum_outlined,          activeIcon: Icons.forum,           label: '커뮤니티'),
    _TabItem(route: AppRoutes.expert,    icon: Icons.support_agent_outlined,  activeIcon: Icons.support_agent,   label: '세무사'),
  ];

  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.report)) return 1;
    if (location.startsWith(AppRoutes.planner)) return 2;
    if (location.startsWith(AppRoutes.community)) return 3;
    if (location.startsWith(AppRoutes.expert)) return 4;
    return 0;
  }

  static const String _routeAt0 = AppRoutes.dashboard;
  static const String _routeAt1 = AppRoutes.report;
  static const String _routeAt2 = AppRoutes.planner;
  static const String _routeAt3 = AppRoutes.community;
  static const String _routeAt4 = AppRoutes.expert;

  void _goToIndex(BuildContext context, int i) {
    final current = _indexFromLocation(GoRouterState.of(context).uri.path);
    if (i == current) return;
    // 방향: 다음 탭으로 갈 때 +1 (오른쪽에서 슬라이드 인), 이전 탭은 -1 (왼쪽에서).
    TabTransition.direction = i > current ? 1 : -1;
    switch (i) {
      case 0:
        context.go(_routeAt0);
        break;
      case 1:
        context.go(_routeAt1);
        break;
      case 2:
        context.go(_routeAt2);
        break;
      case 3:
        context.go(_routeAt3);
        break;
      case 4:
        context.go(_routeAt4);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: _SwipeTabs(
        currentIndex: currentIndex,
        maxIndex: _tabs.length - 1,
        onSwipeNext: () => _goToIndex(context, currentIndex + 1),
        onSwipePrev: () => _goToIndex(context, currentIndex - 1),
        child: child,
      ),
      bottomNavigationBar: _TaxasBottomNav(
        currentIndex: currentIndex,
        tabs: _tabs,
        onTap: (i) => _goToIndex(context, i),
      ),
    );
  }
}

/// 좌우 스와이프로 인접 탭 이동을 트리거하는 래퍼.
///
/// - velocity 기반 (빠른 플릭)
/// - 또는 화면 너비의 20% 이상 드래그
/// 위 둘 중 하나만 만족해도 트리거. 세로 스크롤과 충돌 안 함 — 가로 우세 드래그만 캐치.
class _SwipeTabs extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final int maxIndex;
  final VoidCallback onSwipeNext;
  final VoidCallback onSwipePrev;

  const _SwipeTabs({
    required this.child,
    required this.currentIndex,
    required this.maxIndex,
    required this.onSwipeNext,
    required this.onSwipePrev,
  });

  @override
  State<_SwipeTabs> createState() => _SwipeTabsState();
}

class _SwipeTabsState extends State<_SwipeTabs> {
  double _accumDx = 0;

  void _maybeTrigger(double velocityDx, double screenWidth) {
    final byVelocity = velocityDx.abs() > 250;
    final byDistance = _accumDx.abs() > screenWidth * 0.20;
    if (!byVelocity && !byDistance) return;

    final goingNext = (byVelocity ? velocityDx < 0 : _accumDx < 0);
    if (goingNext && widget.currentIndex < widget.maxIndex) {
      widget.onSwipeNext();
    } else if (!goingNext && widget.currentIndex > 0) {
      widget.onSwipePrev();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _accumDx = 0,
      onHorizontalDragUpdate: (d) => _accumDx += d.delta.dx,
      onHorizontalDragEnd: (d) =>
          _maybeTrigger(d.primaryVelocity ?? 0, screenWidth),
      child: widget.child,
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
