import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../firebase_options.dart';
import 'auth_provider.dart';

/// 플래너 체크 상태 — Firestore 사용자 문서의 `plannerDone` 필드에 저장.
///
/// 메인 사용자 문서에 머지 방식으로 저장 — 기존 보안 규칙 그대로 적용됨.
class PlannerStateController extends StateNotifier<Set<String>> {
  PlannerStateController(this._ref) : super(<String>{}) {
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
      state = <String>{};
      return;
    }
    try {
      final snap = await _doc(uid).get().timeout(const Duration(seconds: 5));
      if (_hydratedUid != uid) return;
      final list = (snap.data()?['plannerDone'] as List?)
              ?.whereType<String>()
              .toSet() ??
          <String>{};
      state = list;
      debugPrint('[planner] hydrated $uid — ${list.length} items');
    } catch (e) {
      debugPrint('[planner] hydrate FAILED: $e');
    }
  }

  /// 항목 토글 (있으면 제거, 없으면 추가) + Firestore에 즉시 저장.
  Future<void> toggle(String id) async {
    final next = <String>{...state};
    if (!next.add(id)) next.remove(id);
    state = next;
    await _save();
  }

  Future<void> _save() async {
    if (!useFirebase) return;
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    try {
      await _doc(uid).set({
        'plannerDone': state.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[planner] save FAILED: $e');
    }
  }
}

final plannerStateProvider =
    StateNotifierProvider<PlannerStateController, Set<String>>(
  (ref) => PlannerStateController(ref),
);
