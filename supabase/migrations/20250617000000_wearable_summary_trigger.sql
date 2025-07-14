-- Migration: Add trigger to call wearable-summary-listener Edge Function on INSERT/UPDATE
-- Sprint-E · Task T1.3.10.2

-- Enable http extension if available (skip when absent)
DO $$
BEGIN
  BEGIN
    EXECUTE 'CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions';
  EXCEPTION
    WHEN undefined_file THEN
      RAISE NOTICE 'http extension not installed – skipping.';
  END;
END$$;

-- Replace existing function (idempotent)
create or replace function public.notify_wearable_summary()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  -- POST the new/updated row as JSON to the Edge Function
  perform
    http_post(
      format('https://%s.functions.supabase.co/wearable-summary-listener',
              current_setting('app.settings.project_ref', true)),
      row_to_json(NEW)::jsonb,
      'application/json'::text,
      1000 -- timeout ms
    );
  return new;
end;
$$;

drop trigger if exists trg_wearable_summary_notify on public.wearable_daily_summary;

create trigger trg_wearable_summary_notify
after insert or update
on public.wearable_daily_summary
for each row
execute function public.notify_wearable_summary(); 