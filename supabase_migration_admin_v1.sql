-- supabase_migration_admin_v1.sql
-- Run this script in the Supabase SQL Editor to configure token enhancements, admin update bypasses, and admin-scoped RLS policies.

-- 1. Add columns to public.institution_assessment_tokens
alter table public.institution_assessment_tokens add column if not exists token_type text default 'institution';
alter table public.institution_assessment_tokens add column if not exists expires_at timestamptz;
alter table public.institution_assessment_tokens add column if not exists notes text;
alter table public.institution_assessment_tokens add column if not exists created_by uuid references public.profiles(id) on delete set null;

-- 2. Drop existing constraint if it exists and replace it to support 'disabled' status
alter table public.institution_assessment_tokens drop constraint if exists institution_assessment_tokens_status_check;
alter table public.institution_assessment_tokens add constraint institution_assessment_tokens_status_check check (status in ('available', 'assigned', 'used', 'disabled', 'expired'));

-- 3. Create a helper function to bypass RLS recursion check for admin validation
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
end;
$$ language plpgsql security definer set search_path = public, pg_temp;

-- 4. Adjust handle_update_profile_roles to allow admins to modify roles/statuses
create or replace function public.handle_update_profile_roles()
returns trigger as $$
begin
  -- Allow admins to bypass role/status update checks
  if public.is_admin() then
    return new;
  end if;

  -- Prevent updates to role or status from general users
  if (old.role <> new.role or old.status <> new.status) then
    raise exception 'Modifying role or status fields is restricted.';
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public, pg_temp;

-- 5. Enable full read/write admin access to all tables under RLS
drop policy if exists "Admins can view all profiles" on public.profiles;
create policy "Admins can view all profiles" on public.profiles
  for select using (public.is_admin());

drop policy if exists "Admins can update all profiles" on public.profiles;
create policy "Admins can update all profiles" on public.profiles
  for update using (public.is_admin());

drop policy if exists "Admins can view all student profiles" on public.student_profiles;
create policy "Admins can view all student profiles" on public.student_profiles
  for select using (public.is_admin());

drop policy if exists "Admins can view all institution profiles" on public.institution_profiles;
create policy "Admins can view all institution profiles" on public.institution_profiles
  for select using (public.is_admin());

drop policy if exists "Admins can update all institution profiles" on public.institution_profiles;
create policy "Admins can update all institution profiles" on public.institution_profiles
  for update using (public.is_admin());

drop policy if exists "Admins can view all counsellor profiles" on public.counsellor_profiles;
create policy "Admins can view all counsellor profiles" on public.counsellor_profiles
  for select using (public.is_admin());

drop policy if exists "Admins can update all counsellor profiles" on public.counsellor_profiles;
create policy "Admins can update all counsellor profiles" on public.counsellor_profiles
  for update using (public.is_admin());

drop policy if exists "Admins can view all orders" on public.orders;
create policy "Admins can view all orders" on public.orders
  for select using (public.is_admin());

drop policy if exists "Admins can view all payments" on public.payments;
create policy "Admins can view all payments" on public.payments
  for select using (public.is_admin());

drop policy if exists "Admins can view all assessment_access" on public.assessment_access;
create policy "Admins can view all assessment_access" on public.assessment_access
  for select using (public.is_admin());

drop policy if exists "Admins can insert all assessment_access" on public.assessment_access;
create policy "Admins can insert all assessment_access" on public.assessment_access
  for insert with check (public.is_admin());

drop policy if exists "Admins can view all tokens" on public.institution_assessment_tokens;
create policy "Admins can view all tokens" on public.institution_assessment_tokens
  for select using (public.is_admin());

drop policy if exists "Admins can insert all tokens" on public.institution_assessment_tokens;
create policy "Admins can insert all tokens" on public.institution_assessment_tokens
  for insert with check (public.is_admin());

drop policy if exists "Admins can update all tokens" on public.institution_assessment_tokens;
create policy "Admins can update all tokens" on public.institution_assessment_tokens
  for update using (public.is_admin());

drop policy if exists "Admins can view all identities" on public.ezeal_identities;
create policy "Admins can view all identities" on public.ezeal_identities
  for select using (public.is_admin());
