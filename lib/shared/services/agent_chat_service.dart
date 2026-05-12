import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/user_info_state.dart';
import '../../core/services/tax_calculator_service.dart';

/// `/api/agent` 호출 결과 — 응답 텍스트 + 에이전트가 호출한 도구로 적용된 업데이트.
class AgentChatResult {
  final String reply;
  final List<AgentUpdate> updates;
  const AgentChatResult({required this.reply, required this.updates});
}

/// 에이전트가 update_user_info 도구로 변경 요청한 필드 한 건.
/// Flutter 측에서 [UserInfoState] mutation 메서드로 변환·적용.
class AgentUpdate {
  final String field; // e.g. 'family.hasSpouse', 'assets.realEstate'
  final Object? value;
  const AgentUpdate({required this.field, required this.value});

  factory AgentUpdate.fromJson(Map<String, dynamic> json) => AgentUpdate(
        field: json['field'] as String,
        value: json['value'],
      );
}

/// `/api/agent` 호출 — 사용자 컨텍스트 + 대화 기록을 보내고 응답 + 업데이트를 받는다.
class AgentChatService {
  AgentChatService();

  Future<AgentChatResult> send({
    required UserInfoState userInfo,
    required TaxResult taxResult,
    required List<({String role, String content})> messages,
  }) async {
    final uri = Uri.parse(ApiConfig.aiAgentEndpoint);
    final payload = {
      'context': {
        'family': {
          'hasSpouse': userInfo.family.hasSpouse,
          'childCount': userInfo.family.childCount,
          'childAges': userInfo.family.childAges,
          'ownerAge': userInfo.family.ownerAge,
        },
        'assets': {
          'realEstate': userInfo.assets.realEstate,
          'financial': userInfo.assets.financial,
          'other': userInfo.assets.other,
          'debt': userInfo.assets.debt,
        },
        'giftHistory': userInfo.giftHistory
            .map((g) => {
                  'relationship': g.relationship,
                  'amount': g.amount,
                  'year': g.year,
                })
            .toList(),
        'taxResult': {
          'noPlanningTax': taxResult.noPlanningTax,
          'withPlanningTax': taxResult.withPlanningTax,
          'planningSavings': taxResult.planningSavings,
          'inheritanceTaxableBase': taxResult.inheritanceTaxableBase,
          'optimalGiftPlan': taxResult.optimalGiftPlan,
        },
      },
      'messages': messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
    };

    final res = await http.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw AgentChatException(
        '에이전트 응답 실패 (${res.statusCode}). 잠시 후 다시 시도해주세요.',
        detail: res.body,
      );
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final reply = data['reply'] as String?;
    if (reply == null || reply.isEmpty) {
      throw const AgentChatException('빈 응답이 반환되었습니다.');
    }
    final updates = (data['updates'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AgentUpdate.fromJson)
        .toList();
    return AgentChatResult(reply: reply, updates: updates);
  }
}

class AgentChatException implements Exception {
  final String message;
  final String? detail;
  const AgentChatException(this.message, {this.detail});

  @override
  String toString() => 'AgentChatException: $message';
}
