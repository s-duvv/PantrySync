-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. HOUSEHOLDS TABLE
CREATE TABLE public.households (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. USERS PROFILE TABLE
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES public.households(id) ON DELETE SET NULL,
    display_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'member',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. GROCERY ITEMS TABLE
CREATE TABLE public.grocery_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT 'General',
    status VARCHAR(30) NOT NULL CHECK (status IN ('IN_STOCK', 'LOW', 'OUT_OF_STOCK')),
    unit VARCHAR(30) DEFAULT 'pcs',
    predicted_out_date DATE,
    last_restocked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. CONSUMPTION LOGS TABLE
CREATE TABLE public.consumption_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id UUID NOT NULL REFERENCES public.grocery_items(id) ON DELETE CASCADE,
    action VARCHAR(30) NOT NULL CHECK (action IN ('RESTOCKED', 'EMPTIED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. REALTIME PUBLICATION SETUP
ALTER PUBLICATION supabase_realtime ADD TABLE public.grocery_items;

-- 6. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grocery_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consumption_logs ENABLE ROW LEVEL SECURITY;

-- Helper Function to get Current User's Household ID
CREATE OR REPLACE FUNCTION get_user_household_id()
RETURNS UUID AS $$
  SELECT household_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- RLS: Grocery Items accessible only within the same household
CREATE POLICY "Allow household members full access to grocery_items"
ON public.grocery_items
FOR ALL
USING (household_id = get_user_household_id())
WITH CHECK (household_id = get_user_household_id());

-- RLS: Consumption Logs access
CREATE POLICY "Allow household members full access to consumption_logs"
ON public.consumption_logs
FOR ALL
USING (
  item_id IN (SELECT id FROM public.grocery_items WHERE household_id = get_user_household_id())
);