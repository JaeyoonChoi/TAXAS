// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$communityServiceHash() => r'3ef69dc7a0c2dea8dbcdbacf26bba4f60e91220b';

/// See also [communityService].
@ProviderFor(communityService)
final communityServiceProvider = AutoDisposeProvider<CommunityService>.internal(
  communityService,
  name: r'communityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$communityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CommunityServiceRef = AutoDisposeProviderRef<CommunityService>;
String _$communityPostsHash() => r'5a95689cb0c714f6a299dbf0ea51e8f3c2af624d';

/// See also [communityPosts].
@ProviderFor(communityPosts)
final communityPostsProvider =
    AutoDisposeStreamProvider<List<CommunityPost>>.internal(
  communityPosts,
  name: r'communityPostsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$communityPostsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CommunityPostsRef = AutoDisposeStreamProviderRef<List<CommunityPost>>;
String _$communityPostHash() => r'058946f4d72e90d1c3c6d190d666ed64eb96a5e2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [communityPost].
@ProviderFor(communityPost)
const communityPostProvider = CommunityPostFamily();

/// See also [communityPost].
class CommunityPostFamily extends Family<AsyncValue<CommunityPost?>> {
  /// See also [communityPost].
  const CommunityPostFamily();

  /// See also [communityPost].
  CommunityPostProvider call(
    String id,
  ) {
    return CommunityPostProvider(
      id,
    );
  }

  @override
  CommunityPostProvider getProviderOverride(
    covariant CommunityPostProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'communityPostProvider';
}

/// See also [communityPost].
class CommunityPostProvider extends AutoDisposeStreamProvider<CommunityPost?> {
  /// See also [communityPost].
  CommunityPostProvider(
    String id,
  ) : this._internal(
          (ref) => communityPost(
            ref as CommunityPostRef,
            id,
          ),
          from: communityPostProvider,
          name: r'communityPostProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$communityPostHash,
          dependencies: CommunityPostFamily._dependencies,
          allTransitiveDependencies:
              CommunityPostFamily._allTransitiveDependencies,
          id: id,
        );

  CommunityPostProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    Stream<CommunityPost?> Function(CommunityPostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommunityPostProvider._internal(
        (ref) => create(ref as CommunityPostRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<CommunityPost?> createElement() {
    return _CommunityPostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommunityPostProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CommunityPostRef on AutoDisposeStreamProviderRef<CommunityPost?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _CommunityPostProviderElement
    extends AutoDisposeStreamProviderElement<CommunityPost?>
    with CommunityPostRef {
  _CommunityPostProviderElement(super.provider);

  @override
  String get id => (origin as CommunityPostProvider).id;
}

String _$communityCommentsHash() => r'1dabf3b25ad088a04e8de88d1a7a1140fcb22660';

/// See also [communityComments].
@ProviderFor(communityComments)
const communityCommentsProvider = CommunityCommentsFamily();

/// See also [communityComments].
class CommunityCommentsFamily
    extends Family<AsyncValue<List<CommunityComment>>> {
  /// See also [communityComments].
  const CommunityCommentsFamily();

  /// See also [communityComments].
  CommunityCommentsProvider call(
    String postId,
  ) {
    return CommunityCommentsProvider(
      postId,
    );
  }

  @override
  CommunityCommentsProvider getProviderOverride(
    covariant CommunityCommentsProvider provider,
  ) {
    return call(
      provider.postId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'communityCommentsProvider';
}

/// See also [communityComments].
class CommunityCommentsProvider
    extends AutoDisposeStreamProvider<List<CommunityComment>> {
  /// See also [communityComments].
  CommunityCommentsProvider(
    String postId,
  ) : this._internal(
          (ref) => communityComments(
            ref as CommunityCommentsRef,
            postId,
          ),
          from: communityCommentsProvider,
          name: r'communityCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$communityCommentsHash,
          dependencies: CommunityCommentsFamily._dependencies,
          allTransitiveDependencies:
              CommunityCommentsFamily._allTransitiveDependencies,
          postId: postId,
        );

  CommunityCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    Stream<List<CommunityComment>> Function(CommunityCommentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommunityCommentsProvider._internal(
        (ref) => create(ref as CommunityCommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<CommunityComment>> createElement() {
    return _CommunityCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommunityCommentsProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CommunityCommentsRef
    on AutoDisposeStreamProviderRef<List<CommunityComment>> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _CommunityCommentsProviderElement
    extends AutoDisposeStreamProviderElement<List<CommunityComment>>
    with CommunityCommentsRef {
  _CommunityCommentsProviderElement(super.provider);

  @override
  String get postId => (origin as CommunityCommentsProvider).postId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
