import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/user_info_state.dart';
import '../../core/services/tax_calculator_service.dart';

/// `/api/agent` 호출 — 사용자 컨텍스트 + 대화 기록을 보내고 한 응답을 받는다.
class AgentChatService {
  AgentChatService();

  Future<String> send({
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
    return reply;
  }
}

class AgentChatException implements Exception {
  final String message;
  final String? detail;
  const AgentChatException(this.message, {this.detail});

  @override
  String toString() => 'AgentChatException: $message';
}
