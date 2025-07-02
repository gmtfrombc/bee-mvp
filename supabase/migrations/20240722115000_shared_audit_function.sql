-- 20240722115000_shared_audit_function.sql
-- Migration: Create universal audit function & log table for cross-service auditing

create schema if not exists _shared;

create table if not exists _shared.audit_log (
  id bigserial primary key,
  table_name text,
  action text,
  old_row jsonb,
  new_row jsonb,
  changed_at timestamptz default now()
);

create or replace function _shared.audit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into _shared.audit_log(table_name, action, old_row, new_row)
  values (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW));
  return coalesce(NEW, OLD);
end;
$$; 