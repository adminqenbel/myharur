-- ==============================================================================
-- MYHARUR PRODUCT DATABASE SCHEMA v2
-- Run in: Supabase Dashboard -> db.qpuvhhvzygdbvlichbqs -> SQL Editor
-- Identity: provided by QenBel Supabase (auth via JWT from QenBel)
-- Google OAuth Android Client: 976428818123-tr1tgub2a690vh7g88s2icpq19smmuvv.apps.googleusercontent.com
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. WARDS (18 static Harur wards)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.wards (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    taluk       TEXT DEFAULT 'Harur',
    district    TEXT DEFAULT 'Dharmapuri',
    geo_bounds  JSONB,  -- {lat_min, lat_max, lon_min, lon_max}
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed 18 Harur wards
INSERT INTO public.wards (id, name, taluk, district) VALUES
    (1,  'Ward 1 - Bazaar Street',           'Harur', 'Dharmapuri'),
    (2,  'Ward 2 - Town Hall Area',           'Harur', 'Dharmapuri'),
    (3,  'Ward 3 - Bus Stand South',          'Harur', 'Dharmapuri'),
    (4,  'Ward 4 - Hospital Road',            'Harur', 'Dharmapuri'),
    (5,  'Ward 5 - Anna Nagar',               'Harur', 'Dharmapuri'),
    (6,  'Ward 6 - Nethaji Nagar',            'Harur', 'Dharmapuri'),
    (7,  'Ward 7 - Gandhi Nagar',             'Harur', 'Dharmapuri'),
    (8,  'Ward 8 - Theerthamalai Road',       'Harur', 'Dharmapuri'),
    (9,  'Ward 9 - Morappur Road',            'Harur', 'Dharmapuri'),
    (10, 'Ward 10 - Kottapatti Area',         'Harur', 'Dharmapuri'),
    (11, 'Ward 11 - Palacode Road',           'Harur', 'Dharmapuri'),
    (12, 'Ward 12 - Collectorate Surrounds',  'Harur', 'Dharmapuri'),
    (13, 'Ward 13 - Railway Colony',          'Harur', 'Dharmapuri'),
    (14, 'Ward 14 - Industrial Area',         'Harur', 'Dharmapuri'),
    (15, 'Ward 15 - Agri Market Zone',        'Harur', 'Dharmapuri'),
    (16, 'Ward 16 - North Extension',         'Harur', 'Dharmapuri'),
    (17, 'Ward 17 - South Colony',            'Harur', 'Dharmapuri'),
    (18, 'Ward 18 - Outskirts & Rural Fringe','Harur', 'Dharmapuri')
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- 2. MODULE FLAGS (feature gates — all off at launch except alerts implicit)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.module_flags (
    module      TEXT PRIMARY KEY,
    enabled     BOOLEAN NOT NULL DEFAULT FALSE,
    updated_by  UUID,   -- QenBel UID of admin who toggled it
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.module_flags (module, enabled) VALUES
    ('jobs',        FALSE),
    ('events',      FALSE),
    ('tournaments', FALSE),
    ('chat',        FALSE),
    ('marketplace', FALSE),
    ('rankings',    FALSE),
    ('donations',   FALSE)
ON CONFLICT (module) DO NOTHING;

-- ==============================================================================
-- 3. PROFILES (MyHarur product-specific — linked to QenBel UID by value)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id                       UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    qenbel_uid               UUID,           -- QenBel identity UID (cross-DB reference by value)
    mmid                     TEXT UNIQUE NOT NULL,
    username                 TEXT UNIQUE,
    full_name                TEXT NOT NULL DEFAULT 'Harur Resident',
    email                    TEXT,
    phone                    TEXT,
    phone_verified           BOOLEAN NOT NULL DEFAULT FALSE,
    avatar_url               TEXT,
    ward_id                  INTEGER REFERENCES public.wards(id),
    ward_verified            BOOLEAN NOT NULL DEFAULT FALSE,
    onboarding_state         TEXT NOT NULL DEFAULT 'PENDING_USERNAME'
                             CHECK (onboarding_state IN ('PENDING_USERNAME','PENDING_PROFILE','PENDING_OCCUPATION','PENDING_SOURCE','COMPLETE')),
    occupation               TEXT CHECK (occupation IN ('student','shop_owner','employee','govt_employee','farmer','other')),
    blood_group              TEXT,
    emergency_contact_name   TEXT,
    emergency_contact_phone  TEXT,
    bio                      TEXT,
    emergency_strikes        INTEGER NOT NULL DEFAULT 0,
    is_active                BOOLEAN NOT NULL DEFAULT TRUE,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 4. USER ROLES (MyHarur-scoped — additive multi-role join table)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.user_roles (
    uid         UUID NOT NULL,  -- QenBel UID
    role        TEXT NOT NULL CHECK (role IN ('resident','govt_official','admin','superadmin')),
    scope       TEXT NOT NULL DEFAULT 'global' CHECK (scope IN ('global','govt')),
    granted_by  UUID,           -- QenBel UID of granting admin
    granted_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at  TIMESTAMPTZ,
    reason      TEXT,
    PRIMARY KEY (uid, role, scope)
);

-- ==============================================================================
-- 5. ALERTS (PRIMARY v1 launch surface: road / electricity / water / govt)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.alerts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category            TEXT NOT NULL CHECK (category IN ('road','electricity','water','govt')),
    ward_id             INTEGER REFERENCES public.wards(id),
    title               TEXT NOT NULL,
    body                TEXT NOT NULL,
    source              TEXT NOT NULL DEFAULT 'community' CHECK (source IN ('official','community')),
    status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('published','pending','rejected','expired')),
    published_as_role   TEXT,   -- 'Official — MyHarur Admin' | 'Official — Govt Dept'
    created_by_uid      UUID,   -- QenBel UID
    expires_at          TIMESTAMPTZ DEFAULT (now() + interval '7 days'),
    emergency_tagged    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 6. MODERATION QUEUE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.moderation_queue (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id            UUID REFERENCES public.alerts(id) ON DELETE CASCADE,
    category            TEXT,
    ward_id             INTEGER REFERENCES public.wards(id),
    status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','approved','rejected','expired')),
    emergency_tagged    BOOLEAN NOT NULL DEFAULT FALSE,
    flagged_by_system   BOOLEAN NOT NULL DEFAULT FALSE,
    assigned_admin      UUID,   -- QenBel UID
    decision_by         UUID,   -- QenBel UID
    decision_at         TIMESTAMPTZ,
    reason              TEXT,   -- 'spam'|'false'|'duplicate'|'low_quality' if rejected
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at          TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '24 hours')
);

