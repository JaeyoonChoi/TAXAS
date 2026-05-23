// ATAX 절세 에이전트 — 멀티턴 대화 + 사용자 정보 업데이트 도구 (Vercel Edge Function).
//
// 흐름:
// 1) 사용자 컨텍스트 + 대화 기록 + 도구 정의로 Claude 호출
// 2) Claude가 update_user_info 도구를 호출하면 tool_result 회신 후 다시 호출
// 3) end_turn 도달 시 최종 텍스트 응답을 반환
// 4) 호출된 모든 도구 인자를 updates 배열로 함께 반환 → Flutter가 Firestore에 반영

export const config = { runtime: 'edge' };

const SYSTEM_PROMPT = `당신은 한국 상속·증여세 전문 절세 컨설턴트 "ATAX 에이전트"입니다.
사용자의 자산·가족 정보와 계산된 예상 세액을 이미 알고 있는 상태로 대화에 참여합니다.

역할:
- 사용자가 자신의 상황에서 어떤 절세 액션을 단계적으로 취하면 좋은지 구체적으로 안내
- **다음 세대(자녀·손주)로의 자산이전이 핵심 목적** — 자녀 사전증여를 1순위 권장
- 사전증여(자녀 우선)·재산평가·보험·신탁 등 다양한 전략을 사용자 상황에 맞게 추천
- 사용자가 묻지 않아도, 대답 끝에 다음 단계 1개를 자연스럽게 제안

배우자 증여 권장 시 주의:
- 배우자 증여는 **같은 세대 이전**이므로 다음 세대 절세 효과가 제한적임을 항상 명시
- 자녀 증여 한도를 먼저 채우는 것을 권장하고, 배우자 증여는 후순위 보조 전략으로만 언급
- 다음 경우에만 배우자 증여를 적극 권장: ① 자녀가 없는 경우, ② 자녀 한도를 모두 소진했는데 자산이 매우 큰 경우, ③ 부부 연령차·건강격차로 명의 분산이 필요한 경우

규칙:
- 모든 응답은 한국어, 친절한 존댓말. 너무 딱딱하지 않게.
- 금액은 "5억 3,000만원" 같은 한국식 단위로.
- 단정적 단어 금지("반드시", "확실히") — "권장합니다", "검토해보세요" 등 권유형.
- 한 응답은 2~5문장 이내로 간결하게. 길게 늘어놓지 말 것.
- 마크다운 코드펜스(\`\`\`) 사용 금지. 다만 **굵게**·목록(-, 1.)·강조는 가독성을 위해 자연스럽게 사용.
- 세무사 상담 권유는 **매 응답마다 넣지 말 것**. 다음 경우에만 짧게 1회 언급:
  ① 법령 해석이 명백히 모호한 경우, ② 자산 이전 규모가 큰 결정(10억원+), ③ 가업승계·신탁 등 고도 설계가 필요한 경우.
  그 외 일반 문답에서는 사용자가 묻지 않는 한 세무사 권유를 넣지 마세요.

도구 사용 규칙:
- 사용자가 "사실 자녀가 한 명 더 있어요", "부동산이 12억으로 늘었어요" 등 **현재 컨텍스트와 다른 새 정보**를 명시적으로 알려주면 update_user_info 도구를 호출해 반영하세요.
- 사용자가 묻지 않은 정보 변경은 절대 호출하지 마세요. 추측 금지.
- 한 메시지 안에서 여러 항목 변경이 필요하면 update_user_info를 여러 번 호출하세요.
- 도구 호출 후 사용자에게 "반영했습니다" 라고 자연스럽게 알려주세요.`;

