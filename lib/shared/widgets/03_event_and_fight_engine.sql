-- ==============================================================================
-- DFC BACKEND - MODULE 3: EVENT & FIGHT ENGINE
-- ==============================================================================

-- 1. Create the Events Table
CREATE TABLE public.events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  promoter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  location TEXT,
  sport_type TEXT DEFAULT 'mma', -- 'mma', 'boxing', 'muay_thai', 'bjj', 'drone_racing'
  status TEXT DEFAULT 'draft', -- 'draft', 'published', 'live', 'completed'
  poster_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the Fights Table
CREATE TABLE public.fights (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  fighter_a_id UUID REFERENCES public.fighters(id) ON DELETE SET NULL,
  fighter_b_id UUID REFERENCES public.fighters(id) ON DELETE SET NULL,
  weight_class TEXT,
  rounds INT DEFAULT 3,
  is_title_fight BOOLEAN DEFAULT FALSE,
  status TEXT DEFAULT 'scheduled', -- 'scheduled', 'in_progress', 'completed'
  winner_id UUID REFERENCES public.fighters(id) ON DELETE SET NULL,
  method TEXT,
  end_round INT,
  end_time TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create the Fight Stats Table (Telemetry & Scoring)
CREATE TABLE public.fight_stats (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fight_id UUID REFERENCES public.fights(id) ON DELETE CASCADE,
  fighter_id UUID REFERENCES public.fighters(id) ON DELETE CASCADE,
  strikes_landed INT DEFAULT 0,
  strikes_thrown INT DEFAULT 0,
  takedowns INT DEFAULT 0,
  control_time_seconds INT DEFAULT 0,
  knockdowns INT DEFAULT 0,
  power_avg DOUBLE PRECISION DEFAULT 0.0,
  speed_avg DOUBLE PRECISION DEFAULT 0.0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fight_stats ENABLE ROW LEVEL SECURITY;

-- 5. Security Policies
CREATE POLICY "Events are viewable by everyone" ON public.events FOR SELECT USING (true);
CREATE POLICY "Promoters can insert their own events" ON public.events FOR INSERT WITH CHECK (auth.uid() = promoter_id);
CREATE POLICY "Promoters can update their own events" ON public.events FOR UPDATE USING (auth.uid() = promoter_id);

CREATE POLICY "Fights are viewable by everyone" ON public.fights FOR SELECT USING (true);
CREATE POLICY "Promoters can insert fights to their events" ON public.fights FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.events WHERE id = event_id AND promoter_id = auth.uid())
);

CREATE POLICY "Fight stats are viewable by everyone" ON public.fight_stats FOR SELECT USING (true);