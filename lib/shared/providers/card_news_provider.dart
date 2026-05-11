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

/// 공개 콘텐츠 탭/홈 헤드라인용 카드 뉴스 목록 — Firestore 실제 데이터.
///
/// 관리자가 발행한 카드만 노출. 비어 있으면 빈 리스트 (각 화면에서
/// "콘텐츠가 곧 올라옵니다" 같은 빈 상태를 직접 처리).
@riverpod
Stream<List<CardNewsItem>> cardNews(CardNewsRef ref) {
  if (!useFirebase) {
    return Stream.value(const <CardNewsItem>[]);
  }
  return ref.read(cardNewsServiceProvider).watchAll();
}

/// 관리자 화면용 — `cardNewsProvider`와 동일하지만 의미상 분리해 둠.
/// 추후 관리자 전용 필터(예: 비공개/임시저장) 추가 가능.
@riverpod
Stream<List<CardNewsItem>> cardNewsRaw(CardNewsRawRef ref) {
  if (!useFirebase) {
    return Stream.value(const <CardNewsItem>[]);
  }
  return ref.read(cardNewsServiceProvider).watchAll();
}
