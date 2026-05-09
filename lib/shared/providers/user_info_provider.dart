import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_info_state.dart';
import '../services/user_data_service.dart';
import '../../firebase_options.dart';
import 'auth_provider.dart';

part 'user_info_provider.g.dart';

@riverpod
UserDataService userDataService(UserDataServiceRef ref) {
  return UserDataService(FirebaseFirestore.instance);
}

@Riverpod(keepAlive: true)
class UserInfo extends _$UserInfo {
  Timer? _saveDebounce;
  String? _hydratedUid;

  @override
  UserInfoState build() {
    // keepAlive: true이므로 화면 이동 중에도 state가 유지됨.
    final uid = useFirebase ? ref.watch(currentUidProvider) : null;
    _saveDebounce?.cancel();

    if (uid != null && uid != _hydratedUid) {
      _hydratedUid = uid;
      // 새 사용자로 바뀌면: 비동기로 Firestore에서 1회 hydrate.
      // 이미 다른 사용자 데이터가 남아있을 수 있으니 일단 비웠다가 채운다.
      Future.microtask(() async {
        if (_hydratedUid != uid) return; // uid가 그 사이에 또 바뀜 → 무시
        state = const UserInfoState();
        try {
          final remote = await ref
              .read(userDataServiceProvider)
              .watch(uid)
              .first
              .timeout(const Duration(seconds: 5));
          if (_hydratedUid == uid) {
            state = remote;
          }
        } catch (_) {
          // 네트워크 오류 등 — 빈 상태 유지하고 계속 진행
        }
      });
    } else if (uid == null) {
      _hydratedUid = null;
    }

    ref.onDispose(() {
      _saveDebounce?.cancel();
    });

    return const UserInfoState();
  }

  /// state 변경 후 Firestore에 디바운스 저장.
  void _scheduleSync() {
    if (!useFirebase) return;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(userDataServiceProvider).save(uid, state).catchError((_) {});
    });
  }

  // ── 가족 정보 ──────────────────────────────────────────
  void updateFamily(FamilyInfo family) {
    state = state.copyWith(family: family);
    _scheduleSync();
  }

  void setHasSpouse(bool value) {
    state = state.copyWith(family: state.family.copyWith(hasSpouse: value));
    _scheduleSync();
  }

  void setOwnerAge(int age) {
    state = state.copyWith(family: state.family.copyWith(ownerAge: age));
    _scheduleSync();
  }

  void setChildCount(int count) {
    final ages = List<int>.from(state.family.childAges);
    while (ages.length < count) {
      ages.add(20);
    }
    while (ages.length > count) {
      ages.removeLast();
    }
    state = state.copyWith(
      family: state.family.copyWith(childCount: count, childAges: ages),
    );
    _scheduleSync();
  }

  void setChildAge(int index, int age) {
    final ages = List<int>.from(state.family.childAges);
    if (index < ages.length) {
      ages[index] = age;
      state = state.copyWith(
        family: state.family.copyWith(childAges: ages),
      );
      _scheduleSync();
    }
  }

  // ── 자산 정보 ──────────────────────────────────────────
  void updateAssets(AssetInfo assets) {
    state = state.copyWith(assets: assets);
    _scheduleSync();
  }

  void setRealEstate(int value) {
    state = state.copyWith(assets: state.assets.copyWith(realEstate: value));
    _scheduleSync();
  }

  void setFinancial(int value) {
    state = state.copyWith(assets: state.assets.copyWith(financial: value));
    _scheduleSync();
  }

  void setOther(int value) {
    state = state.copyWith(assets: state.assets.copyWith(other: value));
    _scheduleSync();
  }

  void setDebt(int value) {
    state = state.copyWith(assets: state.assets.copyWith(debt: value));
    _scheduleSync();
  }

  // ── 증여 이력 ──────────────────────────────────────────
  void addGiftRecord(GiftRecord record) {
    state = state.copyWith(giftHistory: [...state.giftHistory, record]);
    _scheduleSync();
  }

  void removeGiftRecord(String id) {
    state = state.copyWith(
      giftHistory: state.giftHistory.where((r) => r.id != id).toList(),
    );
    _scheduleSync();
  }

  void updateGiftRecord(GiftRecord record) {
    state = state.copyWith(
      giftHistory: state.giftHistory.map(
        (r) => r.id == record.id ? record : r,
      ).toList(),
    );
    _scheduleSync();
  }

  // ── 스텝 이동 ──────────────────────────────────────────
  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      _scheduleSync();
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
      _scheduleSync();
    }
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step.clamp(0, 2));
    _scheduleSync();
  }

  // ── 초기화 ─────────────────────────────────────────────
  void reset() {
    state = const UserInfoState();
    _scheduleSync();
  }
}
