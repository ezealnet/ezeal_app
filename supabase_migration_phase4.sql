-- supabase_migration_phase4.sql
-- Run this script in the Supabase SQL Editor to configure Ezeal identity verification.

-- ========================================================
-- 1. Create ezeal_identities Table
-- ========================================================
create table if not exists public.ezeal_identities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  ezeal_id text unique not null,
  role_type text not null check (role_type in ('student','author','institution','counsellor','admin')),
  aadhaar_verified boolean default false,
  verification_status text default 'pending' check (verification_status in ('pending','verified','failed')),
  verification_provider text default 'mock',
  verification_reference text,
  verified_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, role_type)
);

-- ========================================================
-- 2. Enable Row Level Security (RLS)
-- ========================================================
alter table public.ezeal_identities enable row level security;

-- ========================================================
-- 3. RLS Policies
-- ========================================================

-- SELECT Policy
drop policy if exists "Users can view own identity" on public.ezeal_identities;
create policy "Users can view own identity" on public.ezeal_identities
  for select to authenticated using (auth.uid() = user_id);

-- INSERT Policy
drop policy if exists "Users can insert own identity" on public.ezeal_identities;
create policy "Users can insert own identity" on public.ezeal_identities
  for insert to authenticated with check (auth.uid() = user_id);
