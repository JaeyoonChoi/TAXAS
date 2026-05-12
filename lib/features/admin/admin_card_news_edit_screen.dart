import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../features/info/card_news_data.dart';
import '../../shared/providers/card_news_provider.dart';
import '../../shared/services/image_upload_service.dart';

/// 카드 뉴스 작성/편집 폼.
/// `initial`이 null이면 신규 작성 모드.
class AdminCardNewsEditScreen extends ConsumerStatefulWidget {
  final CardNewsItem? initial;
  const AdminCardNewsEditScreen({super.key, this.initial});

  @override
  ConsumerState<AdminCardNewsEditScreen> createState() =>
      _AdminCardNewsEditScreenState();
}

/// 그라디언트 프리셋 — 카드 톤 통일을 위해.
const _gradientPresets = <List<Color>>[
  [Color(0xFF1E3A5F), Color(0xFF3B5C8A)], // navy
  [Color(0xFFB8954A), Color(0xFFE0B86E)], // gold
  [Color(0xFF2A5A47), Color(0xFF4F8E70)], // green
  [Color(0xFF7A2E2E), Color(0xFFB85959)], // red
  [Color(0xFF4A2D6E), Color(0xFF6E4FA0)], // purple
  [Color(0xFF2F4858), Color(0xFF5A7A8E)], // slate
];

const _tagOptions = ['상속세', '증여세', '양도세', '세법 개정', '절세 전략', '공제 활용', '주의 사항'];

class _AdminCardNewsEditScreenState
    extends ConsumerState<AdminCardNewsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late String _tag;
  late int _gradientIndex;
  late List<_SlideDraft> _slides;
  late String _cardId;
  String? _coverImageUrl;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _cardId = i?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _dateController = TextEditingController(text: i?.date ?? _todayString());
    _tag = i?.tag ?? _tagOptions.first;
    _gradientIndex = _matchPresetIndex(i?.coverGradient);
    _coverImageUrl = i?.coverImageAsset;
    _slides = (i?.slides ?? const <CardNewsSlide>[])
        .map((s) => _SlideDraft.fromSlide(s))
        .toList();
    if (_slides.isEmpty) {
      _slides.add(_SlideDraft());
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    for (final s in _slides) {
      s.dispose();
    }
    super.dispose();
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
  }

  static int _matchPresetIndex(List<Color>? grad) {
    if (grad == null || grad.length < 2) return 0;
    for (var i = 0; i < _gradientPresets.length; i++) {
      final p = _gradientPresets[i];
      if (p[0].toARGB32() == grad[0].toARGB32() &&
          p[1].toARGB32() == grad[1].toARGB32()) {
        return i;
      }
    }
    return 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_slides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('슬라이드를 1장 이상 추가하세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 기존에 큰 이미지로 저장된 슬라이드는 자동 재압축 — 발행 시점에 모든
      // base64 이미지를 1MiB 문서 한도 안에 들어가도록 한 번 더 줄인다.
      final uploader = ref.read(imageUploadServiceProvider);
      final processedCover = _coverImageUrl == null
          ? null
          : await uploader.recompressIfNeeded(_coverImageUrl!);
      final processedSlides = <CardNewsSlide>[];
      for (final s in _slides) {
        final url = s.imageUrl == null
            ? null
            : await uploader.recompressIfNeeded(s.imageUrl!);
        s.imageUrl = url;
        processedSlides.add(CardNewsSlide(
          imageAsset: url,
          gradient: _gradientPresets[_gradientIndex],
        ));
      }

      final item = CardNewsItem(
        id: _cardId,
        title: '',
        summary: '',
        tag: _tag,
        date: _dateController.text.trim(),
        coverGradient: _gradientPresets[_gradientIndex],
        coverImageAsset: processedCover,
        slides: processedSlides,
      );

      await ref.read(cardNewsServiceProvider).upsert(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '수정되었습니다.' : '발행되었습니다.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(_isEdit ? '카드 뉴스 수정' : '새 카드 뉴스'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('발행'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionLabel('기본 정보'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _tag,
                    decoration: const InputDecoration(labelText: '태그'),
                    items: _tagOptions
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _tag = v ?? _tag),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: '날짜',
                      hintText: '2026.05.06',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _SectionLabel('표지 이미지'),
            const SizedBox(height: 8),
            _ImageUploadField(
              currentUrl: _coverImageUrl,
              uploader: ref.read(imageUploadServiceProvider),
              cardId: _cardId,
              filename: 'cover',
              onChanged: (url) => setState(() => _coverImageUrl = url),
              fallbackGradient: _gradientPresets[_gradientIndex],
              aspectRatio: 16 / 9,
              hint: '카드 리스트에서 표지로 보입니다 (가로형 16:9 권장)',
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                _SectionLabel('슬라이드 (${_slides.length}장)'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _slides.add(_SlideDraft())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('슬라이드 추가'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_slides.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SlideEditorCard(
                  index: i,
                  total: _slides.length,
                  draft: _slides[i],
                  cardId: _cardId,
                  uploader: ref.read(imageUploadServiceProvider),
                  fallbackGradient: _gradientPresets[_gradientIndex],
                  onChanged: () => setState(() {}),
                  onRemove: _slides.length <= 1
                      ? null
                      : () => setState(() {
                            _slides[i].dispose();
                            _slides.removeAt(i);
                          }),
                  onMoveUp: i == 0
                      ? null
                      : () => setState(() {
                            final tmp = _slides[i - 1];
                            _slides[i - 1] = _slides[i];
                            _slides[i] = tmp;
                          }),
                  onMoveDown: i == _slides.length - 1
                      ? null
                      : () => setState(() {
                            final tmp = _slides[i + 1];
                            _slides[i + 1] = _slides[i];
                            _slides[i] = tmp;
                          }),
                ),
              );
            }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SlideDraft {
  String? imageUrl;

  _SlideDraft({this.imageUrl});

  factory _SlideDraft.fromSlide(CardNewsSlide s) =>
      _SlideDraft(imageUrl: s.imageAsset);

  void dispose() {}
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _GradientPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _GradientPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_gradientPresets.length, (i) {
        final isActive = i == selected;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradientPresets[i],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.navyBase : Colors.transparent,
                width: 3,
              ),
            ),
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
        );
      }),
    );
  }
}

