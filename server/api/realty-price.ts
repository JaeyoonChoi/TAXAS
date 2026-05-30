// ATAX 부동산 공시지가 조회 프록시 (Vercel Edge Function).
//
// 흐름:
// 1) Daum 우편번호로 받은 주소 정보(법정동코드 + 지번주소)를 받음
// 2) 지번주소에서 본번·부번을 파싱해 PNU 후보 생성
// 3) 국토교통부 개별공시지가 API 호출 → 원/㎡ 단가 반환
// 4) 클라이언트가 면적과 곱해 추정 공시지가 계산
//
// 환경 변수 (Vercel Project Settings → Environment Variables):
//   - REALTY_API_KEY  : 공공데이터포털(data.go.kr)에서 발급한 ServiceKey (Decoding 키 사용)
//   - ALLOWED_ORIGIN  : (선택) CORS 허용 origin. 기본 '*'
//
// 사용 API:
//   국토교통부_개별공시지가정보
//   엔드포인트: https://apis.data.go.kr/1611000/nsdi/IndvdLandPriceService/attr/getIndvdLandPrice

export const config = { runtime: 'edge' };

const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || '*';
const API_KEY = process.env.REALTY_API_KEY || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
  'Content-Type': 'application/json; charset=utf-8',
};

interface RealtyPriceRequest {
  bcode: string;          // 법정동 코드 (10자리) — Daum postcode의 bcode
  jibunAddress?: string;  // 지번주소 — 지번을 자동 파싱
  bun?: string;           // 본번 (직접 지정)
  ji?: string;            // 부번 (직접 지정)
  stdrYear?: string;      // 기준연도 (기본: 최근 발표연도)
}

/// 지번주소("서울 강남구 역삼동 737-2")에서 본번·부번 추출.
function parseJibun(jibunAddress: string): { bun: string; ji: string } | null {
  if (!jibunAddress) return null;
  // 마지막에 등장하는 숫자(-숫자)? 패턴을 추출
  const m = jibunAddress.match(/(\d+)(?:-(\d+))?(?:\s|$)/);
  if (!m) return null;
  const bun = m[1].padStart(4, '0');
  const ji = (m[2] ?? '0').padStart(4, '0');
  return { bun, ji };
}

export default async function handler(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
      status: 405,
      headers: corsHeaders,
    });
  }

  if (!API_KEY) {
    return new Response(JSON.stringify({
      code: 'API_KEY_NOT_SET',
      message: '서버에 REALTY_API_KEY가 설정되지 않았습니다. 공공데이터포털(data.go.kr)에서 "국토교통부_개별공시지가정보" API ServiceKey를 발급받아 Vercel 환경변수로 등록하세요.',
    }), { status: 500, headers: corsHeaders });
  }

  let body: RealtyPriceRequest;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: '잘못된 JSON 요청' }), {
      status: 400,
      headers: corsHeaders,
    });
  }

  const { bcode, jibunAddress } = body;
  if (!bcode || bcode.length !== 10) {
    return new Response(JSON.stringify({
      error: 'bcode(법정동코드 10자리)가 필요합니다.',
    }), { status: 400, headers: corsHeaders });
  }

  // 본번·부번 결정 — 직접 지정 우선, 없으면 jibunAddress에서 파싱
  let bun = body.bun;
  let ji = body.ji;
  if (!bun || !ji) {
    const parsed = parseJibun(jibunAddress ?? '');
    if (!parsed) {
      return new Response(JSON.stringify({
        error: '지번을 파싱하지 못했습니다. bun(본번), ji(부번)을 직접 지정해주세요.',
      }), { status: 400, headers: corsHeaders });
    }
    bun = parsed.bun;
    ji = parsed.ji;
  }

  // PNU = 법정동코드(10) + 토지구분(1, 일반=1) + 본번(4) + 부번(4) = 19자리
  const pnu = `${bcode}1${bun.padStart(4, '0')}${ji.padStart(4, '0')}`;

  const year = body.stdrYear ?? new Date().getFullYear().toString();

  const url =
    `https://apis.data.go.kr/1611000/nsdi/IndvdLandPriceService/attr/getIndvdLandPrice` +
    `?serviceKey=${encodeURIComponent(API_KEY)}` +
    `&pnu=${pnu}` +
    `&stdrYear=${year}` +
    `&format=json` +
    `&numOfRows=10`;

  try {
    const res = await fetch(url, { method: 'GET' });
    const text = await res.text();
    let data: any;
    try {
      data = JSON.parse(text);
    } catch {
      // API가 XML 에러를 반환할 수 있음 — 그대로 전달
      return new Response(JSON.stringify({
        code: 'PARSE_FAILED',
        message: 'API 응답 파싱 실패 (XML 응답일 가능성)',
        raw: text.substring(0, 800),
      }), { status: 502, headers: corsHeaders });
    }

    // 결과 구조 — 공공데이터포털 표준
    const items = data?.indvdLandPrices?.field ?? data?.response?.body?.items?.item ?? [];
    const list = Array.isArray(items) ? items : [items];

    if (list.length === 0 || !list[0]) {
      return new Response(JSON.stringify({
        code: 'NO_DATA',
        message: '해당 지번의 개별공시지가 정보를 찾지 못했습니다.',
        pnu, year,
      }), { status: 404, headers: corsHeaders });
    }

    // 최신 기준연도 데이터 선택
    const sorted = list.sort((a: any, b: any) =>
      (b.stdrYear ?? '').localeCompare(a.stdrYear ?? ''));
    const top = sorted[0];

    return new Response(JSON.stringify({
      pnu,
      year: top.stdrYear,
      pricePerSqm: Number(top.pblntfPclnd ?? top.indvdLandPrice ?? 0), // 원/㎡
      address: top.ldCodeNm ?? jibunAddress ?? '',
      raw: top,
    }), { status: 200, headers: corsHeaders });
  } catch (e: any) {
    return new Response(JSON.stringify({
      code: 'FETCH_FAILED',
      message: String(e?.message ?? e),
    }), { status: 500, headers: corsHeaders });
  }
}
