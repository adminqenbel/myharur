# News crawler

`supabase/functions/news-crawler` collects headlines about Harur and Dharmapuri and stores them in `news_articles`.
The app's News tab reads that table.

## How it works

- **Source:** Google News RSS search feeds (English and Tamil), listed in `FEEDS` at the top of `index.ts`.
- **Schedule:** pg_cron job `myharur-news-crawl` runs every 30 minutes and calls the function through pg_net.
  Old stories are pruned after 30 days (`myharur-prune-news`, daily).
- **What is stored:** headline, publisher name, link, a short plain-text summary, category, region, language, time.
  Never the article body. The app opens the publisher's own site.
- **Filters:** the story must mention Harur or Dharmapuri (English or Tamil). Ads and price listings
  (gold rate, car "on-road price") and sensitive stories (sexual violence, abuse of minors, suicide) are dropped.
  Both rules are regexes at the top of `index.ts` (`DENY`, `DENY_SOURCE`).
- **Categories:** traffic, weather, civic, farming, general (keyword rules in `RULES`; English keywords use word boundaries).

## Security

The function is deployed with `--no-verify-jwt` and checks a shared secret instead:

- Edge secret `CRON_SECRET` (set with `npx supabase secrets set CRON_SECRET=...`).
- The same value in Supabase Vault under the name `myharur_cron_secret`; the cron job reads it from there.
- A request without the right `x-cron-secret` header gets 401.

To rotate: generate a new random value and set it in both places. Nothing else changes.

## Run it by hand

Read the secret from Vault and call the function (nothing is printed except the result):

```bash
S=$(npx supabase db query --linked "select decrypted_secret from vault.decrypted_secrets where name = 'myharur_cron_secret'" -o csv | tail -1 | tr -d '\r\n"')
curl -s -X POST https://qpuvhhvzygdbvlichbqs.supabase.co/functions/v1/news-crawler -H "x-cron-secret: $S" -d "{}"
```

The reply shows how many stories each feed returned and how many were new.

## Changing sources or rules

Edit `index.ts`, then deploy:

```bash
npx supabase functions deploy news-crawler --no-verify-jwt --use-api
```

To sanity-check the regexes without deploying, copy the `PLACE`, `DENY`, `DENY_SOURCE` and `RULES` constants into a
Node script and run sample headlines through them.

## Caveats

- Google News RSS is convenient but not a contract. If it changes or you outgrow it, replace `fetchFeed` with a news API;
  the rest of the pipeline stays the same.
- Only headlines and links are used, with the publisher named on every card.
