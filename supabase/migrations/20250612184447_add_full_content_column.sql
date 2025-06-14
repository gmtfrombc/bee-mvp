ALTER TABLE IF EXISTS public.daily_feed_content ADD COLUMN IF NOT EXISTS full_content jsonb;
