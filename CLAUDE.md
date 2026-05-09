# Taxas — Claude Code / Cursor 가이드

이 파일은 LLM 코딩 도구(Claude Code, Cursor 등)가 본 프로젝트에서 일관된 결과를 만들도록 컨벤션·아키텍처를 기록한다. 사람도 새로 합류할 때 먼저 읽으면 좋다.

## 한 줄 요약
한국 상속·증여세 절세 시뮬레이션 앱. Flutter Web/iOS/Android 단일 코드베이스. Firebase Auth + Firestore. Riverpod + go_router.

---

## 작업 시 지켜야 할 것

### 코드 스타일
- **한국어 우선**: UI 텍스트, 사용자에게 보이는 모든 문자열은 한국어. 코드 주석도 한국어 OK.
- **숫자 표기**: 사용자에게 보이는 금액은 항상 `formatKoreanCurrency(int)` 사용 (`5억 3,000만원` 형식). `NumberFormat`을 새로 만들지 말 것 — 헬퍼는 [common_widgets.dart](lib/shared/widgets/common_widgets.dart)에 정의.
- **색상**: 하드코딩 금지. [AppColors](lib/core/theme/app_colors.dart)에 정의된 토큰 사용. 새 색이 필요하면 토큰부터 추가.
- **`Color.withOpacity()` 사용 금지** — Flutter 3.27+ deprecated. 대신 `Color.withValues(alpha: 0.5)`.
- **`Color.value` 사용 금지** — deprecated. 대신 `Color.toARGB32()`.

### 상태 관리 (Riverpod)
- 새 provider는 `@riverpod` 어노테이션 + `part '...g.dart';` 패턴.
- 코드 수정 후 `dart run build_runner build --delete-conflicting-outputs` 실행해 `.g.dart` 재생성 필수.
- 핫 리스타트로 Firestore 스트림이 끊어질 수 있으니, 사용자 데이터를 보존해야 하는 provider는 `@Riverpod(keepAlive: true)` 고려.

### Firestore 패턴
- 컬렉션 스키마는 `lib/shared/services/`의 `*Service` 클래스에 캡슐화.
- 직접 `FirebaseFirestore.instance`를 위젯에서 호출하지 말 것 — provider 통해 주입.
- 모델 직렬화는 모델 클래스에 `toJson()` / `fromJson()` 정의. `toARGB32()`/`fromInt(int)`로 색상 처리.

### 라우팅
- 모든 라우트는 [app_router.dart](lib/core/router/app_router.dart)의 `AppRoutes` 상수에 정의 → 위젯에서 `context.go(AppRoutes.xxx)`.
- 하단 네비 탭은 ShellRoute 안에 배치, 풀스크린 위저드(스텝 화면 등)는 ShellRoute 밖.
- 라우트 변경 시 [main_shell.dart](lib/features/shell/main_shell.dart)의 `_indexFromLocation`도 같이 갱신.

### 파일 배치
```
core/        # 앱 전반(테마·라우터·상수·서비스 헬퍼)
features/    # 화면 단위 기능
shared/      # 여러 feature가 공유하는 모델·프로바이더·서비스·위젯
```
새 기능은 `features/<name>/`에 폴더로 묶어 추가. 데이터 모델·서비스는 `shared/`로.

### Firebase 보안 규칙
규칙은 코드가 아니라 Firebase 콘솔에 있다. **새 컬렉션 추가 시 반드시 규칙도 갱신**해야 함.
현재 운영 중인 규칙은 콘솔 → Firestore Database → Rules 참조.

### 이미지
- 카드 뉴스 등 사용자 업로드 이미지는 **base64로 Firestore에 저장** (Storage 미사용). 1MiB 문서 한도 안에 들어가도록 `maxWidth: 1024, imageQuality: 75`로 압축.
- 이미지 표시는 항상 `cardNewsImageProvider(String)` 헬퍼로 (data:/http(s):/asset 자동 분기).

---

## 자주 발생하는 함정

1. **`flutter clean` 후에도 빌드 결과가 이상하면** `.dart_tool/flutter_build/` 통째로 삭제. 플러그인 자동 등록 캐시(`web_plugin_registrant.dart`)가 stale해서 Firebase Web 채널이 등록 안 되는 사례 있었음.
2. **Hot reload로 const 데이터 변경이 반영 안 됨** — Hot Restart(`R` 대문자)로.
3. **Firebase 권한 에러** — Firestore Rules 갱신 안 한 경우. 콘솔에서 게시 후 5–10초 대기 필요.
4. **Riverpod provider 시그니처 변경 시** `.g.dart` 재생성 잊지 말 것.

---

## 배포

배포는 현재 수동:
```bash
flutter build web --release --no-tree-shake-icons
firebase deploy --only hosting --project taxas-bd85b
```

`taxas-bd85b` 프로젝트 권한이 있는 멤버만 가능.

---

## 컨벤션 외 — 작업 스타일

- **불필요한 추상화 금지**: 한 곳에서만 쓰는 위젯은 같은 파일에 private(`_Foo`)로 두기. 공통화는 2번 이상 쓸 때.
- **주석은 WHY만**: 코드를 읽으면 알 수 있는 WHAT은 적지 말 것. 비밀스러운 제약·이유만 짧게.
- **임시 코드 금지**: TODO 남기지 말고 끝까지 마무리하거나 빼기. 끝맺음 안 된 코드는 PR 막힘.
- **테스트**: 주요 도메인 로직(`tax_calculator_service.dart` 등)은 단위 테스트 권장. UI 위젯은 수동 검증.
