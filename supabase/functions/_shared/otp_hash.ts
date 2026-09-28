// A one-way hash of an OTP identifier (email/phone) for rate-limit bookkeeping in Postgres.
// The raw identifier is only ever passed to Brevo, never stored in our own tables.
export async function hashIdentifier(identifier: string): Promise<string> {
  const pepper = Deno.env.get('OTP_HASH_PEPPER') ?? '';
  const data = new TextEncoder().encode(pepper + identifier.trim().toLowerCase());
  const digest = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, '0')).join('');
}
