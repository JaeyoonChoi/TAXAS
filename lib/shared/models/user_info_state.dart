import 'package:flutter/foundation.dart';

/// 가족 구성원 모델
@immutable
class FamilyInfo {
  final bool hasSpouse;
  final int childCount;
  final List<int> childAges; // 각 자녀 나이
  final int ownerAge;        // 피상속인(본인) 나이

  const FamilyInfo({
    this.hasSpouse = false,
    this.childCount = 0,
    this.childAges = const [],
    this.ownerAge = 60,
  });

  FamilyInfo copyWith({
    bool? hasSpouse,
    int? childCount,
    List<int>? childAges,
    int? ownerAge,
  }) {
    return FamilyInfo(
      hasSpouse: hasSpouse ?? this.hasSpouse,
      childCount: childCount ?? this.childCount,
      childAges: childAges ?? this.childAges,
      ownerAge: ownerAge ?? this.ownerAge,
    );
  }

  /// 미성년 자녀 수
  int get minorChildCount => childAges.where((age) => age < 19).length;

  /// 성인 자녀 수
  int get adultChildCount => childAges.where((age) => age >= 19).length;

  Map<String, dynamic> toJson() => {
        'hasSpouse': hasSpouse,
        'childCount': childCount,
        'childAges': childAges,
        'ownerAge': ownerAge,
      };

  factory FamilyInfo.fromJson(Map<String, dynamic> json) => FamilyInfo(
        hasSpouse: json['hasSpouse'] as bool? ?? false,
        childCount: (json['childCount'] as num?)?.toInt() ?? 0,
        childAges: (json['childAges'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        ownerAge: (json['ownerAge'] as num?)?.toInt() ?? 60,
      );
}

/// 자산 정보 모델
@immutable
class AssetInfo {
  final int realEstate;    // 부동산 공시지가 (원)
  final int financial;     // 금융자산 (원)
  final int other;         // 기타자산 (원)
  final int debt;          // 채무 (원)

  const AssetInfo({
    this.realEstate = 0,
    this.financial = 0,
    this.other = 0,
    this.debt = 0,
  });

  /// 총 자산 (채무 차감 전)
  int get totalGross => realEstate + financial + other;

  /// 순 자산 (채무 차감)
  int get totalNet => (totalGross - debt).clamp(0, totalGross);

  AssetInfo copyWith({
    int? realEstate,
    int? financial,
    int? other,
    int? debt,
  }) {
    return AssetInfo(
      realEstate: realEstate ?? this.realEstate,
      financial: financial ?? this.financial,
      other: other ?? this.other,
      debt: debt ?? this.debt,
    );
  }

  Map<String, dynamic> toJson() => {
        'realEstate': realEstate,
        'financial': financial,
        'other': other,
        'debt': debt,
      };

  factory AssetInfo.fromJson(Map<String, dynamic> json) => AssetInfo(
        realEstate: (json['realEstate'] as num?)?.toInt() ?? 0,
        financial: (json['financial'] as num?)?.toInt() ?? 0,
        other: (json['other'] as num?)?.toInt() ?? 0,
        debt: (json['debt'] as num?)?.toInt() ?? 0,
      );
}

/// 증여 이력 항목
@immutable
class GiftRecord {
  final String id;
  final String recipientName; // 수증자 이름
  final String relationship;  // 관계 (배우자, 자녀, 기타)
  final int amount;           // 증여액 (원)
  final int year;             // 증여 연도

  const GiftRecord({
    required this.id,
    required this.recipientName,
    required this.relationship,
    required this.amount,
    required this.year,
  });

  GiftRecord copyWith({
    String? id,
    String? recipientName,
    String? relationship,
    int? amount,
    int? year,
  }) {
    return GiftRecord(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      relationship: relationship ?? this.relationship,
      amount: amount ?? this.amount,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientName': recipientName,
        'relationship': relationship,
        'amount': amount,
        'year': year,
      };

  factory GiftRecord.fromJson(Map<String, dynamic> json) => GiftRecord(
        id: json['id'] as String,
        recipientName: json['recipientName'] as String? ?? '',
        relationship: json['relationship'] as String? ?? '자녀',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      );
}

/// 전체 사용자 입력 상태
@immutable
class UserInfoState {
  final FamilyInfo family;
  final AssetInfo assets;
  final List<GiftRecord> giftHistory;
  final int currentStep; // 0=가족, 1=자산, 2=증여이력

  const UserInfoState({
    this.family = const FamilyInfo(),
    this.assets = const AssetInfo(),
    this.giftHistory = const [],
    this.currentStep = 0,
  });

  UserInfoState copyWith({
    FamilyInfo? family,
    AssetInfo? assets,
    List<GiftRecord>? giftHistory,
    int? currentStep,
  }) {
    return UserInfoState(
      family: family ?? this.family,
      assets: assets ?? this.assets,
      giftHistory: giftHistory ?? this.giftHistory,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  /// 총 사전 증여액 (최근 10년)
  int get totalPastGifts =>
      giftHistory.fold(0, (sum, r) => sum + r.amount);

  /// 입력 완성도 (0.0 ~ 1.0)
  double get completeness {
    int filled = 0;
    if (assets.totalGross > 0) filled++;
    if (family.childCount > 0 || family.hasSpouse) filled++;
    if (giftHistory.isNotEmpty) filled++;
    return filled / 3.0;
  }

  Map<String, dynamic> toJson() => {
        'family': family.toJson(),
        'assets': assets.toJson(),
        'giftHistory': giftHistory.map((g) => g.toJson()).toList(),
        'currentStep': currentStep,
      };

  factory UserInfoState.fromJson(Map<String, dynamic> json) => UserInfoState(
        family: json['family'] is Map<String, dynamic>
            ? FamilyInfo.fromJson(json['family'] as Map<String, dynamic>)
            : const FamilyInfo(),
        assets: json['assets'] is Map<String, dynamic>
            ? AssetInfo.fromJson(json['assets'] as Map<String, dynamic>)
            : const AssetInfo(),
        giftHistory: (json['giftHistory'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(GiftRecord.fromJson)
                .toList() ??
            const [],
        currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
      );
}
