"""
Tests the moderation pipeline + RLS in supabase/migrations against a THROWAWAY Postgres.
Stubs Supabase's auth schema (auth.users / auth.uid() / auth.role()) and the anon /
authenticated / service_role roles, applies the migrations (twice, to prove they are
idempotent), then exercises the API as different users.

    docker run -d --name mh-pg -e POSTGRES_PASSWORD=pw -p 55432:5432 postgres:16
    pip install psycopg2-binary
    python supabase/tests/moderation_test.py
    docker rm -f mh-pg

WARNING: drops and recreates the public + auth schemas of whatever it connects to.
Only point it at the throwaway container above.
"""
import psycopg2, sys, uuid, re
from psycopg2 import errors

import os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "migrations") + os.sep
conn = psycopg2.connect(host="localhost", port=55432, user="postgres", password="pw", dbname="postgres")
conn.autocommit = True
cur = conn.cursor()

STUBS = """
drop schema if exists public cascade; create schema public;
drop schema if exists auth cascade; create schema auth;
drop schema if exists storage cascade; create schema storage;
create table storage.buckets(id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(), bucket_id text, name text, owner uuid, created_at timestamptz default now());
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql immutable as $$ select (string_to_array(name,'/'))[1:greatest(cardinality(string_to_array(name,'/'))-1,0)] $$;
create table auth.users(id uuid primary key default gen_random_uuid(), email text, raw_user_meta_data jsonb default '{}', raw_app_meta_data jsonb default '{}');
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true),'')::uuid $$;
create function auth.role() returns text language sql stable as $$ select nullif(current_setting('request.jwt.claim.role', true),'') $$;
create function auth.jwt() returns jsonb language sql stable as $$ select coalesce(nullif(current_setting('request.jwt.claims', true),''), '{}')::jsonb $$;
create table auth.sessions(id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade);
do $$ begin
  if not exists (select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
end $$;
grant usage on schema public, auth to anon, authenticated, service_role;
grant usage on schema storage to anon, authenticated, service_role;
grant all on storage.objects, storage.buckets to authenticated, service_role;
grant select on storage.objects to anon;
-- Supabase's default privileges: every new table/function in public is open to the API roles
-- (RLS and explicit revokes are the real gates). Set BEFORE the migrations run.
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant execute on functions to anon, authenticated, service_role;
"""
cur.execute(STUBS)
cur.execute(open(ROOT + "20260825000000_v2_baseline.sql", encoding="utf-8").read())
later = sorted(f for f in os.listdir(ROOT) if f[:14] > "20260825000000" and f.endswith(".sql"))
for f in later:                          # each migration twice in a row, to prove it is re-runnable
    sql = open(os.path.join(ROOT, f), encoding="utf-8").read()
    cur.execute(sql)
    cur.execute(sql)
print("migrations applied twice OK:", later)

def mkuser(email, role=None):
    cur.execute("insert into auth.users(email) values (%s) returning id", (email,))
    uid = str(cur.fetchone()[0])
    if role:
        cur.execute("insert into public.user_roles(uid, role, scope) values (%s,%s,'global')", (uid, role))
    return uid

R1, R2, M, A = mkuser("r1@x"), mkuser("r2@x"), mkuser("m@x", "moderator"), mkuser("a@x", "admin")

def run(uid, role, sql, params=None, aal="aal2"):
    """Execute as an API caller. Returns (rows|None, err|None)."""
    cur.execute("begin")
    try:
        cur.execute(f"set local role {role}")
        cur.execute("select set_config('request.jwt.claim.sub', %s, true), set_config('request.jwt.claim.role', %s, true),"
                    " set_config('request.jwt.claims', %s, true)",
                    (uid or "", role, '{"aal":"%s"}' % aal))
        cur.execute(sql, params)
        rows = cur.fetchall() if cur.description else None
        cur.execute("commit")
        return rows, None
    except Exception as e:
        cur.execute("rollback")
        return None, e

passed = failed = 0
def check(name, cond, detail=""):
    global passed, failed
    if cond: passed += 1; print(f"  ok   {name}")
    else: failed += 1; print(f"  FAIL {name} {detail}")

INS = "insert into public.alerts(category,title,body,status,source,published_as_role,created_by_uid,emergency_tagged) values (%s,%s,%s,%s,%s,%s,%s,%s) returning id,status,source,published_as_role,created_by_uid,moderation_flags,flagged_by_system,moderation_reason,emergency_tagged"

def submit(uid, title, body, role="authenticated", status="published", source="official", pubrole="Official", by=None, emerg=False):
    return run(uid, role, INS, ("road", title, body, status, source, pubrole, by or str(uuid.uuid4()), emerg))

print("\n[1] client cannot self-publish / self-attribute")
rows, err = submit(R1, "Pothole on main road", "Large pothole near the bus stand", emerg=True)
check("insert succeeds", err is None, err)
a1 = rows[0]
check("status forced to pending", a1[1] == "pending", a1)
check("source forced to community", a1[2] == "community", a1)
check("published_as_role cleared", a1[3] is None, a1)
check("created_by = caller", a1[4] == uuid.UUID(R1) or str(a1[4]) == R1, a1)
check("emergency tag kept (0 strikes)", a1[8] is True, a1)
cur.execute("select count(*) from public.moderation_queue where alert_id=%s and status='pending'", (a1[0],))
check("queue row created", cur.fetchone()[0] == 1)

print("\n[2] anon cannot insert")
_, err = submit(None, "Pothole on main road", "Large pothole near the bus stand", role="anon")
check("anon insert blocked", err is not None, "")

print("\n[3] automated filter")
for label, title, body, want_status, want_flag in [
    ("profanity plain",      "This is a fuck problem", "The road is bad and fuck this", "rejected", "profanity"),
    ("profanity repeated",   "Roads are shiit", "fuuuuck the contractor totally", "rejected", "profanity"),
    ("profanity leetspeak",  "Road is sh1t now", "Please fix this shit road today", "rejected", "profanity"),
    ("danger flagged",       "Bomb threat rumour", "Someone said there is a bomb at the bus stand", "pending", "dangerous_terms"),
    ("link flagged",         "Water shortage today", "See details at www.example.com for more", "pending", "link"),
    ("phone flagged",        "Power cut in ward 3", "Call 9876543210 for the EB helpline", "pending", "phone_number"),
    ("clean passes",         "Street light not working", "The street light near the temple is off", "pending", None),
    ("no false positive (Scunthorpe)", "Class assessment notice", "Assessment of the shitake market road", "pending", None),
]:
    # fresh users so rate-limit doesn't interfere
    u = mkuser(f"{label}@x")
    rows, err = submit(u, title, body)
    if err is not None:
        check(label, False, err); continue
    r = rows[0]
    ok = r[1] == want_status and ((want_flag in r[5]) if want_flag else (r[5] == [] and not r[6]))
    check(f"{label}: {r[1]} flags={r[5]}", ok, r)

print("\n[4] rate limit (5/hour residents)")
u = mkuser("spammer@x")
results = [submit(u, f"Pothole number {i}", "Large pothole near the bus stand")[1] for i in range(7)]
check("first 5 ok", all(e is None for e in results[:5]), results[:5])
check("6th blocked with rate_limited", results[5] is not None and "rate_limited" in str(results[5]), results[5])

print("\n[5] length validation")
_, err = submit(mkuser("short@x"), "Hi", "short")
check("too short rejected", err is not None and "invalid_length" in str(err), err)

print("\n[6] visibility (RLS)")
rows, _ = run(None, "anon", "select count(*) from public.alerts")
check("anon sees 0 pending/rejected", rows[0][0] == 0, rows)
rows, _ = run(R1, "authenticated", "select count(*) from public.alerts")
check("R1 sees only own", rows[0][0] == 1, rows)
rows, _ = run(R2, "authenticated", "select count(*) from public.alerts")
check("R2 sees none of R1's", rows[0][0] == 0, rows)
rows, _ = run(M, "authenticated", "select count(*) from public.alerts")
check("moderator sees all", rows[0][0] >= 10, rows)

print("\n[7] staff alerts still go through moderation")
rows, err = submit(A, "Water supply cut tomorrow", "Supply will be off from 9am to 1pm", status="published")
check("admin alert pending", err is None and rows[0][1] == "pending", (rows, err))
check("admin alert official + role label", rows[0][2] == "official" and "Admin" in rows[0][3], rows)
admin_alert = rows[0][0]