/// 이미지 선택 + 업로드 + 미리보기 + 삭제 통합 위젯.
///
/// `currentUrl == null` → 그라디언트 placeholder 위에 "이미지 추가" 버튼.
/// `currentUrl != null` → 이미지 미리보기 + "변경/삭제" 버튼.
class _ImageUploadField extends StatefulWidget {
  final String? currentUrl;
  final ImageUploadService uploader;
  final String cardId;
  final String filename;
  final ValueChanged<String?> onChanged;
  final List<Color> fallbackGradient;
  final double aspectRatio;
  final String? hint;

  const _ImageUploadField({
    required this.currentUrl,
    required this.uploader,
    required this.cardId,
    required this.filename,
    required this.onChanged,
    required this.fallbackGradient,
    this.aspectRatio = 16 / 9,
    this.hint,
  });

  @override
  State<_ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<_ImageUploadField> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final XFile? file = await widget.uploader.pickImage();
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final dataUri = await widget.uploader.encodeAsDataUri(file);
      widget.onChanged(dataUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _remove() async {
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.currentUrl != null && widget.currentUrl!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 탭 가능한 이미지 박스 ───────────────────────
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _uploading ? null : _pickAndUpload,
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  image: hasImage
                      ? DecorationImage(
                          image: cardNewsImageProvider(widget.currentUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: hasImage
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.fallbackGradient,
                        ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!hasImage && !_uploading)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '탭해서 사진 첨부',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_uploading)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // 이미지가 있을 때 우측 상단에 변경/삭제 단축 표시
                    if (hasImage && !_uploading)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                '변경',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _uploading ? null : _remove,
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 18),
              label: const Text('이미지 삭제',
                  style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
        if (widget.hint != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.hint!,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

class _SlideEditorCard extends StatelessWidget {
  final int index;
  final int total;
  final _SlideDraft draft;
  final String cardId;
  final ImageUploadService uploader;
  final List<Color> fallbackGradient;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _SlideEditorCard({
    required this.index,
    required this.total,
    required this.draft,
    required this.cardId,
    required this.uploader,
    required this.fallbackGradient,
    required this.onChanged,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.navyBase.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '슬라이드 ${index + 1} / $total',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.navyBase,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onMoveUp,
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: '위로',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onMoveDown,
                icon: const Icon(Icons.arrow_downward, size: 18),
                tooltip: '아래로',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                tooltip: '삭제',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ImageUploadField(
            currentUrl: draft.imageUrl,
            uploader: uploader,
            cardId: cardId,
            filename: 'slide_${index + 1}',
            fallbackGradient: fallbackGradient,
            aspectRatio: 4 / 5,
            onChanged: (url) {
              draft.imageUrl = url;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
