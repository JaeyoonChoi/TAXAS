import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/auth_provider.dart';

/// Kakao OAuth 콜백 — URL의 `?code=...`를 받아 서버 토큰 교환 후 Firebase 로그인.
class KakaoCallbackScreen extends ConsumerStatefulWidget {
  final String? code;
  final String? error;
  const KakaoCallbackScreen({super.key, this.code, this.error});

  @override
  ConsumerState<KakaoCallbackScreen> createState() =>
      _KakaoCallbackScreenState();
}

class _KakaoCallbackScreenState extends ConsumerState<KakaoCallbackScreen> {
  String? _displayError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
  }

  Future<void> _handle() async {
    if (widget.error != null && widget.error!.isNotEmpty) {
      setState(() => _displayError = '카카오 로그인이 취소되었거나 실패했습니다.');
      return;
    }
    final code = widget.code;
    if (code == null || code.isEmpty) {
      setState(() => _displayError = '인증 코드가 없습니다. 다시 시도해주세요.');
      return;
    }

    await ref.read(authControllerProvider.notifier).completeKakaoLogin(code);
    final authState = ref.read(authControllerProvider);
    if (!mounted) return;
    if (authState.hasError) {
      setState(() => _displayError = authState.error.toString());
    } else {
      // 성공 — 메인 라우터 redirect 콜백이 대시보드로 보냄
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _displayError == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      '카카오 로그인 처리 중…',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      _displayError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('로그인 화면으로'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