print("\n[8] moderation RPC")
_, err = run(R1, "authenticated", "select public.moderate_alert(%s,'approve')", (str(a1[0]),))
check("resident cannot approve", err is not None and "forbidden" in str(err), err)
_, err = run(None, "anon", "select public.moderate_alert(%s,'approve')", (str(a1[0]),))
check("anon cannot call RPC", err is not None, err)
_, err = run(M, "authenticated", "select public.moderate_alert(%s,'approve')", (str(a1[0]),))
check("moderator approves", err is None, err)
rows, _ = run(None, "anon", "select id,status,expires_at>now() from public.alerts")
check("anon now sees exactly the approved alert", len(rows) == 1 and rows[0][1] == "published" and rows[0][2], rows)
_, err = run(A, "authenticated", "select public.moderate_alert(%s,'approve')", (str(a1[0]),))
check("double review blocked", err is not None and "already_reviewed" in str(err), err)
_, err = run(A, "authenticated", "select public.moderate_alert(%s,'reject')", (str(admin_alert),))
check("reject needs reason", err is not None and "reason_required" in str(err), err)
_, err = run(M, "authenticated", "select public.moderate_alert(%s,'approve')", (str(admin_alert),))
check("any moderator can approve an admin's alert", err is None, err)
cur.execute("select count(*) from public.crud_audit_logs where action like 'alert.%'")
check("audit rows written", cur.fetchone()[0] == 2)

print("\n[9] false emergency -> strike, 2 strikes lose the tag")
u = mkuser("crier@x")
for i in range(2):
    rows, err = submit(u, f"Fire at market {i}", "Big fire at the market please help", emerg=True)
    check(f"emergency alert {i} kept tag", err is None and rows[0][8] is True, (rows, err))
    _, err = run(M, "authenticated", "select public.moderate_alert(%s,'reject','false')", (str(rows[0][0]),))
    check(f"reject {i}", err is None, err)
cur.execute("select emergency_strikes from public.profiles where id=%s", (u,))
check("2 strikes recorded", cur.fetchone()[0] == 2)
rows, err = submit(u, "Fire again at market", "Another fire at the market please help", emerg=True)
check("3rd emergency tag stripped", err is None and rows[0][8] is False, (rows, err))

print("\n[10] profile privacy + column guard")
rows, _ = run(None, "anon", "select count(*) from public.profiles")
check("anon sees 0 profiles", rows[0][0] == 0, rows)
rows, _ = run(R1, "authenticated", "select count(*) from public.profiles")
check("R1 sees only own profile", rows[0][0] == 1, rows)
rows, _ = run(M, "authenticated", "select count(*) from public.profiles")
check("moderator sees only own profile (no PII access)", rows[0][0] == 1, rows)
rows, _ = run(A, "authenticated", "select count(*)>3 from public.profiles")
check("admin can read profiles", rows[0][0] is True, rows)
rows, err = run(R1, "authenticated",
    "update public.profiles set full_name='New Name', emergency_strikes=0, is_active=true, phone_verified=true, mmid='HACKED', email='x@y' where id=%s returning full_name, phone_verified, mmid, email", (R1,))
check("own name edit works", err is None and rows[0][0] == "New Name", (rows, err))
check("protected columns reverted", rows[0][1] is False and rows[0][2] != "HACKED" and rows[0][3] == "r1@x", rows)
rows, err = run(R1, "authenticated", "update public.profiles set full_name='pwn' where id=%s returning id", (R2,))
check("cannot edit others", err is None and rows == [], (rows, err))
rows, _ = run(R1, "authenticated", "select role from public.user_roles")
check("R1 sees only own roles", rows == [("resident",)], rows)

print("\n[11] closed write paths")
for name, sql in [
    ("chat insert", "insert into public.chat_messages(sender_mmid,text,is_official) values ('x','hi',true)"),
    ("audit insert", "insert into public.crud_audit_logs(action,table_name) values ('x','y')"),
    ("job insert",  "insert into public.jobs(title,company_or_farm,description,contact_phone) values ('a','b','c','d')"),
    ("role grant",  "insert into public.user_roles(uid,role,scope) values (%s,'admin','global')"),
]:
    _, err = run(R1, "authenticated", sql, (R1,) if "%s" in sql else None)
    check(f"{name} denied", err is not None, "")
rows, err = run(R1, "authenticated", "update public.alerts set status='published' where created_by_uid=%s returning id", (R1,))
check("client cannot UPDATE alerts", rows in ([], None), (rows, err))
rows, err = run(R1, "authenticated", "delete from public.alerts where created_by_uid=%s returning id", (R1,))
check("client cannot DELETE alerts", rows in ([], None), (rows, err))
_, err = run(R1, "authenticated", "select public.expire_moderation_items()")
check("client cannot call expiry sweep", err is not None, "")

print("\n[12] expiry sweep")
cur.execute("update public.alerts set expires_at = now() - interval '1 minute' where status='pending'")
cur.execute("select public.expire_moderation_items()")
cur.execute("select count(*) from public.alerts where status='pending'")
check("stale pending -> expired", cur.fetchone()[0] == 0)
cur.execute("select count(*) from public.moderation_queue where status='pending'")
check("queue rows expired", cur.fetchone()[0] == 0)

print("\n[13] delete_my_account")
rows, err = run(R2, "authenticated", "select public.delete_my_account()")
check("delete ok", err is None, err)
cur.execute("select count(*) from auth.users where id=%s", (R2,)); a = cur.fetchone()[0]
cur.execute("select count(*) from public.profiles where id=%s", (R2,)); b = cur.fetchone()[0]
check("user + profile gone", a == 0 and b == 0, (a, b))
rows, err = run(R1, "authenticated", "select public.delete_my_account()")
cur.execute("select count(*) from public.alerts where created_by_uid=%s", (R1,))
check("R1's alerts unlinked after delete", err is None and cur.fetchone()[0] == 0, err)
cur.execute("select count(*) from public.alerts where id=%s and status='published'", (str(a1[0]),))
check("published alert survives account deletion", cur.fetchone()[0] == 1)
_, err = run(None, "anon", "select public.delete_my_account()")
check("anon cannot delete", err is not None, "")

print("\n[14] signup trigger")
cur.execute("select count(*) from public.profiles p join public.user_roles r on r.uid=p.id and r.role='resident'")
check("profiles+resident roles created for signups", cur.fetchone()[0] >= 10)

print("\n[15] function privileges (Supabase advisor findings)")
for fn in ("alerts_before_insert", "alerts_after_insert", "handle_new_myharur_user", "profiles_protect_columns"):
    for role in ("anon", "authenticated"):
        cur.execute("select has_function_privilege(%s, %s, 'execute')", (role, f"public.{fn}()"))
        check(f"{role} cannot execute {fn}()", cur.fetchone()[0] is False)
cur.execute("select has_function_privilege('anon', 'public.moderate_alert(uuid,text,text,int)', 'execute')")
check("anon cannot execute moderate_alert", cur.fetchone()[0] is False)
cur.execute("select has_function_privilege('authenticated', 'public.moderate_alert(uuid,text,text,int)', 'execute')")
check("authenticated can execute moderate_alert", cur.fetchone()[0] is True)
cur.execute("select has_function_privilege('anon', 'public.delete_my_account()', 'execute')")
check("anon cannot execute delete_my_account", cur.fetchone()[0] is False)
_, err = run(None, "anon", "select public.alerts_before_insert()")
check("anon RPC to trigger function denied", err is not None)
cur.execute("select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace "
            "where n.nspname='public' and proname in ('profiles_protect_columns','handle_updated_at') and proconfig is not null")
check("search_path pinned on both functions", cur.fetchone()[0] == 2)

print("\n[16] super admin, role management, news, signup lock-down")
S1, S2, S3, S4 = (mkuser(f"super{i}@x", "superadmin") for i in range(1, 5))
T = mkuser("target@x")

_, err = run(R1, "authenticated", "select public.admin_set_role(%s,'moderator',true)", (T,))
check("resident cannot grant roles", err is not None and "forbidden" in str(err), err)
_, err = run(M, "authenticated", "select public.admin_set_role(%s,'moderator',true)", (T,))
check("moderator cannot grant roles", err is not None and "forbidden" in str(err), err)
_, err = run(A, "authenticated", "select public.admin_set_role(%s,'moderator',true)", (T,))
check("admin can grant moderator", err is None, err)
rows, _ = run(T, "authenticated", "select public.is_staff()")
check("granted moderator is now staff", rows[0][0] is True, rows)
_, err = run(A, "authenticated", "select public.admin_set_role(%s,'admin',true)", (T,))
check("admin cannot grant admin", err is not None and "superadmin_required" in str(err), err)
_, err = run(S1, "authenticated", "select public.admin_set_role(%s,'admin',true)", (T,))
check("superadmin can grant admin", err is None, err)
_, err = run(A, "authenticated", "select public.admin_set_role(%s,'moderator',false)", (T,))
check("admin can revoke moderator", err is None, err)
rows, _ = run(T, "authenticated", "select public.is_admin()")
check("target still admin via separate role", rows[0][0] is True, rows)
_, err = run(S1, "authenticated", "select public.admin_set_role(%s,'moderator',true)", (str(uuid.uuid4()),))
check("unknown user rejected", err is not None and "user_not_found" in str(err), err)
_, err = run(S1, "authenticated", "select public.admin_set_role(%s,'root',true)", (T,))
check("invalid role rejected", err is not None and "invalid_role" in str(err), err)

