import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/community_provider.dart';
import '../../firebase_options.dart';
import 'community_post.dart';
import 'community_compose_screen.dart';
import 'community_post_screen.dart';

/// 커뮤니티 메인 — 게시글 리스트 + 작성 FAB.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!useFirebase) {
      return const _DisabledState();
    }
    final user = ref.watch(authStateProvider).valueOrNull;
    final postsAsync = ref.watch(communityPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            const Divider(height: 1),
            Expanded(
              child: postsAsync.when(
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
                data: (posts) {
                  if (posts.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 60, color: AppColors.textTertiary),
                            SizedBox(height: 12),
                            Text(
                              '아직 게시글이 없습니다.\n첫 글을 작성해보세요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, i) {
                      final post = posts[i];
                      return _PostRow(
                        post: post,
                        onTap: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CommunityPostScreen(postId: post.id),
                          ),
                        ),
                      ).animate().fadeIn(delay: (i * 40).ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.navyBase,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('글쓰기'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CommunityComposeScreen(),
                  fullscreenDialog: true,
                ),
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Text(
            '커뮤니티',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;

  const _PostRow({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.35,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    post.displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('·',
                      style: TextStyle(color: AppColors.textTertiary)),
                  const SizedBox(width: 6),
                  Text(
                    _formatRelativeTime(post.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  if (post.likeCount > 0) ...[
                    const Icon(Icons.favorite,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      '${post.likeCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisabledState extends StatelessWidget {
  const _DisabledState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            '커뮤니티 기능을 사용하려면 Firebase 설정이 필요합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${t.year}.${t.month.toString().padLeft(2, '0')}.${t.day.toString().padLeft(2, '0')}';
}