-- ==============================================================================
-- 7. PROFANITY WORDLIST (managed table — not hardcoded)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profanity_wordlist (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    term        TEXT NOT NULL,
    script      TEXT NOT NULL CHECK (script IN ('english','tamil_unicode','tamil_tanglish','hindi_tanglish')),
    variant_type TEXT,  -- 'exact','leetspeak','phonetic'
    added_by    UUID,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 8. AUDIT LOGS (MyHarur product-level actions — not admin governance)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.crud_audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    qenbel_uid  UUID,
    mmid        TEXT,
    action      TEXT NOT NULL,
    table_name  TEXT NOT NULL,
    record_id   TEXT,
    details     JSONB DEFAULT '{}',
    ip_address  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 9. KEEP EXISTING FLAG-GATED TABLES (preserved, not dropped — flag controls visibility)
-- ==============================================================================

-- Jobs (flag: jobs=false)
CREATE TABLE IF NOT EXISTS public.jobs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id     UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    company_or_farm TEXT NOT NULL,
    job_type        TEXT NOT NULL DEFAULT 'full_time',
    description     TEXT NOT NULL,
    salary_range    TEXT,
    location_name   TEXT NOT NULL DEFAULT 'Harur',
    contact_phone   TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','published','closed')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Events (flag: events=false)
CREATE TABLE IF NOT EXISTS public.events (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id                  UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title                       TEXT NOT NULL,
    venue                       TEXT NOT NULL,
    event_type                  TEXT NOT NULL DEFAULT 'cultural',
    description                 TEXT NOT NULL,
    start_time                  TIMESTAMPTZ NOT NULL,
    end_time                    TIMESTAMPTZ NOT NULL,
    is_paid                     BOOLEAN NOT NULL DEFAULT FALSE,
    external_registration_url   TEXT,
    status                      TEXT NOT NULL DEFAULT 'pending',
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Chat messages (flag: chat=false)
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_name       TEXT NOT NULL DEFAULT 'public_town',
    sender_id       UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    sender_name     TEXT NOT NULL DEFAULT 'Harur Resident',
    sender_mmid     TEXT NOT NULL,
    text            TEXT NOT NULL,
    attachment_url  TEXT,
    is_official     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 10. ROW LEVEL SECURITY
-- ==============================================================================
ALTER TABLE public.wards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profanity_wordlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crud_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Wards: public read
CREATE POLICY "Public read wards" ON public.wards FOR SELECT USING (true);

-- Module flags: public read (app reads them to show/hide features)
CREATE POLICY "Public read module_flags" ON public.module_flags FOR SELECT USING (true);
CREATE POLICY "Service role write module_flags" ON public.module_flags
    FOR ALL USING (auth.role() = 'service_role');

-- Profiles
CREATE POLICY "Public read profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- User roles: read only (written by admin via service role)
CREATE POLICY "Public read user_roles" ON public.user_roles FOR SELECT USING (true);
CREATE POLICY "Service role write user_roles" ON public.user_roles
    FOR ALL USING (auth.role() = 'service_role');

-- Alerts: published alerts are public; pending/rejected visible to mods only
CREATE POLICY "Public read published alerts" ON public.alerts
    FOR SELECT USING (status = 'published');
CREATE POLICY "Authenticated insert alerts" ON public.alerts
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Service role all alerts" ON public.alerts
    FOR ALL USING (auth.role() = 'service_role');

-- Moderation queue: service role only
CREATE POLICY "Service role all moderation" ON public.moderation_queue
    USING (auth.role() = 'service_role');

-- Profanity wordlist: service role only
CREATE POLICY "Service role all profanity" ON public.profanity_wordlist
    USING (auth.role() = 'service_role');

-- Audit logs
CREATE POLICY "Service role all audit" ON public.crud_audit_logs
    USING (auth.role() = 'service_role');
CREATE POLICY "Authenticated insert audit" ON public.crud_audit_logs
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Jobs/Events/Chat (flag-gated but readable when published)
CREATE POLICY "Public read jobs" ON public.jobs FOR SELECT USING (status = 'published' AND is_active = TRUE);
CREATE POLICY "Authenticated insert jobs" ON public.jobs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Public read events" ON public.events FOR SELECT USING (status = 'approved');
CREATE POLICY "Authenticated insert events" ON public.events FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Public read chat" ON public.chat_messages FOR SELECT USING (true);
CREATE POLICY "Authenticated insert chat" ON public.chat_messages FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ==============================================================================
-- 11. AUTO-PROFILE TRIGGER (create profile row after auth.users insert)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_myharur_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    new_mmid TEXT;
BEGIN
    new_mmid := to_char(now() AT TIME ZONE 'UTC', 'YYYYMMDDHHMMSS') ||
                lpad((floor(random() * 9000) + 1000)::text, 4, '0');

    INSERT INTO public.profiles (id, mmid, full_name, email, onboarding_state)
    VALUES (
        NEW.id,
        new_mmid,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Harur Resident'),
        NEW.email,
        'PENDING_USERNAME'
    )
    ON CONFLICT (id) DO NOTHING;

    -- Grant default resident role
    INSERT INTO public.user_roles (uid, role, scope, granted_at)
    VALUES (NEW.id, 'resident', 'global', now())
    ON CONFLICT (uid, role, scope) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_myharur_user_created ON auth.users;
CREATE TRIGGER on_myharur_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_myharur_user();

-- ==============================================================================
-- 12. UPDATED_AT TRIGGER
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER alerts_updated_at BEFORE UPDATE ON public.alerts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 13. AUTO-EXPIRE: moderation queue items expire after 24h
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.expire_moderation_items()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.moderation_queue
    SET status = 'expired'
    WHERE status = 'pending' AND expires_at < now();

    UPDATE public.alerts
    SET status = 'expired'
    WHERE status = 'pending' AND expires_at < now();
END;
$$;

-- ==============================================================================
-- 14. COMMUNITY ALERT VISIBILITY RULE
-- Pending community reports show in-feed immediately (visually distinct)
-- but are NOT pushed via notifications. This prevents stale closure suppression.
-- ==============================================================================
-- (Handled in application layer via alert.status filter — no extra DB work needed)
