-- 20250724161000_action_steps_digest_bytea_fix.sql
-- Migration: Ensure pgcrypto extension exists and cast digest() input to bytea
-- Context: Tester report – Postgres error 42883 "function digest(text, unknown) does not exist"
--          observed when inserting into public.action_steps (audit trigger).
--          Root cause: pgcrypto extension missing OR wrong parameter type.
--          Fix: 1) create extension if missing. 2) Recreate trigger function
--             with explicit ::bytea cast on user_id text value to satisfy
--             digest(bytea, text) signature.

-- 1. Enable pgcrypto (safe if it already exists)
create extension if not exists pgcrypto;

-- 2. Recreate audit trigger function with correct casting
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
    v_hash := encode(digest(old.user_id::text::bytea, 'sha256'), 'hex');
    v_old  := (row_to_json(old)::jsonb - 'user_id') || jsonb_build_object('user_hash', v_hash);
  end if;

  if new is not null then
    v_hash := encode(digest(new.user_id::text::bytea, 'sha256'), 'hex');
    v_new  := (row_to_json(new)::jsonb - 'user_id') || jsonb_build_object('user_hash', v_hash);
  end if;

  insert into _shared.audit_log(table_name, action, old_row, new_row)
    values (tg_table_name, tg_op, v_old, v_new);

  return coalesce(new, old);
end;
$$;
