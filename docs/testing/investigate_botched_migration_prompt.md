# Prompt: Investigate a Suspected Botched Migration

**Context**  
Curently all CI passes locally (ACT) and on GitHub. However, we have noticed that since recent migrations we've had a high number of Backend and Integration CI failures on Github Actions that pass locally. A possilbe hypothesis is that a migration file is malformed or state‑dependent. Your task is to prove or disprove that the migration set cannot rebuild a clean database from scratch.

---

## 🎯 Objectives

1. Identify the first migration that fails on a blank database.  
2. Produce logs and line numbers for the defective SQL.  
3. Note if newer Supabase CLI/Postgres versions expose the fault.  
4. Recommend a remediation plan (forward‑only fix or rollback).

---

## 🛠️  Step‑by‑Step Investigation

| # | Step | Command | Success Criteria |
|---|------|---------|------------------|
| 1 | Check out a debug branch | `git checkout -b debug/migration-failure` | Branch created |
| 2 | Align local CLI & Postgres versions with CI | Use `supabase/actions/setup-cli@v1` version shown in CI logs | Versions identical |
| 3 | Remove containers & volumes | `docker compose down -v` | Fresh state |
| 4 | Rebuild DB from scratch | `supabase db reset --no-encrypt --password test` | Error here ⇒ migration defect |
| 5 | Bisect migrations if step 4 fails | `for f in supabase/migrations/*.sql; do psql -f "$f" || { echo BAD: $f; break; }; done` | First failing file printed |
| 6 | Capture stderr | Redirect to `migration_error.log` | Log saved |
| 7 | Compare Postgres image tags | `docker images | grep supabase/postgres` | Matches CI |
| 8 | Retry with previous CLI version | `supabase db reset --tag v1.189.0` | Pass here ⇒ stricter parser |
| 9 | Document root cause & plan | Add to `debug_report.md` | Clear analysis |
|10| Commit report & logs | Push to PR | Reviewable by team |

---

## 📄 Deliverables

* **debug_report.md** – findings & remediation plan  
* **migration_error.log** – raw error output  
* PR comment linking to both files
