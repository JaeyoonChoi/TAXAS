import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/community/community_comment.dart';
import '../../features/community/community_post.dart';

/// `posts/{id}` 컬렉션 read/write.
class CommunityService {
  CommunityService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('posts');

  /// 최신순 게시글 watch.
  Stream<List<CommunityPost>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(CommunityPost.fromDoc).toList());
  }

  /// 단일 게시글 watch.
  Stream<CommunityPost?> watchById(String id) {
    return _col.doc(id).snapshots().map(
          (snap) => snap.exists ? CommunityPost.fromDoc(snap) : null,
        );
  }

  Future<String> create({
    required String authorUid,
    required String authorEmail,
    required String title,
    required String body,
  }) async {
    final doc = await _col.add({
      'authorUid': authorUid,
      'authorEmail': authorEmail,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
    });
    return doc.id;
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  /// 좋아요 토글 — uid가 like 컬렉션에 있으면 제거, 없으면 추가.
  Future<bool> toggleLike({
    required String postId,
    required String uid,
  }) async {
    final likeRef = _col.doc(postId).collection('likes').doc(uid);
    final postRef = _col.doc(postId);

    return _firestore.runTransaction<bool>((tx) async {
      final likeSnap = await tx.get(likeRef);
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
        return false;
      } else {
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'likeCount': FieldValue.increment(1)});
        return true;
      }
    });
  }

  Stream<bool> watchLiked({required String postId, required String uid}) {
    return _col
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((s) => s.exists);
  }

  // ── 댓글 ──────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _commentCol(String postId) =>
      _col.doc(postId).collection('comments');

  /// 게시글의 모든 댓글(+답글)을 시간순으로 watch.
  Stream<List<CommunityComment>> watchComments(String postId) {
    return _commentCol(postId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(CommunityComment.fromDoc).toList());
  }

  /// 댓글 또는 답글 작성. [parentCommentId]가 null이면 최상위 댓글.
  Future<void> createComment({
    required String postId,
    required String authorUid,
    required String authorEmail,
    required String body,
    String? parentCommentId,
  }) async {
    final commentRef = _commentCol(postId).doc();
    final postRef = _col.doc(postId);
    await _firestore.runTransaction((tx) async {
      tx.set(commentRef, {
        'authorUid': authorUid,
        'authorEmail': authorEmail,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'parentCommentId': parentCommentId,
      });
      tx.update(postRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  /// 본인 댓글 삭제. 답글이 함께 따라오는 케이스는 클라이언트 단순화를 위해
  /// 한 번에 하나씩만 지운다 (필요 시 추후 cascade 처리).
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final commentRef = _commentCol(postId).doc(commentId);
    final postRef = _col.doc(postId);
    await _firestore.runTransaction((tx) async {
      tx.delete(commentRef);
      tx.update(postRef, {'commentCount': FieldValue.increment(-1)});
    });
  }
}
