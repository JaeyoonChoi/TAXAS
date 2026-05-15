import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../firebase_options.dart';
import 'auth_provider.dart';

/// 프리미엄 구독 상태 — Firestore 사용자 문서(`users/{uid}`)의 `isSubscribed` 필드에 저장.
///
/// 서브컬렉션이 아닌 메인 문서에 머지 방식으로 저장 — 기존 사용자 정보 보안 규칙이
/// 그대로 커버. UserInfoState 직렬화 시 해당 필드는 무시되므로 충돌 없음.
class IsSubscribedController extends StateNotifier<bool> {
  IsSubscribedController(this._ref) : super(false) {
    _hydrate();
    _ref.listen<String?>(currentUidProvider, (prev, next) {
      if (prev != next) _hydrate();
    });
  }

  final Ref _ref;
  String? _hydratedUid;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> _hydrate() async {
    if (!useFirebase) return;
    final uid = _ref.read(currentUidProvider);
    if (uid == _hydratedUid) return;
    _hydratedUid = uid;

    if (uid == null) {
      state = false;
      return;
    }
    try {
      final snap = await _doc(uid).get().timeout(const Duration(seconds: 5));
      if (_hydratedUid != uid) return;
      state = snap.exists && (snap.data()?['isSubscribed'] == true);
      debugPrint('[subscription] hydrated $uid — active=$state');
    } catch (e) {
      debugPrint('[subscription] hydrate FAILED: $e');
    }
  }

  /// 구독 활성화 — 메모리 + Firestore 동시 업데이트.
  Future<bool> activate() async {
    state = true;
    if (!useFirebase) return true;
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return false;
    try {
      await _doc(uid).set({
        'isSubscribed': true,
        'subscribedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[subscription] activated $uid');
      return true;
    } catch (e) {
      debugPrint('[subscription] activate FAILED: $e');
      return false;
    }
  }

  /// 해지 — 테스트 / 향후 확장용.
  Future<void> deactivate() async {
    state = false;
    if (!useFirebase) return;
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    try {
      await _doc(uid).set({'isSubscribed': false}, SetOptions(merge: true));
    } catch (_) {}
  }
}

final isSubscribedProvider =
    StateNotifierProvider<IsSubscribedController, bool>(
  (ref) => IsSubscribedController(ref),
);
