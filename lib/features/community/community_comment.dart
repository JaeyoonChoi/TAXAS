import 'package:cloud_firestore/cloud_firestore.dart';

/// 커뮤니티 댓글 (또는 답글).
///
/// `parentCommentId`가 null이면 최상위 댓글, 값이 있으면 그 댓글에 대한 답글.
/// 2단(댓글 → 답글)까지만 허용하므로 답글의 답글은 같은 부모(원댓글)로 묶인다.
class CommunityComment {
  final String id;
  final String authorUid;
  final String authorEmail;
  final String body;
  final DateTime createdAt;
  final String? parentCommentId;

  const CommunityComment({
    required this.id,
    required this.authorUid,
    required this.authorEmail,
    required this.body,
    required this.createdAt,
    required this.parentCommentId,
  });

  factory CommunityComment.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    final ts = d['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : DateTime.now();
    return CommunityComment(
      id: doc.id,
      authorUid: d['authorUid'] as String? ?? '',
      authorEmail: d['authorEmail'] as String? ?? '',
      body: d['body'] as String? ?? '',
      createdAt: created,
      parentCommentId: d['parentCommentId'] as String?,
    );
  }

  /// 익명 표시용 — 이메일 앞 2글자 + 마스킹.
  String get displayName {
    final at = authorEmail.indexOf('@');
    if (at <= 0) return '익명';
    final id = authorEmail.substring(0, at);
    if (id.length <= 2) return '$id**';
    return '${id.substring(0, 2)}${'*' * (id.length - 2)}';
  }
}
