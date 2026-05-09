# Taxas — 증여·상속 절세 플랫폼

Flutter Web/iOS/Android 크로스플랫폼 앱.
사용자가 자산·가족 정보를 입력하면 한국 세법 기준으로 상속세·증여세를 계산하고, 사전증여 시뮬레이션으로 절세 가능 금액을 보여줍니다.

배포 URL: https://taxas-bd85b.web.app

## 기술 스택

- **Flutter** (Dart) — Web · iOS · Android 단일 코드베이스
- **상태관리** — Riverpod (`@riverpod` 코드 생성)
- **라우팅** — go_router
- **인증/DB** — Firebase Auth + Cloud Firestore
- **차트** — fl_chart
- **폰트** — NotoSansKR (한글) + Playfair Display (TAXAS 로고)

## 처음 셋업

### 1. Flutter SDK 설치
- macOS Apple Silicon: https://docs.flutter.dev/get-started/install/macos 참고
- 본 저장소는 Flutter 3.41+ / Dart 3.11+ 기준으로 빌드됨

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. 코드 생성 (Riverpod, go_router)
```bash
dart run build_runner build --delete-conflicting-outputs
```

> 빈 출력만 나오고 실제로 생성이 안 되면: `rm -rf .dart_tool/build` 후 재실행.

### 4. Firebase 연동 확인
이미 `lib/firebase_options.dart`가 커밋되어 있어 추가 설정 없이 동작합니다.
새 Firebase 프로젝트로 바꾸고 싶을 때만:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 5. 실행
```bash
# 웹 (가장 빠른 검증)
flutter run -d chrome

# 또는
flutter run -d <device-id>
```

## 빌드 / 배포

웹 프로덕션 빌드:
```bash
flutter build web --release --no-tree-shake-icons
```

Firebase Hosting 배포 (관리자 권한 필요):
```bash
firebase deploy --only hosting --project taxas-bd85b
```

## 프로젝트 구조

```
lib/
├── core/
│   ├── admin_config.dart       # 관리자 이메일 allowlist
│   ├── constants/              # 세법 상수 (세율·공제 한도)
│   ├── router/                 # go_router 설정
│   ├── services/               # 세금 계산 서비스 (순수 함수)
│   └── theme/                  # 색상·테마
├── features/
│   ├── admin/                  # 카드 뉴스 관리 (관리자 전용)
│   ├── auth/                   # 로그인·가입
│   ├── community/              # 커뮤니티 (게시글·댓글·답글·좋아요)
│   ├── dashboard/              # 홈 대시보드
│   ├── info/                   # 콘텐츠 탭 (카드 뉴스·기초지식·FAQ)
│   ├── onboarding/             # 첫 진입 안내 3페이지
│   ├── portfolio/              # 자산 분포 차트
│   ├── shell/                  # BottomNav 래퍼
│   ├── tax_calculator/         # 결과 화면 (상속세 계산 결과)
│   └── user_info/              # 입력 위저드 (Step 1/2/3)
├── shared/
│   ├── models/                 # 데이터 모델
│   ├── providers/              # Riverpod 프로바이더
│   ├── services/               # Firestore CRUD 서비스
│   └── widgets/                # 공통 위젯 + formatKoreanCurrency
├── firebase_options.dart       # flutterfire 자동 생성 (Web/iOS/Android 키)
└── main.dart                   # 앱 진입점 + Firebase 초기화
```

## Firestore 데이터 모델

```
users/{uid}                            # 사용자별 입력값(가족·자산·증여이력)
cardNews/{cardId}                      # 카드 뉴스 (관리자만 작성)
posts/{postId}                         # 커뮤니티 게시글
  ├─ likes/{uid}                       # 좋아요
  └─ comments/{commentId}              # 댓글·답글 (parentCommentId)
```

보안 규칙은 Firebase 콘솔 → Firestore Database → Rules 참조.

## 협업 흐름

1. 자기 브랜치 생성: `git checkout -b feat/your-feature`
2. 작업 → 커밋 → push: `git push -u origin feat/your-feature`
3. GitHub에서 PR 생성 → 리뷰 → main에 머지
4. main이 업데이트되면 빌드·배포는 관리자가 수동으로 진행

자세한 코드 컨벤션은 `CLAUDE.md` 참조.

## 알려진 이슈 / 메모

- Flutter Web 빌드 시 `.dart_tool/flutter_build/` 캐시가 stale하면 플러그인 등록이 누락될 수 있음 → `rm -rf .dart_tool/flutter_build` 후 재빌드
- Service Worker 비활성화 상태로 운영 중 (개발 중 캐시 이슈 회피). 배포 안정화 후 활성화 검토
- 세금 계산은 단순화된 가정 — 실제 신고 시 세무사 상담 필수 (앱 내 면책 고지 표시됨)