# superadmin cap = 3: start from S1 only, grant S2 and S3 through the RPC, then S4 must fail
cur.execute("delete from public.user_roles where role='superadmin' and uid in (%s,%s,%s)", (S2, S3, S4))
_, err = run(S1, "authenticated", "select public.admin_set_role(%s,'superadmin',true)", (S2,))
check("second superadmin allowed", err is None, err)
_, err = run(S1, "authenticated", "select public.admin_set_role(%s,'superadmin',true)", (S3,))
check("third superadmin allowed", err is None, err)
_, err = run(S1, "authenticated", "select public.admin_set_role(%s,'superadmin',true)", (S4,))
check("fourth superadmin blocked", err is not None and "superadmin_limit_reached" in str(err), err)
cur.execute("update public.user_roles set revoked_at=now() where role='superadmin' and uid in (%s,%s)", (S2, S3))
_, err = run(S1, "authenticated", "select public.admin_set_role(%s,'superadmin',false)", (S1,))
check("last superadmin cannot be removed", err is not None and "last_superadmin" in str(err), err)

rows, err = run(A, "authenticated", "select count(*) from public.admin_search_users('target')")
check("admin can search users", err is None and rows[0][0] == 1, (rows, err))
rows, err = run(A, "authenticated", "select roles from public.admin_search_users('target')")
check("search returns roles", err is None and "admin" in rows[0][0], (rows, err))
_, err = run(M, "authenticated", "select * from public.admin_search_users('')")
check("moderator cannot search users", err is not None, err)
rows, err = run(A, "authenticated", "select public.admin_stats()->>'pending_alerts'")
check("admin can read stats", err is None and rows[0][0] is not None, (rows, err))
_, err = run(R1, "authenticated", "select public.admin_stats()")
check("resident cannot read stats", err is not None, err)

_, err = run(A, "authenticated", "select * from public.admin_filter_terms()")
check("admin (non-super) cannot read filter lists", err is not None, err)
_, err = run(S1, "authenticated", "select public.admin_save_filter_term('profanity','zzzbadword','english')")
check("superadmin can add a word", err is None, err)
u = mkuser("wordtest@x")
rows, err = submit(u, "Road is zzzbadword today", "Please fix the zzzbadword road near the school")
check("new word is enforced immediately", err is None and rows[0][1] == "rejected", (rows, err))
rows, err = run(S1, "authenticated", "select count(*) from public.admin_filter_terms() where term='zbadword'")
check("word is listed in normalised form", rows[0][0] == 1, rows)
_, err = run(S1, "authenticated", "select public.admin_delete_filter_term('profanity','zbadword')")
check("superadmin can delete a word", err is None, err)
_, err = run(S1, "authenticated", "select public.admin_save_filter_term('profanity','x','english')")
check("too-short word rejected", err is not None and "invalid_term" in str(err), err)

# news
cur.execute("insert into public.news_articles(guid,title,url,published_at) values ('g1','Harur road work','https://example.com',now())")
rows, _ = run(None, "anon", "select count(*) from public.news_articles")
check("anon can read news", rows[0][0] == 1, rows)
_, err = run(R1, "authenticated", "insert into public.news_articles(guid,title,url,published_at) values ('g2','x','https://x',now())")
check("clients cannot write news", err is not None, err)
_, err = run(None, "anon", "insert into public.news_articles(guid,title,url,published_at) values ('g3','x','https://x',now())")
check("anon cannot write news", err is not None, err)
_, err = run(R1, "authenticated", "select public.prune_news()")
check("clients cannot call prune_news", err is not None, err)

# Google profile sync + email signup lock-down
cur.execute("""insert into auth.users(email, raw_user_meta_data, raw_app_meta_data)
               values ('g@x', '{"full_name":"Hema P","avatar_url":"https://lh3.googleusercontent.com/a/x"}', '{"provider":"google"}') returning id""")
gid = cur.fetchone()[0]
cur.execute("select full_name, avatar_url from public.profiles where id=%s", (gid,))
row = cur.fetchone()
check("google name + photo copied to profile", row == ("Hema P", "https://lh3.googleusercontent.com/a/x"), row)
cur.execute("""insert into auth.users(email, raw_user_meta_data, raw_app_meta_data)
               values ('p@x', '{"name":"Picture Only","picture":"https://lh3.googleusercontent.com/a/y"}', '{"provider":"google"}') returning id""")
pid = cur.fetchone()[0]
cur.execute("select full_name, avatar_url from public.profiles where id=%s", (pid,))
row = cur.fetchone()
check("falls back to name/picture claims", row == ("Picture Only", "https://lh3.googleusercontent.com/a/y"), row)
try:
    cur.execute("""insert into auth.users(email, raw_app_meta_data) values ('spam@x', '{"provider":"email"}')""")
    check("email sign-up blocked", False, "insert succeeded")
except Exception as e:
    check("email sign-up blocked", "email_signup_disabled" in str(e), e)
try:
    cur.execute("insert into auth.users(email) values ('nometa@x')")
    check("users without provider metadata still allowed", True)
except Exception as e:
    check("users without provider metadata still allowed", False, e)

R1n = mkuser("r1new@x")   # R1 was deleted by the account-deletion test above
print("\n[17] wards removed, optional address, structured alert location")
cur.execute("select to_regclass('public.wards')")
check("wards table is gone", cur.fetchone()[0] is None)
cur.execute("select count(*) from information_schema.columns where table_schema='public' and column_name in ('ward_id','ward_verified')")
check("no ward columns remain", cur.fetchone()[0] == 0)
rows, err = run(R1n, "authenticated", "update public.profiles set address_text='12 Bazaar St, Harur', address_lat=12.06, address_lng=78.49, address_source='map' where id=%s returning address_text", (R1n,))
check("user can set an optional address", err is None and rows[0][0] == "12 Bazaar St, Harur", (rows, err))
rows, _ = run(R1n, "authenticated", "select address_text from public.profiles where id=%s", (R1n,))
check("address round-trips", rows[0][0] == "12 Bazaar St, Harur", rows)
rows, _ = run(R2 if False else M, "authenticated", "select count(*) from public.profiles where address_text is not null")
check("address is private (another user sees none)", rows[0][0] == 0, rows)
for label, sql in [
    ("lat without lng rejected",  "update public.profiles set address_lat=12.0, address_lng=null where id=%s"),
    ("lat out of range rejected", "update public.profiles set address_lat=200, address_lng=78 where id=%s"),
    ("bad source rejected",       "update public.profiles set address_source='gps2' where id=%s"),
    ("address longer than 200",   "update public.profiles set address_text=repeat('x',201) where id=%s"),
]:
    _, err = run(R1n, "authenticated", sql, (R1n,))
    check(label, err is not None, "")
u17 = mkuser("loc@x")
rows, err = run(u17, "authenticated",
    "insert into public.alerts(category,title,body,location_text,location_lat,location_lng,location_source) values ('road','Pothole near temple','Large pothole near the temple gate','Temple gate, Harur',12.0624,78.4983,'map') returning location_text,location_lat,location_source")
check("alert stores a pinned location", err is None and rows[0][0] == "Temple gate, Harur" and rows[0][2] == "map", (rows, err))
_, err = run(u17, "authenticated", "insert into public.alerts(category,title,body,location_lat,location_lng) values ('road','Pothole near temple','Large pothole near the temple gate',95,78)")
check("alert with impossible latitude rejected", err is not None, "")
_, err = run(u17, "authenticated", "insert into public.alerts(category,title,body,location_lat) values ('road','Pothole near temple','Large pothole near the temple gate',12)")
check("alert with lat but no lng rejected", err is not None, "")

print("\n[18] server-side username rules")
for label, name, want in [
    ("uppercase rejected",        "@Hema",       "username_invalid"),
    ("too short rejected",        "@ab",         "username_invalid"),
    ("missing @ rejected",        "hema_p",      "username_invalid"),
    ("space rejected",            "@he ma",      "username_invalid"),
    ("reserved: admin",           "@admin",      "username_reserved"),
    ("reserved: admin + digits",  "@admin123",   "username_reserved"),
    ("reserved: qenshar",         "@qen_shar",   "username_reserved"),
    ("profanity rejected",        "@fuckyou",    "username_bad"),
]:
    _, err = run(R1n, "authenticated", "update public.profiles set username=%s where id=%s", (name, R1n))
    check(label, err is not None and want in str(err), err)
_, err = run(R1n, "authenticated", "update public.profiles set username='@hema_p' where id=%s", (R1n,))
check("valid username accepted", err is None, err)
_, err = run(A, "authenticated", "update public.profiles set username='@hema_p' where id=%s", (A,))
check("duplicate username rejected", err is not None and "unique" in str(err).lower(), err)
_, err = run(R1n, "authenticated", "update public.profiles set bio='hello' where id=%s", (R1n,))
check("other edits do not re-validate the username", err is None, err)

print("\n[19] rate limiter")
rl = mkuser("ratelimit@x")
for i in range(3):
    _, err = run(rl, "authenticated", "select public.enforce_rate_limit('demo', 3, interval '1 hour')")
    check(f"call {i+1}/3 allowed", err is None, err)
