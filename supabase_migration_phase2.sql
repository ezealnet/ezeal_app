-- supabase_migration_phase2.sql
-- Run this script in the Supabase SQL Editor to extend the student_profiles table for Phase 2.

ALTER TABLE public.student_profiles
  ADD COLUMN IF NOT EXISTS grade_or_year text,
  ADD COLUMN IF NOT EXISTS school_or_college text,
  ADD COLUMN IF NOT EXISTS board_or_university text,
  ADD COLUMN IF NOT EXISTS date_of_birth date,
  ADD COLUMN IF NOT EXISTS gender text;
