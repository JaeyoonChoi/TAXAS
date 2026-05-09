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
String _$cardNewsHash() => r'81c196c091dd6b5bd94ce929d6340d424565d8d1';

/// 표시용 카드 뉴스 목록.
///
/// Firebase가 켜져 있고 Firestore에 데이터가 있으면 그쪽을 사용,
/// 없거나 에러면 [cardNewsItems] 정적 fallback.
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