_, err = run(rl, "authenticated", "select public.enforce_rate_limit('demo', 3, interval '1 hour')")
check("4th call blocked", err is not None and "rate_limited" in str(err), err)
_, err = run(rl, "authenticated", "select public.enforce_rate_limit('other', 3, interval '1 hour')")
check("limits are per action", err is None, err)
_, err = run(mkuser("ratelimit2@x"), "authenticated", "select public.enforce_rate_limit('demo', 3, interval '1 hour')")
check("limits are per user", err is None, err)
cur.execute("update public.rate_limits set window_start = now() - interval '2 hours' where user_id=%s and action='demo'", (rl,))
_, err = run(rl, "authenticated", "select public.enforce_rate_limit('demo', 3, interval '1 hour')")
check("window expiry resets the counter", err is None, err)
_, err = run(None, "anon", "select public.enforce_rate_limit('demo', 3, interval '1 hour')")
check("anon cannot use the limiter", err is not None, "")
_, err = run(rl, "authenticated", "select * from public.rate_limits")
check("clients cannot read rate_limits", err is not None, "")

print("\n[20] username-login lockout")
def retry(u, ip="ip1"):
    rows, err = run(None, "service_role", "select public.login_retry_after(%s,%s)", (u, ip))
    assert err is None, err
    return rows[0][0]
def attempt(u, ok, ip="ip1"):
    _, err = run(None, "service_role", "select public.record_login_attempt(%s,%s,%s)", (u, ip, ok))
    assert err is None, err
for i in range(4):
    attempt("uh1", False)
check("4 failures: still allowed", retry("uh1") == 0)
attempt("uh1", False)
w = retry("uh1")
check("5th failure: locked ~15 min", 800 <= w <= 900, w)
check("lock is per username", retry("uh2", "ip-other") == 0)
attempt("uh1", True)
check("a success clears the lock", retry("uh1") == 0)
for i in range(10):
    attempt("uh3", False, "ip3")
w = retry("uh3", "ip3")
check("10 failures: back-off doubles to ~30 min", 1700 <= w <= 1800, w)
for i in range(20):
    attempt(f"spray{i}", False, "ip-spray")
check("password spraying from one IP locks that IP", retry("fresh-user", "ip-spray") > 3000)
check("other IPs unaffected", retry("fresh-user", "ip-clean") == 0)
for role, uid in (("anon", None), ("authenticated", R1n)):
    _, err = run(uid, role, "select public.login_retry_after('x','y')")
    check(f"{role} cannot call login_retry_after", err is not None, "")
    _, err = run(uid, role, "select * from public.internal_lookup_login('@hema_p')")
    check(f"{role} cannot look up login emails", err is not None, "")
    _, err = run(uid, role, "select * from public.auth_attempts")
    check(f"{role} cannot read auth_attempts", err is not None, "")
rows, err = run(None, "service_role", "select email from public.internal_lookup_login('@hema_p')")
check("service role resolves a username to its account", err is None and rows == [("r1new@x",)], (rows, err))
rows, _ = run(None, "service_role", "select count(*) from public.internal_lookup_login('@does_not_exist')")
check("unknown username returns nothing", rows[0][0] == 0)
cur.execute("update public.profiles set is_active=false where id=%s", (R1n,))
rows, _ = run(None, "service_role", "select count(*) from public.internal_lookup_login('@hema_p')")
check("disabled accounts cannot log in by username", rows[0][0] == 0)
cur.execute("update public.profiles set is_active=true where id=%s", (R1n,))

print("\n[21] client error log")
ce = mkuser("crashy@x")
jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abcDEF123_-xyz"
_, err = run(ce, "authenticated", "select public.log_client_error('crash', %s, %s, 'HomePage', '1.2.0+7', 'Android 16')",
             ("Failed for hema@example.com with " + jwt, "stack " + jwt + " " + "x" * 5000))
check("authenticated users can log an error", err is None, err)
rows, _ = run(S1, "authenticated", "select message, length(stack), user_id is not null from public.client_errors order by created_at desc limit 1")
check("e-mail and token are redacted", "hema@example.com" not in rows[0][0] and "eyJ" not in rows[0][0] and "[email]" in rows[0][0] and "[token]" in rows[0][0], rows)
check("stack is truncated to 4000", rows[0][1] <= 4000, rows)
rows, _ = run(ce, "authenticated", "select count(*) from public.client_errors")
check("residents see zero error rows", rows is not None and rows[0][0] == 0, rows)
rows, _ = run(S1, "authenticated", "select count(*) from public.client_errors")
check("super admin sees the error log", rows[0][0] >= 1, rows)
rows, err = run(S1, "authenticated", "update public.client_errors set status='seen' returning status")
check("super admin can mark errors seen", err is None and rows and rows[0][0] == "seen", (rows, err))
rows, _ = run(ce, "authenticated", "update public.client_errors set status='fixed' returning id")
check("residents cannot change error status", rows == [], rows)
_, err = run(ce, "authenticated", "insert into public.client_errors(kind,message) values ('crash','direct insert')")
check("direct inserts are refused (RPC only)", err is not None, "")
_, err = run(None, "anon", "select public.log_client_error('crash','x','y','z','1','a')")
check("anon cannot log errors", err is not None, "")
for i in range(19):
    run(ce, "authenticated", "select public.log_client_error('crash','spam','s','z','1','a')")
_, err = run(ce, "authenticated", "select public.log_client_error('crash','spam','s','z','1','a')")
check("21st error in a day is rate limited", err is not None and "rate_limited" in str(err), err)

print("\n[22] audit log is append-only, deleting an account still works")
cur.execute("select count(*) from public.crud_audit_logs")
before = cur.fetchone()[0]
for label, sql in [("update refused", "update public.crud_audit_logs set action='tampered'"),
                   ("delete refused", "delete from public.crud_audit_logs")]:
    try:
        cur.execute(sql)
        check(label, False, "statement succeeded")
    except Exception as e:
        check(label, "append_only" in str(e), e)
        conn.rollback() if not conn.autocommit else None
_, err = run(A, "authenticated", "update public.crud_audit_logs set action='tampered'")
check("staff cannot edit the audit log", err is not None, "")
x = mkuser("leaver@x", "moderator")
al, _ = submit(mkuser("leaver-author@x"), "Street light broken", "The street light near the school is broken")
run(x, "authenticated", "select public.moderate_alert(%s,'approve')", (str(al[0][0]),))
_, err = run(x, "authenticated", "select public.delete_my_account()")
check("moderator with audit rows can still delete their account", err is None, err)
cur.execute("select count(*) from public.crud_audit_logs where user_id is null and action='alert.approve'")
check("their audit rows survive, anonymised", cur.fetchone()[0] >= 1)
cur.execute("select count(*) from public.crud_audit_logs")
check("no audit rows were lost", cur.fetchone()[0] >= before)

print("\n[23] login escalation: 5 fails -> 24h, 3 strikes -> permanent, recovery by super admin")
SU = mkuser("super@x", "superadmin")
V = mkuser("victim@x")
cur.execute("update public.profiles set username='@victim', full_name='Victim' where id=%s", (V,))
def svc(sql, params=None):
    return run(None, "service_role", sql, params)
def fail(uid, h="u-victim"):
    r, e = svc("select public.record_login_attempt(%s,'ip1',false,%s)", (h, uid))
    return r[0][0] if r else str(e)
res = [fail(V) for _ in range(5)]
check("4 failures do not lock, the 5th does", res[:4] == ["fail"] * 4 and res[4] == "locked_24h", res)
r, _ = svc("select permanent, locked_until > now() + interval '23 hours' from public.login_lock_state(%s)", (V,))
check("lock is 24 h and temporary", r and r[0][0] is False and r[0][1] is True, r)
r, _ = svc("select count(*) from public.security_events where user_id=%s and kind='login_lock_24h'", (V,))
check("the 24 h lock is logged", r[0][0] == 1, r)
# lock expires; two more strikes make it permanent
for n in (2, 3):
    cur.execute("update public.login_locks set locked_until = now() - interval '1 minute', last_lock_at = now() - interval '25 hours' where user_id=%s", (V,))
    res = [fail(V) for _ in range(5)]
check("third strike disables password login", res[-1] == "locked_permanent", res)
r, _ = svc("select permanent, locked_until from public.login_lock_state(%s)", (V,))
check("permanent lock has no expiry", r and r[0][0] is True and r[0][1] is None, r)
r, _ = svc("select count(*) from public.security_events where user_id=%s and kind='login_lock_permanent'", (V,))
check("the permanent lock is logged", r[0][0] == 1, r)

# a success in between resets the streak
W = mkuser("w@x")
for _ in range(4): fail(W, "u-w")
svc("select public.record_login_attempt('u-w','ip1',true,%s)", (W,))
res = [fail(W, "u-w") for _ in range(4)]
check("success resets the failure streak", "locked_24h" not in res, res)
# unknown usernames are throttled elsewhere, never locked
r, _ = svc("select public.record_login_attempt('u-ghost','ip1',false,null)")
check("unknown username is never given a lock row", r[0][0] == "fail")

