-- supabase_migration_phase7a.sql
-- Run this script in the Supabase SQL Editor to configure the assessment runner, attempt tracking, answers, and sessions.

-- ========================================================
-- 1. Create assessment_attempts Table
-- ========================================================
create table if not exists public.assessment_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  assessment_access_id uuid not null references public.assessment_access(id) on delete cascade,
  status text default 'in_progress' check (status in ('in_progress','submitted','abandoned')),
  started_at timestamptz default now(),
  submitted_at timestamptz,
  current_question_index int default 0,
  answered_count int default 0,
  completion_percentage numeric default 0,
  last_active_at timestamptz default now(),
  version int default 1,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ========================================================
-- 2. Create assessment_answers Table
-- ========================================================
create table if not exists public.assessment_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.assessment_attempts(id) on delete cascade,
  question_id uuid not null references public.assessment_questions(id) on delete cascade,
  selected_option_id uuid references public.assessment_question_options(id) on delete set null,
  answer_value text,
  answered_at timestamptz default now(),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(attempt_id, question_id)
);

-- ========================================================
-- 3. Create assessment_sessions Table
-- ========================================================
create table if not exists public.assessment_sessions (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.assessment_attempts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  started_at timestamptz default now(),
  last_active_at timestamptz default now(),
  resume_count int default 0,
  device_type text,
  browser_name text,
  session_status text default 'active' check (session_status in ('active','paused','completed')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ========================================================
-- 4. Enable Row Level Security (RLS)
-- ========================================================
alter table public.assessment_attempts enable row level security;
alter table public.assessment_answers enable row level security;
alter table public.assessment_sessions enable row level security;

-- ========================================================
-- 5. RLS Policies
-- ========================================================

-- Policies for assessment_attempts
drop policy if exists "Users can view own attempts" on public.assessment_attempts;
create policy "Users can view own attempts" on public.assessment_attempts
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "Users can insert own attempts" on public.assessment_attempts;
create policy "Users can insert own attempts" on public.assessment_attempts
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users can update own attempts" on public.assessment_attempts;
create policy "Users can update own attempts" on public.assessment_attempts
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Policies for assessment_answers
drop policy if exists "Users can view own answers" on public.assessment_answers;
create policy "Users can view own answers" on public.assessment_answers
  for select to authenticated using (
    exists (
      select 1 from public.assessment_attempts 
      where assessment_attempts.id = attempt_id 
      and assessment_attempts.user_id = auth.uid()
    )
  );

drop policy if exists "Users can insert own answers" on public.assessment_answers;
create policy "Users can insert own answers" on public.assessment_answers
  for insert to authenticated with check (
    exists (
      select 1 from public.assessment_attempts 
      where assessment_attempts.id = attempt_id 
      and assessment_attempts.user_id = auth.uid()
      and assessment_attempts.status = 'in_progress'
    )
  );

drop policy if exists "Users can update own answers" on public.assessment_answers;
create policy "Users can update own answers" on public.assessment_answers
  for update to authenticated using (
    exists (
      select 1 from public.assessment_attempts 
      where assessment_attempts.id = attempt_id 
      and assessment_attempts.user_id = auth.uid()
      and assessment_attempts.status = 'in_progress'
    )
  ) with check (
    exists (
      select 1 from public.assessment_attempts 
      where assessment_attempts.id = attempt_id 
      and assessment_attempts.user_id = auth.uid()
      and assessment_attempts.status = 'in_progress'
    )
  );

-- Policies for assessment_sessions
drop policy if exists "Users can view own sessions" on public.assessment_sessions;
create policy "Users can view own sessions" on public.assessment_sessions
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "Users can insert own sessions" on public.assessment_sessions;
create policy "Users can insert own sessions" on public.assessment_sessions
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users can update own sessions" on public.assessment_sessions;
create policy "Users can update own sessions" on public.assessment_sessions
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
