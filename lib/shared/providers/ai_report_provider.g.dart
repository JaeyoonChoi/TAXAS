// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiReportServiceHash() => r'ccd12c59a0a01f6aaa452f59dc30ecaf403c5554';

/// See also [aiReportService].
@ProviderFor(aiReportService)
final aiReportServiceProvider = AutoDisposeProvider<AiReportService>.internal(
  aiReportService,
  name: r'aiReportServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiReportServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AiReportServiceRef = AutoDisposeProviderRef<AiReportService>;
String _$aiReportControllerHash() =>
    r'd734cf26f11dbd631b6a0419be523f49efb04e59';

/// 리포트 화면에서 보는 분석.
///
/// 자동으로 캐시를 먼저 확인하고, 없거나 입력이 바뀌었을 때만
/// Vercel API를 호출. UI에서 "재생성" 버튼을 누르면 강제 갱신 가능.
///
/// Copied from [AiReportController].
@ProviderFor(AiReportController)
final aiReportControllerProvider =
    NotifierProvider<AiReportController, AiReportState>.internal(
  AiReportController.new,
  name: r'aiReportControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiReportControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AiReportController = Notifier<AiReportState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
