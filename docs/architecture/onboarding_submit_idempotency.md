# Idempotency Strategy – `submit_onboarding` RPC

Milestone **M1.11.6** · Action **C4**\
Status: 🟡 Draft – pending review

---

## Why Idempotency?

Mobile clients may retry submissions due to network timeouts or app restarts.
Without safeguards, duplicated inserts could corrupt analytics or violate
constraints.

---

## Server-Side Safeguards

1. **Early Exit Flag** – First statement inside the function:
   ```sql
   if exists (select 1 from public.profiles p
              where p.id = p_user_id and p.onboarding_complete = true) then
     return jsonb_build_object('status', 'duplicate');
   end if;
   ```
   This avoids DB writes on subsequent calls.
2. **Unique Index (optional)** – If we still want to allow one raw record per
   user:
   ```sql
   create unique index if not exists onboarding_responses_user_idx
     on public.onboarding_responses(user_id);
   ```
   Duplicate insert will raise `23505` and trigger rollback.
3. **Upsert for Tags** – `coach_memory` already uses `on conflict` → no dupes.

---

## Client-Side Token

- Generate a **submission UUID** once per onboarding flow and store in Hive
  queue item.
- Pass `submission_id` param to RPC; server stores it in
  `onboarding_responses.id` (rather than gen_random_uuid()).
  - Guarantees full idempotency: same UUID → conflict error.

---

## Error Handling

- Server returns JSON `{status: 'duplicate'}` → client marks queue item as
  _success_ and purges.
- Any other error: retry with back-off up to 5 attempts.

---

_Author: AI Pair-Programmer\
Date: 2025-07-11_
