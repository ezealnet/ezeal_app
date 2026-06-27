-- supabase_migration_phase6.sql
-- Run this script in the Supabase SQL Editor to configure the assessment engine tables, RLS, and seed questions.

-- ========================================================
-- 1. Create assessment_questions Table
-- ========================================================
create table if not exists public.assessment_questions (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  question_text text not null,
  question_type text not null default 'single_choice',
  question_order int not null default 1,
  scoring_key text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ========================================================
-- 2. Create assessment_question_options Table
-- ========================================================
create table if not exists public.assessment_question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.assessment_questions(id) on delete cascade,
  option_text text not null,
  option_value text not null,
  option_order int not null default 1,
  score_value int default 0,
  created_at timestamptz default now()
);

-- ========================================================
-- 3. Create assessment_engine_configs Table
-- ========================================================
create table if not exists public.assessment_engine_configs (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  passing_required boolean default false,
  allow_resume boolean default true,
  randomize_questions boolean default false,
  randomize_options boolean default false,
  show_progress boolean default true,
  duration_minutes int default 30,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(assessment_id)
);

-- ========================================================
-- 4. Enable Row Level Security (RLS)
-- ========================================================
alter table public.assessment_questions enable row level security;
alter table public.assessment_question_options enable row level security;
alter table public.assessment_engine_configs enable row level security;

-- ========================================================
-- 5. RLS Policies
-- ========================================================

-- assessment_questions: read-only for authenticated, active questions of published assessments
drop policy if exists "Allow select questions for published assessments" on public.assessment_questions;
create policy "Allow select questions for published assessments" on public.assessment_questions
  for select to authenticated
  using (
    is_active = true and
    exists (
      select 1 from public.assessments
      where assessments.id = assessment_questions.assessment_id
        and assessments.is_published = true
    )
  );

-- assessment_question_options: read-only for authenticated, options of active questions of published assessments
drop policy if exists "Allow select options for published assessments" on public.assessment_question_options;
create policy "Allow select options for published assessments" on public.assessment_question_options
  for select to authenticated
  using (
    exists (
      select 1 from public.assessment_questions q
      join public.assessments a on a.id = q.assessment_id
      where q.id = assessment_question_options.question_id
        and q.is_active = true
        and a.is_published = true
    )
  );

-- assessment_engine_configs: read-only for authenticated, configs of published assessments
drop policy if exists "Allow select configs for published assessments" on public.assessment_engine_configs;
create policy "Allow select configs for published assessments" on public.assessment_engine_configs
  for select to authenticated
  using (
    exists (
      select 1 from public.assessments
      where assessments.id = assessment_engine_configs.assessment_id
        and assessments.is_published = true
    )
  );

-- Admin manage policies TODO comments:
-- TODO: Add admin insert/update/delete policies for questions, options, and configs later.
-- TODO: Add author insert/update/delete policies for assessments authoring workspace later.

-- ========================================================
-- 6. Clean Existing Seeds (Idempotence)
-- ========================================================
delete from public.assessment_engine_configs;
delete from public.assessment_question_options;
delete from public.assessment_questions;

-- ========================================================
-- 7. Seed Engine Configs & Questions
-- ========================================================

-- --------------------------------------------------------
-- A. Career Interest Assessment (RIASEC)
-- --------------------------------------------------------
insert into public.assessment_engine_configs (assessment_id, passing_required, allow_resume, randomize_questions, randomize_options, show_progress, duration_minutes)
select id, false, true, false, false, true, 30 from public.assessments where slug = 'career-interest-assessment';

-- Q1
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'How do you prefer to spend your free time?', 'single_choice', 1, 'riasec' from public.assessments where slug = 'career-interest-assessment';

