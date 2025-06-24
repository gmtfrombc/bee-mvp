-- Migration: allow multiple runs per day and keep only latest 20 rows
-- 1) Schema changes
ALTER TABLE public.daily_feed_content
    ADD COLUMN IF NOT EXISTS generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- 2) Drop UPDATE version trigger and function (no longer needed)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_daily_feed_content_update_version'
    ) THEN
        DROP TRIGGER trigger_daily_feed_content_update_version ON public.daily_feed_content;
    END IF;
    IF EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'trigger_create_update_version'
    ) THEN
        DROP FUNCTION public.trigger_create_update_version();
    END IF;
END $$;

-- 3) Create/replace function to mark only the newest row as active
CREATE OR REPLACE FUNCTION public.mark_latest_daily_feed_content()
RETURNS TRIGGER AS $$
BEGIN
    -- De-activate all other rows – newest wins
    UPDATE public.daily_feed_content
       SET is_active = false
     WHERE id <> NEW.id
       AND is_active = true;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4) Attach AFTER INSERT trigger (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_set_latest_daily_feed_content'
    ) THEN
        CREATE TRIGGER trigger_set_latest_daily_feed_content
        AFTER INSERT ON public.daily_feed_content
        FOR EACH ROW EXECUTE FUNCTION public.mark_latest_daily_feed_content();
    END IF;
END $$;

-- 5) Update pruning logic – keep the 20 newest rows overall
CREATE OR REPLACE FUNCTION public.prune_daily_feed_content()
RETURNS trigger AS $$
BEGIN
    DELETE FROM public.daily_feed_content
    WHERE id IN (
        SELECT id FROM public.daily_feed_content
        ORDER BY generated_at DESC
        OFFSET 20
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Ensure the AFTER INSERT statement-level trigger exists & uses new function
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'trg_prune_daily_feed_content'
    ) THEN
        CREATE TRIGGER trg_prune_daily_feed_content
        AFTER INSERT ON public.daily_feed_content
        EXECUTE FUNCTION public.prune_daily_feed_content();
    END IF;
END $$;

-- 6) Create helper view for the app
CREATE OR REPLACE VIEW public.daily_feed_content_current AS
SELECT *
  FROM public.daily_feed_content
 WHERE is_active = true
 ORDER BY generated_at DESC
 LIMIT 1; 