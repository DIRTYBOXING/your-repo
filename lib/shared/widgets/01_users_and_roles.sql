-- ==============================================================================
-- DFC BACKEND - MODULE 1: USERS, PROFILES & ROLES
-- ==============================================================================

-- 1. Create the Enum for DFC Roles
CREATE TYPE dfc_role AS ENUM (
  'fan', 'fighter', 'coach', 'gym_owner', 'promoter', 'official', 'medical', 'sponsor', 'admin'
);

-- 2. Create the Profiles Table (Extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  role dfc_role DEFAULT 'fan'::dfc_role,
  country TEXT,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable Row Level Security (RLS) - The absolute shield
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create Security Policies
-- Everyone can view profiles (needed for public fighter/coach profiles)
CREATE POLICY "Profiles are viewable by everyone" 
  ON public.profiles FOR SELECT 
  USING (true);

-- Users can only insert their own profile
CREATE POLICY "Users can insert their own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update their own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

-- 5. Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_modtime
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION update_modified_column();