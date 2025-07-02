# Supabase CLI setup for BEE-MVP

> **Never commit real credentials.** Keep them outside the repository.

## 1. One-time machine setup

1. Create a private secrets folder outside the repo:
   ```bash
   mkdir -p ~/.bee_secrets
   ```
2. Add the file `~/.bee_secrets/supabase.env` and paste the variables below.
   **Fill in your own values.**
   ```env
   # ===========================================================
   # Supabase CLI credentials (DO NOT COMMIT THIS FILE)
   # ===========================================================

   # Public
   SUPABASE_URL=
   ANON_KEY=

   # Admin API / CLI
   PROJECT_ID=
   SUPABASE_ACCESS_TOKEN=

   # Direct Postgres / RLS bypass (optional)
   SUPABASE_PASSWORD=
   SERVICE_ROLE_SECRET=
   ```
3. (Optional) Store your PAT once so `supabase` commands don't require
   `SUPABASE_ACCESS_TOKEN` each time:
   ```bash
   supabase login --personal-access-token "$SUPABASE_ACCESS_TOKEN"
   ```

## 2. Per-session workflow

Whenever you—or the AI assistant—needs to run Supabase CLI commands, execute:

```bash
set -a && source ~/.bee_secrets/supabase.env && set +a
```

This exports every variable defined in the file for the lifetime of the shell
session, while keeping them out of the command log.

### Handy alias

Add this to `~/.zshrc` (or `~/.bashrc`):

```sh
alias sbenv='set -a && source ~/.bee_secrets/supabase.env && set +a'
```

Then just run `sbenv` before any Supabase work.

## 3. What needs which variable?

| Task                                   | Minimum variables                                |
| -------------------------------------- | ------------------------------------------------ |
| Read-only Edge Function test           | SUPABASE_URL, ANON_KEY                           |
| Supabase CLI commands (`supabase ...`) | PROJECT_ID, SUPABASE_ACCESS_TOKEN (+ URL)        |
| Direct Postgres / seeds / migrations   | SUPABASE_PASSWORD (_and/or_ SERVICE_ROLE_SECRET) |

## 4. Safety nets

- `~/.bee_secrets` is outside the repo → cannot be checked in.
- Pre-commit `gitleaks` hooks add another guard.
- Never paste secrets in chat or commit history; reference this doc instead.
