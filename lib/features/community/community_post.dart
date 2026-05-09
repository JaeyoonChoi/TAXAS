import 'package:cloud_firestore/cloud_firestore.dart';

/// 커뮤니티 게시글.
class CommunityPost {
  final String id;
  final String authorUid;
  final String authorEmail;
  final String title;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  const CommunityPost({
    required this.id,
    required this.authorUid,
    required this.authorEmail,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
  });

  factory CommunityPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : DateTime.now();
    return CommunityPost(
      id: doc.id,
      authorUid: d['authorUid'] as String? ?? '',
      authorEmail: d['authorEmail'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      createdAt: created,
      likeCount: (d['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (d['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// 익명 표시용 — 이메일 앞부분 + 마스킹
  String get displayName {
    final at = authorEmail.indexOf('@');
    if (at <= 0) return '익명';
    final id = authorEmail.substring(0, at);
    if (id.length <= 2) return '$id**';
    return '${id.substring(0, 2)}${'*' * (id.length - 2)}';
  }
}
