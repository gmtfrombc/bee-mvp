# Pre-Task Completion Sprint – Registration & Auth

This short sprint prepares the codebase so the main **M1.6.1 – Supabase Auth
Backend Setup** milestone can be executed smoothly by the next AI coder without
regressions.

## Sprint Goals

1. Establish Terraform hooks for applying DB migrations.
2. Provide a universal audit-logging function required by upcoming tables.
3. Set automated password-policy enforcement.
4. Wire CI/CD so pushes to `main` automatically apply migrations after safety
   checks.
5. Extend tests and docs so everything is verifiable by a novice maintainer.

## Work Breakdown & Directions

| ID                                                  | Task                                          | File / Path                                                    | Notes                                                                                                                  |
| --------------------------------------------------- | --------------------------------------------- | -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| S1                                                  | **Create `_shared.audit()`** migration        | `supabase/migrations/20240722115000_shared_audit_function.sql` | Use SQL below. Must run **before** any triggers reference it.                                                          |
| S2                                                  | **Add `profiles` table & RLS** migration stub | _leave empty for now_                                          | Will be filled by milestone; include timestamp scaffold so ordering is correct (`20240722120000_v1.6.1_profiles.sql`). |
| S3                                                  | **Add Terraform variable**                    | `infra/vars.tf`                                                | ```hcl                                                                                                                 |
| variable "supabase_migration_tag" { type = string } |                                               |                                                                |                                                                                                                        |

````|
| S4 | **Add Supabase migration resource** | `infra/main.tf` | See HCL snippet under *Implementation Details* below. Ensure you `terraform fmt`. |
| S5 | **Create CI workflow to deploy migrations** | `.github/workflows/migrations-deploy.yml` | Trigger: push to `main` with changes in `supabase/migrations/**` or `infra/**`. Steps: checkout → setup Supabase CLI → load secrets → DB dump → `supabase db push --non-interactive` → `terraform apply -auto-approve`. |
| S6 | **Password-policy automation** | `.github/workflows/migrations-deploy.yml` (same job) | After migrations, run: `supabase auth settings update --password_min_length 8 --password_require_special_char true`. |
| S7 | **Snapshot / rollback step** | Same workflow | Use `supabase db dump --output backups/dump_$(date +%s).sql` and upload as artifact. |
| S8 | **Extend test suite for audit + RLS** | `tests/db/test_rls_audit.py` | New tests: insert/select by owner vs stranger on `profiles`; insert row & assert entry in `_shared.audit_log`. |
| S9 | **Update README / docs** | `docs/MVP_ROADMAP/1-6 Registration and Auth/M1.6.1_supabase_auth_backend_setup.md` | Add link to new workflow & variable description. |
| S10 | **Update environment vars** | `terraform.tfvars` in each env | Set `supabase_migration_tag = "v1.6.1"` (staging) – prod updated when ready. |

## S1 – `_shared.audit()` SQL
```sql
-- 20240722115000_shared_audit_function.sql
create schema if not exists _shared;

create table if not exists _shared.audit_log (
  id bigserial primary key,
  table_name text,
  action text,
  old_row jsonb,
  new_row jsonb,
  changed_at timestamptz default now()
);

create or replace function _shared.audit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into _shared.audit_log(table_name, action, old_row, new_row)
  values (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW));
  return coalesce(NEW, OLD);
end;
$$;
````

## Terraform – `infra/main.tf` snippet (S4)

```hcl
# Fetch existing project defined in Supabase dashboard
data "supabase_project" "current" {}

resource "supabase_migration" "auth_profiles" {
  project_ref   = data.supabase_project.current.id
  version       = var.supabase_migration_tag
  migration_sql = file("${path.module}/../supabase/migrations/20240722120000_v1.6.1_profiles.sql")
}
```

## Acceptance Criteria for Sprint

- [ ] `terraform validate` passes with the new variable/resource.
- [ ] `supabase db reset --linked` succeeds locally after running both new SQL
      files.
- [ ] New GitHub Action executes on a test branch (dry-run) without error.
- [ ] Tests in `tests/db/` cover audit trigger and RLS.
- [ ] Documentation updated; novice can follow steps to apply or roll back.

## Risks & Mitigations

| Risk                                    | Mitigation                                                                                      |
| --------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Supabase CLI or Terraform version drift | Pin CLI via `supabase/setup-cli@v1` and Terraform via `hashicorp/setup-terraform@v3`.           |
| Dump file size in CI artifacts          | Retain only last 3 dumps, or use GCS bucket lifecycle rule.                                     |
| Migration ordering                      | Numeric timestamps guarantee order; ensure audit function timestamp < profiles table timestamp. |

---

After this sprint, the milestone tasks T1–T5 can be completed with minimal
friction, enabling 100–200 beta users to register & log in during MVP testing.

Ran tool

Read file: docs/MVP_ROADMAP/1-6 Registration and Auth/M1.6.1_supabase_auth_backend_setup.md

Here’s the step-by-step plan I’ll follow to kick off Milestone 1.6.1 (Supabase Auth Backend) now that your PR is merged:

Step 0 – sync workspace   
 a. `git checkout main`  
 b. `git pull origin main`  
 c. Run the full test suite once to confirm the baseline is green.

Step 1 – create milestone branch  
 `git checkout -b feat/m1.6.1-auth-backend-setup`

Step 2 – add the real SQL migration  
 • Fill `supabase/migrations/20240722120000_v1.6.1_profiles.sql` with the table, RLS policies, and audit trigger shown in the milestone doc (idempotent `IF NOT EXISTS`).  
 • Keep the timestamp identical so ordering remains correct.

Step 3 – Terraform wiring  
 • Add `variable "supabase_migration_tag"` (already scaffolded).  
 • Ensure `supabase_migration_tag = "v1.6.1"` is present in `infra/terraform.tfvars` (staging only).

Step 4 – extend database tests  
 • Update `tests/db/test_rls_audit.py` to assert:  
   – owner can `SELECT/INSERT` into `profiles`  
   – stranger cannot  
   – audit log receives a row after CRUD.

Step 5 – local verification  
 • `supabase db reset --linked` to apply migrations locally.  
 • Run all Python and Dart tests.

Step 6 – commit & push  
 • Push the branch; open a PR against `main`.  
 • The “migrations-deploy” workflow will apply the migration in staging automatically.

Step 7 – handover  
 • Once green, we proceed to the Flutter registration UI milestone (M1.6.2).

Let me know if anything should be adjusted; otherwise I’ll start with Step 0.
