
        DROP TRIGGER IF EXISTS audit_onboarding_responses ON public.onboarding_responses CASCADE;

        DROP TABLE IF EXISTS public.onboarding_responses CASCADE;
        DROP TABLE IF EXISTS public.medical_history CASCADE;
        DROP TABLE IF EXISTS public.biometrics CASCADE;
        DROP TABLE IF EXISTS public.energy_rating_schedules CASCADE;

        DROP TYPE IF EXISTS public.energy_rating_schedule CASCADE;
        