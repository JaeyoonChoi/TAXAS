// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_news_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cardNewsServiceHash() => r'9c8888f22645a26f8495ef33709200f1ba114d2d';

/// See also [cardNewsService].
@ProviderFor(cardNewsService)
final cardNewsServiceProvider = AutoDisposeProvider<CardNewsService>.internal(
  cardNewsService,
  name: r'cardNewsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cardNewsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CardNewsServiceRef = AutoDisposeProviderRef<CardNewsService>;
String _$imageUploadServiceHash() =>
    r'cccaf240abdb36331cf7f268a779a928c060e03d';

/// See also [imageUploadService].
@ProviderFor(imageUploadService)
final imageUploadServiceProvider =
    AutoDisposeProvider<ImageUploadService>.internal(
  imageUploadService,
  name: r'imageUploadServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$imageUploadServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ImageUploadServiceRef = AutoDisposeProviderRef<ImageUploadService>;
String _$cardNewsHash() => r'265959febe50dbae8ea3efdd287ba7cc46ca0300';

/// 공개 콘텐츠 탭/홈 헤드라인용 카드 뉴스 목록 — Firestore 실제 데이터.
///
/// 관리자가 발행한 카드만 노출. 비어 있으면 빈 리스트 (각 화면에서
/// "콘텐츠가 곧 올라옵니다" 같은 빈 상태를 직접 처리).
///
/// Copied from [cardNews].
@ProviderFor(cardNews)
final cardNewsProvider = AutoDisposeStreamProvider<List<CardNewsItem>>.internal(
  cardNews,
  name: r'cardNewsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cardNewsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CardNewsRef = AutoDisposeStreamProviderRef<List<CardNewsItem>>;
String _$cardNewsRawHash() => r'8d34121944bf37ead9c4abfbc0e7bde0f9682bb3';

/// 관리자 화면용 — `cardNewsProvider`와 동일하지만 의미상 분리해 둠.
/// 추후 관리자 전용 필터(예: 비공개/임시저장) 추가 가능.
///
/// Copied from [cardNewsRaw].
@ProviderFor(cardNewsRaw)
final cardNewsRawProvider =
    AutoDisposeStreamProvider<List<CardNewsItem>>.internal(
  cardNewsRaw,
  name: r'cardNewsRawProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cardNewsRawHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CardNewsRawRef = AutoDisposeStreamProviderRef<List<CardNewsItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
