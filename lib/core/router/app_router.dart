import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../firebase_options.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/user_info/steps/step1_family_screen.dart';
import '../../features/user_info/steps/step2_assets_screen.dart';
import '../../features/user_info/steps/step3_gift_history_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/planner/planner_screen.dart';
import '../../features/expert/expert_screen.dart';
import '../../features/agent/agent_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/kakao_callback_screen.dart';
import '../../shared/providers/auth_provider.dart';

part 'app_router.g.dart';

/// 탭 전환 방향 — 다음 탭으로 갈 때 +1, 이전 탭으로 갈 때 -1.
/// MainShell이 네비게이션 직전에 설정, 라우트 페이지 빌더가 트랜지션 방향에 사용.
class TabTransition {
  TabTransition._();
  static int direction = 1;
}

/// 라우트 경로 상수
class AppRoutes {
  AppRoutes._();

  static const String onboarding    = '/onboarding';
  static const String login         = '/auth/login';
  static const String signup        = '/auth/signup';
  static const String kakaoCallback = '/auth/kakao/callback';
  static const String dashboard     = '/';
  static const String step1Family   = '/input/family';
  static const String step2Assets   = '/input/assets';
  static const String step3Gift     = '/input/gift-history';
  static const String report        = '/report';
  static const String planner       = '/planner';
  static const String community     = '/community';
  static const String expert        = '/expert';
  static const String agent         = '/agent';

  // 호환용 — 기존 코드가 참조
  static const String taxResult     = report;
  static const String portfolio     = report;
  static const String info          = community;
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final notifier = _AuthRouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Firebase가 비활성화면 인증 우회 — 로컬 전용 모드
      if (!useFirebase) return null;

      final loggedIn = ref.read(authStateProvider).valueOrNull != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/auth/');
      final isOnboarding = loc == AppRoutes.onboarding;

      // 미인증 + 보호된 라우트 → 로그인
      if (!loggedIn && !isAuthRoute && !isOnboarding) {
        return AppRoutes.login;
      }
      // 인증됨 + auth 라우트 → 대시보드
      if (loggedIn && isAuthRoute) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      // ─ 온보딩 ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ─ 인증 ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.kakaoCallback,
        name: 'kakao-callback',
        builder: (context, state) => KakaoCallbackScreen(
          code: state.uri.queryParameters['code'],
          error: state.uri.queryParameters['error'],
        ),
      ),

      // ─ 메인 쉘 (BottomNav) ──────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => _tabPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.report,
            name: 'report',
            pageBuilder: (context, state) => _tabPage(state, const ReportScreen()),
          ),
          GoRoute(
            path: AppRoutes.planner,
            name: 'planner',
            pageBuilder: (context, state) => _tabPage(state, const PlannerScreen()),
          ),
          GoRoute(
            path: AppRoutes.community,
            name: 'community',
            pageBuilder: (context, state) => _tabPage(state, const CommunityScreen()),
          ),
          GoRoute(
            path: AppRoutes.expert,
            name: 'expert',
            pageBuilder: (context, state) => _tabPage(state, const ExpertScreen()),
          ),
        ],
      ),

      // ─ 사용자 입력 플로우 (쉘 밖, 풀스크린 스텝) ──────────
      GoRoute(
        path: AppRoutes.step1Family,
        name: 'step1-family',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Step1FamilyScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.step2Assets,
        name: 'step2-assets',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Step2AssetsScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.step3Gift,
        name: 'step3-gift',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const Step3GiftHistoryScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // ─ AI 에이전트 (풀스크린) ─────────────────────────
      GoRoute(
        path: AppRoutes.agent,
        name: 'agent',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AgentScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
    ],
  );
}

/// 인증 상태 변화를 GoRouter에 알리는 ChangeNotifier 어댑터.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _sub = _ref.listen<AsyncValue<Object?>>(
      authStateProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final AppRouterRef _ref;
  late final ProviderSubscription<AsyncValue<Object?>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// 탭 라우트용 페이지 — [TabTransition.direction]에 따라 좌/우 슬라이드 트랜지션 적용.
/// 페이지 빌더가 호출되는 시점에 capture한 방향을 closure에 보존해, 트랜지션 끝까지 같은 방향으로 동작.
CustomTransitionPage _tabPage(GoRouterState state, Widget child) {
  final dir = TabTransition.direction.toDouble();
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final curvedSec = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: Offset(dir, 0), end: Offset.zero).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset.zero, end: Offset(-dir, 0)).animate(curvedSec),
          child: child,
        ),
      );
    },
  );
}

/// 슬라이드 전환 (오른쪽 → 왼쪽)
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  const curve = Curves.easeInOutCubic;
  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  return SlideTransition(
    position: animation.drive(tween),
    child: child,
  );
}

/// 페이드 전환
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}