# API roles cannot touch any of it
for who, role in ((R1n, "authenticated"), (None, "anon")):
    _, err = run(who, role, "select public.record_login_attempt('x','y',true,%s)", (R1n,))
    check(f"{role} cannot record login attempts", err is not None)
    _, err = run(who, role, "select * from public.login_lock_state(%s)", (V,))
    check(f"{role} cannot read lock state", err is not None)
_, err = run(R1n, "authenticated", "select * from public.login_locks")
check("residents cannot read login_locks", err is not None)
rows, err = run(R1n, "authenticated", "select count(*) from public.security_events")
check("residents see no security events", err is not None or rows[0][0] == 0, (rows, err))

# recovery
_, err = run(R1n, "authenticated", "select * from public.admin_list_locked_logins()")
check("resident cannot list locked accounts", err is not None and "forbidden" in str(err), err)
rows, err = run(SU, "authenticated", "select username, permanent from public.admin_list_locked_logins()", aal="aal2")
check("super admin lists the locked account", err is None and rows == [("@victim", True)], (rows, err))
cur.execute("insert into auth.sessions(user_id) values (%s)", (V,))
for who, aal, reason, label, code in (
        (A, "aal2", "forgot everything, verified by phone", "admin (not super) cannot recover", "forbidden"),
        (SU, "aal1", "forgot everything, verified by phone", "super admin without 2FA cannot recover", "aal2_required"),
        (SU, "aal2", "short", "reason is mandatory (10+ chars)", "reason_required")):
    _, err = run(who, "authenticated", "select public.admin_recover_login(%s,%s)", (V, reason), aal=aal)
    check(label, err is not None and code in str(err), err)
_, err = run(SU, "authenticated", "select public.admin_recover_login(%s,'verified by phone call with the owner')", (V,), aal="aal2")
check("super admin with 2FA and a reason recovers the account", err is None, err)
r, _ = svc("select count(*) from public.login_locks where user_id=%s", (V,))
check("lock cleared", r[0][0] == 0)
r, _ = svc("select must_change_password from public.profiles where id=%s", (V,))
check("must_change_password set", r[0][0] is True)
cur.execute("select count(*) from auth.sessions where user_id=%s", (V,))
check("their sessions are revoked", cur.fetchone()[0] == 0)
r, _ = svc("select count(*) from public.crud_audit_logs where action='login.recover' and record_id=%s and details->>'reason' like 'verified by phone%%'", (V,))
check("recovery is in the audit log with the reason", r[0][0] == 1)
r, _ = svc("select count(*) from public.security_events where user_id=%s and kind='login_recovered'", (V,))
check("recovery is in security events", r[0][0] == 1)
r, _ = svc("select public.record_login_attempt('u-victim','ip1',true,%s)", (V,))
_, err = run(V, "authenticated", "update public.profiles set must_change_password = false where id = auth.uid()")
r, _ = svc("select must_change_password from public.profiles where id=%s", (V,))
check("the person cannot clear the flag by editing their profile", r[0][0] is True, r)
_, err = run(V, "authenticated", "select public.clear_must_change_password()")
r, _ = svc("select must_change_password from public.profiles where id=%s", (V,))
check("the app clears it through the RPC after a password change", err is None and r[0][0] is False, (err, r))

print("\n[24] app update policy")
rows, err = run(None, "anon", "select latest_build, min_supported_build, update_url from public.app_config")
check("anyone can read the update policy (needed before sign-in)", err is None and len(rows) == 1 and rows[0][2].startswith("https://"), (rows, err))
_, err = run(None, "anon", "update public.app_config set min_supported_build = 999")
check("anon cannot change it", err is not None)
_, err = run(R1n, "authenticated", "update public.app_config set min_supported_build = 999")
check("a resident cannot change it directly", err is not None)
for who, aal, label, code in ((R1n, "aal2", "resident cannot use admin_set_app_config", "forbidden"),
                              (A, "aal2", "admin (not super) cannot", "forbidden"),
                              (SU, "aal1", "super admin without 2FA cannot", "aal2_required")):
    _, err = run(who, "authenticated", "select public.admin_set_app_config(10,5,'https://play.google.com/x','','')", aal=aal)
    check(label, err is not None and code in str(err), err)
_, err = run(SU, "authenticated", "select public.admin_set_app_config(5,10,null,'','')", aal="aal2")
check("min cannot exceed latest", err is not None and "invalid_versions" in str(err), err)
_, err = run(SU, "authenticated", "select public.admin_set_app_config(10,5,'javascript:alert(1)','','')", aal="aal2")
check("update link must be https", err is not None, err)
_, err = run(SU, "authenticated", "select public.admin_set_app_config(10,5,'https://play.google.com/store/apps/details?id=com.myharur.app','Please update','')", aal="aal2")
check("super admin with 2FA sets the policy", err is None, err)
rows, _ = run(None, "anon", "select latest_build, min_supported_build, message_en from public.app_config")
check("the change is visible to everyone", rows == [(10, 5, "Please update")], rows)
cur.execute("select count(*) from public.crud_audit_logs where action='app_config.update'")
check("the change is audited", cur.fetchone()[0] == 1)

print("\n[25] two-factor enforcement: admins only count as admins at aal2")
pend, _ = submit(mkuser("aal-author@x"), "Water leak near market", "Pipe burst near the market road")
pid = str(pend[0][0])
for label, who, fn, at1, at2 in (
        ("admin", A, "is_admin", False, True),
        ("admin", A, "is_staff", False, True),
        ("super admin", SU, "is_superadmin", False, True),
        ("super admin", SU, "is_admin", False, True),
        ("moderator (2FA optional)", M, "is_staff", True, True),
        ("moderator", M, "is_admin", False, False)):
    r1, _ = run(who, "authenticated", f"select public.{fn}()", aal="aal1")
    r2, _ = run(who, "authenticated", f"select public.{fn}()", aal="aal2")
    check(f"{label}: {fn}() = {at1} at aal1, {at2} at aal2", r1[0][0] is at1 and r2[0][0] is at2, (r1, r2))
r, _ = run(None, "anon", "select public.has_aal2()", aal="aal1")
check("anon is never aal2", r[0][0] is False)
_, err = run(A, "authenticated", "select public.moderate_alert(%s,'approve')", (pid,), aal="aal1")
check("admin without 2FA cannot approve an alert", err is not None, err)
rows, _ = run(A, "authenticated", "select count(*) from public.alerts where id=%s", (pid,), aal="aal1")
check("admin without 2FA cannot even see the pending alert", rows[0][0] == 0, rows)
rows, _ = run(A, "authenticated", "select count(*) from public.alerts where id=%s", (pid,), aal="aal2")
check("admin with 2FA sees it", rows[0][0] == 1, rows)
rows, err = run(A, "authenticated", "select public.admin_stats()", aal="aal1")
check("admin_stats refuses aal1", err is not None, rows)
rows, err = run(A, "authenticated", "select public.admin_stats()", aal="aal2")
check("admin_stats works at aal2", err is None, err)
_, err = run(M, "authenticated", "select public.moderate_alert(%s,'approve')", (pid,), aal="aal1")
check("a moderator without 2FA can still review", err is None, err)

print("\n[26] community news, images, cooldown")
def aged(email, role=None):
    u = mkuser(email, role)
    cur.execute("update public.profiles set created_at = now() - interval '3 days' where id=%s", (u,))
    return u
NEWS = ("insert into public.alerts(kind,category,title,body,link_url,image_paths,status,source,published_as_role,created_by_uid) "
        "values (%s,%s,%s,%s,%s,%s,'published','official','Official',%s) returning id,status,kind,link_url,image_paths,moderation_flags")
def news(uid, cat="traffic", title="Bypass road reopened", body="The Harur bypass reopened after repairs today.", link=None, imgs=None, kind="news"):
    return run(uid, "authenticated", NEWS, (kind, cat, title, body, link, imgs or [], str(uuid.uuid4())))
N1 = aged("news1@x")
rows, err = news(N1)
check("a resident can submit community news (lands pending)", err is None and rows[0][1] == "pending" and rows[0][2] == "news", err)
rows, err = news(N1, link="https://www.thehindu.com/news/x")
check("news with an https link is accepted and flagged for the reviewer", err is None and "link" in rows[0][5], (rows, err))
_, err = news(N1, link="javascript:alert(1)")
check("a javascript: link is refused", err is not None)
_, err = news(mkuser("news2@x"), link="http://insecure.example/x")
check("a plain http link is refused", err is not None)
_, err = news(mkuser("news3@x"), cat="road")
check("a report category is not valid for news", err is not None)
_, err = news(mkuser("news4@x"), cat="traffic", kind="report")
check("a news category is not valid for a report", err is not None)
rows, err = news(mkuser("news5@x"), cat="road", kind="report", link="https://x.example/y")
check("reports never keep a link", err is None and rows[0][3] is None, (rows, err))

