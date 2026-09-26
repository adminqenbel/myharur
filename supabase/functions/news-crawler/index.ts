// news-crawler — gathers headlines about Harur & Dharmapuri (traffic, weather, civic, farming, local)
//
// Source: Google News RSS search feeds (English + Tamil). We store ONLY the headline, source name,
// a short plain-text summary and the link — never the article body — and the app links out to the
// publisher. The source list is data (FEEDS below) so it can be swapped for a news API later.
//
// Auth: called by pg_cron/pg_net with header  x-cron-secret: <CRON_SECRET>  (deployed with --no-verify-jwt).
// Writes use the service-role key that Supabase injects into every edge function.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type Category = 'traffic' | 'weather' | 'civic' | 'farming' | 'general';
type Region = 'harur' | 'dharmapuri' | 'both';

const FEEDS: { q: string; lang: 'en' | 'ta' }[] = [
  { q: 'Harur Dharmapuri traffic when:14d', lang: 'en' },
  { q: 'Dharmapuri accident road when:14d', lang: 'en' },
  { q: 'Harur when:14d', lang: 'en' },
  { q: 'Dharmapuri when:7d', lang: 'en' },
  { q: 'Dharmapuri power cut OR water supply when:14d', lang: 'en' },
  { q: 'Dharmapuri farmers when:14d', lang: 'en' },
  { q: 'தர்மபுரி when:7d', lang: 'ta' },
  { q: 'அரூர் when:14d', lang: 'ta' },
  { q: 'தர்மபுரி போக்குவரத்து விபத்து when:14d', lang: 'ta' },
];

// An article must actually mention one of these places (Google's search is fuzzy).
const PLACE = /harur|aroor|dharmapuri|dharmapury|dharmapuram district|அரூர்|தர்மபுரி|தருமபுரி|ஹரூர்/i;
const HARUR = /harur|aroor|அரூர்|ஹரூர்/i;
const DHARMAPURI = /dharmapuri|dharmapury|தர்மபுரி|தருமபுரி/i;

// Skip listings/ads and sensitive stories. Headlines about sexual violence, minors' abuse and
// suicide are not something a civic app should push into people's feeds.
const DENY = /\b(?:on[- ]road price|ex[- ]showroom|gold rate|silver rate|petrol price|diesel price|share price|horoscope|rasi palan|lottery|matrimony|rate today|price today)\b|pocso|\b(?:rape[ds]?|raping|molest\w*|sexual(?:ly)?|suicide|sexually|porn\w*)\b|போக்சோ|பாலியல்|தற்கொலை|கற்பழ|வன்கொடுமை/i;
const DENY_SOURCE = /zigwheels|cardekho|carwale|bikedekho|bikewale|goodreturns|justdial|olx|magicbricks/i;

// English keywords use word boundaries ("train" must not match "rain"); Tamil has no word
// boundaries, so those terms are kept specific.
const RULES: [Category, RegExp][] = [
  ['traffic', /\b(?:traffic|accidents?|collisions?|highways?|roads?|buses|bus|lorr(?:y|ies)|trucks?|diversions?|jams?|bridges?|ghat|flyover|overturn\w*|killed in|road mishap)\b|போக்குவரத்து|விபத்து|சாலை|பேருந்து|லாரி|நெடுஞ்சாலை|பாலம்|மலைப்பாதை/i],
  ['weather', /\b(?:rain|rains|rainfall|heavy rain|floods?|flooding|storms?|heatwave|heat wave|weather|cyclone|lightning|drought|thunder\w*)\b|மழை|வெள்ளம்|புயல்|வெயில்|வானிலை|வறட்சி/i],
  ['civic', /\b(?:power cuts?|electricity|tangedco|water supply|drinking water|sanitation|garbage|municipal\w*|panchayat|collector|ration|hospital|school)\b|மின்தடை|மின்சாரம்|குடிநீர்|குப்பை|நகராட்சி|பேரூராட்சி|ஆட்சியர்|மருத்துவமனை/i],
  ['farming', /\b(?:farmers?|agricultur\w*|crops?|mango|tomato|paddy|cultivation|irrigation|dam|harvest|market price)\b|விவசாய|பயிர்|மாம்பழம்|தக்காளி|நெல்|பாசனம்|அணை/i],
];

