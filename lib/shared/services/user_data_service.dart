import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_info_state.dart';

/// Firestore에 `users/{uid}` 문서로 저장되는 사용자 입력 데이터의 read/write.
class UserDataService {
  UserDataService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// 사용자 문서를 실시간으로 watch. 문서가 없으면 빈 UserInfoState 발행.
  Stream<UserInfoState> watch(String uid) {
    return _doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return const UserInfoState();
      return UserInfoState.fromJson(data);
    });
  }

  /// 사용자 입력을 Firestore에 저장 (merge).
  Future<void> save(String uid, UserInfoState state) async {
    final payload = {
      ...state.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _doc(uid).set(payload, SetOptions(merge: true));
  }
}