NI = mkuser("img@x")
mine = f"{NI}/{uuid.uuid4()}.jpg"
rows, err = news(NI, imgs=[mine])
check("own image path accepted", err is None and rows[0][4] == [mine], err)
_, err = news(NI, imgs=[f"{R2}/{uuid.uuid4()}.jpg"])
check("someone else's image path is refused", err is not None and "invalid_image" in str(err), err)
_, err = news(NI, imgs=[f"{NI}/../{R2}/{uuid.uuid4()}.jpg"])
check("path traversal is refused", err is not None, err)
_, err = news(NI, imgs=[f"{NI}/{uuid.uuid4()}.exe"])
check("a non-image extension is refused", err is not None)
same = f"{NI}/{uuid.uuid4()}.png"
_, err = news(NI, imgs=[same, same])
check("the same image twice is refused", err is not None)
_, err = news(NI, imgs=[f"{NI}/{uuid.uuid4()}.jpg" for _ in range(4)])
check("more than 3 images is refused", err is not None)

RL = mkuser("newsrate@x")
res = [news(RL, title=f"Town news item {i}")[1] for i in range(4)]
check("residents get 3 news posts per hour", [e is None for e in res] == [True, True, True, False] and "rate_limited" in str(res[3]), res)
rows, err = submit(RL, "Pothole near school", "A large pothole near the school gate")
check("the news limit does not use up the report limit", err is None, err)

CD = mkuser("cool@x")
for i in range(3):
    cur.execute("insert into public.alerts(kind,category,title,body,status,moderation_reason,created_by_uid,source) values ('report','road',%s,'auto rejected body text','rejected','auto_rejected',%s,'community')", (f"bad post {i}", CD))
_, err = submit(CD, "Fine report now", "A perfectly fine report about a road")
check("3 auto-rejections in 24 h put the author on cooldown", err is not None and "cooldown" in str(err), err)
_, err = submit(mkuser("cool-mod@x", "moderator"), "Staff are exempt", "Staff are exempt from the cooldown rule")
check("staff are exempt from the cooldown", err is None, err)

print("\n[27] delete own / staff delete")
def publish(uid, title="Water tank cleaning", body="The overhead water tank cleaning is on Sunday"):
    rows, err = submit(uid, title, body)
    assert err is None, err
    aid = str(rows[0][0])
    _, err = run(M, "authenticated", "select public.moderate_alert(%s,'approve')", (aid,))
    assert err is None, err
    return aid
D1, D2 = aged("del1@x"), aged("del2@x")
pa = publish(D1)
rows, _ = run(None, "anon", "select count(*) from public.alerts where id=%s", (pa,), aal="aal1")
check("a published post is public", rows[0][0] == 1)
_, err = run(D2, "authenticated", "select public.delete_content(%s)", (pa,))
check("another resident cannot delete it", err is not None and "forbidden" in str(err), err)
_, err = run(M, "authenticated", "select public.delete_content(%s)", (pa,))
check("staff must give a reason", err is not None and "reason_required" in str(err), err)
_, err = run(D1, "authenticated", "select public.delete_content(%s)", (pa,))
check("the author deletes their own post", err is None, err)
rows, _ = run(None, "anon", "select count(*) from public.alerts where id=%s", (pa,), aal="aal1")
check("it disappears from the public feed", rows[0][0] == 0)
rows, _ = run(D1, "authenticated", "select count(*) from public.alerts where id=%s", (pa,))
check("and from the author's own list", rows[0][0] == 0)
_, err = run(D1, "authenticated", "select public.delete_content(%s)", (pa,))
check("deleting twice is harmless", err is None, err)
cur.execute("select status, deleted_by is not null from public.alerts where id=%s", (pa,))
check("row is kept (soft delete, status expired)", cur.fetchone() == ("expired", True))
pb = publish(D1, "Bus timing changed", "The morning bus timing has changed from Monday")
_, err = run(M, "authenticated", "select public.delete_content(%s,'misleading timing, checked with depot')", (pb,))
check("staff delete any post with a reason", err is None, err)
cur.execute("select count(*) from public.crud_audit_logs where action='content.delete' and record_id=%s and details->>'reason' like 'misleading%%'", (pb,))
check("staff deletion is audited with the reason", cur.fetchone()[0] == 1)
pn, _ = news(D1, title="Pending news to delete")
_, err = run(D1, "authenticated", "select public.delete_content(%s)", (str(pn[0][0]),))
cur.execute("select status from public.moderation_queue where alert_id=%s", (str(pn[0][0]),))
check("deleting a pending post removes it from the review queue", err is None and cur.fetchone()[0] == "expired", err)

print("\n[28] report a post, auto-restrict, staff decision")
AU = aged("author@x")
post = publish(AU, "Road repair on main street", "Road repair work is going on along the main street")
reps = [aged(f"rep{i}@x") for i in range(3)]
newbie = mkuser("newbie@x")
_, err = run(AU, "authenticated", "select public.report_content(%s,'spam')", (post,))
check("you cannot report your own post", err is not None)
_, err = run(reps[0], "authenticated", "select public.report_content(%s,'nonsense')", (post,))
check("unknown reason refused", err is not None)
run(reps[0], "authenticated", "select public.report_content(%s,'spam')", (post,))
run(reps[0], "authenticated", "select public.report_content(%s,'abuse')", (post,))
cur.execute("select count(*) from public.user_reports where reporter=%s", (reps[0],))
check("the same reporter, post and day counts once", cur.fetchone()[0] == 1)
run(newbie, "authenticated", "select public.report_content(%s,'spam')", (post,))
run(reps[1], "authenticated", "select public.report_content(%s,'false')", (post,))
cur.execute("select count(*) from public.user_restrictions where user_id=%s", (AU,))
check("2 aged reporters + 1 brand-new account do not restrict", cur.fetchone()[0] == 0)
run(reps[2], "authenticated", "select public.report_content(%s,'harassment')", (post,))
cur.execute("select status from public.user_restrictions where user_id=%s", (AU,))
row = cur.fetchone()
check("3 distinct aged reporters auto-restrict the author", row is not None and row[0] == "restricted", row)
_, err = submit(AU, "Another report", "Posting again while restricted should fail")
check("a restricted author cannot post", err is not None and "account_restricted" in str(err), err)
rows, _ = run(AU, "authenticated", "select status from public.user_restrictions")
check("they can see their own restriction", rows == [("restricted",)], rows)
rows, _ = run(R1n, "authenticated", "select count(*) from public.user_restrictions")
check("others cannot see restrictions", rows[0][0] == 0, rows)
rows, err = run(R1n, "authenticated", "select count(*) from public.user_reports")
check("residents cannot read reports", err is not None)

mp = publish(aged("modauthor@x", "moderator"), "Official notice on works", "Official notice about the road works this week")
for i in range(3):
    run(aged(f"modrep{i}@x"), "authenticated", "select public.report_content(%s,'spam')", (mp,))
cur.execute("select count(*) from public.user_restrictions where user_id=(select created_by_uid from public.alerts where id=%s)", (mp,))
check("staff are never auto-restricted", cur.fetchone()[0] == 0)

rows, err = run(A, "authenticated", "select username, restriction, reporters from public.admin_list_user_reports()")
check("admin sees the reported author with their reporters", err is None and any(r[1] == "restricted" and r[2] >= 3 for r in rows), (rows, err))
_, err = run(A, "authenticated", "select * from public.admin_list_user_reports()", aal="aal1")
check("admin list needs 2FA", err is not None)
_, err = run(M, "authenticated", "select * from public.admin_list_user_reports()")
check("moderators cannot open the user-report list", err is not None)
_, err = run(A, "authenticated", "select public.admin_resolve_user_report(%s,'ban','')", (AU,))
check("a ban needs a written reason", err is not None and "reason_required" in str(err), err)
_, err = run(A, "authenticated", "select public.admin_resolve_user_report(%s,'dismiss')", (AU,))
check("dismiss lifts the restriction", err is None, err)
cur.execute("select count(*) from public.user_restrictions where user_id=%s", (AU,))
check("restriction gone after dismiss", cur.fetchone()[0] == 0)
rows, err = submit(AU, "Posting again after review", "The author may post again after being cleared")
check("they can post again", err is None, err)
cur.execute("insert into auth.sessions(user_id) values (%s)", (AU,))
_, err = run(A, "authenticated", "select public.admin_resolve_user_report(%s,'ban','repeated abuse after warning')", (AU,))
check("admin bans a resident", err is None, err)
cur.execute("select is_active from public.profiles where id=%s", (AU,))
check("ban deactivates the profile", cur.fetchone()[0] is False)
cur.execute("select count(*) from auth.sessions where user_id=%s", (AU,))
check("ban signs them out everywhere", cur.fetchone()[0] == 0)
_, err = submit(AU, "Banned poster", "A banned account must not be able to post")
check("banned account cannot post", err is not None)
_, err = run(A, "authenticated", "select public.admin_resolve_user_report(%s,'reinstate','appeal accepted, mistaken reports')", (AU,))
cur.execute("select is_active from public.profiles where id=%s", (AU,))
check("reinstate restores the account", err is None and cur.fetchone()[0] is True, err)
_, err = run(A, "authenticated", "select public.admin_resolve_user_report(%s,'ban','trying to ban a moderator')", (M,))
check("an admin cannot ban a moderator (super admin only)", err is not None and "superadmin_required" in str(err), err)
_, err = run(SU, "authenticated", "select public.admin_resolve_user_report(%s,'restrict','moderator misused tools')", (M,))
check("a super admin can restrict a moderator", err is None, err)
_, err = run(SU, "authenticated", "select public.admin_resolve_user_report(%s,'ban','no one bans a super admin')", (SU,))
check("nobody acts on themselves", err is not None)
_, err = run(A, "authenticated", "select public.admin_resolve_user_report(%s,'ban','trying to ban the super admin')", (SU,))
check("a super admin cannot be banned", err is not None)
_, err = run(SU, "authenticated", "select public.admin_resolve_user_report(%s,'reinstate','restored moderator')", (M,))

