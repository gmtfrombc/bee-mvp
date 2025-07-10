# Edge Function: /sync-ai-tags – Error Handling & Idempotency

This function persists motivation/readiness **AI tags** into the `coach_memory`
table after onboarding submission.

## Idempotency Rules

- **Natural key** = `user_id` (unique index enforced in DB).
- On repeated requests for the same `user_id` we **UPDATE** the row instead of
  INSERT, ensuring exactly-one record per user.
- Response for duplicates: **HTTP 409** with
  `{ "status": "duplicate_ignored" }`.

## Error Handling Matrix

| Scenario             | Returned Status | Body.example                                               | Notes                      |
| -------------------- | --------------- | ---------------------------------------------------------- | -------------------------- |
| Happy path           | 200             | `{ "status": "success" }`                                  | tags upserted              |
| Missing field        | 400             | `{ "error": "motivation_type required" }`                  | validated at edge          |
| Enum value invalid   | 400             | `{ "error": "readiness_level must be Low/Moderate/High" }` |                            |
| Unauthorized JWT     | 401             | `{ "error": "invalid token" }`                             | guard via Supabase client  |
| Duplicate submission | 409             | `{ "status": "duplicate_ignored" }`                        | harmless retry             |
| DB failure           | 500             | `{ "error": "internal" }`                                  | logged via `console.error` |

## Retry Guidance

Client should treat **409** same as **200**; safe to retry after network
failure. On **5xx** exponential back-off (max 3 tries).
