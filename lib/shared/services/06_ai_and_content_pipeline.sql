-- ==============================================================================
-- DFC BACKEND - MODULE 6: AI & CONTENT PIPELINE
-- ==============================================================================

-- 1. Create the Feed Posts Table (The Social Engine)
CREATE TABLE public.feed_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'clip', 'news', 'ppvPromo', 'result', 'sponsor'
  headline TEXT NOT NULL,
  body TEXT,
  media_url TEXT,
  event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
  priority INT DEFAULT 0, -- For pinning/boosting
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the AI Insights Table (The Brain's Output)
CREATE TABLE public.ai_insights (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fighter_id UUID REFERENCES public.fighters(id) ON DELETE CASCADE,
  insight_type TEXT NOT NULL, -- 'readiness', 'fatigue', 'injury_risk', 'gameplan'
  value_score DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create the Telemetry Table (The Nervous System)
CREATE TABLE public.telemetry (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fighter_id UUID REFERENCES public.fighters(id) ON DELETE CASCADE,
  event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
  fight_id UUID REFERENCES public.fights(id) ON DELETE SET NULL,
  heart_rate INT,
  hrv DOUBLE PRECISION,
  power_output DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.feed_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;

-- 5. Security Policies
CREATE POLICY "Feed posts are viewable by everyone" ON public.feed_posts FOR SELECT USING (true);
CREATE POLICY "Promoters and Admins can insert feed posts" ON public.feed_posts FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Fighters can view their own AI insights" ON public.ai_insights FOR SELECT USING (auth.uid() = fighter_id);