import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../firebase_options.dart';
import '../services/agent_chat_history_service.dart';
import '../services/agent_chat_service.dart';
import 'auth_provider.dart';
import 'tax_result_provider.dart';
import 'user_info_provider.dart';

/// 에이전트 채팅 상태 — Vercel `/api/agent` 호출 + Firestore 영속 저장.
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

  StoredMessage toStored() => StoredMessage(
        text: text,
        fromUser: fromUser,
        at: at,
        isError: isError,
      );

  static ChatMessage fromStored(StoredMessage m) => ChatMessage(
        text: m.text,
        fromUser: m.fromUser,
        at: m.at,
        isError: m.isError,
      );
}

class AgentChatState {
  final List<ChatMessage> messages;
  final bool waiting;
  final bool loading; // 초기 hydrate 중

  const AgentChatState({
    required this.messages,
    required this.waiting,
    this.loading = false,
  });

  AgentChatState copyWith({
    List<ChatMessage>? messages,
    bool? waiting,
    bool? loading,
  }) =>
      AgentChatState(
        messages: messages ?? this.messages,
        waiting: waiting ?? this.waiting,
        loading: loading ?? this.loading,
      );
}

class AgentChatController extends StateNotifier<AgentChatState> {
  final Ref _ref;
  final AgentChatService _service;
  final AgentChatHistoryService _history;
  String? _hydratedUid;
  late final Future<void> _hydrateFuture;

  AgentChatController(this._ref, this._service, this._history)
      : super(AgentChatState(
          messages: [_initialGreeting()],
          waiting: false,
          loading: true,
        )) {
    _hydrateFuture = _hydrateForCurrentUser();
  }

  Future<void> _hydrateForCurrentUser() async {
    if (!useFirebase) {
      state = state.copyWith(loading: false);
      return;
    }
    final uid = _ref.read(currentUidProvider);
    if (uid == null) {
      // 로그인 전엔 hydrate 스킵, 로딩 종료 (auth 변경 시 invalidateSelf로 재구성됨).
      state = state.copyWith(loading: false);
      return;
    }
    if (uid == _hydratedUid) {
      state = state.copyWith(loading: false);
      return;
    }
    _hydratedUid = uid;

    try {
      final stored = await _history.load(uid);
      debugPrint('[agentChat] hydrated $uid — ${stored.length} messages loaded');
      if (stored.isEmpty) {
        state = AgentChatState(
          messages: [_initialGreeting()],
          waiting: false,
          loading: false,
        );
        // 빈 상태에서는 저장하지 않음 — 사용자가 첫 메시지 보낼 때 자연스럽게 저장됨.
      } else {
        state = AgentChatState(
          messages: stored.map(ChatMessage.fromStored).toList(),
          waiting: false,
          loading: false,
        );
      }
    } catch (e, st) {
      debugPrint('[agentChat] hydrate FAILED: $e\n$st');
      state = state.copyWith(loading: false);
    }
  }

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

  Future<void> _persist() async {
    if (!useFirebase) return;
    final uid = _ref.read(currentUidProvider);
    if (uid == null) {
      debugPrint('[agentChat] persist skipped — uid is null');
      return;
    }
    try {
      await _history.save(
        uid,
        state.messages.map((m) => m.toStored()).toList(),
      );
      debugPrint('[agentChat] persisted $uid — ${state.messages.length} messages');
    } catch (e, st) {
      debugPrint('[agentChat] persist FAILED: $e\n$st');
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.waiting) return;

    // 초기 hydrate가 끝나기 전에 send가 호출되면 기존 대화를 덮어쓰는 문제 발생.
    // 반드시 hydrate 완료 후 진행.
    await _hydrateFuture;

    final userMsg = ChatMessage(
      text: trimmed,
      fromUser: true,
      at: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      waiting: true,
    );
    unawaited(_persist());

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

      final result = await _service.send(
        userInfo: userInfo,
        taxResult: taxResult,
        messages: apiMessages,
      );

      // 에이전트가 호출한 도구 업데이트를 사용자 상태에 반영
      _applyUpdates(result.updates);

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: result.reply,
            fromUser: false,
            at: DateTime.now(),
          ),
        ],
        waiting: false,
      );
      unawaited(_persist());
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
      unawaited(_persist());
    }
  }

  void _applyUpdates(List<AgentUpdate> updates) {
    if (updates.isEmpty) return;
    final notifier = _ref.read(userInfoProvider.notifier);
    for (final u in updates) {
      switch (u.field) {
        case 'family.hasSpouse':
          if (u.value is bool) notifier.setHasSpouse(u.value as bool);
          break;
        case 'family.childCount':
          final v = _toInt(u.value);
          if (v != null && v >= 0) notifier.setChildCount(v);
          break;
        case 'family.ownerAge':
          final v = _toInt(u.value);
          if (v != null && v >= 0) notifier.setOwnerAge(v);
          break;
        case 'assets.realEstate':
          final v = _toInt(u.value);
          if (v != null && v >= 0) notifier.setRealEstate(v);
          break;
        case 'assets.financial':
          final v = _toInt(u.value);
          if (v != null && v >= 0) notifier.setFinancial(v);
          break;
        case 'assets.other':
          final v = _toInt(u.value);
          if (v != null && v >= 0) notifier.setOther(v);
          break;
        case 'assets.debt':
          final v = _toInt(u.value);
          if (v != null && v >= 0) notifier.setDebt(v);
          break;
        // 알 수 없는 필드는 무시
      }
    }
  }

  static int? _toInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> reset() async {
    state = AgentChatState(
      messages: [_initialGreeting()],
      waiting: false,
    );
    await _persist();
  }
}

/// `unawaited` — fire-and-forget으로 명시.
void unawaited(Future<void> _) {}

final agentChatServiceProvider =
    Provider<AgentChatService>((ref) => AgentChatService());

final agentChatHistoryServiceProvider = Provider<AgentChatHistoryService>(
  (ref) => AgentChatHistoryService(FirebaseFirestore.instance),
);

final agentChatProvider =
    StateNotifierProvider<AgentChatController, AgentChatState>(
  (ref) {
    // 인증 상태 변화 감지 — 사용자 바뀌면 새로 hydrate
    ref.listen(currentUidProvider, (prev, next) {
      if (prev != next) {
        // 새 컨트롤러 강제 — invalidateSelf
        ref.invalidateSelf();
      }
    });
    return AgentChatController(
      ref,
      ref.read(agentChatServiceProvider),
      ref.read(agentChatHistoryServiceProvider),
    );
  },
);
