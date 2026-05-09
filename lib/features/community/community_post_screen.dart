import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/community_provider.dart';
import 'community_comment.dart';
import 'community_post.dart';

/// 게시글 상세 — 본문 + 좋아요 + 댓글/답글.
class CommunityPostScreen extends ConsumerStatefulWidget {
  final String postId;
  const CommunityPostScreen({super.key, required this.postId});

  @override
  ConsumerState<CommunityPostScreen> createState() =>
      _CommunityPostScreenState();
}

class _CommunityPostScreenState extends ConsumerState<CommunityPostScreen> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();
  CommunityComment? _replyTarget;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(communityServiceProvider).createComment(
            postId: widget.postId,
            authorUid: user.uid,
            authorEmail: user.email ?? '',
            body: body,
            parentCommentId: _replyTarget == null
                ? null
                // 답글의 답글이면 원댓글의 id로 묶음
                : (_replyTarget!.parentCommentId ?? _replyTarget!.id),
          );
      _commentController.clear();
      setState(() {
        _replyTarget = null;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 등록 실패: $e')),
      );
    }
  }

  void _startReply(CommunityComment target) {
    setState(() => _replyTarget = target);
    _commentFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyTarget = null);
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(communityPostProvider(widget.postId));
    final commentsAsync =
        ref.watch(communityCommentsProvider(widget.postId));
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('게시글'),
        actions: [
          postAsync.when(
            data: (post) {
              if (post == null || user?.uid != post.authorUid) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: '삭제',
                onPressed: () => _confirmDeletePost(context, ref, post),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '게시글을 불러오지 못했습니다.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
        ),
        data: (post) {
          if (post == null) {
            return const Center(
              child: Text('삭제된 게시글입니다.',
                  style: TextStyle(color: AppColors.textTertiary)),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _PostBody(post: post, currentUid: user?.uid),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _CommentsSection(
                      commentsAsync: commentsAsync,
                      currentUid: user?.uid,
                      postId: widget.postId,
                      onReply: _startReply,
                    ),
                  ],
                ),
              ),
              if (user != null)
                _CommentInputBar(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  replyTarget: _replyTarget,
                  submitting: _submitting,
                  onSubmit: _submitComment,
                  onCancelReply: _cancelReply,
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: AppColors.surfaceAlt,
                  child: const Text(
                    '로그인 후 댓글을 작성할 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeletePost(
      BuildContext context, WidgetRef ref, CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 삭제할까요? 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communityServiceProvider).delete(post.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }
}

// ── 게시글 본문 ────────────────────────────────────────────

class _PostBody extends ConsumerWidget {
  final CommunityPost post;
  final String? currentUid;

  const _PostBody({required this.post, required this.currentUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedAsync = currentUid == null
        ? const AsyncValue<bool>.data(false)
        : ref.watch(_postLikedProvider((postId: post.id, uid: currentUid!)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.3,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              post.displayName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Text('·', style: TextStyle(color: AppColors.textTertiary)),
            const SizedBox(width: 6),
            Text(
              _formatTime(post.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),
        SelectableText(
          post.body,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 24),
        if (currentUid != null)
          Align(
            alignment: Alignment.centerLeft,
            child: likedAsync.when(
              data: (liked) => OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      liked ? AppColors.error : AppColors.textSecondary,
                  side: BorderSide(
                    color: liked ? AppColors.error : AppColors.border,
                  ),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => ref
                    .read(communityServiceProvider)
                    .toggleLike(postId: post.id, uid: currentUid!),
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                ),
                label: Text('좋아요 ${post.likeCount}'),
              ),
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}

// ── 댓글 섹션 (2단 스레드) ─────────────────────────────────

class _CommentsSection extends ConsumerWidget {
  final AsyncValue<List<CommunityComment>> commentsAsync;
  final String? currentUid;
  final String postId;
  final ValueChanged<CommunityComment> onReply;

  const _CommentsSection({
    required this.commentsAsync,
    required this.currentUid,
    required this.postId,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return commentsAsync.when(
      loading: () =>
          const Padding(padding: EdgeInsets.all(24), child: SizedBox.shrink()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '댓글을 불러오지 못했습니다.\n$e',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textTertiary),
        ),
      ),
      data: (all) {
        final topLevel = all.where((c) => c.parentCommentId == null).toList();
        // parentId → list of replies
        final repliesByParent = <String, List<CommunityComment>>{};
        for (final c in all) {
          if (c.parentCommentId != null) {
            repliesByParent
                .putIfAbsent(c.parentCommentId!, () => [])
                .add(c);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '댓글 ${all.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (topLevel.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '아직 댓글이 없어요. 첫 댓글을 남겨보세요.',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ...topLevel.map((c) => _CommentTile(
                    comment: c,
                    replies: repliesByParent[c.id] ?? const [],
                    currentUid: currentUid,
                    postId: postId,
                    onReply: onReply,
                  )),
          ],
        );
      },
    );
  }
}

class _CommentTile extends ConsumerWidget {
  final CommunityComment comment;
  final List<CommunityComment> replies;
  final String? currentUid;
  final String postId;
  final ValueChanged<CommunityComment> onReply;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.currentUid,
    required this.postId,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SingleComment(
          comment: comment,
          isReply: false,
          currentUid: currentUid,
          postId: postId,
          onReply: onReply,
        ),
        ...replies.map((r) => Padding(
              padding: const EdgeInsets.only(left: 28),
              child: _SingleComment(
                comment: r,
                isReply: true,
                currentUid: currentUid,
                postId: postId,
                onReply: onReply,
              ),
            )),
      ],
    );
  }
}

class _SingleComment extends ConsumerWidget {
  final CommunityComment comment;
  final bool isReply;
  final String? currentUid;
  final String postId;
  final ValueChanged<CommunityComment> onReply;

  const _SingleComment({
    required this.comment,
    required this.isReply,
    required this.currentUid,
    required this.postId,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine = currentUid != null && currentUid == comment.authorUid;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isReply) ...[
                const Icon(Icons.subdirectory_arrow_right,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
              ],
              Text(
                comment.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatRelativeTime(comment.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              if (isMine)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.textTertiary),
                  tooltip: '삭제',
                  onPressed: () => _confirmDelete(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.body,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
          if (currentUid != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => onReply(comment),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '답글',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communityServiceProvider).deleteComment(
            postId: postId,
            commentId: comment.id,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }
}

// ── 댓글 입력바 ───────────────────────────────────────────

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final CommunityComment? replyTarget;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancelReply;

  const _CommentInputBar({
    required this.controller,
    required this.focusNode,
    required this.replyTarget,
    required this.submitting,
    required this.onSubmit,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTarget != null)
              Container(
                width: double.infinity,
                color: AppColors.surfaceAlt,
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${replyTarget!.displayName} 에게 답글',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: replyTarget != null
                            ? '답글을 입력하세요'
                            : '댓글을 입력하세요',
                        hintStyle: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                              color: AppColors.navyBase, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: submitting ? null : onSubmit,
                    icon: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send,
                            color: AppColors.navyBase, size: 22),
                    tooltip: '등록',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 헬퍼 ──────────────────────────────────────────────────

String _formatTime(DateTime t) {
  return '${t.year}.${t.month.toString().padLeft(2, '0')}.${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

String _formatRelativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${t.year}.${t.month.toString().padLeft(2, '0')}.${t.day.toString().padLeft(2, '0')}';
}

/// 좋아요 상태 stream.
final _postLikedProvider =
    StreamProvider.family.autoDispose<bool, ({String postId, String uid})>(
  (ref, p) => ref
      .read(communityServiceProvider)
      .watchLiked(postId: p.postId, uid: p.uid),
);
