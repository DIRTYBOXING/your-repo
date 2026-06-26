-- ==============================================================================
-- DFC BACKEND - MODULE 5: PPV & STREAMING ENGINE
-- ==============================================================================

-- 1. Create the PPV Events Table (The Storefront)
CREATE TABLE public.ppv_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_active BOOLEAN DEFAULT FALSE,
  is_featured BOOLEAN DEFAULT FALSE,
  stream_url TEXT,
  replay_url TEXT,
  hero_backdrop_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the PPV Purchases Table (The Gates)
CREATE TABLE public.ppv_purchases (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'paid', -- 'paid', 'refunded'
  payment_provider TEXT, -- 'stripe', 'apple_pay', 'google_pay'
  purchase_time TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create the Watch History Table (Continue Watching)
CREATE TABLE public.watch_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  last_position_seconds INT DEFAULT 0,
  last_watched_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.ppv_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ppv_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watch_history ENABLE ROW LEVEL SECURITY;

-- 5. Security Policies
CREATE POLICY "PPV events are viewable by everyone" ON public.ppv_events FOR SELECT USING (true);
CREATE POLICY "Users can view their own purchases" ON public.ppv_purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own watch history" ON public.watch_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert/update their watch history" ON public.watch_history FOR ALL USING (auth.uid() = user_id);