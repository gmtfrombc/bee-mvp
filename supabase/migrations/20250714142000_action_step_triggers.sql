-- 20250714142000_action_step_triggers.sql
-- Migration: Add audit trigger & hashed-user audit function for action_steps
-- Epic 1.5 · Milestone 1.5.1 · Task T3

-- Ensure pgcrypto extension for SHA-256 hashing
create extension if not exists pgcrypto;

-- 1. Trigger function: logs changes with hashed user_id for HIPAA compliance
create or replace function public.log_audit_action_step()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_old jsonb;
  v_new jsonb;
  v_hash text;
begin
  if old is not null then
    v_hash := encode(digest(old.user_id::text, 'sha256'), 'hex');
    v_old  := (row_to_json(old)::jsonb - 'user_id') || jsonb_build_object('user_hash', v_hash);
  end if;

  if new is not null then
    v_hash := encode(digest(new.user_id::text, 'sha256'), 'hex');
    v_new  := (row_to_json(new)::jsonb - 'user_id') || jsonb_build_object('user_hash', v_hash);
  end if;

  insert into _shared.audit_log(table_name, action, old_row, new_row)
    values (tg_table_name, tg_op, v_old, v_new);

  return coalesce(new, old);
end;
$$;

-- 2. Attach audit trigger to action_steps (AFTER INSERT/UPDATE/DELETE)
drop trigger if exists trg_action_steps_audit on public.action_steps;
create trigger trg_action_steps_audit
  after insert or update or delete on public.action_steps
  for each row execute procedure public.log_audit_action_step();

-- 3. Attach generic audit trigger to action_step_logs (AFTER INSERT/DELETE)
--    This table contains no PHI; standard _shared.audit() is sufficient.
drop trigger if exists trg_action_step_logs_audit on public.action_step_logs;
create trigger trg_action_step_logs_audit
  after insert or delete on public.action_step_logs
  for each row execute procedure _shared.audit(); 