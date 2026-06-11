// ATAX 부동산 공시지가/실거래가 조회 프록시 (Vercel Edge Function).
//
// 두 가지 type 지원:
//
// [type: 'land' — 기본] 토지·단독주택 개별공시지가
//   국토교통부_개별공시지가정보 API
//   입력: bcode(10자리) + jibunAddress (또는 bun·ji 직접 지정)
//   출력: pricePerSqm (원/㎡)
//
// [type: 'apartment'] 아파트 실거래가 평균 (최근 6개월)
//   국토교통부_아파트매매 실거래자료 API
//   입력: bcode(10자리) + buildingName
//   출력: avgPrice (원), txCount (건수), recentYm (최근 거래 연월)
//
// 환경 변수 (Vercel Project Settings → Environment Variables):
//   - REALTY_API_KEY : 공공데이터포털 ServiceKey (Decoding 키)
//     · "국토교통부_개별공시지가정보" + "국토교통부_아파트매매 실거래자료" 모두 활용신청 필요
//   - ALLOWED_ORIGIN : (선택) CORS 허용 origin. 기본 '*'

export const config = { runtime: 'edge' };

const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || '*';
const API_KEY = process.env.REALTY_API_KEY || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
  'Content-Type': 'application/json; charset=utf-8',
};

interface RealtyPriceRequest {
  type?: 'land' | 'apartment';
  bcode: string;          // 법정동 코드 10자리
  jibunAddress?: string;
  bun?: string;
  ji?: string;
  stdrYear?: string;
  buildingName?: string;  // 아파트 단지명 (apartment 타입)
}

function parseJibun(jibunAddress: string): { bun: string; ji: string } | null {
  if (!jibunAddress) return null;
  const m = jibunAddress.match(/(\d+)(?:-(\d+))?(?:\s|$)/);
  if (!m) return null;
  return {
    bun: m[1].padStart(4, '0'),
    ji: (m[2] ?? '0').padStart(4, '0'),
  };
}

function jsonResponse(body: any, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
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
    return jsonResponse({ error: 'Method Not Allowed' }, 405);
  }

  if (!API_KEY) {
    return jsonResponse({
      code: 'API_KEY_NOT_SET',
      message: '서버에 REALTY_API_KEY가 설정되지 않았습니다. 공공데이터포털(data.go.kr)에서 활용신청 후 Vercel 환경변수로 등록하세요.',
    }, 500);
  }

  let body: RealtyPriceRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: '잘못된 JSON 요청' }, 400);
  }

  const { bcode } = body;
  if (!bcode || bcode.length !== 10) {
    return jsonResponse({ error: 'bcode(법정동코드 10자리)가 필요합니다.' }, 400);
  }

  if (body.type === 'apartment') {
    return await handleApartment(body);
  }
  return await handleLand(body);
}

// ── 토지·단독주택: 개별공시지가 ─────────────────────────────

async function handleLand(body: RealtyPriceRequest): Promise<Response> {
  let bun = body.bun;
  let ji = body.ji;
  if (!bun || !ji) {
    const parsed = parseJibun(body.jibunAddress ?? '');
    if (!parsed) {
      return jsonResponse({
        error: '지번을 파싱하지 못했습니다. bun(본번), ji(부번)을 직접 지정해주세요.',
      }, 400);
    }
    bun = parsed.bun;
    ji = parsed.ji;
  }

  const pnu = `${body.bcode}1${bun.padStart(4, '0')}${ji.padStart(4, '0')}`;
  const year = body.stdrYear ?? new Date().getFullYear().toString();

  const url =
    `https://apis.data.go.kr/1611000/nsdi/IndvdLandPriceService/attr/getIndvdLandPrice` +
    `?serviceKey=${encodeURIComponent(API_KEY)}` +
    `&pnu=${pnu}&stdrYear=${year}&format=json&numOfRows=10`;

  try {
    const res = await fetch(url);
    const text = await res.text();
    let data: any;
    try {
      data = JSON.parse(text);
    } catch {
      return jsonResponse({
        code: 'PARSE_FAILED',
        message: 'API 응답 파싱 실패',
        raw: text.substring(0, 500),
      }, 502);
    }

    const items = data?.indvdLandPrices?.field ?? data?.response?.body?.items?.item ?? [];
    const list = Array.isArray(items) ? items : [items];
    if (list.length === 0 || !list[0]) {
      return jsonResponse({
        code: 'NO_DATA',
        message: '해당 지번의 개별공시지가 정보를 찾지 못했습니다.',
        pnu, year,
      }, 404);
    }
    const sorted = list.sort((a: any, b: any) =>
      (b.stdrYear ?? '').localeCompare(a.stdrYear ?? ''));
    const top = sorted[0];

    return jsonResponse({
      type: 'land',
      pnu,
      year: top.stdrYear,
      pricePerSqm: Number(top.pblntfPclnd ?? top.indvdLandPrice ?? 0),
      address: top.ldCodeNm ?? body.jibunAddress ?? '',
    });
  } catch (e: any) {
    return jsonResponse({
      code: 'FETCH_FAILED',
      message: String(e?.message ?? e),
    }, 500);
  }
}

