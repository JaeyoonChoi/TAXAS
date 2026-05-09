// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseAuthHash() => r'7791bf70ce0f01bf991a53a76abc915478673c0b';

/// FirebaseAuth 인스턴스. Firebase 미설정(useFirebase=false)일 때도
/// 화면이 컴파일·렌더링되도록 lazy하게 접근한다.
///
/// Copied from [firebaseAuth].
@ProviderFor(firebaseAuth)
final firebaseAuthProvider = AutoDisposeProvider<FirebaseAuth>.internal(
  firebaseAuth,
  name: r'firebaseAuthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firebaseAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FirebaseAuthRef = AutoDisposeProviderRef<FirebaseAuth>;
String _$authStateHash() => r'363acb77c429679d6e9134a479d0266047edd3c5';

/// 현재 인증 상태를 스트리밍. 로그아웃 상태면 User?의 null.
///
/// Copied from [authState].
@ProviderFor(authState)
final authStateProvider = AutoDisposeStreamProvider<User?>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthStateRef = AutoDisposeStreamProviderRef<User?>;
String _$currentUidHash() => r'f2f92299ec8a582da67c0dcca8bb049b9d4f4cec';

/// 로그인된 사용자의 uid (없으면 null).
///
/// Copied from [currentUid].
@ProviderFor(currentUid)
final currentUidProvider = AutoDisposeProvider<String?>.internal(
  currentUid,
  name: r'currentUidProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUidHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentUidRef = AutoDisposeProviderRef<String?>;
String _$isAdminHash() => r'763c38df887290c468ed6220a298d6cc08570d5c';

/// 현재 사용자가 관리자인지 — 이메일 allowlist 기반.
///
/// Copied from [isAdmin].
@ProviderFor(isAdmin)
final isAdminProvider = AutoDisposeProvider<bool>.internal(
  isAdmin,
  name: r'isAdminProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isAdminHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsAdminRef = AutoDisposeProviderRef<bool>;
String _$authControllerHash() => r'07e556881c47e49172d22593651f6cea092f3bf6';

/// 인증 작업(로그인·가입·로그아웃)을 수행하는 컨트롤러.
///
/// Copied from [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    AutoDisposeNotifierProvider<AuthController, AsyncValue<void>>.internal(
  AuthController.new,
  name: r'authControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthController = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
