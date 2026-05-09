// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookmarksHash() => r'ec5d8973478b3220fa16e701b5670a669dadb65c';

/// 카드 뉴스 북마크 — 로컬 저장(shared_preferences) 기반.
///
/// 북마크는 큰 데이터가 아니고 디바이스별로 로컬 저장이 충분.
/// 추후 멀티 디바이스 동기화가 필요해지면 Firestore로 이전 가능.
///
/// Copied from [Bookmarks].
@ProviderFor(Bookmarks)
final bookmarksProvider =
    AsyncNotifierProvider<Bookmarks, Set<String>>.internal(
  Bookmarks.new,
  name: r'bookmarksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$bookmarksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Bookmarks = AsyncNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
