import { corsHeaders } from '../_shared/cors.ts';

// Server-side proxy for Google Gemini 1.5 Flash.
// Keeps GEMINI_API_KEY secure in Supabase Secrets / Vault instead of exposing it in client bundles.

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const { prompt, userQuery } = await request.json();
    const queryText = (prompt || userQuery || '').trim();

    if (!queryText) {
      return new Response(JSON.stringify({ error: 'Prompt or query required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      return new Response(
        JSON.stringify({
          error: 'GEMINI_API_KEY is not configured on the server',
          handled_by: 'PROXY_UNCONFIGURED',
        }),
        {
          status: 503,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text: `You are the friendly MyHarur Town Assistant for Harur & Dharmapuri district, Tamil Nadu. Answer briefly and helpfully in English or Tamil: ${queryText}`,
              },
            ],
          },
        ],
      }),
    });

    if (!geminiResponse.ok) {
      const errBody = await geminiResponse.text();
      return new Response(
        JSON.stringify({ error: `Gemini API returned ${geminiResponse.status}`, details: errBody }),
        {
          status: geminiResponse.status,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const data = await geminiResponse.json();
    const answer = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? '';

    return new Response(
      JSON.stringify({
        success: true,
        answer,
        handled_by: 'GEMINI_AI_PROXY',
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || 'Internal proxy error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
