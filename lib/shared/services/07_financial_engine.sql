-- ==============================================================================
-- DFC BACKEND - MODULE 7: FINANCIAL ENGINE (PAYOUTS & REVENUE)
-- ==============================================================================

-- 1. Create the Event Revenue Table
CREATE TABLE public.event_revenue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  ticket_sales DECIMAL(12,2) DEFAULT 0.00,
  ppv_sales DECIMAL(12,2) DEFAULT 0.00,
  sponsor_revenue DECIMAL(12,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the Payouts Table
CREATE TABLE public.payouts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fighter_id UUID REFERENCES public.fighters(id) ON DELETE CASCADE,
  event_id UUID REFERENCES public.events(id) ON DELETE CASCADE,
  base_purse DECIMAL(10,2) DEFAULT 0.00,
  win_bonus DECIMAL(10,2) DEFAULT 0.00,
  performance_bonus DECIMAL(10,2) DEFAULT 0.00,
  ppv_share DECIMAL(10,2) DEFAULT 0.00,
  deductions DECIMAL(10,2) DEFAULT 0.00,
  status TEXT DEFAULT 'pending', -- 'pending', 'processed', 'paid'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.event_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;

-- 4. Security Policies
CREATE POLICY "Promoters view their own event revenue" ON public.event_revenue FOR SELECT USING (EXISTS (SELECT 1 FROM public.events WHERE id = event_id AND promoter_id = auth.uid()));
CREATE POLICY "Promoters view their event payouts" ON public.payouts FOR SELECT USING (EXISTS (SELECT 1 FROM public.events WHERE id = event_id AND promoter_id = auth.uid()));
CREATE POLICY "Fighters can view their own payouts" ON public.payouts FOR SELECT USING (auth.uid() = fighter_id);