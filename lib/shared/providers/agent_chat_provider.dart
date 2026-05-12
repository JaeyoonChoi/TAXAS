import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/agent_chat_service.dart';
import 'user_info_provider.dart';
import 'tax_result_provider.dart';

/// 에이전트 채팅 상태 — Vercel `/api/agent` 호출로 멀티턴 대화 진행.
class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime at;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.fromUser,
    required this.at,
    this.isError = false,
  });
}

class AgentChatState {
  final List<ChatMessage> messages;
  final bool waiting;

  const AgentChatState({required this.messages, required this.waiting});

  AgentChatState copyWith({List<ChatMessage>? messages, bool? waiting}) =>
      AgentChatState(
        messages: messages ?? this.messages,
        waiting: waiting ?? this.waiting,
      );
}

class AgentChatController extends StateNotifier<AgentChatState> {
  final Ref _ref;
  final AgentChatService _service;

  AgentChatController(this._ref, this._service)
      : super(AgentChatState(
          messages: [_initialGreeting()],
          waiting: false,
        ));

  static ChatMessage _initialGreeting() => ChatMessage(
        text:
            '안녕하세요. ATAX 절세 에이전트입니다.\n'
            '입력하신 자산·가족 정보를 바탕으로 절세 과정 전반을 함께 도와드릴게요. '
            '어떤 부분부터 시작할까요?',
        fromUser: false,
        at: DateTime.now(),
      );

  /// 추천 시작 질문 — 첫 화면 칩으로 노출.
  static const List<String> startingPrompts = [
    '지금 사전증여를 시작해도 될까요?',
    '배우자 공제 30억 어떻게 활용하나요?',
    '제 상황에서 가장 큰 절세 포인트는?',
    '향후 10년 동안 무엇부터 해야 하나요?',
  ];

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.waiting) return;

    // 사용자 메시지 추가 + 대기 상태
    final userMsg = ChatMessage(
      text: trimmed,
      fromUser: true,
      at: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      waiting: true,
    );

    try {
      final userInfo = _ref.read(userInfoProvider);
      final taxResult = _ref.read(taxResultProvider);

      // 첫 인사 메시지는 시스템 안내라 API 대화 기록에서 제외 — 실제 대화만 보냄.
      final apiMessages = state.messages
          .skip(1)
          .map((m) => (
                role: m.fromUser ? 'user' : 'assistant',
                content: m.text,
              ))
          .toList();

      final reply = await _service.send(
        userInfo: userInfo,
        taxResult: taxResult,
        messages: apiMessages,
      );

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: reply,
            fromUser: false,
            at: DateTime.now(),
          ),
        ],
        waiting: false,
      );
    } catch (e) {
      final msg = e is AgentChatException
          ? e.message
          : '응답을 받지 못했습니다. 네트워크 상태를 확인하고 다시 시도해주세요.';
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: msg,
            fromUser: false,
            at: DateTime.now(),
            isError: true,
          ),
        ],
        waiting: false,
      );
    }
  }

  void reset() {
    state = AgentChatState(
      messages: [_initialGreeting()],
      waiting: false,
    );
  }
}

final agentChatServiceProvider =
    Provider<AgentChatService>((ref) => AgentChatService());

final agentChatProvider =
    StateNotifierProvider<AgentChatController, AgentChatState>(
  (ref) => AgentChatController(ref, ref.read(agentChatServiceProvider)),
);