// ── 아파트: 실거래가 평균 (최근 6개월) ───────────────────────

async function handleApartment(body: RealtyPriceRequest): Promise<Response> {
  const buildingName = (body.buildingName ?? '').trim();
  if (!buildingName) {
    return jsonResponse({
      error: '아파트 단지명(buildingName)이 필요합니다.',
    }, 400);
  }

  const debug = (body as any).debug === true;
  const lawdCd = body.bcode.substring(0, 5); // 실거래가 API는 시군구 5자리
  const months = lastNMonths(6);

  const allTrades: Trade[] = [];
  const diag: any = { months, lawdCd, perMonth: [] as any[] };
  // 공공데이터포털 1613000(국토부)은 일부 환경에서 https + 기본 fetch가 403.
  // http + 명시 헤더 조합이 통과율 높음.
  const headers = {
    'User-Agent':
      'Mozilla/5.0 (compatible; ATAXBot/1.0; +https://atax-beta.web.app)',
    'Accept': 'application/xml, text/xml, */*',
  };
  for (const ym of months) {
    const url = `https://apis.data.go.kr/1613000/RTMSDataSvcAptTradeDev/getRTMSDataSvcAptTradeDev`
      + `?serviceKey=${encodeURIComponent(API_KEY)}`
      + `&LAWD_CD=${lawdCd}`
      + `&DEAL_YMD=${ym}`
      + `&pageNo=1`
      + `&numOfRows=200`;
    try {
      const res = await fetch(url, { headers });
      const text = await res.text();
      const trades = parseTradeXml(text);
      allTrades.push(...trades);
      if (debug) {
        diag.perMonth.push({
          ym,
          status: res.status,
          itemCount: trades.length,
          sample: text.substring(0, 600),
        });
      }
    } catch (e: any) {
      if (debug) {
        diag.perMonth.push({ ym, error: String(e?.message ?? e) });
      }
    }
  }

  if (debug) {
    return jsonResponse({
      debug: true,
      totalParsed: allTrades.length,
      aptNamesFound: [...new Set(allTrades.map(t => t.aptName))].slice(0, 30),
      diag,
    });
  }

  // 단지명 fuzzy match — 공백·괄호 제거 후 substring 매칭
  const norm = (s: string) => s.replace(/[\s()]/g, '').toLowerCase();
  const targetN = norm(buildingName);
  const matched = allTrades.filter(t => {
    if (!t.aptName) return false;
    const n = norm(t.aptName);
    return n.includes(targetN) || targetN.includes(n);
  });

  if (matched.length === 0) {
    return jsonResponse({
      code: 'NO_TRADES',
      message: `최근 6개월 내 "${buildingName}"의 실거래 기록을 찾지 못했습니다.`,
      buildingName,
      lawdCd,
    }, 404);
  }

  const sum = matched.reduce((s, t) => s + t.dealAmount, 0);
  const avg = Math.round(sum / matched.length);
  const sortedByDate = [...matched].sort((a, b) =>
    `${b.year}${b.month}`.localeCompare(`${a.year}${a.month}`));
  const recent = sortedByDate[0];

  return jsonResponse({
    type: 'apartment',
    buildingName,
    avgPrice: avg,        // 원
    txCount: matched.length,
    recentYm: `${recent.year}.${recent.month}`,
    recentPrice: recent.dealAmount,
    recentArea: recent.exclusiveArea,
  });
}

interface Trade {
  aptName: string;
  dealAmount: number;      // 원
  exclusiveArea: number;   // ㎡
  year: string;
  month: string;
}

function parseTradeXml(xml: string): Trade[] {
  const items: Trade[] = [];
  const itemRegex = /<item>([\s\S]*?)<\/item>/g;
  let match: RegExpExecArray | null;
  while ((match = itemRegex.exec(xml)) !== null) {
    const c = match[1];
    const dealStr = (extractTag(c, '거래금액') ?? '').replace(/[,\s]/g, '');
    const dealMan = parseInt(dealStr, 10);
    if (!dealStr || isNaN(dealMan)) continue;
    items.push({
      aptName: extractTag(c, '아파트') ?? '',
      dealAmount: dealMan * 10000, // 만원 → 원
      exclusiveArea: parseFloat(extractTag(c, '전용면적') ?? '0'),
      year: extractTag(c, '년') ?? '',
      month: (extractTag(c, '월') ?? '').padStart(2, '0'),
    });
  }
  return items;
}

function extractTag(xml: string, tag: string): string | null {
  const re = new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`);
  const m = xml.match(re);
  return m ? m[1].trim() : null;
}

function lastNMonths(n: number): string[] {
  const result: string[] = [];
  const now = new Date();
  for (let i = 0; i < n; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    result.push(`${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}`);
  }
  return result;
}
