-- ==============================================================================
-- MYHARUR: FULL PRODUCTION SCHEMA, AUDIT LOGGING & ROOT SUPER ADMIN SEED
-- Copy and paste this directly into Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. PROFILES TABLE (With MMID, Personal Details & Roles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    mmid TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL DEFAULT 'Harur Resident',
    email TEXT,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'resident' CHECK (role IN ('resident', 'shop_admin', 'event_head', 'admin', 'superadmin')),
    avatar_url TEXT,
    ward_locality TEXT DEFAULT 'Harur Town',
    blood_group TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    bio TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. CRUD & SECURITY AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS public.crud_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_mmid TEXT,
    action TEXT NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'EMERGENCY_BROADCAST', 'CONSENSUS_VOTE'
    table_name TEXT NOT NULL,
    record_id TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. NEWS ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.news_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Civic',
    locality TEXT NOT NULL DEFAULT 'Harur',
    source_name TEXT DEFAULT 'Local Report',
    source_url TEXT,
    image_path TEXT,
    status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('pending', 'published', 'rejected', 'archived')),
    submitted_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. MARKETPLACE LISTINGS
CREATE TABLE IF NOT EXISTS public.marketplace_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    condition TEXT NOT NULL DEFAULT 'like_new',
    category TEXT NOT NULL DEFAULT 'Farm & Tools',
    location_name TEXT NOT NULL DEFAULT 'Harur',
    contact_phone TEXT,
    is_sold BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. SHOPS & STOREFRONTS
CREATE TABLE IF NOT EXISTS public.shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Groceries & Agro',
    description TEXT,
    address TEXT NOT NULL DEFAULT 'Bazaar Street, Harur',
    phone TEXT NOT NULL,
    rating_score NUMERIC(3, 2) DEFAULT 4.9,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 6. JOBS BOARD
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    company_or_farm TEXT NOT NULL,
    job_type TEXT NOT NULL DEFAULT 'full_time',
    description TEXT NOT NULL,
    salary_range TEXT,
    location_name TEXT NOT NULL DEFAULT 'Harur',
    contact_phone TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 7. EVENTS & TOURNAMENTS
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    venue TEXT NOT NULL,
    event_type TEXT NOT NULL DEFAULT 'tournaments',
    description TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days'),
    end_time TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '9 days'),
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    external_registration_url TEXT,
    status TEXT NOT NULL DEFAULT 'approved',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 8. REAL-TIME CHAT MESSAGES
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_name TEXT NOT NULL DEFAULT 'public_town',
    sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    sender_name TEXT NOT NULL DEFAULT 'Harur Resident',
    sender_mmid TEXT NOT NULL DEFAULT 'MMID-RESIDENT',
    sender_role TEXT NOT NULL DEFAULT 'Resident',
    text TEXT NOT NULL,
    attachment_url TEXT,
    is_official BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 9. EMERGENCY BROADCASTS
CREATE TABLE IF NOT EXISTS public.emergency_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    broadcaster_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    emergency_type TEXT NOT NULL,
    latitude NUMERIC(9,6) NOT NULL,
    longitude NUMERIC(9,6) NOT NULL,
    radius_km INTEGER NOT NULL DEFAULT 5,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- SEED ROOT SUPER ADMIN (admin.qenbel@gmail.com / admin@qenbel)
-- ==============================================================================
DO $$
DECLARE
    super_admin_uid UUID := 'a0000000-0000-0000-0000-000000000001';
BEGIN
    -- 1. Insert into auth.users if not exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin.qenbel@gmail.com') THEN
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            role,
            aud
        ) VALUES (
            super_admin_uid,
            '00000000-0000-0000-0000-000000000000',
            'admin.qenbel@gmail.com',
            crypt('admin@qenbel', gen_salt('bf')),
            now(),
            '{"provider":"email","providers":["email"]}',
            '{"full_name":"Root SuperAdmin Qenbel","role":"superadmin"}',
            now(),
            now(),
            'authenticated',
            'authenticated'
        );
    ELSE
        SELECT id INTO super_admin_uid FROM auth.users WHERE email = 'admin.qenbel@gmail.com';
    END IF;

    -- 2. Insert into public.profiles
    INSERT INTO public.profiles (
        id,
        mmid,
        full_name,
        email,
        phone,
        role,
        ward_locality,
        bio,
        is_verified
    ) VALUES (
        super_admin_uid,
        'SUPERADMIN-0001',
        'Root SuperAdmin Qenbel',
        'admin.qenbel@gmail.com',
        '+919944005500',
        'superadmin',
        'Harur Town HQ',
        'Chief System Administrator & Governance Root for MyHarur Digital Town.',
        TRUE
    ) ON CONFLICT (id) DO UPDATE SET
        role = 'superadmin',
        full_name = 'Root SuperAdmin Qenbel',
        updated_at = now();

    -- 3. Log the system seed event in audit logs
    INSERT INTO public.crud_audit_logs (
        user_id,
        user_mmid,
        action,
        table_name,
        record_id,
        details
    ) VALUES (
        super_admin_uid,
        'SUPERADMIN-0001',
        'SYSTEM_SEED',
        'profiles',
        super_admin_uid::text,
        '{"note":"Root SuperAdmin initialized successfully with credentials admin.qenbel@gmail.com"}'::jsonb
    );
END $$;

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crud_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.news_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_events ENABLE ROW LEVEL SECURITY;

-- Public read policies
CREATE POLICY "Public read profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Public read news" ON public.news_items FOR SELECT USING (true);
CREATE POLICY "Authenticated insert news" ON public.news_items FOR INSERT WITH CHECK (true);

CREATE POLICY "Public read marketplace" ON public.marketplace_listings FOR SELECT USING (true);
CREATE POLICY "Authenticated insert marketplace" ON public.marketplace_listings FOR INSERT WITH CHECK (true);

CREATE POLICY "Public read shops" ON public.shops FOR SELECT USING (true);
CREATE POLICY "Authenticated insert shops" ON public.shops FOR INSERT WITH CHECK (true);

CREATE POLICY "Public read jobs" ON public.jobs FOR SELECT USING (true);
CREATE POLICY "Authenticated insert jobs" ON public.jobs FOR INSERT WITH CHECK (true);

CREATE POLICY "Public read events" ON public.events FOR SELECT USING (true);
CREATE POLICY "Authenticated insert events" ON public.events FOR INSERT WITH CHECK (true);

CREATE POLICY "Public read chat" ON public.chat_messages FOR SELECT USING (true);
CREATE POLICY "Authenticated insert chat" ON public.chat_messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Public read audit logs for admins" ON public.crud_audit_logs FOR SELECT USING (true);
CREATE POLICY "Public insert audit logs" ON public.crud_audit_logs FOR INSERT WITH CHECK (true);
