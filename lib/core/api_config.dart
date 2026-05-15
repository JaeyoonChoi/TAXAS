/// 외부 API 엔드포인트 설정.
///
/// Vercel에 [server/api/analyze.ts]를 배포한 뒤 `aiAnalyzeEndpoint`를
/// 자신의 Vercel 도메인으로 갱신하세요. 비어 있으면 AI 분석 섹션이
/// "준비 중" 상태로 표시됩니다.
class ApiConfig {
  ApiConfig._();

  /// AI 맞춤 분석 API. 예: 'https://atax-server.vercel.app/api/analyze'
  static const String aiAnalyzeEndpoint =
      'https://atax-phi.vercel.app/api/analyze';

  /// AI 에이전트 멀티턴 채팅 API.
  static const String aiAgentEndpoint =
      'https://atax-phi.vercel.app/api/agent';

  /// Kakao OAuth → Firebase custom token 발급 API.
  static const String kakaoAuthEndpoint =
      'https://atax-phi.vercel.app/api/kakao-auth';

  /// Kakao Developers > 내 애플리케이션 > 앱 키 > **REST API 키**.
  /// (JavaScript 키와 다름. authorize URL에서 client_id로 사용.)
  /// Kakao Developers 셋업 후 채워주세요.
  static const String kakaoRestApiKey = 'YOUR_KAKAO_REST_API_KEY';

  /// Kakao Developers > 카카오 로그인 > Redirect URI에 등록된 URL과 정확히 일치해야 함.
  static const String kakaoRedirectUri =
      'https://taxas-bd85b.web.app/auth/kakao/callback';

  /// 설정 여부.
  static bool get isAiAnalyzeReady => aiAnalyzeEndpoint.isNotEmpty;
  static bool get isAiAgentReady => aiAgentEndpoint.isNotEmpty;
  static bool get isKakaoReady =>
      kakaoRestApiKey.isNotEmpty && kakaoRestApiKey != 'YOUR_KAKAO_REST_API_KEY';
}
