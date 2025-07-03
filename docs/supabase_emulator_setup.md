# Supabase Emulator – Local Setup

This emulator lets you run integration tests (e.g. password-reset flow) without
hitting the production Supabase project.

## 1. Start the container

```bash
# From project root
docker compose -f supabase/docker-compose.emulator.yml up -d --build
```

The first run downloads images (~1.5 GB).

## 2. Environment variables

Create/append the following to `~/.bee_secrets/supabase.env` and
`supabase/env.test.sample`:

```
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=local-anon-key
```

Your tests will pick these up automatically.

## 3. Email templates

Copy the production HTML templates (or use the ones under
`supabase/emulator/mail-templates/`). They are read by the emulator to generate
password-reset emails.

## 4. Tear down

```bash
docker compose -f supabase/docker-compose.emulator.yml down -v
```
