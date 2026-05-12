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

  /// 설정 여부.
  static bool get isAiAnalyzeReady => aiAnalyzeEndpoint.isNotEmpty;
  static bool get isAiAgentReady => aiAgentEndpoint.isNotEmpty;
}
