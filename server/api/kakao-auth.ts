// Kakao OAuth → Firebase 커스텀 토큰 발급 (Vercel Node Function).
//
// 흐름:
// 1) 클라이언트가 Kakao authorize 후 받은 code + redirectUri를 POST
// 2) 서버: code → access token (Kakao token endpoint)
// 3) access token → Kakao user info
// 4) firebase-admin으로 uid `kakao:{kakaoId}`에 대한 custom token 발급
// 5) 응답 { token } → 클라이언트가 signInWithCustomToken으로 Firebase 로그인
//
// 환경 변수 (Vercel Project Settings → Environment Variables):
//   - KAKAO_REST_API_KEY           : Kakao Developers에서 발급 (REST API Key)
//   - FIREBASE_SERVICE_ACCOUNT_JSON: Firebase Console → 프로젝트 설정 → 서비스 계정 JSON 통째로 (한 줄)
//   - ALLOWED_ORIGIN               : (선택) 기본 *

import type { VercelRequest, VercelResponse } from '@vercel/node';
import { cert, getApps, initializeApp, type ServiceAccount } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

function corsHeaders(): Record<string, string> {
  const allowed = process.env.ALLOWED_ORIGIN ?? '*';
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'content-type',
  };
}

function initFirebase() {
  if (getApps().length) return;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON env not set');
  let parsed: ServiceAccount;
  try {
    parsed = JSON.parse(raw) as ServiceAccount;
  } catch (e) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON: ' + String(e));
  }
  initializeApp({ credential: cert(parsed) });
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const headers = corsHeaders();
  for (const [k, v] of Object.entries(headers)) res.setHeader(k, v);

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  const { code, redirectUri } = (req.body ?? {}) as {
    code?: string;
    redirectUri?: string;
  };
  if (!code || !redirectUri) {
    return res.status(400).json({ error: 'missing_code_or_redirect_uri' });
  }

  const restKey = process.env.KAKAO_REST_API_KEY;
  if (!restKey) {
    return res.status(500).json({ error: 'server_misconfigured', detail: 'KAKAO_REST_API_KEY missing' });
  }

  // 1) Kakao 토큰 교환
  let accessToken: string;
  try {
    const tokenRes = await fetch('https://kauth.kakao.com/oauth/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: restKey,
        redirect_uri: redirectUri,
        code,
      }).toString(),
    });
    if (!tokenRes.ok) {
      const txt = await tokenRes.text();
      return res.status(502).json({
        error: 'kakao_token_failed',
        status: tokenRes.status,
        detail: txt,
      });
    }
    const tokenJson = (await tokenRes.json()) as { access_token?: string };
    if (!tokenJson.access_token) {
      return res.status(502).json({ error: 'no_access_token', detail: tokenJson });
    }
    accessToken = tokenJson.access_token;
  } catch (e: unknown) {
    return res.status(500).json({ error: 'kakao_token_fetch_failed', detail: String(e) });
  }

  // 2) Kakao 사용자 정보
  let kakaoUser: {
    id: number;
    kakao_account?: {
      email?: string;
      profile?: { nickname?: string; profile_image_url?: string };
    };
  };
  try {
    const userRes = await fetch('https://kapi.kakao.com/v2/user/me', {
      method: 'GET',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    if (!userRes.ok) {
      const txt = await userRes.text();
      return res.status(502).json({ error: 'kakao_userinfo_failed', detail: txt });
    }
    kakaoUser = (await userRes.json()) as typeof kakaoUser;
  } catch (e: unknown) {
    return res.status(500).json({ error: 'kakao_userinfo_fetch_failed', detail: String(e) });
  }

  if (!kakaoUser.id) {
    return res.status(502).json({ error: 'kakao_id_missing' });
  }

  // 3) Firebase 커스텀 토큰 발급
  try {
    initFirebase();
    const uid = `kakao:${kakaoUser.id}`;
    const email = kakaoUser.kakao_account?.email;
    const nickname = kakaoUser.kakao_account?.profile?.nickname;
    const photoURL = kakaoUser.kakao_account?.profile?.profile_image_url;

    // 사용자가 없으면 생성, 있으면 정보 업데이트 (이메일·닉네임 등).
    const auth = getAuth();
    try {
      await auth.updateUser(uid, {
        email: email ?? undefined,
        displayName: nickname ?? undefined,
        photoURL: photoURL ?? undefined,
      });
    } catch (err) {
      // 존재하지 않으면 생성
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      if ((err as any)?.code === 'auth/user-not-found') {
        await auth.createUser({
          uid,
          email: email ?? undefined,
          displayName: nickname ?? undefined,
          photoURL: photoURL ?? undefined,
        });
      } else {
        throw err;
      }
    }

    const customToken = await auth.createCustomToken(uid, {
      provider: 'kakao',
      kakaoId: kakaoUser.id,
    });
    return res.status(200).json({ token: customToken });
  } catch (e: unknown) {
    return res.status(500).json({
      error: 'firebase_token_failed',
      detail: e instanceof Error ? e.message : String(e),
    });
  }
}
