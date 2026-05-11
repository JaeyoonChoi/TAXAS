import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api_config.dart';
import '../models/ai_report.dart';
import '../services/ai_report_service.dart';
import 'auth_provider.dart';
import 'tax_result_provider.dart';
import 'user_info_provider.dart';

part 'ai_report_provider.g.dart';

@riverpod
AiReportService aiReportService(AiReportServiceRef ref) {
  return AiReportService(FirebaseFirestore.instance);
}

/// 맞춤 분석 상태: idle / loading / success / error / disabled.
sealed class AiReportState {
  const AiReportState();
}

class AiReportIdle extends AiReportState {
  const AiReportIdle();
}

class AiReportDisabled extends AiReportState {
  /// API endpoint가 아직 설정되지 않음.
  const AiReportDisabled();
}

class AiReportLoading extends AiReportState {
  const AiReportLoading();
}

class AiReportReady extends AiReportState {
  final AiReport report;
  final bool fromCache;
  const AiReportReady(this.report, {required this.fromCache});
}

class AiReportError extends AiReportState {
  final String message;
  const AiReportError(this.message);
}

/// 리포트 화면에서 보는 분석.
///
/// 자동으로 캐시를 먼저 확인하고, 없거나 입력이 바뀌었을 때만
/// Vercel API를 호출. UI에서 "재생성" 버튼을 누르면 강제 갱신 가능.
@Riverpod(keepAlive: true)
class AiReportController extends _$AiReportController {
  @override
  AiReportState build() {
    if (!ApiConfig.isAiAnalyzeReady) return const AiReportDisabled();
    // 화면 진입 시 자동으로 캐시 확인 + 필요 시 생성
    Future.microtask(_loadOrGenerate);
    return const AiReportIdle();
  }

  Future<void> _loadOrGenerate() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final userInfo = ref.read(userInfoProvider);
    if (userInfo.assets.totalGross == 0) return;
    final result = ref.read(taxResultProvider);
    final service = ref.read(aiReportServiceProvider);
    final expectedHash = service.computeInputHash(userInfo, result);

    state = const AiReportLoading();
    try {
      final cached = await service.readCached(
        uid: uid,
        expectedHash: expectedHash,
      );
      if (cached != null) {
        state = AiReportReady(cached, fromCache: true);
        return;
      }
      final fresh = await service.generate(
        uid: uid,
        userInfo: userInfo,
        result: result,
      );
      state = AiReportReady(fresh, fromCache: false);
    } catch (e) {
      state = AiReportError(e.toString());
    }
  }

  /// 캐시 무시하고 강제 재생성.
  Future<void> regenerate() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final userInfo = ref.read(userInfoProvider);
    if (userInfo.assets.totalGross == 0) return;
    final result = ref.read(taxResultProvider);

    state = const AiReportLoading();
    try {
      final fresh = await ref.read(aiReportServiceProvider).generate(
            uid: uid,
            userInfo: userInfo,
            result: result,
          );
      state = AiReportReady(fresh, fromCache: false);
    } catch (e) {
      state = AiReportError(e.toString());
    }
  }
}
