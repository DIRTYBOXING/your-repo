-- ==============================================================================
-- DFC BACKEND - MODULE 2: FIGHTER & GYM ENGINE
-- ==============================================================================

-- 1. Create the Gyms Table (With Google Maps Integration)
CREATE TABLE public.gyms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  location TEXT,
  google_place_id TEXT, -- Google Places API Hook
  latitude DOUBLE PRECISION, -- Google Geocoding Hook
  longitude DOUBLE PRECISION,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the Fighters Table (With NVIDIA Compute Hook)
CREATE TABLE public.fighters (
  id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
  gym_id UUID REFERENCES public.gyms(id) ON DELETE SET NULL,
  nickname TEXT,
  weight_class TEXT,
  stance TEXT,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  draws INT DEFAULT 0,
  reach_cm DOUBLE PRECISION,
  height_cm DOUBLE PRECISION,
  nvidia_tracking_enabled BOOLEAN DEFAULT FALSE, -- Routes video to NVIDIA GPUs for pose estimation
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.gyms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fighters ENABLE ROW LEVEL SECURITY;

-- 4. Create Security Policies for Gyms
CREATE POLICY "Gyms are viewable by everyone" 
  ON public.gyms FOR SELECT USING (true);

CREATE POLICY "Gym owners can update their own gym" 
  ON public.gyms FOR UPDATE 
  USING (auth.uid() = owner_id);

CREATE POLICY "Gym owners can insert a gym" 
  ON public.gyms FOR INSERT 
  WITH CHECK (auth.uid() = owner_id);

-- 5. Create Security Policies for Fighters
CREATE POLICY "Fighters are viewable by everyone" 
  ON public.fighters FOR SELECT USING (true);

CREATE POLICY "Fighters can update their own stats" 
  ON public.fighters FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Fighters can insert their own stats" 
  ON public.fighters FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- 6. Auto-update timestamp triggers
CREATE TRIGGER update_gyms_modtime
BEFORE UPDATE ON public.gyms
FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_fighters_modtime
BEFORE UPDATE ON public.fighters
FOR EACH ROW EXECUTE FUNCTION update_modified_column();