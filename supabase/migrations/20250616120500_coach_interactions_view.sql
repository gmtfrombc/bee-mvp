-- Migration: create redacted view for coach interactions
-- Generated 2025-06-16

create or replace view public.coach_interactions_public as
select
  id,
  user_id,
  sender,
  left(message, 100) as message_preview,
  metadata - 'pii' as metadata_sanitized,
  created_at
from public.coach_interactions;

comment on view public.coach_interactions_public is 'Redacted view for analytics – trims message and removes possible PII keys.'; 