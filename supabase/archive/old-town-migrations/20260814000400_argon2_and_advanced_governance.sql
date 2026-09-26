-- ==============================================================================
-- Migration: Advanced Governance, Argon2id Credentials, Multi-lingual Profanity,
-- 3-Admin Termination Consensus, Super Admin Invariants, and AID Registry
-- ==============================================================================

-- 1. Argon2id Credentials Storage for Staff & Administrators
CREATE TABLE IF NOT EXISTS public.staff_credentials (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL, -- Stored Argon2id string: $argon2id$v=19$m=65536,t=3,p=2$...
    salt TEXT NOT NULL,
    pepper_version INTEGER NOT NULL DEFAULT 1,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    is_google_linked BOOLEAN NOT NULL DEFAULT FALSE,
    google_account_email TEXT,
    mfa_enforced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Admin ID (AID) Registry
CREATE TABLE IF NOT EXISTS public.admin_identifiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    aid TEXT NOT NULL UNIQUE, -- E.g., AID-HR-0001
    assigned_by UUID REFERENCES public.profiles(id),
    role TEXT NOT NULL CHECK (role IN ('super_admin', 'admin', 'moderator', 'government_official')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    promoted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    revoked_at TIMESTAMPTZ
);

-- Sequence for deterministic AID generation
CREATE SEQUENCE IF NOT EXISTS public.aid_seq START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE FUNCTION public.generate_aid()
RETURNS TEXT AS $$
BEGIN
    RETURN 'AID-HR-' || LPAD(nextval('public.aid_seq')::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- 3. Super Admin Invariant Constraint
-- Max 3 super admins total, exactly 1 primary non-deletable super admin
CREATE TABLE IF NOT EXISTS public.super_admin_invariants (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE RESTRICT,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE OR REPLACE FUNCTION public.check_super_admin_limits()
RETURNS TRIGGER AS $$
DECLARE
    super_count INTEGER;
    primary_count INTEGER;
BEGIN
    SELECT count(*) INTO super_count FROM public.super_admin_invariants;
    SELECT count(*) INTO primary_count FROM public.super_admin_invariants WHERE is_primary = TRUE;

    IF TG_OP = 'INSERT' THEN
        IF super_count >= 3 THEN
            RAISE EXCEPTION 'Maximum limit of 3 Super Admins reached';
        END IF;
        IF NEW.is_primary = TRUE AND primary_count >= 1 THEN
            RAISE EXCEPTION 'Only 1 Primary Super Admin is allowed';
        END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
        IF OLD.is_primary = TRUE THEN
            RAISE EXCEPTION 'Primary Super Admin account is permanent and cannot be deleted';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_super_admin_limits ON public.super_admin_invariants;
CREATE TRIGGER trg_super_admin_limits
    BEFORE INSERT OR UPDATE OR DELETE ON public.super_admin_invariants
    FOR EACH ROW EXECUTE FUNCTION public.check_super_admin_limits();

-- 4. Multi-Admin Termination Consensus (3-Admin Confirmation Queue)
CREATE TABLE IF NOT EXISTS public.account_termination_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    admin_voter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    voted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(target_user_id, admin_voter_id)
);

CREATE TABLE IF NOT EXISTS public.account_termination_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    votes_required INTEGER NOT NULL DEFAULT 3,
    status TEXT NOT NULL DEFAULT 'voting' CHECK (status IN ('voting', 'terminated', 'dismissed', 'superadmin_overridden')),
    terminated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. Multi-Lingual Profanity & Reserved Word Blocklist
CREATE TABLE IF NOT EXISTS public.profanity_and_reserved_terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    term TEXT NOT NULL UNIQUE,
    language TEXT NOT NULL CHECK (language IN ('english', 'tamil', 'hindi', 'system_reserved')),
    is_reserved_keyword BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Seed System Reserved Keywords
INSERT INTO public.profanity_and_reserved_terms (term, language, is_reserved_keyword)
VALUES 
    ('admin', 'system_reserved', TRUE),
    ('superadmin', 'system_reserved', TRUE),
    ('moderator', 'system_reserved', TRUE),
    ('mod', 'system_reserved', TRUE),
    ('police', 'system_reserved', TRUE),
    ('harur_police', 'system_reserved', TRUE),
    ('collector', 'system_reserved', TRUE),
    ('tahsildar', 'system_reserved', TRUE),
    ('government', 'system_reserved', TRUE),
    ('official', 'system_reserved', TRUE),
    ('news', 'system_reserved', TRUE),
    ('support', 'system_reserved', TRUE),
    ('help', 'system_reserved', TRUE),
    ('api', 'system_reserved', TRUE),
    ('verification', 'system_reserved', TRUE),
    ('emergency', 'system_reserved', TRUE),
    ('gh_harur', 'system_reserved', TRUE),
    ('ambulance', 'system_reserved', TRUE)
ON CONFLICT (term) DO NOTHING;

-- RLS Enforcement
ALTER TABLE public.staff_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_identifiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.super_admin_invariants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_termination_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_termination_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profanity_and_reserved_terms ENABLE ROW LEVEL SECURITY;

-- Read policies
CREATE POLICY "Public read admin identifiers" ON public.admin_identifiers FOR SELECT USING (true);
CREATE POLICY "Public read reserved terms" ON public.profanity_and_reserved_terms FOR SELECT USING (true);
