// ATAX 리포트 AI 분석 API — Vercel Edge Function.
//
// 입력: 사용자 자산·가족·증여이력 + 계산된 세액
// 출력: Claude Haiku가 생성한 구조화된 절세 분석 (JSON)
//
// 환경 변수 (Vercel Project Settings → Environment Variables):
//   - ANTHROPIC_API_KEY    : Anthropic console에서 발급
//   - ALLOWED_ORIGIN       : (선택) CORS 허용 origin. 미설정 시 *

export const config = { runtime: 'edge' };

const SYSTEM_PROMPT = `당신은 한국 상속·증여세 전문 세무 컨설턴트입니다.
사용자가 입력한 자산·가족 정보와 계산된 세액을 바탕으로,
실용적이고 친절한 한국어 절세 분석을 작성하세요.
서용자들이 보고 한 번에 이해하기 쉽게 그래프나 도표 등의 사진을 적극 활용하세요.

규칙:
- 모든 응답은 한국어, 존댓말로.
- 금액은 "5억 3,000만원" 같은 한국식 단위로.
- 단정적 단어 금지 ("반드시", "확실히") — "권장", "검토하세요" 등 권유형.
- 면책: 본 분석은 참고용이며 실제 신고는 세무사 상담 필요.
- 출력은 반드시 아래 JSON 스키마를 따르세요. 다른 텍스트 금지.

JSON 스키마:
{
  "headline": "한 줄 핵심 메시지 (30자 이내)",
  "summary": "전체 상황을 2-3 문장으로 요약",
  "strengths": ["현재 잘 활용 중인 절세 포인트 1-3개"],
  "weaknesses": ["놓치고 있거나 개선 여지가 있는 부분 1-3개"],
  "actions": [
    { "title": "액션 제목", "detail": "1-2 문장 설명", "priority": "high" }
  ]
}

actions는 우선순위 순으로 **최대 3개**. priority는 "high" | "medium" | "low".
각 항목은 간결하게 — strengths/weaknesses는 1문장씩, actions의 detail은 1-2문장.
중요: 응답은 순수 JSON만 출력하세요. 마크다운 코드펜스(\`\`\`) 사용 금지.`;

interface AnalyzeRequest {
  userInfo: {
    family: {
      hasSpouse: boolean;
      childCount: number;
      childAges: number[];
      ownerAge: number;
    };
    assets: {
      realEstate: number;
      financial: number;
      other: number;
      debt: number;
    };
    giftHistory: Array<{
      relationship: string;
      amount: number;
      year: number;
    }>;
  };
  taxResult: {
    noPlanningTax: number;
    withPlanningTax: number;
    planningSavings: number;
    inheritanceTax: number;
    inheritanceTaxableBase: number;
    inheritanceTotalDeduction: number;
    optimalGiftPlan: Record<string, number>;
  };
}

function corsHeaders(origin?: string | null): Record<string, string> {
  const allowed = process.env.ALLOWED_ORIGIN ?? '*';
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'content-type',
  };
}

export default async function handler(req: Request): Promise<Response> {
  const headers = corsHeaders(req.headers.get('origin'));

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers });
  }

  let body: AnalyzeRequest;
  try {
    body = (await req.json()) as AnalyzeRequest;
  } catch {
    return new Response(JSON.stringify({ error: 'invalid_json' }), {
      status: 400,
      headers: { ...headers, 'content-type': 'application/json' },
    });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: 'server_misconfigured', detail: 'ANTHROPIC_API_KEY missing' }),
      { status: 500, headers: { ...headers, 'content-type': 'application/json' } },
    );
  }

  const userPrompt = buildUserPrompt(body);

  try {
    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 2048,
        system: SYSTEM_PROMPT,
        messages: [{ role: 'user', content: userPrompt }],
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      return new Response(
        JSON.stringify({ error: 'upstream_error', status: res.status, detail: errText }),
        { status: 502, headers: { ...headers, 'content-type': 'application/json' } },
      );
    }

    const data = (await res.json()) as {
      content: Array<{ type: string; text: string }>;
    };
    const text = data.content?.[0]?.text ?? '';

    const analysis = extractJson(text);
    if (!analysis) {
      return new Response(
        JSON.stringify({ error: 'parse_failed', raw: text.slice(0, 1500) }),
        { status: 502, headers: { ...headers, 'content-type': 'application/json' } },
      );
    }

    return new Response(JSON.stringify({ analysis }), {
      status: 200,
      headers: { ...headers, 'content-type': 'application/json' },
    });
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : 'unknown';
    return new Response(
      JSON.stringify({ error: 'fetch_failed', detail: msg }),
      { status: 500, headers: { ...headers, 'content-type': 'application/json' } },
    );
  }
}

