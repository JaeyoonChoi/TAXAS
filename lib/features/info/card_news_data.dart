import 'dart:convert';
import 'package:flutter/material.dart';

/// 카드 뉴스 이미지 경로 → 적절한 [ImageProvider]로 변환.
///
/// - `data:image/...;base64,...` → [MemoryImage] (인앱 base64 인코딩한 결과)
/// - `http(s)://...` → [NetworkImage] (외부 호스팅 URL)
/// - 그 외 → [AssetImage] (앱 번들 정적 자산 경로)
ImageProvider cardNewsImageProvider(String pathOrUrl) {
  if (pathOrUrl.startsWith('data:')) {
    final commaIdx = pathOrUrl.indexOf(',');
    if (commaIdx > 0) {
      final b64 = pathOrUrl.substring(commaIdx + 1);
      return MemoryImage(base64Decode(b64));
    }
  }
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return NetworkImage(pathOrUrl);
  }
  return AssetImage(pathOrUrl);
}

/// 카드 뉴스 한 편(여러 슬라이드 포함).
class CardNewsItem {
  final String id;
  final String title;
  final String summary;
  final String tag;
  final String date;
  final List<Color> coverGradient;
  final String? coverImageAsset;
  final List<CardNewsSlide> slides;

  const CardNewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.tag,
    required this.date,
    required this.coverGradient,
    this.coverImageAsset,
    required this.slides,
  });

  CardNewsItem copyWith({
    String? id,
    String? title,
    String? summary,
    String? tag,
    String? date,
    List<Color>? coverGradient,
    String? coverImageAsset,
    List<CardNewsSlide>? slides,
  }) {
    return CardNewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      tag: tag ?? this.tag,
      date: date ?? this.date,
      coverGradient: coverGradient ?? this.coverGradient,
      coverImageAsset: coverImageAsset ?? this.coverImageAsset,
      slides: slides ?? this.slides,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'tag': tag,
        'date': date,
        'coverGradient': coverGradient.map((c) => c.toARGB32()).toList(),
        if (coverImageAsset != null) 'coverImageAsset': coverImageAsset,
        'slides': slides.map((s) => s.toJson()).toList(),
      };

  factory CardNewsItem.fromJson(Map<String, dynamic> json) => CardNewsItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        date: json['date'] as String? ?? '',
        coverGradient: (json['coverGradient'] as List?)
                ?.map((v) => Color((v as num).toInt()))
                .toList() ??
            const [Color(0xFF1E3A5F), Color(0xFF3B5C8A)],
        coverImageAsset: json['coverImageAsset'] as String?,
        slides: (json['slides'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(CardNewsSlide.fromJson)
                .toList() ??
            const [],
      );
}

/// 카드 뉴스 한 슬라이드.
///
/// `imageAsset`이 있으면 이미지가 우선, 없으면 [gradient]로 색상 placeholder.
/// `heading`이 큰 제목, `body`가 본문.
class CardNewsSlide {
  final String? heading;
  final String? body;
  final String? imageAsset;
  final List<Color>? gradient;

  const CardNewsSlide({
    this.heading,
    this.body,
    this.imageAsset,
    this.gradient,
  });

  CardNewsSlide copyWith({
    String? heading,
    String? body,
    String? imageAsset,
    List<Color>? gradient,
  }) {
    return CardNewsSlide(
      heading: heading ?? this.heading,
      body: body ?? this.body,
      imageAsset: imageAsset ?? this.imageAsset,
      gradient: gradient ?? this.gradient,
    );
  }

  Map<String, dynamic> toJson() => {
        if (heading != null) 'heading': heading,
        if (body != null) 'body': body,
        if (imageAsset != null) 'imageAsset': imageAsset,
        if (gradient != null)
          'gradient': gradient!.map((c) => c.toARGB32()).toList(),
      };

  factory CardNewsSlide.fromJson(Map<String, dynamic> json) => CardNewsSlide(
        heading: json['heading'] as String?,
        body: json['body'] as String?,
        imageAsset: json['imageAsset'] as String?,
        gradient: (json['gradient'] as List?)
            ?.map((v) => Color((v as num).toInt()))
            .toList(),
      );
}

