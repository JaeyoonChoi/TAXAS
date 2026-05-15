import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/bookmark_provider.dart';
import 'card_news_data.dart';

/// 인스타그램 스타일의 카드 뉴스 상세 화면.
/// 좌우 스와이프로 슬라이드 이동, 상단에 닫기·북마크·공유 버튼.
class CardNewsDetailScreen extends ConsumerStatefulWidget {
  final CardNewsItem item;
  const CardNewsDetailScreen({super.key, required this.item});

  @override
  ConsumerState<CardNewsDetailScreen> createState() =>
      _CardNewsDetailScreenState();
}

class _CardNewsDetailScreenState extends ConsumerState<CardNewsDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final body =
        '[ATAX] ${widget.item.title.replaceAll('\n', ' ')}\n${widget.item.summary}';
    await Share.share(body);
  }

  Future<void> _toggleBookmark() async {
    await ref.read(bookmarksProvider.notifier).toggle(widget.item.id);
    if (!mounted) return;
    final bookmarks = await ref.read(bookmarksProvider.future);
    final added = bookmarks.contains(widget.item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added ? '북마크에 추가되었습니다' : '북마크에서 제거되었습니다'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.item.slides;
    final bookmarks = ref.watch(bookmarksProvider).valueOrNull ?? const {};
    final isBookmarked = bookmarks.contains(widget.item.id);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 액션 바 ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '닫기',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: isBookmarked
                          ? AppColors.goldBase
                          : Colors.white,
                    ),
                    onPressed: _toggleBookmark,
                    tooltip: isBookmarked ? '북마크 해제' : '북마크',
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share, color: Colors.white),
                    onPressed: _share,
                    tooltip: '공유',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── 슬라이드 진행 인디케이터 (스토리 형식) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(slides.length, (i) {
                  final isActive = i <= _currentPage;
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(
                          right: i < slides.length - 1 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // ── 슬라이드 + 좌우 네비게이션 ────────────────────
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) {
                      final slide = slides[i];
                      return _SlideView(
                        slide: slide,
                        fallbackGradient: widget.item.coverGradient,
                      );
                    },
                  ),
                  if (_currentPage > 0)
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.chevron_left,
                          onTap: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage < slides.length - 1)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.chevron_right,
                          onTap: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── 하단 메타 ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      widget.item.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentPage + 1} / ${slides.length}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.item.date,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
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

class _SlideView extends StatelessWidget {
  final CardNewsSlide slide;
  final List<Color> fallbackGradient;

  const _SlideView({
    required this.slide,
    required this.fallbackGradient,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = slide.gradient ?? fallbackGradient;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 4 / 5, // 인스타 카드뉴스 표준 비율
          child: Container(
            decoration: BoxDecoration(
              image: slide.imageAsset != null
                  ? DecorationImage(
                      image: cardNewsImageProvider(slide.imageAsset!),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: slide.imageAsset == null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // 이미지가 없을 때만 텍스트 오버레이 — 이미지가 있으면 디자인이 이미지 안에 있다고 가정
                if (slide.imageAsset == null)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (slide.heading != null)
                        Text(
                          slide.heading!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      if (slide.heading != null && slide.body != null)
                        const SizedBox(height: 16),
                      if (slide.body != null)
                        Text(
                          slide.body!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 슬라이드 좌우 네비게이션 원형 버튼.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
