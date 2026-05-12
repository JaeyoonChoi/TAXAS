import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// 카드 뉴스 이미지 처리.
///
/// Firebase Storage 무료 한도 제약으로, 이미지를 자동 압축한 뒤 base64로
/// 인코딩해 `data:image/...;base64,...` 형태로 반환. 호출부는 그 문자열을
/// 그대로 Firestore 문서 필드(`coverImageAsset`/`imageAsset`)에 저장한다.
///
/// `image_picker`의 `maxWidth`/`imageQuality`는 Web에서 무시되는 경우가 많아
/// `image` 패키지로 직접 리사이즈/JPEG 재인코딩을 수행한다.
///
/// **개별 이미지 한도**: 카드뉴스 한 문서에 표지 1 + 슬라이드 N개가 모두
/// base64로 인라인되어 들어가기 때문에, 합계가 Firestore 문서 한도(1 MiB)를
/// 넘지 않으려면 개별 이미지를 ~140KB 이하로 묶어야 한다. 7장까지 안전.
class ImageUploadService {
  ImageUploadService();

  final ImagePicker _picker = ImagePicker();

  /// 한 이미지가 차지할 수 있는 base64 문자열 최대 바이트.
  /// 카드뉴스 문서 1MiB 한도에서 7장까지 들어가도록 잡은 기본값.
  static const int defaultMaxDataUriBytes = 140 * 1024;

  /// 갤러리에서 이미지 1장 선택. 압축은 [encodeAsDataUri]에서 처리.
  Future<XFile?> pickImage() async {
    return _picker.pickImage(source: ImageSource.gallery);
  }

  /// [XFile]을 리사이즈·재인코딩하여 `data:image/jpeg;base64,...` 문자열로 변환.
  /// 한도 안에 못 맞추면 [StateError].
  Future<String> encodeAsDataUri(
    XFile file, {
    int maxBytes = defaultMaxDataUriBytes,
  }) async {
    final raw = await file.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw StateError('이미지를 읽을 수 없습니다. JPEG/PNG/WebP 파일인지 확인하세요.');
    }

    // 단계적 시도: 가로 폭과 JPEG 품질을 점진적으로 낮춰 한도를 맞춘다.
    // 텍스트 슬라이드는 보통 720px q=55 정도면 100KB 이하로 떨어진다.
    const widths = [1024, 880, 760, 640, 540, 460];
    const qualities = [75, 65, 55, 45, 35];

    for (final w in widths) {
      final resized = decoded.width > w
          ? img.copyResize(decoded, width: w, interpolation: img.Interpolation.average)
          : decoded;
      for (final q in qualities) {
        final jpg = img.encodeJpg(resized, quality: q);
        final b64 = base64Encode(jpg);
        final dataUri = 'data:image/jpeg;base64,$b64';
        if (dataUri.length <= maxBytes) {
          return dataUri;
        }
      }
    }

    // 최후의 수단: 400px · 품질 25
    final tiny = img.copyResize(decoded, width: 400, interpolation: img.Interpolation.average);
    final jpg = img.encodeJpg(tiny, quality: 25);
    final dataUri = 'data:image/jpeg;base64,${base64Encode(jpg)}';
    if (dataUri.length <= maxBytes) return dataUri;

    throw StateError(
      '이미지가 너무 큽니다 (압축 후 ${(dataUri.length / 1024).round()}KB, 한도 ${(maxBytes / 1024).round()}KB). '
      '슬라이드 수를 줄이거나 더 단순한 이미지로 시도해주세요.',
    );
  }

  /// 기존 저장된 `data:` URI가 한도를 넘으면 다시 압축. 한도 안이면 그대로 반환.
  /// `data:` 가 아닌 URL/asset 경로는 손대지 않는다.
  Future<String> recompressIfNeeded(
    String dataUriOrUrl, {
    int maxBytes = defaultMaxDataUriBytes,
  }) async {
    if (!dataUriOrUrl.startsWith('data:')) return dataUriOrUrl;
    if (dataUriOrUrl.length <= maxBytes) return dataUriOrUrl;

    final commaIdx = dataUriOrUrl.indexOf(',');
    if (commaIdx < 0) return dataUriOrUrl;
    final bytes = base64Decode(dataUriOrUrl.substring(commaIdx + 1));
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('저장된 이미지를 다시 압축할 수 없습니다.');
    }

    const widths = [880, 760, 640, 540, 460];
    const qualities = [70, 60, 50, 40, 30];
    for (final w in widths) {
      final resized = decoded.width > w
          ? img.copyResize(decoded, width: w, interpolation: img.Interpolation.average)
          : decoded;
      for (final q in qualities) {
        final jpg = img.encodeJpg(resized, quality: q);
        final result = 'data:image/jpeg;base64,${base64Encode(jpg)}';
        if (result.length <= maxBytes) return result;
      }
    }

    final tiny = img.copyResize(decoded, width: 400, interpolation: img.Interpolation.average);
    final jpg = img.encodeJpg(tiny, quality: 25);
    final result = 'data:image/jpeg;base64,${base64Encode(jpg)}';
    if (result.length <= maxBytes) return result;
    throw StateError(
      '이미지 재압축 실패 (${(result.length / 1024).round()}KB). 더 단순한 이미지로 교체하세요.',
    );
  }

  /// `data:` URI나 외부 URL이면 별도 처리 불필요. 본 구현은 외부 Storage를
  /// 쓰지 않으므로 인메모리 데이터를 무효화할 일은 없다 (Firestore 문서를
  /// 갱신하면 즉시 사라짐).
  Future<void> deleteByUrl(String _) async {}
}