/// 카드 뉴스 샘플 데이터.
/// 실제 콘텐츠로 교체하거나 새 항목을 추가하세요.
const cardNewsItems = <CardNewsItem>[
  CardNewsItem(
    id: 'tax-reform-2026',
    title: '2026년 상속세 개정\n한눈에 보기',
    summary: '올해 바뀐 상속·증여세법 주요 변경 사항을 정리했습니다.',
    tag: '세법 개정',
    date: '2026.05.01',
    coverGradient: [Color(0xFF1E3A5F), Color(0xFF3B5C8A)],
    slides: [
      CardNewsSlide(
        heading: '2026년 상속세 개정',
        body: '주요 변경 사항을 4장으로 정리했습니다. 좌우로 스와이프하세요.',
        gradient: [Color(0xFF1E3A5F), Color(0xFF3B5C8A)],
      ),
      CardNewsSlide(
        heading: '1. 자녀 공제 인상',
        body: '자녀 1인당 5천만원 → 5억원으로 대폭 상향. 미성년자 추가 공제도 1년당 1천만원 → 5천만원.',
        gradient: [Color(0xFF1E3A5F), Color(0xFF3B5C8A)],
      ),
      CardNewsSlide(
        heading: '2. 최고 세율 조정',
        body: '50% → 40%로 인하. 30억 초과 구간의 세 부담이 줄어들었습니다.',
        gradient: [Color(0xFF1E3A5F), Color(0xFF3B5C8A)],
      ),
      CardNewsSlide(
        heading: '3. 일괄공제 유지',
        body: '5억원 일괄공제는 그대로. 기초+인적공제 합계가 더 크면 그쪽을 적용.',
        gradient: [Color(0xFF1E3A5F), Color(0xFF3B5C8A)],
      ),
    ],
  ),
  CardNewsItem(
    id: 'gift-strategies-5',
    title: '사전증여로 절세하는\n5가지 방법',
    summary: '미리 증여하면 어떻게 세금이 줄어드는지, 실제 사례로 풀어봤습니다.',
    tag: '절세 전략',
    date: '2026.04.20',
    coverGradient: [Color(0xFFB8954A), Color(0xFFE0B86E)],
    slides: [
      CardNewsSlide(
        heading: '사전증여 5가지 전략',
        body: '상속세를 줄이는 핵심 노하우.',
        gradient: [Color(0xFFB8954A), Color(0xFFE0B86E)],
      ),
      CardNewsSlide(
        heading: '① 10년 단위 분산',
        body: '증여공제는 10년마다 갱신됩니다. 시기를 분산해 같은 한도를 여러 번 활용하세요.',
        gradient: [Color(0xFFB8954A), Color(0xFFE0B86E)],
      ),
      CardNewsSlide(
        heading: '② 배우자 공제 활용',
        body: '배우자 간 증여는 6억원까지 비과세. 이를 활용해 자산을 분산시키면 상속세 누진세율을 피할 수 있습니다.',
        gradient: [Color(0xFFB8954A), Color(0xFFE0B86E)],
      ),
      CardNewsSlide(
        heading: '③ 미성년 자녀 분산',
        body: '미성년 자녀에게도 1인당 2천만원 공제 가능. 가족 구성원이 많을수록 절세 효과 ↑',
        gradient: [Color(0xFFB8954A), Color(0xFFE0B86E)],
      ),
      CardNewsSlide(
        heading: '④ 공시지가 시점 활용',
        body: '부동산은 증여 시점의 공시지가 기준으로 평가됩니다. 가격 상승 전 증여하면 평가액이 낮아집니다.',
        gradient: [Color(0xFFB8954A), Color(0xFFE0B86E)],
      ),
      CardNewsSlide(
        heading: '⑤ 생명보험 활용',
        body: '계약자·수익자 설계에 따라 상속재산에서 제외 가능. 전문가 상담 필수.',
        gradient: [Color(0xFFB8954A), Color(0xFFE0B86E)],
      ),
    ],
  ),
  CardNewsItem(
    id: 'spouse-deduction-30',
    title: '배우자 공제 30억,\n어떻게 활용할까',
    summary: '배우자 공제 한도를 최대로 살리는 분배 시뮬레이션.',
    tag: '공제 활용',
    date: '2026.04.10',
    coverGradient: [Color(0xFF2A5A47), Color(0xFF4F8E70)],
    slides: [
      CardNewsSlide(
        heading: '배우자 상속공제',
        body: '한국 상속세에서 가장 큰 공제 항목.',
        gradient: [Color(0xFF2A5A47), Color(0xFF4F8E70)],
      ),
      CardNewsSlide(
        heading: '한도: 5억 ~ 30억',
        body: '최소 5억은 무조건 공제. 법정상속분 범위 내에서 최대 30억까지 추가 공제.',
        gradient: [Color(0xFF2A5A47), Color(0xFF4F8E70)],
      ),
      CardNewsSlide(
        heading: '법정상속분 계산',
        body: '배우자 + 자녀 1명 → 배우자 3/5\n배우자 + 자녀 2명 → 배우자 3/7\n배우자 + 자녀 3명 → 배우자 3/9',
        gradient: [Color(0xFF2A5A47), Color(0xFF4F8E70)],
      ),
      CardNewsSlide(
        heading: '실제 사례',
        body: '총 자산 50억, 배우자+자녀 2명 가정\n→ 배우자 법정상속분 약 21억\n→ 30억 한도 내이므로 21억 전액 공제 가능',
        gradient: [Color(0xFF2A5A47), Color(0xFF4F8E70)],
      ),
    ],
  ),
  CardNewsItem(
    id: 'gift-trap-10y',
    title: '10년 사전증여의 함정',
    summary: '사전증여 후 10년 내 사망 시 어떻게 합산되는지 사례로 살펴봅니다.',
    tag: '주의 사항',
    date: '2026.03.28',
    coverGradient: [Color(0xFF7A2E2E), Color(0xFFB85959)],
    slides: [
      CardNewsSlide(
        heading: '⚠️ 10년 합산 규정',
        body: '사망 전 10년 이내 상속인에게 증여한 재산은 상속재산에 합산됩니다.',
        gradient: [Color(0xFF7A2E2E), Color(0xFFB85959)],
      ),
      CardNewsSlide(
        heading: '왜 함정인가',
        body: '미리 증여세를 냈다고 안심하기 쉽지만, 10년 안에 상속이 시작되면 합산되어 다시 상속세 계산에 포함됩니다.',
        gradient: [Color(0xFF7A2E2E), Color(0xFFB85959)],
      ),
      CardNewsSlide(
        heading: '제3자 증여는 5년',
        body: '상속인이 아닌 사람에게 증여한 경우 5년 이내만 합산. 친족 외 증여라면 기간이 짧습니다.',
        gradient: [Color(0xFF7A2E2E), Color(0xFFB85959)],
      ),
      CardNewsSlide(
        heading: '결론',
        body: '사전증여는 가능한 한 일찍 시작하세요. 절세 효과를 보려면 10년+ 생존이 필요합니다.',
        gradient: [Color(0xFF7A2E2E), Color(0xFFB85959)],
      ),
    ],
  ),
];
