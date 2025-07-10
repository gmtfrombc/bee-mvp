# `/sync-ai-tags` – Supabase Edge Function

Synchronises AI tag metadata (`motivation_type`, `readiness_level`,
`coach_style`) to the `coach_memory` table.

---

## Environment Variables

| Variable              | Purpose                                                               | Example                   |
| --------------------- | --------------------------------------------------------------------- | ------------------------- |
| `SUPABASE_URL`        | Base URL of the Supabase project                                      | `https://abc.supabase.co` |
| `SUPABASE_ANON_KEY`   | Public anon key for client auth                                       | `eyJhb...`                |
| `SERVICE_ROLE_SECRET` | Service-role JWT for privileged access (used only in tests)           | `eyJhb...`                |
| `SKIP_SUPABASE`       | Set to `true` to bypass DB calls and use in-memory store (unit tests) | `true`                    |

Load these automatically via the project-level secrets file
(`~/.bee_secrets/supabase.env`).

```bash
set -a && source ~/.bee_secrets/supabase.env && set +a
```

---

## Local Testing

1. **Install deps**
   ```bash
   deno task deps
   ```
2. **Run unit & contract tests** (offline mode):
   ```bash
   SKIP_SUPABASE=true deno test --allow-env
   ```
3. **Against cloud Supabase** (writes to branch DB):
   ```bash
   deno test --allow-env --allow-net
   ```
   Ensure `SUPABASE_URL` points at a **branch database** – not production.

---

## Deployment

Edge functions are deployed automatically by CI on merge to `main`:

```yaml
jobs:
  supabase-deploy:
    uses: supabase/setup-cli@v1
```

Manual deployment:

```bash
supabase functions deploy sync-ai-tags --project-ref $PROJECT_ID
```

---

## API Contract

```
POST /sync-ai-tags
{
  "user_id": "<uuid>",
  "motivation_type": "Internal|Mixed|External|Unclear",
  "readiness_level": "Low|Moderate|High",
  "coach_style": "RH|Cheerleader|DS|Unsure"
}
```

Responses: `200 success`, `409 duplicate_ignored`, `400 validation`,
`500 internal`.
