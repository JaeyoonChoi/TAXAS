// ATAX 절세 에이전트 — 멀티턴 대화 API (Vercel Edge Function).
//
// 입력: 사용자 컨텍스트(가족·자산·세액·증여이력) + 대화 기록
// 출력: Claude Haiku의 에이전트 응답 (한 메시지)
//
// /api/analyze (1회성 리포트 분석)와 분리. 이쪽은 자유 대화용.

export const config = { runtime: 'edge' };

const SYSTEM_PROMPT = `당신은 한국 상속·증여세 전문 절세 컨설턴트 "ATAX 에이전트"입니다.
사용자의 자산·가족 정보와 계산된 예상 세액을 이미 알고 있는 상태로 대화에 참여합니다.

역할:
- 사용자가 자신의 상황에서 어떤 절세 액션을 단계적으로 취하면 좋은지 구체적으로 안내
- 사전증여·배우자공제·재산평가·보험·신탁 등 다양한 전략을 사용자 상황에 맞게 추천
- 사용자가 묻지 않아도, 대답 끝에 다음 단계 1개를 자연스럽게 제안

규칙:
- 모든 응답은 한국어, 친절한 존댓말. 너무 딱딱하지 않게.
- 금액은 "5억 3,000만원" 같은 한국식 단위로.
- 단정적 단어 금지("반드시", "확실히") — "권장합니다", "검토해보세요" 등 권유형.
- 한 응답은 2~5문장 이내로 간결하게. 길게 늘어놓지 말 것.
- 출력은 마크다운 코드펜스(\`\`\`) 사용 금지. 일반 문장만.
- 법령 해석이 모호하거나 큰 의사결정이면 "세무사 상담을 권장합니다" 한 줄 덧붙임.`;

interface AgentRequest {
  context: {
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
    taxResult: {
      noPlanningTax: number;
      withPlanningTax: number;
      planningSavings: number;
      inheritanceTaxableBase: number;
      optimalGiftPlan: Record<string, number>;
    };
  };
  messages: Array<{ role: 'user' | 'assistant'; content: string }>;
}

function corsHeaders(): Record<string, string> {
  const allowed = process.env.ALLOWED_ORIGIN ?? '*';
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'content-type',
  };
}

export default async function handler(req: Request): Promise<Response> {
  const headers = corsHeaders();

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers });
  }

  let body: AgentRequest;
  try {
    body = (await req.json()) as AgentRequest;
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

  const contextBlock = buildContextBlock(body);
  const fullSystem = `${SYSTEM_PROMPT}\n\n## 현재 사용자 정보 (대화 내내 참고)\n${contextBlock}`;

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
        max_tokens: 1024,
        system: fullSystem,
        messages: body.messages.map((m) => ({
          role: m.role,
          content: m.content,
        })),
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
    const reply = data.content?.[0]?.text?.trim() ?? '';

    if (!reply) {
      return new Response(
        JSON.stringify({ error: 'empty_response' }),
        { status: 502, headers: { ...headers, 'content-type': 'application/json' } },
      );
    }

    return new Response(JSON.stringify({ reply }), {
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

function buildContextBlock(b: AgentRequest): string {
  const { context: c } = b;
  const f = c.family;
  const a = c.assets;
  const totalGross = a.realEstate + a.financial + a.other;
  const netAsset = Math.max(0, totalGross - a.debt);

  const childInfo = f.childAges.length
    ? f.childAges
      .map((age, i) => `자녀${i + 1}: ${age}세${age < 19 ? ' (미성년)' : ''}`)
      .join(', ')
    : '없음';

  const giftHistoryStr = c.giftHistory.length
    ? c.giftHistory
      .map((g) => `${g.year}년 ${g.relationship}에게 ${formatKr(g.amount)}`)
      .join('; ')
    : '없음';

  const optimalPlanStr = Object.entries(c.taxResult.optimalGiftPlan)
    .map(([k, v]) => `${k}: ${formatKr(v)}`)
    .join('; ');

  return `### 가족
- 본인 나이: ${f.ownerAge}세
- 배우자: ${f.hasSpouse ? '있음' : '없음'}
- 자녀: ${f.childCount}명 (${childInfo})

### 자산
- 부동산: ${formatKr(a.realEstate)}
- 금융자산: ${formatKr(a.financial)}
- 기타자산: ${formatKr(a.other)}
- 채무: ${formatKr(a.debt)}
- 총자산: ${formatKr(totalGross)}
- 순자산: ${formatKr(netAsset)}

### 과거 10년 증여 이력
${giftHistoryStr}

### 계산된 세액 (단순화된 시뮬레이션)
- 대비 X 시: ${formatKr(c.taxResult.noPlanningTax)}
- 사전증여 활용 시: ${formatKr(c.taxResult.withPlanningTax)}
- 절감 가능 금액: ${formatKr(c.taxResult.planningSavings)}
- 권장 증여 분배: ${optimalPlanStr || '없음'}`;
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