rr = aged("ratelimit-reporter@x")
outs = [run(rr, "authenticated", "select public.report_content(%s,'spam')", (post,))[1] for _ in range(6)]
check("report_content is limited to 5 a day", outs[5] is not None and "rate_limited" in str(outs[5]), outs[5])

print("\n[29] block an author")
B1 = aged("blocker@x")
bp = publish(aged("blocked-author@x"), "Market day moved", "The weekly market day has moved to Thursday this week")
rows, _ = run(B1, "authenticated", "select count(*) from public.alerts where id=%s", (bp,))
check("before blocking the post is visible", rows[0][0] == 1)
_, err = run(B1, "authenticated", "select public.block_author(%s)", (bp,))
check("block succeeds", err is None, err)
rows, _ = run(B1, "authenticated", "select count(*) from public.alerts where id=%s", (bp,))
check("the blocked author's posts vanish for the blocker", rows[0][0] == 0)
rows, _ = run(R2, "authenticated", "select count(*) from public.alerts where id=%s", (bp,))
check("but not for anyone else", rows[0][0] == 1)
rows, _ = run(B1, "authenticated", "select label from public.user_blocks")
check("the block list shows the post title, not the person", rows == [("Market day moved",)], rows)
rows, _ = run(R2, "authenticated", "select count(*) from public.user_blocks")
check("nobody sees another person's block list", rows[0][0] == 0)
_, err = run(B1, "authenticated", "insert into public.user_blocks(blocker,blocked) values (%s,%s)", (B1, R2))
check("blocks can only be made through block_author()", err is not None)
cur.execute("select blocked from public.user_blocks where blocker=%s", (B1,))
blocked_id = str(cur.fetchone()[0])
_, err = run(B1, "authenticated", "select public.unblock_user(%s)", (blocked_id,))
rows, _ = run(B1, "authenticated", "select count(*) from public.alerts where id=%s", (bp,))
check("unblock brings the posts back", err is None and rows[0][0] == 1, err)

print("\n[30] bug reports")
BU = mkuser("bugger@x")
_, err = run(BU, "authenticated", "select public.report_bug('Crash on Reports tab','The app closes when I open the Reports tab twice','1.2.0+7','Android 16')")
check("anyone signed in can file a bug", err is None, err)
_, err = run(BU, "authenticated", "select public.report_bug('x','too short','1','a')")
check("a too-short title is refused", err is not None)
rows, err = run(BU, "authenticated", "select count(*) from public.client_errors")
check("residents cannot read bug reports", err is not None or rows[0][0] == 0, (rows, err))
rows, err = run(SU, "authenticated", "select message, kind from public.client_errors where kind='bug'")
check("super admin reads them", err is None and ("Crash on Reports tab", "bug") in rows, (rows, err))
rows, _ = run(SU, "authenticated", "select count(*) from public.client_errors where kind='bug'", aal="aal1")
check("even a super admin needs 2FA to read them", rows[0][0] == 0, rows)
outs = [run(BU, "authenticated", "select public.report_bug('Another bug here','details of the bug number %s','1','a')" % i)[1] for i in range(5)]
check("5 bug reports a day at most", outs[4] is not None and "rate_limited" in str(outs[4]), outs[4])

print("\n[31] photo storage")
cur.execute("select public, file_size_limit, allowed_mime_types from storage.buckets where id='content-images'")
b = cur.fetchone()
check("bucket is private, 2 MB, image types only", b == (False, 2097152, ["image/jpeg", "image/png", "image/webp"]), b)
def put(uid, name):
    return run(uid, "authenticated", "insert into storage.objects(bucket_id,name,owner) values ('content-images',%s,%s)", (name, uid))
def can_see(uid, name):
    rows, err = run(uid, "authenticated", "select count(*) from storage.objects where bucket_id='content-images' and name=%s", (name,))
    return err is None and rows[0][0] == 1
PU, PO, PR = aged("photo-owner@x"), aged("photo-other@x"), aged("photo-restricted@x")
f1 = f"{PU}/{uuid.uuid4()}.jpg"
_, err = put(PU, f1)
check("upload into your own folder", err is None, err)
_, err = put(PU, f"{PO}/{uuid.uuid4()}.jpg")
check("cannot upload into someone else's folder", err is not None)
_, err = put(PU, f"{PU}/{uuid.uuid4()}.exe")
check("cannot upload a non-image name", err is not None)
_, err = put(PU, f"{PU}/notes.jpg")
check("names must be a uuid", err is not None)
_, err = put(None, f"{PU}/{uuid.uuid4()}.jpg")
check("anon cannot upload", err is not None)
outs = [put(PU, f"{PU}/{uuid.uuid4()}.webp")[1] for _ in range(15)]
check("15 uploads an hour (the 16th is refused)", sum(e is None for e in outs) == 14 and outs[14] is not None, [str(e)[:30] if e else None for e in outs])
cur.execute("insert into public.user_restrictions(user_id,status,reason) values (%s,'restricted','test')", (PR,))
_, err = put(PR, f"{PR}/{uuid.uuid4()}.jpg")
check("restricted users cannot upload", err is not None)

check("the owner sees their own file", can_see(PU, f1))
check("other residents do not see an unattached file", not can_see(PO, f1))
check("staff can see it", can_see(M, f1))
# attach it to a post: visible only once the post is public
post_rows, err = news(PU, title="Photo news story", body="A story with a photo attached to it.", imgs=[f1])
assert err is None, err
pid2 = str(post_rows[0][0])
check("a pending post's image stays hidden from others", not can_see(PO, f1))
check("staff can see a pending post's image (they review it)", can_see(M, f1))
run(M, "authenticated", "select public.moderate_alert(%s,'approve')", (pid2,))
check("once approved, other residents can sign the image", can_see(PO, f1))
_, err = run(PU, "authenticated", "select public.block_author(%s)", (pid2,))
check("the author cannot block themselves", err is not None)
run(PO, "authenticated", "select public.block_author(%s)", (pid2,))
check("a blocker no longer sees the blocked author's image", not can_see(PO, f1))
cur.execute("delete from public.user_blocks")
_, err = run(PU, "authenticated", "select public.delete_content(%s)", (pid2,))
check("after the post is deleted its image is unreachable for others", err is None and not can_see(PO, f1))
check("and for the author (their post is gone)", can_see(PU, f1) is True)   # own folder rule: they uploaded it

# deleting files (a fresh user: PU has used up the hourly upload limit)
PV = aged("photo-v@x")
f2 = f"{PV}/{uuid.uuid4()}.png"
put(PV, f2)
_, err = run(PO, "authenticated", "delete from storage.objects where name=%s", (f2,))
cur.execute("select count(*) from storage.objects where name=%s", (f2,))
check("another resident cannot delete your file", cur.fetchone()[0] == 1)
run(PV, "authenticated", "delete from storage.objects where name=%s", (f2,))
cur.execute("select count(*) from storage.objects where name=%s", (f2,))
check("you can delete an unattached file of yours", cur.fetchone()[0] == 0)
f3 = f"{PV}/{uuid.uuid4()}.png"
put(PV, f3)
news(PV, title="Second photo story", body="Another story that uses the photo.", imgs=[f3])
run(PV, "authenticated", "delete from storage.objects where name=%s", (f3,))
cur.execute("select count(*) from storage.objects where name=%s", (f3,))
check("you cannot delete a file a post is using", cur.fetchone()[0] == 1)
run(M, "authenticated", "delete from storage.objects where name=%s", (f3,))
cur.execute("select count(*) from storage.objects where name=%s", (f3,))
check("staff can delete it", cur.fetchone()[0] == 0)

# purge
orphan = f"{PO}/{uuid.uuid4()}.jpg"
put(PO, orphan)
cur.execute("update storage.objects set created_at = now() - interval '2 days' where name=%s", (orphan,))
cur.execute("update public.alerts set deleted_at = now() - interval '40 days' where id=%s", (pid2,))
rows, err = svc("select path from public.internal_purge_candidates()")
paths = {r[0] for r in rows or []}
check("purge finds an old unattached upload", orphan in paths, paths)
check("purge finds the files of a post deleted 40 days ago", f1 in paths, paths)
check("purge leaves recent uploads alone", not any(p.startswith(str(PR)) for p in paths))
_, err = run(PO, "authenticated", "select * from public.internal_purge_candidates()")
check("residents cannot call the purge helpers", err is not None)
n, _ = svc("select public.internal_purge_deleted_rows()")
cur.execute("select count(*) from public.alerts where id=%s", (pid2,))
check("rows are kept while their files still exist", n[0][0] == 0 and cur.fetchone()[0] == 1, n)
cur.execute("delete from storage.objects where name=%s", (f1,))
n, _ = svc("select public.internal_purge_deleted_rows()")
cur.execute("select count(*) from public.alerts where id=%s", (pid2,))
check("once the files are removed the old row is purged", n[0][0] >= 1 and cur.fetchone()[0] == 0, n)

