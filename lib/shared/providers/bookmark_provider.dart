import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'bookmark_provider.g.dart';

/// 카드 뉴스 북마크 — 로컬 저장(shared_preferences) 기반.
///
/// 북마크는 큰 데이터가 아니고 디바이스별로 로컬 저장이 충분.
/// 추후 멀티 디바이스 동기화가 필요해지면 Firestore로 이전 가능.
@Riverpod(keepAlive: true)
class Bookmarks extends _$Bookmarks {
  static const _prefsKey = 'card_news_bookmarks';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? const <String>[];
    return list.toSet();
  }

  Future<void> toggle(String id) async {
    final current = await future;
    final next = current.toSet();
    if (!next.add(id)) {
      next.remove(id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next.toList());
    state = AsyncData(next);
  }

  Future<bool> isBookmarked(String id) async {
    final current = await future;
    return current.contains(id);
  }
}