const TOOLS = [
  {
    name: 'update_user_info',
    description:
      '사용자가 자신의 가족·자산 정보가 변경되었거나 잘못 입력되었음을 명시적으로 알려준 경우에만 호출. 한 번 호출당 한 필드만 변경. 여러 필드는 여러 번 호출.',
    input_schema: {
      type: 'object',
      properties: {
        field: {
          type: 'string',
          enum: [
            'family.hasSpouse',
            'family.childCount',
            'family.ownerAge',
            'assets.realEstate',
            'assets.financial',
            'assets.other',
            'assets.debt',
          ],
          description: '변경할 필드 키',
        },
        value: {
          description:
            '새 값. family.hasSpouse는 boolean, 나머지는 integer(원 단위 또는 정수). 예: realEstate=1200000000',
        },
      },
      required: ['field', 'value'],
    },
  },
];

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

interface AppliedUpdate {
  field: string;
  value: unknown;
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
      JSON.stringify({ error: 'server_misconfigured' }),
      { status: 500, headers: { ...headers, 'content-type': 'application/json' } },
    );
  }

  const contextBlock = buildContextBlock(body);
  const fullSystem = `${SYSTEM_PROMPT}\n\n## 현재 사용자 정보 (대화 내내 참고)\n${contextBlock}`;

  // 대화 기록을 Anthropic 메시지 포맷으로 변환 (텍스트만)
  const messages: Array<Record<string, unknown>> = body.messages.map((m) => ({
    role: m.role,
    content: m.content,
  }));

  const appliedUpdates: AppliedUpdate[] = [];

  // 도구 사용 루프 — 최대 5회 (무한 루프 방지)
  for (let i = 0; i < 5; i++) {
    let res: Response;
    try {
      res = await fetch('https://api.anthropic.com/v1/messages', {
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
          tools: TOOLS,
          messages,
        }),
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'unknown';
      return new Response(
        JSON.stringify({ error: 'fetch_failed', detail: msg }),
        { status: 500, headers: { ...headers, 'content-type': 'application/json' } },
      );
    }

    if (!res.ok) {
      const errText = await res.text();
      return new Response(
        JSON.stringify({ error: 'upstream_error', status: res.status, detail: errText }),
        { status: 502, headers: { ...headers, 'content-type': 'application/json' } },
      );
    }

    const data = (await res.json()) as {
      stop_reason: string;
      content: Array<
        | { type: 'text'; text: string }
        | { type: 'tool_use'; id: string; name: string; input: Record<string, unknown> }
      >;
    };

    if (data.stop_reason !== 'tool_use') {
      // 최종 응답 추출
      const textBlock = data.content.find((c) => c.type === 'text') as
        | { type: 'text'; text: string }
        | undefined;
      const reply = textBlock?.text?.trim() ?? '';
      if (!reply) {
        return new Response(
          JSON.stringify({ error: 'empty_response' }),
          { status: 502, headers: { ...headers, 'content-type': 'application/json' } },
        );
      }
      return new Response(
        JSON.stringify({ reply, updates: appliedUpdates }),
        { status: 200, headers: { ...headers, 'content-type': 'application/json' } },
      );
    }

    // 도구 호출 처리
    const toolUseBlocks = data.content.filter(
      (c): c is { type: 'tool_use'; id: string; name: string; input: Record<string, unknown> } =>
        c.type === 'tool_use',
    );

    // assistant 메시지로 통째로 다시 넣기 (Claude 도구 호출 프로토콜)
    messages.push({ role: 'assistant', content: data.content });

    // tool_result 메시지 생성
    const toolResults = toolUseBlocks.map((tu) => {
      let ok = false;
      if (tu.name === 'update_user_info') {
        const field = tu.input.field as string;
        const value = tu.input.value;
        if (typeof field === 'string') {
          appliedUpdates.push({ field, value });
          ok = true;
        }
      }
      return {
        type: 'tool_result',
        tool_use_id: tu.id,
        content: ok ? 'updated' : 'unknown_tool_or_invalid_args',
      };
    });

    messages.push({ role: 'user', content: toolResults });
  }

  // 5회 루프해도 끝 안 남 — 비정상
  return new Response(
    JSON.stringify({ error: 'tool_loop_overflow' }),
    { status: 502, headers: { ...headers, 'content-type': 'application/json' } },
  );
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