function buildUserPrompt(b: AnalyzeRequest): string {
  const { userInfo, taxResult } = b;
  const f = userInfo.family;
  const a = userInfo.assets;
  const totalGross = a.realEstate + a.financial + a.other;
  const netAsset = Math.max(0, totalGross - a.debt);

  const childInfo = f.childAges.length
    ? f.childAges.map((age, i) => `자녀${i + 1}: ${age}세${age < 19 ? ' (미성년)' : ''}`).join(', ')
    : '없음';

  const giftHistoryStr = userInfo.giftHistory.length
    ? userInfo.giftHistory
      .map((g) => `${g.year}년 ${g.relationship}에게 ${formatKr(g.amount)}`)
      .join('; ')
    : '없음';

  const optimalPlanStr = Object.entries(taxResult.optimalGiftPlan)
    .map(([k, v]) => `${k}: ${formatKr(v)}`)
    .join('; ');

  return `## 사용자 정보
- 본인 나이: ${f.ownerAge}세
- 배우자: ${f.hasSpouse ? '있음' : '없음'}
- 자녀: ${f.childCount}명 (${childInfo})

## 자산 (단위: 원)
- 부동산: ${formatKr(a.realEstate)}
- 금융자산: ${formatKr(a.financial)}
- 기타자산: ${formatKr(a.other)}
- 채무: ${formatKr(a.debt)}
- 총자산(채무 차감 전): ${formatKr(totalGross)}
- 순자산: ${formatKr(netAsset)}

## 과거 10년 증여 이력
${giftHistoryStr}

## 계산된 세액
- 대비 X 시 예상 상속세: ${formatKr(taxResult.noPlanningTax)}
- 사전증여 활용 시 예상 세액: ${formatKr(taxResult.withPlanningTax)}
- 절감 가능 금액: ${formatKr(taxResult.planningSavings)}
- 권장 증여 분배: ${optimalPlanStr || '없음'}

위 정보를 바탕으로 JSON 스키마에 맞는 맞춤 분석을 작성해주세요.`;
}

/// Claude 응답 텍스트에서 JSON 객체를 추출.
/// 1) ```json ... ``` 코드펜스 안 우선
/// 2) 첫 `{` 부터 매칭되는 `}` 까지 brace-aware 추출
/// 3) trailing comma 등 흔한 비표준 syntax 정리 후 JSON.parse
function extractJson(text: string): unknown | null {
  // 1. 코드펜스 추출
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  let candidate = fenceMatch ? fenceMatch[1] : text;

  // 2. 첫 { 부터 매칭되는 } 까지 brace 깊이 추적
  const start = candidate.indexOf('{');
  if (start === -1) return null;

  let depth = 0;
  let end = -1;
  let inString = false;
  let escape = false;
  for (let i = start; i < candidate.length; i++) {
    const ch = candidate[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (ch === '\\') {
      escape = true;
      continue;
    }
    if (ch === '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (ch === '{') depth++;
    else if (ch === '}') {
      depth--;
      if (depth === 0) {
        end = i;
        break;
      }
    }
  }
  if (end === -1) return null;

  let body = candidate.slice(start, end + 1);

  // 3. trailing comma 정리: ,] 또는 ,} 패턴
  body = body.replace(/,(\s*[\]}])/g, '$1');

  try {
    return JSON.parse(body);
  } catch {
    return null;
  }
}

function formatKr(value: number): string {
  if (value === 0) return '0원';
  const eok = Math.floor(value / 100000000);
  const rem = value % 100000000;
  const man = Math.floor(rem / 10000);
  const won = rem % 10000;
  const parts: string[] = [];
  if (eok > 0) parts.push(`${eok.toLocaleString('ko-KR')}억`);
  if (man > 0) parts.push(`${man.toLocaleString('ko-KR')}만`);
  if (won > 0) parts.push(`${won.toLocaleString('ko-KR')}`);
  return parts.length === 0 ? '0원' : `${parts.join(' ')}원`;
}
