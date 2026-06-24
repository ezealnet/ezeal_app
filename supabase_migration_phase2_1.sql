-- supabase_migration_phase2_1.sql
-- Run this script in the Supabase SQL Editor to add education_metadata jsonb field to student_profiles.

ALTER TABLE public.student_profiles
  ADD COLUMN IF NOT EXISTS education_metadata jsonb;
