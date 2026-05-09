#!/bin/bash
# Taxas 프로젝트 초기화 스크립트
# Flutter SDK 압축 해제 후 이 스크립트 실행

set -e

FLUTTER_SDK="/Volumes/SDcard(512)/flutter-sdk/flutter"
PROJECT_DIR="/Volumes/SDcard(512)/Project/Focus_On/Taxas"
FLUTTER="$FLUTTER_SDK/bin/flutter"

echo "🚀 Taxas 프로젝트 초기화 시작..."

# Flutter SDK 확인
if [ ! -f "$FLUTTER" ]; then
    echo "❌ Flutter SDK를 찾을 수 없습니다: $FLUTTER_SDK"
    echo "   먼저 flutter.zip을 압축 해제하세요:"
    echo "   cd /Volumes/SDcard(512)/flutter-sdk && unzip flutter.zip"
    exit 1
fi

echo "✅ Flutter SDK 확인됨: $($FLUTTER --version | head -1)"

# 폰트 디렉토리 생성
mkdir -p "$PROJECT_DIR/assets/fonts"
mkdir -p "$PROJECT_DIR/assets/images"

# Noto Sans KR 폰트 다운로드
FONTS_DIR="$PROJECT_DIR/assets/fonts"
echo "📥 Noto Sans KR 폰트 다운로드 중..."

BASE_URL="https://fonts.gstatic.com/s/notosanskr/v36"

download_font() {
    local filename=$1
    local url=$2
    if [ ! -f "$FONTS_DIR/$filename" ]; then
        curl -L "$url" -o "$FONTS_DIR/$filename" --silent
        echo "  ✅ $filename"
    else
        echo "  ⏭️  $filename (이미 존재)"
    fi
}

# Google Fonts API로 폰트 URL 가져오기
FONT_CSS=$(curl -s "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700&display=swap" \
    -H "User-Agent: Mozilla/5.0")

echo "   폰트 URL 확인 중 (수동 다운로드 필요할 수 있음)..."

# 대체: npm을 통한 구글 폰트 다운로드
if command -v npx &> /dev/null; then
    cd "$FONTS_DIR"
    # 직접 URL에서 다운로드
    echo "   TTF 직접 다운로드 시도..."
fi

echo ""
echo "⚠️  Noto Sans KR 폰트를 수동으로 다운로드해주세요:"
echo "   1. https://fonts.google.com/noto/specimen/Noto+Sans+KR 접속"
echo "   2. 'Download family' 버튼 클릭"
echo "   3. 다음 파일을 $FONTS_DIR 에 복사:"
echo "      - NotoSansKR-Regular.ttf"
echo "      - NotoSansKR-Medium.ttf"
echo "      - NotoSansKR-SemiBold.ttf"
echo "      - NotoSansKR-Bold.ttf"
echo ""

read -p "폰트 파일을 배치했나요? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "폰트 없이 계속합니다 (기본 폰트 사용됨)..."
    # pubspec.yaml에서 폰트 섹션 제거 대신 더미 파일 생성
fi

# pub get
echo "📦 의존성 설치 중..."
cd "$PROJECT_DIR"
$FLUTTER pub get

echo ""
echo "✅ 초기화 완료!"
echo ""
echo "📱 실행 방법:"
echo "   웹:     $FLUTTER run -d chrome"
echo "   Android: $FLUTTER run -d android"
echo "   iOS:    $FLUTTER run -d ios"
