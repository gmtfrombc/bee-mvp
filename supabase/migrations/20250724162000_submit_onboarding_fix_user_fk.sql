-- 20250724162000_submit_onboarding_fix_user_fk.sql
-- Migration: Harden submit_onboarding RPC against FK errors (user not found)
-- Issue: Tester hit foreign key violation onboarding_responses_user_id_fkey.
--        Likely caused by mismatched/absent user_id.
-- Fixes:
--   1) Make p_user_id optional; default to auth.uid() when null.
--   2) Verify auth.users row exists (raise if not).
--   3) Ensure profile stub row exists before marking onboarding_complete.
--   4) Retain previous behaviour + return payload.

begin;

drop function if exists public.submit_onboarding (uuid, jsonb, text, text, text);

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
    v_user_id uuid := coalesce(p_user_id, auth.uid());
    v_response_id uuid;
begin
    if v_user_id is null then
      raise exception using errcode = 'P0001', message = 'ONB_SUBMIT_FAILED: user_id is null';
    end if;

    -- Ensure auth.users row exists (defensive; should always be true)
    if not exists (select 1 from auth.users where id = v_user_id) then
      raise exception using errcode = 'P0001', message = 'ONB_SUBMIT_FAILED: user not found';
    end if;

    -- Ensure profile row exists
    insert into public.profiles(id) values (v_user_id)
      on conflict do nothing;

    ------------------------------------------------------------------------
    -- Insert raw answers ---------------------------------------------------
    ------------------------------------------------------------------------
    insert into public.onboarding_responses(user_id, answers)
      values (v_user_id, p_answers)
      returning id into v_response_id;

    ------------------------------------------------------------------------
    -- Upsert personalisation tags into coach_memory -----------------------
    ------------------------------------------------------------------------
    if p_motivation_type is not null or p_readiness_level is not null or p_coach_style is not null then
      insert into public.coach_memory(user_id, motivation_type, readiness_level, coach_style)
        values (v_user_id, p_motivation_type, p_readiness_level, p_coach_style)
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
    where id = v_user_id;

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

-- Permissions remain: allow authenticated role to execute.
grant execute on function public.submit_onboarding(uuid, jsonb, text, text, text) to authenticated;

commit;
