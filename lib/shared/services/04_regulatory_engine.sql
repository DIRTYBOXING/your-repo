-- ==============================================================================
-- DFC BACKEND - MODULE 4: REGULATORY ENGINE (MEDICAL & OFFICIALS)
-- ==============================================================================

-- 1. Create the Medical Checks Table
CREATE TABLE public.medical_checks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fighter_id UUID REFERENCES public.fighters(id) ON DELETE CASCADE,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  check_type TEXT NOT NULL, -- 'pre_fight' or 'post_fight'
  heart_rate INT,
  blood_pressure TEXT,
  passed BOOLEAN DEFAULT FALSE,
  concussion_cleared BOOLEAN DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the Suspensions Table
CREATE TABLE public.suspensions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fighter_id UUID REFERENCES public.fighters(id) ON DELETE CASCADE,
  medical_check_id UUID REFERENCES public.medical_checks(id) ON DELETE SET NULL,
  reason TEXT NOT NULL, -- 'KO', 'TKO', 'Cut', 'Medical'
  days INT NOT NULL,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Judges' Scores Table
CREATE TABLE public.judges_scores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fight_id UUID REFERENCES public.fights(id) ON DELETE CASCADE,
  judge_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  round_num INT NOT NULL,
  fighter_a_score INT NOT NULL,
  fighter_b_score INT NOT NULL,
  locked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.medical_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suspensions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.judges_scores ENABLE ROW LEVEL SECURITY;

-- 5. Security Policies
CREATE POLICY "Medical checks viewable by fighter and medical staff" ON public.medical_checks FOR SELECT USING (auth.uid() = fighter_id OR auth.uid() = doctor_id);
CREATE POLICY "Suspensions viewable by everyone" ON public.suspensions FOR SELECT USING (true);
CREATE POLICY "Judges scores viewable by everyone" ON public.judges_scores FOR SELECT USING (true);