const decode = (s: string) =>
  s.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
   .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
   .replace(/&#39;|&apos;/g, "'").replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&');

const stripTags = (s: string) => decode(s).replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
const tag = (item: string, name: string) => item.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`, 'i'))?.[1];

function classify(text: string): Category {
  for (const [cat, re] of RULES) if (re.test(text)) return cat;
  return 'general';
}

function regionOf(text: string): Region {
  const h = HARUR.test(text), d = DHARMAPURI.test(text);
  return h && !d ? 'harur' : d && !h ? 'dharmapuri' : 'both';
}

async function fetchFeed(q: string, lang: 'en' | 'ta') {
  const params = lang === 'ta' ? 'hl=ta&gl=IN&ceid=IN:ta' : 'hl=en-IN&gl=IN&ceid=IN:en';
  const url = `https://news.google.com/rss/search?q=${encodeURIComponent(q)}&${params}`;
  const res = await fetch(url, { headers: { 'User-Agent': 'MyHarurNewsBot/1.0 (+https://myharur-rvz9.onrender.com)' } });
  if (!res.ok) throw new Error(`feed ${res.status}`);
  const xml = await res.text();
  const out: Record<string, unknown>[] = [];
  for (const m of xml.matchAll(/<item>([\s\S]*?)<\/item>/g)) {
    const item = m[1];
    const rawTitle = stripTags(tag(item, 'title') ?? '');
    const link = decode(tag(item, 'link') ?? '').trim();
    const guid = stripTags(tag(item, 'guid') ?? link);
    const source = stripTags(tag(item, 'source') ?? '') || null;
    const pub = new Date(tag(item, 'pubDate') ?? '');
    if (!rawTitle || !link || isNaN(pub.getTime())) continue;

    // Google appends " - Publisher" to titles
    const title = source && rawTitle.endsWith(` - ${source}`) ? rawTitle.slice(0, -(source.length + 3)) : rawTitle;
    let summary = stripTags(tag(item, 'description') ?? '');
    if (summary === title || summary === rawTitle || summary.startsWith(title)) summary = '';
    summary = summary.replace(source ?? '\u0000', '').trim().slice(0, 240);

    const text = `${title} ${summary}`;
    if (!PLACE.test(text)) continue;             // drop off-topic hits
    if (DENY.test(text) || DENY_SOURCE.test(source ?? '')) continue;   // ads, price listings, sensitive stories

    out.push({
      guid, title, url: link, source, summary: summary || null,
      category: classify(text), region: regionOf(text), language: lang,
      published_at: pub.toISOString(),
    });
  }
  return out;
}

Deno.serve(async (req) => {
  const secret = Deno.env.get('CRON_SECRET');
  if (!secret || req.headers.get('x-cron-secret') !== secret) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json' } });
  }

  const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const byGuid = new Map<string, Record<string, unknown>>();
  const feedResults: Record<string, string | number> = {};

  for (const f of FEEDS) {
    try {
      const items = await fetchFeed(f.q, f.lang);
      for (const it of items) byGuid.set(it.guid as string, it);
      feedResults[f.q] = items.length;
    } catch (e) {
      feedResults[f.q] = `error: ${(e as Error).message}`;
    }
    await new Promise((r) => setTimeout(r, 400));   // be polite
  }

  const rows = [...byGuid.values()];
  let inserted = 0;
  if (rows.length) {
    const { data, error } = await db.from('news_articles')
      .upsert(rows, { onConflict: 'guid', ignoreDuplicates: true }).select('id');
    if (error) {
      return new Response(JSON.stringify({ error: error.message, feeds: feedResults }), { status: 500, headers: { 'Content-Type': 'application/json' } });
    }
    inserted = data?.length ?? 0;
  }

  return new Response(JSON.stringify({ ok: true, fetched: rows.length, inserted, feeds: feedResults }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
