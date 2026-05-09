import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/bookmark_provider.dart';
import '../../shared/providers/card_news_provider.dart';
import 'card_news_data.dart';
import 'card_news_detail_screen.dart';

/// 콘텐츠 메인 — 가로형 카드 리스트 + 카테고리 필터 칩.
class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  static const _allFilter = '전체';
  static const _filters = [
    _allFilter, '상속세', '증여세', '양도세', '세법 개정', '절세 전략', '공제 활용', '주의 사항',
  ];

  String _selected = _allFilter;
  bool _showOnlyBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(cardNewsProvider);
    final bookmarks = ref.watch(bookmarksProvider).valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              showOnlyBookmarked: _showOnlyBookmarked,
              onToggleBookmarks: () =>
                  setState(() => _showOnlyBookmarked = !_showOnlyBookmarked),
              onTapInfo: () => _openKnowledgeFaq(context),
            ),
            _FilterChips(
              filters: _filters,
              selected: _selected,
              onSelect: (f) => setState(() => _selected = f),
            ),
            const Divider(height: 1),
            Expanded(
              child: newsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '콘텐츠를 불러오지 못했습니다.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                ),
                data: (items) {
                  // 필터 적용
                  var visible = items;
                  if (_selected != _allFilter) {
                    visible = items.where((i) => i.tag == _selected).toList();
                  }
                  if (_showOnlyBookmarked) {
                    visible = visible
                        .where((i) => bookmarks.contains(i.id))
                        .toList();
                  }

                  if (visible.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          _showOnlyBookmarked
                              ? '북마크한 콘텐츠가 없습니다.'
                              : '${_selected == _allFilter ? '' : "$_selected "}콘텐츠가 곧 올라옵니다.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textTertiary),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, i) {
                      final item = visible[i];
                      return _ContentRow(
                        item: item,
                        isBookmarked: bookmarks.contains(item.id),
                        onTap: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) =>
                                CardNewsDetailScreen(item: item),
                          ),
                        ),
                        onBookmarkTap: () =>
                            ref.read(bookmarksProvider.notifier).toggle(item.id),
                      ).animate().fadeIn(delay: (i * 50).ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openKnowledgeFaq(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _KnowledgeFaqScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

// ── 헤더: 타이틀 + 우측 아이콘 ────────────────────────────

class _Header extends StatelessWidget {
  final bool showOnlyBookmarked;
  final VoidCallback onToggleBookmarks;
  final VoidCallback onTapInfo;

  const _Header({
    required this.showOnlyBookmarked,
    required this.onToggleBookmarks,
    required this.onTapInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          const Text(
            '콘텐츠',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: showOnlyBookmarked ? '전체 보기' : '북마크 보기',
            onPressed: onToggleBookmarks,
            icon: Icon(
              showOnlyBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: showOnlyBookmarked
                  ? AppColors.navyBase
                  : AppColors.textSecondary,
            ),
          ),
          IconButton(
            tooltip: '기초 지식 · FAQ',
            onPressed: onTapInfo,
            icon: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 필터 칩 가로 스크롤 ────────────────────────────────

class _FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final f = filters[i];
            final isActive = f == selected;
            return GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.textPrimary : AppColors.border,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 가로형 콘텐츠 카드 ─────────────────────────────────

class _ContentRow extends StatelessWidget {
  final CardNewsItem item;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  const _ContentRow({
    required this.item,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkTap,
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
              // 썸네일 + 카테고리 배지
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

              // 제목 + 요약 + 날짜
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // 북마크 토글
              IconButton(
                onPressed: onBookmarkTap,
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

// ── 기초지식 / FAQ — 우측 메뉴 아이콘으로 진입 ───────────

class _KnowledgeFaqScreen extends StatefulWidget {
  const _KnowledgeFaqScreen();

  @override
  State<_KnowledgeFaqScreen> createState() => _KnowledgeFaqScreenState();
}

class _KnowledgeFaqScreenState extends State<_KnowledgeFaqScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('상속·증여 가이드'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기초 지식'),
            Tab(text: 'FAQ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _KnowledgeTab(),
          _FaqTab(),
        ],
      ),
    );
  }
}

// ── 기초 지식 탭 ──────────────────────────────────────────

class _KnowledgeTab extends StatelessWidget {
  const _KnowledgeTab();

  static const _articles = [
    _Article(
      icon: Icons.account_balance_outlined,
      color: AppColors.navyBase,
      title: '상속세란?',
      summary: '피상속인 사망 시 유산을 상속받은 상속인이 납부하는 세금입니다.',
      body: '''상속세는 피상속인(돌아가신 분)이 남긴 재산(상속재산)에 대해 상속인이 납부해야 하는 세금입니다.

**과세 범위**
• 국내·해외 모든 재산
• 사망 전 10년 이내 상속인에게 증여한 재산
• 사망 전 5년 이내 제3자에게 증여한 재산

**신고·납부 기한**
상속 개시일(사망일)이 속하는 달의 말일로부터 **6개월** 이내

**주요 공제**
• 일괄공제: 5억원
• 배우자공제: 최소 5억 ~ 최대 30억원
• 기초공제 + 인적공제 합계가 클 경우 선택 적용''',
    ),
    _Article(
      icon: Icons.card_giftcard_outlined,
      color: AppColors.goldDeep,
      title: '증여세란?',
      summary: '재산을 무상으로 받은 자(수증자)가 납부하는 세금입니다.',
      body: '''증여세는 재산을 무상으로 받은 사람(수증자)이 납부하는 세금입니다.

**증여세 공제 (10년 합산)**
• 배우자: 6억원
• 직계비속(자녀): 성인 5천만 / 미성년 2천만
• 직계존속(부모): 5천만원
• 기타 친족: 1천만원

**신고·납부 기한**
증여를 받은 달의 말일로부터 **3개월** 이내

**핵심 포인트**
공제는 10년마다 새로 시작됩니다. 시기를 분산해 여러 번 활용하면 절세 효과가 큽니다.''',
    ),
    _Article(
      icon: Icons.handshake_outlined,
      color: AppColors.success,
      title: '양도소득세란?',
      summary: '부동산·주식 등을 팔아 얻은 차익에 부과되는 세금입니다.',
      body: '''양도소득세는 부동산, 주식 등 자산을 팔아 발생한 차익(양도차익)에 부과됩니다.

**과세 대상**
• 부동산: 1세대 1주택은 비과세 요건 충족 시 면제
• 주식: 대주주 양도는 과세, 소액주주는 일반적으로 비과세
• 분양권·입주권 등

**계산 구조**
양도가액 − 취득가액 − 필요경비 − 공제 = 과세표준

상속·증여 자산 처분 시 양도세도 고려해야 절세 전략이 완성됩니다.''',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _ArticleCard(article: _articles[i]),
    );
  }
}

class _Article {
  final IconData icon;
  final Color color;
  final String title;
  final String summary;
  final String body;

  const _Article({
    required this.icon,
    required this.color,
    required this.title,
    required this.summary,
    required this.body,
  });
}

class _ArticleCard extends StatelessWidget {
  final _Article article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: article.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(article.icon, color: article.color, size: 20),
        ),
        title: Text(
          article.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          article.summary,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
            height: 1.4,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              article.body,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAQ 탭 ──────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  static const _items = [
    _FaqItem(
      q: '미리 증여하면 무조건 세금이 줄어드나요?',
      a: '아닙니다. 사망 전 10년 이내 상속인에게 증여한 재산은 상속재산에 합산됩니다. 10년 이상 생존 가정에서만 절세 효과가 명확합니다.',
    ),
    _FaqItem(
      q: '배우자 공제는 어떻게 적용되나요?',
      a: '최소 5억원, 최대 30억원까지 공제됩니다. 배우자의 법정상속분(자녀 수에 따라 다름) 범위 내에서 더 큰 금액이 적용됩니다.',
    ),
    _FaqItem(
      q: '신고 기한을 놓치면 어떻게 되나요?',
      a: '무신고 가산세(20%)와 납부지연 가산세(연 8.03%)가 부과됩니다. 가급적 기한 내 신고하는 것이 좋습니다.',
    ),
    _FaqItem(
      q: '부동산 평가는 공시지가로 하나요?',
      a: '원칙은 시가입니다. 시가 산정이 어려우면 공시지가, 임대료 환산가 등 보충적 평가방법을 사용합니다. 본 앱은 입력의 단순화를 위해 공시지가 기준으로 계산합니다.',
    ),
    _FaqItem(
      q: '본 앱 계산 결과를 그대로 신고할 수 있나요?',
      a: '아닙니다. 본 앱은 참고용이며 실제 신고는 세무사와 상담하여 정확히 산정하셔야 합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final item = _items[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.navyBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Q',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.q,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.goldBase,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.a,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}
