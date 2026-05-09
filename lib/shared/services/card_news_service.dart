import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/info/card_news_data.dart';

/// `cardNews` 컬렉션의 read/write.
///
/// 문서 구조는 [CardNewsItem.toJson]과 동일 + 서버 타임스탬프 `createdAt`/`updatedAt`.
class CardNewsService {
  CardNewsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('cardNews');

  /// 발행된 카드 뉴스를 최신순으로 watch.
  Stream<List<CardNewsItem>> watchAll() {
    return _col.orderBy('date', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = {...d.data(), 'id': d.id};
        return CardNewsItem.fromJson(data);
      }).toList();
    });
  }

  Future<void> upsert(CardNewsItem item) async {
    final payload = {
      ...item.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final doc = _col.doc(item.id);
    final exists = (await doc.get()).exists;
    if (!exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await doc.set(payload, SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