with q as (select id from public.assessment_questions where question_text = 'How do you prefer to spend your free time?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Working on hands-on craft or repair projects', 'A', 1, 4 from q union all select id, 'Conducting research or reading science topics', 'B', 2, 3 from q union all select id, 'Painting, writing music, or reading literature', 'C', 3, 2 from q union all select id, 'Volunteering at a community center or helping friends', 'D', 4, 1 from q;

-- Q2
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'Which work environment sounds most appealing to you?', 'single_choice', 2, 'riasec' from public.assessments where slug = 'career-interest-assessment';

with q as (select id from public.assessment_questions where question_text = 'Which work environment sounds most appealing to you?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'An outdoor site or workshop using specialized tools', 'A', 1, 4 from q union all select id, 'A research lab analyzing complex data points', 'B', 2, 3 from q union all select id, 'A creative studio where I can set my own agenda', 'C', 3, 2 from q union all select id, 'A non-profit office coordinating team projects', 'D', 4, 1 from q;

-- Q3
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'What kind of projects do you enjoy working on?', 'single_choice', 3, 'riasec' from public.assessments where slug = 'career-interest-assessment';

with q as (select id from public.assessment_questions where question_text = 'What kind of projects do you enjoy working on?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Building furniture or maintaining mechanical systems', 'A', 1, 4 from q union all select id, 'Programming code or solving engineering problems', 'B', 2, 3 from q union all select id, 'Designing graphics, marketing copy, or artwork', 'C', 3, 2 from q union all select id, 'Teaching others a new skill or coaching a sport', 'D', 4, 1 from q;

-- Q4
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'How do you tackle complex problems?', 'single_choice', 4, 'riasec' from public.assessments where slug = 'career-interest-assessment';

with q as (select id from public.assessment_questions where question_text = 'How do you tackle complex problems?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'By finding a practical, physical solution', 'A', 1, 4 from q union all select id, 'By searching for scientific evidence and testing hypotheses', 'B', 2, 3 from q union all select id, 'By thinking outside the box and experimenting creatively', 'C', 3, 2 from q union all select id, 'By discussing with a group to find consensus', 'D', 4, 1 from q;

-- Q5
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'Which role in a startup appeals to you most?', 'single_choice', 5, 'riasec' from public.assessments where slug = 'career-interest-assessment';

with q as (select id from public.assessment_questions where question_text = 'Which role in a startup appeals to you most?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Operations manager overseeing physical assets', 'A', 1, 4 from q union all select id, 'Lead developer researching technical architecture', 'B', 2, 3 from q union all select id, 'Creative director managing UI/UX design', 'C', 3, 2 from q union all select id, 'Community relations lead coordinating user support', 'D', 4, 1 from q;


-- --------------------------------------------------------
-- B. Personality Assessment (BigFive)
-- --------------------------------------------------------
insert into public.assessment_engine_configs (assessment_id, passing_required, allow_resume, randomize_questions, randomize_options, show_progress, duration_minutes)
select id, false, true, false, false, true, 30 from public.assessments where slug = 'personality-assessment';

-- Q1
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'When in a social gathering, you usually...', 'single_choice', 1, 'bigfive' from public.assessments where slug = 'personality-assessment';

with q as (select id from public.assessment_questions where question_text = 'When in a social gathering, you usually...')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Actively talk to new people and initiate conversations', 'A', 1, 4 from q union all select id, 'Prefer to talk only to close friends', 'B', 2, 3 from q union all select id, 'Feel overwhelmed and seek a quiet spot', 'C', 3, 2 from q union all select id, 'Keep to yourself and observe', 'D', 4, 1 from q;

-- Q2
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'How do you organize your work/study projects?', 'single_choice', 2, 'bigfive' from public.assessments where slug = 'personality-assessment';

with q as (select id from public.assessment_questions where question_text = 'How do you organize your work/study projects?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Create detailed schedules and checklist goals', 'A', 1, 4 from q union all select id, 'Start immediately and adjust dynamically as I go', 'B', 2, 3 from q union all select id, 'Prefer a flexible arrangement without hard dates', 'C', 3, 2 from q union all select id, 'Procrastinate but finish under pressure', 'D', 4, 1 from q;

-- Q3
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'Faced with sudden change or unexpected issues, you...', 'single_choice', 3, 'bigfive' from public.assessments where slug = 'personality-assessment';

with q as (select id from public.assessment_questions where question_text = 'Faced with sudden change or unexpected issues, you...')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Stay calm, positive, and work out logical next steps', 'A', 1, 4 from q union all select id, 'Look for creative alternatives and opportunities', 'B', 2, 3 from q union all select id, 'Reach out to collaborate with peers', 'C', 3, 2 from q union all select id, 'Double down on existing project guidelines', 'D', 4, 1 from q;

-- Q4
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'When learning new concepts, you are mostly drawn to...', 'single_choice', 4, 'bigfive' from public.assessments where slug = 'personality-assessment';

with q as (select id from public.assessment_questions where question_text = 'When learning new concepts, you are mostly drawn to...')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Abstract theories, art, and philosophical discussions', 'A', 1, 4 from q union all select id, 'Practical applications, case studies, and procedures', 'B', 2, 3 from q union all select id, 'Peer discussions and group work', 'C', 3, 2 from q union all select id, 'Individual study with minimal instruction', 'D', 4, 1 from q;

-- Q5
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'In group discussions, you prioritize...', 'single_choice', 5, 'bigfive' from public.assessments where slug = 'personality-assessment';

with q as (select id from public.assessment_questions where question_text = 'In group discussions, you prioritize...')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Ensuring harmony and listening to all perspectives', 'A', 1, 4 from q union all select id, 'Keeping discussions structured and on-topic', 'B', 2, 3 from q union all select id, 'Expressing my own views and debating ideas', 'C', 3, 2 from q union all select id, 'Analyzing details with calm reasoning', 'D', 4, 1 from q;


-- --------------------------------------------------------
-- C. Aptitude Assessment (Cognitive)
-- --------------------------------------------------------
insert into public.assessment_engine_configs (assessment_id, passing_required, allow_resume, randomize_questions, randomize_options, show_progress, duration_minutes)
select id, true, true, false, false, true, 30 from public.assessments where slug = 'aptitude-assessment';

-- Q1
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'Which number completes the pattern: 2, 4, 8, 16, ...?', 'single_choice', 1, 'cognitive' from public.assessments where slug = 'aptitude-assessment';

with q as (select id from public.assessment_questions where question_text = 'Which number completes the pattern: 2, 4, 8, 16, ...?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, '32', 'A', 1, 4 from q union all select id, '24', 'B', 2, 1 from q union all select id, '20', 'C', 3, 2 from q union all select id, '64', 'D', 4, 3 from q;

-- Q2
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'Choose the word most opposite in meaning to Generic:', 'single_choice', 2, 'cognitive' from public.assessments where slug = 'aptitude-assessment';

with q as (select id from public.assessment_questions where question_text = 'Choose the word most opposite in meaning to Generic:')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Specific', 'A', 1, 4 from q union all select id, 'Common', 'B', 2, 1 from q union all select id, 'Broad', 'C', 3, 2 from q union all select id, 'Simple', 'D', 4, 3 from q;

-- Q3
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'If all A are B, and all B are C, then:', 'single_choice', 3, 'cognitive' from public.assessments where slug = 'aptitude-assessment';

with q as (select id from public.assessment_questions where question_text = 'If all A are B, and all B are C, then:')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'All A are C', 'A', 1, 4 from q union all select id, 'All C are A', 'B', 2, 1 from q union all select id, 'Some B are not A', 'C', 3, 2 from q union all select id, 'No A is C', 'D', 4, 3 from q;

-- Q4
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'How many faces does a standard cube have?', 'single_choice', 4, 'cognitive' from public.assessments where slug = 'aptitude-assessment';

with q as (select id from public.assessment_questions where question_text = 'How many faces does a standard cube have?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, '6', 'A', 1, 4 from q union all select id, '8', 'B', 2, 2 from q union all select id, '12', 'C', 3, 1 from q union all select id, '4', 'D', 4, 3 from q;

-- Q5
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'Determine the missing letter in the sequence: A, C, E, G, ...?', 'single_choice', 5, 'cognitive' from public.assessments where slug = 'aptitude-assessment';

with q as (select id from public.assessment_questions where question_text = 'Determine the missing letter in the sequence: A, C, E, G, ...?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'I', 'A', 1, 4 from q union all select id, 'H', 'B', 2, 2 from q union all select id, 'J', 'C', 3, 1 from q union all select id, 'K', 'D', 4, 3 from q;


-- --------------------------------------------------------
-- D. Learning Style Assessment (VARK)
-- --------------------------------------------------------
insert into public.assessment_engine_configs (assessment_id, passing_required, allow_resume, randomize_questions, randomize_options, show_progress, duration_minutes)
select id, false, true, false, false, true, 30 from public.assessments where slug = 'learning-style-assessment';

-- Q1
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'When assembling a complex product, you prefer to...', 'single_choice', 1, 'vark' from public.assessments where slug = 'learning-style-assessment';

with q as (select id from public.assessment_questions where question_text = 'When assembling a complex product, you prefer to...')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Look at diagram illustrations and graphics', 'A', 1, 4 from q union all select id, 'Listen to someone explain the steps', 'B', 2, 2 from q union all select id, 'Read the printed instruction manual', 'C', 3, 3 from q union all select id, 'Start putting pieces together directly', 'D', 4, 1 from q;

-- Q2
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'During a presentation, you retain information best when...', 'single_choice', 2, 'vark' from public.assessments where slug = 'learning-style-assessment';

with q as (select id from public.assessment_questions where question_text = 'During a presentation, you retain information best when...')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Colored slides and videos are shown', 'A', 1, 4 from q union all select id, 'The speaker has a clear voice and tells stories', 'B', 2, 2 from q union all select id, 'There are handouts or text summaries on screen', 'C', 3, 3 from q union all select id, 'There is an interactive workshop or exercise', 'D', 4, 1 from q;

-- Q3
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'If you need to learn a new software tool, you will...', 'single_choice', 3, 'vark' from public.assessments where slug = 'learning-style-assessment';

with q as (select id from public.assessment_questions where question_text = 'If you need to learn a new software tool, you will...')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Watch video tutorials online', 'A', 1, 4 from q union all select id, 'Ask a colleague to talk you through it', 'B', 2, 2 from q union all select id, 'Read help guides or user documentation', 'C', 3, 3 from q union all select id, 'Practice clicking through features yourself', 'D', 4, 1 from q;

-- Q4
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'When remembering things, you usually picture:', 'single_choice', 4, 'vark' from public.assessments where slug = 'learning-style-assessment';

with q as (select id from public.assessment_questions where question_text = 'When remembering things, you usually picture:')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Visual layouts, colors, or faces', 'A', 1, 4 from q union all select id, 'Spoken words, sounds, or voices', 'B', 2, 2 from q union all select id, 'Lists, text, or written notes', 'C', 3, 3 from q union all select id, 'The physical actions or hands-on feelings', 'D', 4, 1 from q;

-- Q5
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'Your favorite school subject activities are...', 'single_choice', 5, 'vark' from public.assessments where slug = 'learning-style-assessment';

with q as (select id from public.assessment_questions where question_text = 'Your favorite school subject activities are...')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Analyzing charts, maps, and visual media', 'A', 1, 4 from q union all select id, 'Class debates, lectures, and group sharing', 'B', 2, 2 from q union all select id, 'Reading textbooks and writing summaries', 'C', 3, 3 from q union all select id, 'Lab experiments, physical models, and field trips', 'D', 4, 1 from q;


-- --------------------------------------------------------
-- E. Stream Selection Assessment (Academics)
-- --------------------------------------------------------
insert into public.assessment_engine_configs (assessment_id, passing_required, allow_resume, randomize_questions, randomize_options, show_progress, duration_minutes)
select id, false, true, false, false, true, 30 from public.assessments where slug = 'stream-selection-assessment';

-- Q1
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'Which subjects do you enjoy studying the most?', 'single_choice', 1, 'academics' from public.assessments where slug = 'stream-selection-assessment';

with q as (select id from public.assessment_questions where question_text = 'Which subjects do you enjoy studying the most?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Physics, Chemistry, and Mathematics', 'A', 1, 4 from q union all select id, 'Accountancy, Business Studies, and Economics', 'B', 2, 2 from q union all select id, 'History, Political Science, and Literature', 'C', 3, 3 from q union all select id, 'Applied IT, Design Technology, or Crafts', 'D', 4, 1 from q;

-- Q2
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'What kind of career projects excite you?', 'single_choice', 2, 'academics' from public.assessments where slug = 'stream-selection-assessment';

with q as (select id from public.assessment_questions where question_text = 'What kind of career projects excite you?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Researching medical cures or building space rockets', 'A', 1, 4 from q union all select id, 'Managing financial portfolios or running a business', 'B', 2, 2 from q union all select id, 'Writing scripts, painting, or planning policy campaigns', 'C', 3, 3 from q union all select id, 'Welding, carpentry, or electrical installation projects', 'D', 4, 1 from q;

-- Q3
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'How do you prefer to analyze historical events?', 'single_choice', 3, 'academics' from public.assessments where slug = 'stream-selection-assessment';

with q as (select id from public.assessment_questions where question_text = 'How do you prefer to analyze historical events?')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Using data models, statistical correlation, and evidence', 'A', 1, 4 from q union all select id, 'Looking at trade, supply routes, and economic impacts', 'B', 2, 2 from q union all select id, 'Reading diaries, culture studies, and political movements', 'C', 3, 3 from q union all select id, 'Rebuilding historical tools or physical replicas', 'D', 4, 1 from q;

-- Q4
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'When visiting a museum, you spend the most time at:', 'single_choice', 4, 'academics' from public.assessments where slug = 'stream-selection-assessment';

with q as (select id from public.assessment_questions where question_text = 'When visiting a museum, you spend the most time at:')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Interactive chemistry labs and astronomy domes', 'A', 1, 4 from q union all select id, 'Gift shop business models or visitor logistics data', 'B', 2, 2 from q union all select id, 'History of science exhibits or philosophy corners', 'C', 3, 3 from q union all select id, 'Heavy machinery simulators and hands-on workshops', 'D', 4, 1 from q;

-- Q5
insert into public.assessment_questions (assessment_id, question_text, question_type, question_order, scoring_key)
select id, 'If you had to choose a volunteer project, you would:', 'single_choice', 5, 'academics' from public.assessments where slug = 'stream-selection-assessment';

with q as (select id from public.assessment_questions where question_text = 'If you had to choose a volunteer project, you would:')
insert into public.assessment_question_options (question_id, option_text, option_value, option_order, score_value) select id, 'Help test water quality in local reservoirs', 'A', 1, 4 from q union all select id, 'Audit the fundraising budget of a local NGO', 'B', 2, 2 from q union all select id, 'Paint community murals or write newsletters', 'C', 3, 3 from q union all select id, 'Help repair facilities or set up technical sound systems', 'D', 4, 1 from q;