print("\n[32] AI fallback daily budget")
takes = [svc("select public.internal_ai_take(3)")[0][0][0] for _ in range(5)]
check("a cap of 3 allows exactly 3 calls a day", takes == [True, True, True, False, False], takes)
cur.execute("select calls from public.ai_usage where day = current_date")
check("the counter stops at the cap (no runaway growth)", cur.fetchone()[0] == 3)
cur.execute("update public.ai_usage set day = current_date - 1")
takes = [svc("select public.internal_ai_take(3)")[0][0][0] for _ in range(4)]
check("a new day starts a fresh budget", takes == [True, True, True, False], takes)
for who, role in ((R1n, "authenticated"), (None, "anon")):
    _, err = run(who, role, "select public.internal_ai_take(1000000)")
    check(f"{role} cannot spend the AI budget", err is not None)
_, err = run(R1n, "authenticated", "select * from public.ai_usage")
check("residents cannot read usage", err is not None)

print("\n[33] push notifications: tokens, preferences, caps, quiet hours")
def tok(): return "fcm-" + uuid.uuid4().hex + uuid.uuid4().hex
PN, PM = aged("push-a@x"), aged("push-b@x")
t1 = tok()
_, err = run(PN, "authenticated", "select public.register_push_token(%s,'ta')", (t1,))
check("a signed-in person registers a device token", err is None, err)
_, err = run(None, "anon", "select public.register_push_token(%s,'en')", (tok(),), aal="aal1")
check("anon cannot register a token", err is not None)
_, err = run(PN, "authenticated", "select public.register_push_token('short','en')")
check("an implausible token is refused", err is not None and "invalid_token" in str(err), err)
rows, err = run(PN, "authenticated", "select count(*) from public.push_tokens")
check("tokens cannot be read through the API", err is not None)
rows, _ = run(PN, "authenticated", "select * from public.my_notification_prefs()")
check("everything is on by default", rows == [(True, True, True)], rows)
_, err = run(PN, "authenticated", "select public.set_notification_prefs(true, false, true)")
rows, _ = run(PN, "authenticated", "select * from public.my_notification_prefs()")
check("a person can switch a kind off", err is None and rows == [(True, False, True)], (rows, err))
rows, _ = run(PM, "authenticated", "select * from public.my_notification_prefs()")
check("preferences are per person", rows == [(True, True, True)], rows)
# a token that moves to another account (shared phone) follows the newest owner
run(PM, "authenticated", "select public.register_push_token(%s,'en')", (t1,))
cur.execute("select user_id from public.push_tokens where token=%s", (t1,))
check("a device token belongs to whoever registered it last", str(cur.fetchone()[0]) == PM)
_, err = run(PN, "authenticated", "select public.unregister_push_token(%s)", (t1,))
cur.execute("select count(*) from public.push_tokens where token=%s", (t1,))
check("you cannot remove someone else's token", cur.fetchone()[0] == 1)
run(PM, "authenticated", "select public.unregister_push_token(%s)", (t1,))
cur.execute("select count(*) from public.push_tokens where token=%s", (t1,))
check("you can remove your own", cur.fetchone()[0] == 0)
PZ = aged("push-many@x")
for i in range(7):
    run(PZ, "authenticated", "select public.register_push_token(%s,'en')", (tok(),))
cur.execute("select count(*) from public.push_tokens where user_id=%s", (PZ,))
check("at most 5 devices per person", cur.fetchone()[0] == 5)
PR2 = aged("push-rate@x")
outs = [run(PR2, "authenticated", "select public.register_push_token(%s,'en')", (tok(),))[1] for _ in range(21)]
check("token registration is rate limited (20 a day)", outs[20] is not None and "rate_limited" in str(outs[20]), outs[20])

# quiet hours, India time
def quiet(ts): return svc("select public.in_quiet_hours(%s::timestamptz)", (ts,))[0][0][0]
check("22:30 IST is quiet", quiet("2026-09-27 17:00:00+00") is True)
check("06:30 IST is quiet", quiet("2026-09-27 01:00:00+00") is True)
check("07:00 IST is not quiet", quiet("2026-09-27 01:30:00+00") is False)
check("18:00 IST is not quiet", quiet("2026-09-27 12:30:00+00") is False)

# the digest plan: silent unless something new is live, once a day, never in quiet hours
DAY = "2026-09-27 12:30:00+00"
cur.execute("delete from public.notification_log")
cur.execute("update public.alerts set reviewed_at = now() - interval '3 days' where status='published'")
plan = svc("select * from public.internal_digest_plan(now())")[0][0]
day_plan = svc("select * from public.internal_digest_plan(%s::timestamptz)", (DAY,))[0][0]
check("nothing new -> no digest", day_plan[0] is False and day_plan[1] == "nothing_new", day_plan)
DP = aged("digest-author@x")
dp1 = publish(DP, "Streetlight repaired on market road", "The streetlight on the market road has been repaired")
dp2 = publish(DP, "Water supply timing changed", "Water supply timing changed for the east side this week")
cur.execute("update public.alerts set reviewed_at = now(), expires_at = now() + interval '3 days' where id in (%s,%s)", (dp1, dp2))
run_at = svc("select now()")[0][0][0].isoformat()
day = svc("select * from public.internal_digest_plan(date_trunc('day', now()) + interval '12 hours 30 minutes')")[0][0]
check("new live reports -> a digest is allowed (daytime IST)", day[0] is True or day[1] == "quiet_hours", day)
q = svc("select * from public.internal_digest_plan(date_trunc('day', now()) + interval '17 hours')")[0][0]
check("the same content in quiet hours -> silent", q[0] is False and q[1] == "quiet_hours", q)
svc("select public.internal_log_notification('reports_digest', 12, '{}')")
again = svc("select * from public.internal_digest_plan(now() + interval '5 hours')")[0][0]
check("a second digest within 20 hours is refused", again[0] is False and again[1] in ("already_sent", "quiet_hours"), again)
cur.execute("select count(*) from public.notification_log where kind='reports_digest'")
check("the send is logged", cur.fetchone()[0] == 1)

# the digest reaches only people who want it
DQ1, DQ2, DQ3 = aged("dq1@x"), aged("dq2@x"), aged("dq3@x")
ta, tb, tc = tok(), tok(), tok()
run(DQ1, "authenticated", "select public.register_push_token(%s,'en')", (ta,))
run(DQ2, "authenticated", "select public.register_push_token(%s,'ta')", (tb,))
run(DQ3, "authenticated", "select public.register_push_token(%s,'en')", (tc,))
run(DQ2, "authenticated", "select public.set_notification_prefs(true, false, true)")     # reports off
run(DQ3, "authenticated", "select public.set_notification_prefs(false, true, true)")     # master off
got = {r[0] for r in svc("select token from public.internal_digest_tokens()")[0]}
check("digest goes to people with the reports switch on", ta in got, got)
check("not to someone who switched reports off", tb not in got)
check("not to someone who switched everything off", tc not in got)
run(DQ1, "authenticated", "select 1")
cur.execute("update public.profiles set is_active=false where id=%s", (DQ1,))
got = {r[0] for r in svc("select token from public.internal_digest_tokens()")[0]}
check("not to a deactivated account", ta not in got)
n = svc("select public.internal_drop_tokens(%s)", ([ta, tb],))[0][0][0]
check("tokens Firebase says are gone are forgotten", n == 2, n)

# event alerts: 2 a week
cur.execute("delete from public.notification_log")
ok1 = svc("select public.internal_event_push_allowed(date_trunc('day', now()) + interval '12 hours')")[0][0][0]
ok2 = svc("select public.internal_event_push_allowed(date_trunc('day', now()) + interval '12 hours')")[0][0][0]
ok3 = svc("select public.internal_event_push_allowed(date_trunc('day', now()) + interval '12 hours')")[0][0][0]
check("event alerts: 2 a week, the third is refused", [ok1, ok2, ok3] == [True, True, False], [ok1, ok2, ok3])
q = svc("select public.internal_event_push_allowed(date_trunc('day', now()) + interval '17 hours')")[0][0][0]
check("event alerts never go out in quiet hours", q is False)

# nothing here is callable by app users
for fn in ("internal_digest_tokens()", "internal_digest_plan(now())", "internal_event_push_allowed(now())"):
    _, err = run(PN, "authenticated", f"select * from public.{fn}")
    check(f"residents cannot call {fn.split('(')[0]}", err is not None)

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
