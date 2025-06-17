-- Migration: enable realtime broadcasts for coach_interactions inserts
-- Generated 2025-06-16

-- Safety check: Only create when function missing
create or replace function public.broadcast_coach_interaction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Broadcast to a per-user channel so mobile clients can subscribe
  perform public.realtime.broadcast(
    'coach_interactions:' || NEW.user_id::text,
    'INSERT',
    row_to_json(NEW)
  );
  return new;
end;
$$;

-- Drop existing trigger if present to allow idempotent deploys
DROP TRIGGER IF EXISTS coach_interactions_realtime_trigger on public.coach_interactions;

create trigger coach_interactions_realtime_trigger
after insert on public.coach_interactions
for each row execute function public.broadcast_coach_interaction(); 