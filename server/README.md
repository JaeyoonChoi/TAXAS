# ATAX AI 분석 API (Vercel)

`api/analyze.ts` — Claude Haiku로 사용자 맞춤 절세 분석을 생성하는 Edge Function.

## 배포 (한 번만)

### 1. Anthropic API 키 발급
1. https://console.anthropic.com 접속 → 계정 생성
2. **API Keys** → **Create Key** → 키 복사

### 2. Vercel 계정 + 프로젝트 생성
1. https://vercel.com 접속 → GitHub 계정으로 가입 (카드 등록 불필요)
2. **Add New → Project** → 본 GitHub 저장소(JaeyoonChoi/TAXAS) 선택
3. **Import** 눌러서 들어간 뒤 **Root Directory** 설정에서 `server/` 입력
4. **Framework Preset**: Other (자동 감지)
5. **Environment Variables** 에 추가:
   - `ANTHROPIC_API_KEY` = (1단계에서 복사한 키)
   - `ALLOWED_ORIGIN` = `https://taxas-bd85b.web.app`
6. **Deploy** 클릭 → 1분 정도 빌드/배포

### 3. 배포된 URL 확인
- 배포 완료 후 `https://your-project.vercel.app` 형태의 URL 부여
- 이 URL을 Flutter 앱의 [lib/core/api_config.dart](../lib/core/api_config.dart)에 입력

### 4. 검증
```bash
curl -X POST https://your-project.vercel.app/api/analyze \
  -H "content-type: application/json" \
  -d '{"userInfo":{"family":{"hasSpouse":true,"childCount":2,"childAges":[15,20],"ownerAge":55},"assets":{"realEstate":2000000000,"financial":500000000,"other":0,"debt":0},"giftHistory":[]},"taxResult":{"noPlanningTax":300000000,"withPlanningTax":150000000,"planningSavings":150000000,"inheritanceTax":300000000,"inheritanceTaxableBase":1000000000,"inheritanceTotalDeduction":1500000000,"optimalGiftPlan":{"배우자":600000000,"성인 자녀 1":50000000,"미성년 자녀 1":20000000}}}'
```
정상이면 `{ "analysis": { "headline": ..., "summary": ..., ... } }` 반환.

## 비용

- Claude Haiku 4.5: 약 1,000 토큰 입력 + 600 토큰 출력 ≈ **카드당 약 0.5원**
- 캐시되어 사용자 데이터 변경 시에만 호출 — 한 사용자 월 5회 호출이라도 ~3원
- Vercel Hobby 플랜 무료 한도: 월 100GB-시간 — 100배 넘게 호출 가능

## 로컬 개발

```bash
cd server
npm install
npx vercel dev
# → http://localhost:3000/api/analyze 로 테스트
```

`.env.local` 파일에 `ANTHROPIC_API_KEY=...` 입력 (gitignore됨).

## 보안

- API 키는 Vercel 환경 변수에만 저장 (코드/Git에 절대 X)
- `ALLOWED_ORIGIN`을 실제 도메인으로 한정해 외부 호출 차단
- 추후 트래픽 늘면 Rate Limiting 추가 고려 (예: Vercel KV로 IP 카운팅)
