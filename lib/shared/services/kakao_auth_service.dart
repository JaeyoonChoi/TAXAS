import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/api_config.dart';

/// Kakao 로그인 — OAuth code 흐름 + Vercel `/api/kakao-auth` → Firebase 로그인.
class KakaoAuthService {
  KakaoAuthService();

  /// Kakao authorize 페이지로 브라우저 리다이렉트 (웹 only).
  /// 이후 [ApiConfig.kakaoRedirectUri]로 돌아옴 (code 쿼리 포함).
  void startLogin() {
    if (!kIsWeb) {
      throw UnsupportedError('Kakao 로그인은 현재 웹에서만 지원됩니다.');
    }
    if (!ApiConfig.isKakaoReady) {
      throw StateError('Kakao REST API 키가 설정되지 않았습니다.');
    }
    final url = Uri.parse('https://kauth.kakao.com/oauth/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': ApiConfig.kakaoRestApiKey,
        'redirect_uri': ApiConfig.kakaoRedirectUri,
      },
    );
    // 동일 창에서 리다이렉트 (팝업 차단·credential flow 호환성 위해)
    html.window.location.href = url.toString();
  }

  /// 콜백 화면이 호출 — code를 서버로 보내 Firebase 커스텀 토큰을 받고
  /// 즉시 [FirebaseAuth.signInWithCustomToken] 호출.
  Future<void> completeLogin(String code) async {
    final res = await http.post(
      Uri.parse(ApiConfig.kakaoAuthEndpoint),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'redirectUri': ApiConfig.kakaoRedirectUri,
      }),
    );
    if (res.statusCode != 200) {
      throw _KakaoAuthException(
        '카카오 로그인 실패 (${res.statusCode})',
        detail: res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const _KakaoAuthException('서버에서 토큰을 받지 못했습니다.');
    }
    await FirebaseAuth.instance.signInWithCustomToken(token);
  }
}

class _KakaoAuthException implements Exception {
  final String message;
  final String? detail;
  const _KakaoAuthException(this.message, {this.detail});
  @override
  String toString() => message;
}
