-- supabase_migration.sql
-- Run this script in the Supabase SQL Editor to set up the MVP authentication profiles.

-- ========================================================
-- 1. Create Tables
-- ========================================================

-- public.profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  phone text,
  role text not null check (role in ('student', 'admin', 'institution', 'counsellor')),
  status text not null default 'active' check (status in ('active', 'pending', 'rejected', 'suspended')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- public.student_profiles
create table if not exists public.student_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  education_stage text,
  city text,
  state text,
  profile_completion int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- public.institution_profiles
create table if not exists public.institution_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  institution_name text,
  institution_type text,
  contact_person text,
  city text,
  state text,
  approval_status text default 'pending' check (approval_status in ('pending', 'approved', 'rejected')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- public.counsellor_profiles
create table if not exists public.counsellor_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  specialization text,
  experience_years int,
  city text,
  state text,
  approval_status text default 'pending' check (approval_status in ('pending', 'approved', 'rejected')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ========================================================
-- 2. Trigger to Restrict Role/Status Changes
-- ========================================================

create or replace function public.handle_update_profile_roles()
returns trigger as $$
begin
  -- Prevent updates to role or status from general users
  if (old.role <> new.role or old.status <> new.status) then
    raise exception 'Modifying role or status fields is restricted.';
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if it exists
drop trigger if exists restrict_profile_updates on public.profiles;

create trigger restrict_profile_updates
  before update on public.profiles
  for each row
  execute function public.handle_update_profile_roles();

-- ========================================================
-- 3. Enable Row Level Security (RLS)
-- ========================================================

alter table public.profiles enable row level security;
alter table public.student_profiles enable row level security;
alter table public.institution_profiles enable row level security;
alter table public.counsellor_profiles enable row level security;

-- ========================================================
-- 4. Configure RLS Policies
-- ========================================================

-- profiles
create policy "Allow select own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Allow update own profile" on public.profiles
  for update using (auth.uid() = id);

create policy "Allow insert own profile" on public.profiles
  for insert to authenticated with check (auth.uid() = id);

-- student_profiles
create policy "Allow select own student profile" on public.student_profiles
  for select using (auth.uid() = user_id);

create policy "Allow update own student profile" on public.student_profiles
  for update using (auth.uid() = user_id);

create policy "Allow insert own student profile" on public.student_profiles
  for insert to authenticated with check (auth.uid() = user_id);

-- institution_profiles
create policy "Allow select own institution profile" on public.institution_profiles
  for select using (auth.uid() = user_id);

create policy "Allow update own institution profile" on public.institution_profiles
  for update using (auth.uid() = user_id);

create policy "Allow insert own institution profile" on public.institution_profiles
  for insert to authenticated with check (auth.uid() = user_id);

-- counsellor_profiles
create policy "Allow select own counsellor profile" on public.counsellor_profiles
  for select using (auth.uid() = user_id);

create policy "Allow update own counsellor profile" on public.counsellor_profiles
  for update using (auth.uid() = user_id);

create policy "Allow insert own counsellor profile" on public.counsellor_profiles
  for insert to authenticated with check (auth.uid() = user_id);
