import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/bookmark_provider.dart';
import '../../shared/providers/card_news_provider.dart';
import '../../shared/providers/community_provider.dart';
import '../../firebase_options.dart';
import '../info/card_news_data.dart';
import '../info/card_news_detail_screen.dart';
import 'community_post.dart';
import 'community_compose_screen.dart';
import 'community_post_screen.dart';

/// 커뮤니티 탭 — 두 개의 세부탭(커뮤니티 / ATAX NEWS)을 가짐.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!useFirebase) {
      return const _DisabledState();
    }
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
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
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.navyBase,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.navyBase,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              tabs: const [
                Tab(text: '커뮤니티'),
                Tab(text: 'ATAX NEWS'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _CommunityFeed(),
                  _TaxasNewsFeed(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (user == null || _tabController.index != 0)
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

// ── 커뮤니티 게시글 피드 ─────────────────────────────────

class _CommunityFeed extends ConsumerWidget {
  const _CommunityFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityPostsProvider);
    return postsAsync.when(
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
                  builder: (_) => CommunityPostScreen(postId: post.id),
                ),
              ),
            ).animate().fadeIn(delay: (i * 40).ms);
          },
        );
      },
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
                    const SizedBox(width: 8),
                  ],
                  if (post.commentCount > 0) ...[
                    const Icon(Icons.chat_bubble_outline,
                        size: 11, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      '${post.commentCount}',
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

// ── ATAX NEWS (카드 뉴스) ────────────────────────────────

class _TaxasNewsFeed extends ConsumerWidget {
  const _TaxasNewsFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(cardNewsProvider);
    final bookmarks = ref.watch(bookmarksProvider).valueOrNull ?? const {};

    return newsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '카드 뉴스를 불러오지 못했습니다.\n$e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textTertiary),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                '준비 중인 카드 뉴스가 곧 올라옵니다.',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (ctx, i) {
            final item = items[i];
            return _NewsRow(
              item: item,
              isBookmarked: bookmarks.contains(item.id),
              onTap: () => Navigator.of(ctx).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => CardNewsDetailScreen(item: item),
                ),
              ),
              onBookmark: () =>
                  ref.read(bookmarksProvider.notifier).toggle(item.id),
            ).animate().fadeIn(delay: (i * 40).ms);
          },
        );
      },
    );
  }
}

class _NewsRow extends StatelessWidget {
  final CardNewsItem item;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _NewsRow({
    required this.item,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            image: item.coverImageAsset != null
                                ? DecorationImage(
                                    image: cardNewsImageProvider(
                                        item.coverImageAsset!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: item.coverImageAsset == null
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: item.coverGradient,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.navyDeep,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          item.tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title.trim().isNotEmpty) ...[
                      Text(
                        item.title.replaceAll('\n', ' '),
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
                    ],
                    if (item.summary.trim().isNotEmpty) ...[
                      Text(
                        item.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else
                      const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${item.slides.length}장',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onBookmark,
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked
                      ? AppColors.navyBase
                      : AppColors.textTertiary,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
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
