import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/info/card_news_data.dart';
import '../services/card_news_service.dart';
import '../services/image_upload_service.dart';
import '../../firebase_options.dart';

part 'card_news_provider.g.dart';

@riverpod
CardNewsService cardNewsService(CardNewsServiceRef ref) {
  return CardNewsService(FirebaseFirestore.instance);
}

@riverpod
ImageUploadService imageUploadService(ImageUploadServiceRef ref) {
  return ImageUploadService();
}

/// 표시용 카드 뉴스 목록.
///
/// Firebase가 켜져 있고 Firestore에 데이터가 있으면 그쪽을 사용,
/// 없거나 에러면 [cardNewsItems] 정적 fallback.
@riverpod
Stream<List<CardNewsItem>> cardNews(CardNewsRef ref) async* {
  if (!useFirebase) {
    yield cardNewsItems;
    return;
  }
  await for (final list in ref.read(cardNewsServiceProvider).watchAll()) {
    yield list.isEmpty ? cardNewsItems : list;
  }
}
