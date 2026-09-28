// Thin wrappers over Brevo's transactional email/SMS APIs. Used only by the Auth Hooks
// (send-email-hook, send-sms-hook) — never called with anything but a one-time sign-in code.
const BREVO_API = 'https://api.brevo.com/v3';

export async function sendBrevoEmail(opts: { to: string; subject: string; html: string }): Promise<boolean> {
  const key = Deno.env.get('BREVO_API_KEY');
  const senderEmail = Deno.env.get('BREVO_SENDER_EMAIL');
  const senderName = Deno.env.get('BREVO_SENDER_NAME') ?? 'MyHarur';
  if (!key || !senderEmail) return false;
  const res = await fetch(`${BREVO_API}/smtp/email`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json', 'api-key': key },
    body: JSON.stringify({ sender: { name: senderName, email: senderEmail }, to: [{ email: opts.to }], subject: opts.subject, htmlContent: opts.html }),
  });
  return res.ok;
}

export async function sendBrevoSms(opts: { to: string; text: string }): Promise<boolean> {
  const key = Deno.env.get('BREVO_API_KEY');
  const sender = Deno.env.get('BREVO_SMS_SENDER') ?? 'MyHarur';
  if (!key) return false;
  const recipient = opts.to.replace(/^\+/, '');
  const res = await fetch(`${BREVO_API}/transactionalSMS/sms`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json', 'api-key': key },
    body: JSON.stringify({ sender, recipient, content: opts.text, type: 'transactional' }),
  });
  return res.ok;
}
