import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/ai_report.dart';
import '../models/user_info_state.dart';
import '../../core/services/tax_calculator_service.dart';

/// AI 맞춤 분석 서비스 — Vercel `/api/analyze` 호출 + Firestore 캐시.
class AiReportService {
  AiReportService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _cacheDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('aiReport').doc('latest');

  /// 사용자 데이터에서 캐시 키 해시 계산.
  /// 자산·가족·증여이력·계산된 세액이 모두 같으면 같은 해시 → 캐시 재사용.
  String computeInputHash(UserInfoState info, TaxResult result) {
    final payload = {
      'family': info.family.toJson(),
      'assets': info.assets.toJson(),
      'giftHistory': info.giftHistory.map((g) => g.toJson()).toList(),
      'noPlanningTax': result.noPlanningTax,
      'withPlanningTax': result.withPlanningTax,
      'inheritanceTaxableBase': result.inheritanceTaxableBase,
      'optimalGiftPlan': result.optimalGiftPlan,
    };
    final bytes = utf8.encode(jsonEncode(payload));
    return sha1.convert(bytes).toString();
  }

  /// 캐시된 분석 읽기 (없거나 해시 불일치면 null 반환).
  Future<AiReport?> readCached({
    required String uid,
    required String expectedHash,
  }) async {
    try {
      final snap = await _cacheDoc(uid).get();
      if (!snap.exists) return null;
      final cached = CachedAiReport.fromJson(snap.data() ?? const {});
      if (cached.inputHash != expectedHash) return null;
      return cached.report;
    } catch (_) {
      return null;
    }
  }

  /// Vercel API 호출 → 결과 캐시 저장.
  Future<AiReport> generate({
    required String uid,
    required UserInfoState userInfo,
    required TaxResult result,
  }) async {
    if (!ApiConfig.isAiAnalyzeReady) {
      throw StateError('AI 분석 API가 아직 설정되지 않았습니다.');
    }

    final body = jsonEncode({
      'userInfo': {
        'family': userInfo.family.toJson(),
        'assets': userInfo.assets.toJson(),
        'giftHistory': userInfo.giftHistory.map((g) => g.toJson()).toList(),
      },
      'taxResult': {
        'noPlanningTax': result.noPlanningTax,
        'withPlanningTax': result.withPlanningTax,
        'planningSavings': result.planningSavings,
        'inheritanceTax': result.inheritanceTax,
        'inheritanceTaxableBase': result.inheritanceTaxableBase,
        'inheritanceTotalDeduction': result.inheritanceTotalDeduction,
        'optimalGiftPlan': result.optimalGiftPlan,
      },
    });

    final res = await http
        .post(
          Uri.parse(ApiConfig.aiAnalyzeEndpoint),
          headers: const {'content-type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw StateError(
          'AI 분석 호출 실패 (${res.statusCode}): ${res.body.substring(0, res.body.length.clamp(0, 200))}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final analysisJson = (decoded['analysis'] as Map?)?.cast<String, dynamic>();
    if (analysisJson == null) {
      throw StateError('AI 응답 형식이 올바르지 않습니다.');
    }
    final report = AiReport.fromJson(analysisJson);

    // 캐시 저장
    final inputHash = computeInputHash(userInfo, result);
    final cached = CachedAiReport(
      inputHash: inputHash,
      report: report,
      generatedAt: DateTime.now(),
    );
    await _cacheDoc(uid).set(cached.toJson());

    return report;
  }
}
