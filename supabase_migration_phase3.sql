-- supabase_migration_phase3.sql
-- Run this script in the Supabase SQL Editor to configure assessments and cart.

-- ========================================================
-- 1. Create assessments Table
-- ========================================================
create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique not null,
  description text,
  assessment_type text,
  duration_minutes int default 30,
  question_count int default 20,
  base_price int default 299,
  price_type text default 'paid',
  is_published boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ========================================================
-- 2. Create assessment_cart_items Table
-- ========================================================
create table if not exists public.assessment_cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, assessment_id)
);

-- ========================================================
-- 3. Enable Row Level Security (RLS)
-- ========================================================
alter table public.assessments enable row level security;
alter table public.assessment_cart_items enable row level security;

-- ========================================================
-- 4. RLS Policies
-- ========================================================

-- assessments
drop policy if exists "Allow select published assessments" on public.assessments;
create policy "Allow select published assessments" on public.assessments
  for select to authenticated using (is_published = true);

-- assessment_cart_items
drop policy if exists "Allow select own cart items" on public.assessment_cart_items;
create policy "Allow select own cart items" on public.assessment_cart_items
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "Allow insert own cart items" on public.assessment_cart_items;
create policy "Allow insert own cart items" on public.assessment_cart_items
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Allow delete own cart items" on public.assessment_cart_items;
create policy "Allow delete own cart items" on public.assessment_cart_items
  for delete to authenticated using (auth.uid() = user_id);

-- ========================================================
-- 5. Seed 5 default MVP assessments
-- ========================================================
insert into public.assessments (title, slug, description, assessment_type, duration_minutes, question_count, base_price, price_type, is_published)
values
  (
    'Career Interest Assessment', 
    'career-interest-assessment', 
    'Identify your primary career interests, occupational matches, and alignment with various industries.', 
    'RIASEC', 
    30, 
    20, 
    299, 
    'paid', 
    true
  ),
  (
    'Personality Assessment', 
    'personality-assessment', 
    'Discover your personality traits, behavioral styles, and how they match with specific professional environments.', 
    'BigFive', 
    30, 
    20, 
    299, 
    'paid', 
    true
  ),
  (
    'Aptitude Assessment', 
    'aptitude-assessment', 
    'Measure your cognitive strengths, verbal and logical reasoning skills, and quantitative intelligence capabilities.', 
    'Cognitive', 
    30, 
    20, 
    299, 
    'paid', 
    true
  ),
  (
    'Learning Style Assessment', 
    'learning-style-assessment', 
    'Understand how you naturally process, retain, and recall information to optimize your educational study habits.', 
    'VARK', 
    30, 
    20, 
    299, 
    'paid', 
    true
  ),
  (
    'Stream Selection Assessment', 
    'stream-selection-assessment', 
    'Evaluate your interests and academic strengths to choose the right subject stream (Science, Commerce, or Arts) for high school and university.', 
    'Academics', 
    30, 
    20, 
    299, 
    'paid', 
    true
  )
on conflict (slug) do update set
  title = excluded.title,
  description = excluded.description,
  duration_minutes = excluded.duration_minutes,
  question_count = excluded.question_count,
  base_price = excluded.base_price,
  price_type = excluded.price_type,
  is_published = excluded.is_published,
  updated_at = now();
