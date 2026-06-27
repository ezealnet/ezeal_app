-- supabase_migration_phase5.sql
-- Run this script in the Supabase SQL Editor to configure orders, payments, access, and tokens.

-- ========================================================
-- 1. Create orders Table
-- ========================================================
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  ezeal_identity_id uuid references public.ezeal_identities(id) on delete set null,
  amount int not null,
  status text default 'created' check (status in ('created','paid','failed','cancelled')),
  access_source text default 'individual' check (access_source in ('individual','institution')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ========================================================
-- 2. Create payments Table
-- ========================================================
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  provider text default 'mock',
  provider_payment_id text,
  amount int not null,
  status text default 'success' check (status in ('success','failed')),
  paid_at timestamptz default now()
);

-- ========================================================
-- 3. Create assessment_access Table
-- ========================================================
create table if not exists public.assessment_access (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  ezeal_identity_id uuid references public.ezeal_identities(id) on delete set null,
  order_id uuid references public.orders(id) on delete set null,
  access_source text not null check (access_source in ('individual','institution')),
  status text default 'unlocked' check (status in ('unlocked','started','completed','expired')),
  created_at timestamptz default now(),
  unique(user_id, assessment_id)
);

-- ========================================================
-- 4. Create institution_assessment_tokens Table
-- ========================================================
create table if not exists public.institution_assessment_tokens (
  id uuid primary key default gen_random_uuid(),
  token_code text unique not null,
  institution_id uuid references public.profiles(id) on delete set null,
  assessment_id uuid references public.assessments(id) on delete set null,
  assigned_student_id uuid references public.profiles(id) on delete set null,
  status text default 'available' check (status in ('available','assigned','used','expired')),
  created_at timestamptz default now(),
  used_at timestamptz
);

-- ========================================================
-- 5. Enable Row Level Security (RLS)
-- ========================================================
alter table public.orders enable row level security;
alter table public.payments enable row level security;
alter table public.assessment_access enable row level security;
alter table public.institution_assessment_tokens enable row level security;

-- ========================================================
-- 6. RLS Policies
-- ========================================================

-- orders
drop policy if exists "Users can view own orders" on public.orders;
create policy "Users can view own orders" on public.orders
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "Users can insert own orders" on public.orders;
create policy "Users can insert own orders" on public.orders
  for insert to authenticated with check (auth.uid() = user_id);

-- payments
drop policy if exists "Users can view own payments" on public.payments;
create policy "Users can view own payments" on public.payments
  for select to authenticated using (
    exists (select 1 from public.orders where orders.id = order_id and orders.user_id = auth.uid())
  );

drop policy if exists "Users can insert own payments" on public.payments;
create policy "Users can insert own payments" on public.payments
  for insert to authenticated with check (
    exists (select 1 from public.orders where orders.id = order_id and orders.user_id = auth.uid())
  );

-- assessment_access
drop policy if exists "Users can view own assessment_access" on public.assessment_access;
create policy "Users can view own assessment_access" on public.assessment_access
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "Users can insert own assessment_access" on public.assessment_access;
create policy "Users can insert own assessment_access" on public.assessment_access
  for insert to authenticated with check (auth.uid() = user_id);

-- institution_assessment_tokens
drop policy if exists "Users can view assigned tokens" on public.institution_assessment_tokens;
create policy "Users can view assigned tokens" on public.institution_assessment_tokens
  for select to authenticated using (assigned_student_id is null or assigned_student_id = auth.uid());

drop policy if exists "Users can update tokens to redeem" on public.institution_assessment_tokens;
create policy "Users can update tokens to redeem" on public.institution_assessment_tokens
  for update to authenticated using (assigned_student_id is null or assigned_student_id = auth.uid());

-- ========================================================
-- 7. Seed 5 mock institution tokens
-- ========================================================
insert into public.institution_assessment_tokens (token_code, assessment_id, status)
select 'MOCK-TOKEN-RIASEC', id, 'available' from public.assessments where slug = 'career-interest-assessment'
on conflict (token_code) do update set status = 'available', used_at = null, assigned_student_id = null;

insert into public.institution_assessment_tokens (token_code, assessment_id, status)
select 'MOCK-TOKEN-PERSONALITY', id, 'available' from public.assessments where slug = 'personality-assessment'
on conflict (token_code) do update set status = 'available', used_at = null, assigned_student_id = null;

insert into public.institution_assessment_tokens (token_code, assessment_id, status)
select 'MOCK-TOKEN-APTITUDE', id, 'available' from public.assessments where slug = 'aptitude-assessment'
on conflict (token_code) do update set status = 'available', used_at = null, assigned_student_id = null;

insert into public.institution_assessment_tokens (token_code, assessment_id, status)
select 'MOCK-TOKEN-LEARNING', id, 'available' from public.assessments where slug = 'learning-style-assessment'
on conflict (token_code) do update set status = 'available', used_at = null, assigned_student_id = null;

insert into public.institution_assessment_tokens (token_code, assessment_id, status)
select 'MOCK-TOKEN-STREAM', id, 'available' from public.assessments where slug = 'stream-selection-assessment'
on conflict (token_code) do update set status = 'available', used_at = null, assigned_student_id = null;
