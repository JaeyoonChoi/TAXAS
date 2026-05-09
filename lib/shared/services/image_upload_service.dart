import 'dart:convert';
import 'package:image_picker/image_picker.dart';

/// 카드 뉴스 이미지 처리.
///
/// Firebase Storage 무료 한도 제약으로, 이미지를 자동 압축한 뒤 base64로
/// 인코딩해 `data:image/...;base64,...` 형태로 반환. 호출부는 그 문자열을
/// 그대로 Firestore 문서 필드(`coverImageAsset`/`imageAsset`)에 저장한다.
///
/// 압축 옵션은 슬라이드 카드 1장이 보통 100–200KB로 떨어져 Firestore 1MiB
/// 문서 한도 안에서 카드당 6장까지 충분히 들어가도록 잡혀 있다.
class ImageUploadService {
  ImageUploadService();

  final ImagePicker _picker = ImagePicker();

  /// 갤러리에서 이미지 1장 선택 + 압축. 취소하면 null.
  Future<XFile?> pickImage() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1280,
      imageQuality: 75,
    );
  }

  /// 선택된 [XFile]을 `data:image/...;base64,...` 문자열로 인코딩.
  /// 결과 길이가 제한(900KB ≈ 921,600자)을 넘으면 [StateError].
  Future<String> encodeAsDataUri(XFile file) async {
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? _guessMime(file.name);
    final b64 = base64Encode(bytes);
    final dataUri = 'data:$mime;base64,$b64';
    if (dataUri.length > 900 * 1024) {
      throw StateError(
        '이미지가 너무 큽니다 (${(dataUri.length / 1024).round()}KB). '
        '더 작은 이미지를 선택하거나, 외부 호스팅 후 URL을 사용하세요.',
      );
    }
    return dataUri;
  }

  /// `data:` URI나 외부 URL이면 별도 처리 불필요. 본 구현은 외부 Storage를
  /// 쓰지 않으므로 인메모리 데이터를 무효화할 일은 없다 (Firestore 문서를
  /// 갱신하면 즉시 사라짐).
  Future<void> deleteByUrl(String _) async {}

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
