-- 20250708123000_onboarding_responses_audit_trigger.sql
-- Milestone M1.11.1 · Task T5
-- Adds audit trigger to onboarding_responses table using _shared.audit()

-- 1️⃣  Audit Trigger ---------------------------------------------------------

drop trigger if exists audit_onboarding_responses on public.onboarding_responses;
create trigger audit_onboarding_responses
after insert or update or delete on public.onboarding_responses
for each row execute procedure _shared.audit(); 