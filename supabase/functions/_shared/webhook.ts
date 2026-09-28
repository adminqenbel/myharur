// Verifies a Supabase Auth Hook request against the Standard Webhooks signature the dashboard
// shows you when you enable the hook (format: v1,whsec_<base64>). Rejects anything more than five
// minutes old to block replay. Never logs the secret or the signature.
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export async function verifyAuthHook(req: Request, rawBody: string, secretEnvValue: string): Promise<boolean> {
  const id = req.headers.get('webhook-id');
  const timestamp = req.headers.get('webhook-timestamp');
  const signature = req.headers.get('webhook-signature');
  if (!id || !timestamp || !signature) return false;

  const ts = Number(timestamp);
  if (!Number.isFinite(ts) || Math.abs(Date.now() / 1000 - ts) > 300) return false;

  try {
    const secret = secretEnvValue.startsWith('whsec_') ? secretEnvValue.slice(6) : secretEnvValue;
    const keyBytes = Uint8Array.from(atob(secret), (c) => c.charCodeAt(0));
    const key = await crypto.subtle.importKey('raw', keyBytes, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
    const signedContent = `${id}.${timestamp}.${rawBody}`;
    const mac = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signedContent));
    const expected = btoa(String.fromCharCode(...new Uint8Array(mac)));

    return signature.split(' ').some((part) => {
      const sig = part.includes(',') ? part.split(',')[1] : part;
      return !!sig && safeEqual(sig, expected);
    });
  } catch {
    return false;
  }
}
