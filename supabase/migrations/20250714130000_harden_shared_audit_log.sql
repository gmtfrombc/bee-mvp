-- 20250714130000_harden_shared_audit_log.sql
-- Migration: Harden _shared.audit_log with Row-Level Security and least-privilege grants

-- Enable RLS on audit table
alter table _shared.audit_log enable row level security;

-- Policy: allow SELECT only for service_role requests
create policy read_service_role on _shared.audit_log
  for select
  using ( current_setting('request.jwt.claim.role', true) = 'service_role' );

-- Revoke data-modification privileges from non-trusted roles
revoke insert, update, delete on _shared.audit_log from authenticated, anon, public;

-- Tighten schema usage
revoke all on schema _shared from public;
grant usage on schema _shared to authenticated, service_role; 