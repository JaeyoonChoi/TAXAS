// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userDataServiceHash() => r'0f6a363ad54de89b690c8ec9532c472011aa486a';

/// See also [userDataService].
@ProviderFor(userDataService)
final userDataServiceProvider = AutoDisposeProvider<UserDataService>.internal(
  userDataService,
  name: r'userDataServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userDataServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserDataServiceRef = AutoDisposeProviderRef<UserDataService>;
String _$userInfoHash() => r'e7533489b09f48758f1459605a3a6e0e5bed7521';

/// See also [UserInfo].
@ProviderFor(UserInfo)
final userInfoProvider = NotifierProvider<UserInfo, UserInfoState>.internal(
  UserInfo.new,
  name: r'userInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserInfo = Notifier<UserInfoState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
