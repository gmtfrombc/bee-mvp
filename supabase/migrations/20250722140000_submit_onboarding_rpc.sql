-- 20250722140000_submit_onboarding_rpc.sql
-- Milestone M1.11.6 · Action C1
-- FINAL: Implements submit_onboarding RPC (transactional multi-insert + flag)

begin;

drop function if exists public.submit_onboarding(uuid, jsonb, text, text, text);

-- 1️⃣  Function -------------------------------------------------------------
create or replace function public.submit_onboarding(
    p_user_id uuid,
    p_answers jsonb,
    p_motivation_type text default null,
    p_readiness_level text default null,
    p_coach_style text default null
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_response_id uuid;
begin
    ------------------------------------------------------------------------
    -- Insert raw answers ---------------------------------------------------
    ------------------------------------------------------------------------
    insert into public.onboarding_responses(user_id, answers)
      values (p_user_id, p_answers)
      returning id into v_response_id;

    ------------------------------------------------------------------------
    -- Upsert personalisation tags into coach_memory -----------------------
    ------------------------------------------------------------------------
    if p_motivation_type is not null or p_readiness_level is not null or p_coach_style is not null then
      insert into public.coach_memory(user_id, motivation_type, readiness_level, coach_style)
        values (p_user_id, p_motivation_type, p_readiness_level, p_coach_style)
      on conflict (user_id) do update
        set motivation_type = excluded.motivation_type,
            readiness_level = excluded.readiness_level,
            coach_style = excluded.coach_style,
            updated_at = now();
    end if;

    ------------------------------------------------------------------------
    -- Mark onboarding as complete -----------------------------------------
    ------------------------------------------------------------------------
    update public.profiles
      set onboarding_complete = true
    where id = p_user_id;

    ------------------------------------------------------------------------
    -- Return payload -------------------------------------------------------
    ------------------------------------------------------------------------
    return jsonb_build_object('response_id', v_response_id, 'status', 'success');

exception
    when others then
      -- Roll back entire transaction and bubble custom SQLSTATE (P0001)
      raise exception using
        errcode = 'P0001',
        message = 'ONB_SUBMIT_FAILED: onboarding submission failed → ' || SQLERRM;
end;
$$;

-- 2️⃣  Permissions ---------------------------------------------------------
-- Allow authenticated users to execute their own submission
grant execute on function public.submit_onboarding(uuid, jsonb, text, text, text) to authenticated;

commit; 