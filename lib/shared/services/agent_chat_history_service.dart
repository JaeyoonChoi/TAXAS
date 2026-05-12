import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}/agentChat/current` 단일 문서에 메시지 배열을 보관.
///
/// 문서 한도 1MiB 안에 충분 (텍스트만, 평균 메시지 ~500바이트 가정 시 ~2000개).
class AgentChatHistoryService {
  AgentChatHistoryService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid).collection('agentChat').doc('current');

  /// 현재 대화 로드 (1회). 문서가 없으면 빈 리스트.
  Future<List<StoredMessage>> load(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return const [];
    final data = snap.data() ?? {};
    final raw = (data['messages'] as List?) ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StoredMessage.fromJson)
        .toList();
  }

  /// 메시지 배열 통째로 저장 (overwrite).
  Future<void> save(String uid, List<StoredMessage> messages) async {
    await _doc(uid).set({
      'messages': messages.map((m) => m.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 대화 초기화 — 문서 삭제.
  Future<void> clear(String uid) async {
    await _doc(uid).delete();
  }
}

class StoredMessage {
  final String text;
  final bool fromUser;
  final DateTime at;
  final bool isError;

  const StoredMessage({
    required this.text,
    required this.fromUser,
    required this.at,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'fromUser': fromUser,
        'at': at.toIso8601String(),
        if (isError) 'isError': true,
      };

  factory StoredMessage.fromJson(Map<String, dynamic> json) => StoredMessage(
        text: json['text'] as String? ?? '',
        fromUser: json['fromUser'] as bool? ?? false,
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
        isError: json['isError'] as bool? ?? false,
      );
}
