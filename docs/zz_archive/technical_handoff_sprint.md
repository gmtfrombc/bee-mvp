# Technical Handoff Sprint – Registration & Auth

_This document is for the **next AI coder** assigned to complete the work
defined in_ [`pre-task_completion_sprint.md`](./pre-task_completion_sprint.md).

The goal of this hand-off is to provide a precise, step-by-step execution plan
so you can deliver the sprint with zero regressions and minimal back-and-forth.

---

## 0. Pre-requisites

1. **Secrets** – Ensure the Supabase secrets file is present at
   `~/.bee_secrets/supabase.env` (contains `SUPABASE_URL`,
   `SUPABASE_ACCESS_TOKEN`, `SERVICE_ROLE_SECRET`, etc.).
2. **Tooling versions**\
   • Supabase CLI ≥ 1.138.5\
   • Terraform ≥ 1.5\
   • Node ≥ 18 (for GitHub Action runners)\
   • Python ≥ 3.10 (for tests)
3. **Branching** – Work from a new feature branch `feat/auth-prep-sprint`.

---

## 1. Task Matrix (derived from S1 – S10)

| ID  | Task                                    | Estimated Effort | Blocking | Deliverable                                                              |
| --- | --------------------------------------- | ---------------- | -------- | ------------------------------------------------------------------------ |
| S1  | Create `_shared.audit()` migration      | 0.5 h            | none     | `supabase/migrations/20240722115000_shared_audit_function.sql`           |
| S2  | Scaffold `profiles` migration stub      | 0.2 h            | S1       | `supabase/migrations/20240722120000_v1.6.1_profiles.sql` (empty for now) |
| S3  | Add `supabase_migration_tag` variable   | 0.2 h            | none     | Update `infra/vars.tf` + `terraform.tfvars` (staging)                    |
| S4  | Add `supabase_migration` resource       | 0.5 h            | S3       | Edit `infra/main.tf`                                                     |
| S5  | Create `migrations-deploy.yml` workflow | 1 h              | S1 – S4  | New file under `.github/workflows/`                                      |
| S6  | Automate password policy                | 0.3 h            | S5       | CLI step in the above workflow                                           |
| S7  | Add rollback (DB dump) step             | 0.3 h            | S5       | Artifact upload in the workflow                                          |
| S8  | Extend audit & RLS tests                | 1.5 h            | S1 – S2  | `tests/db/test_rls_audit.py`                                             |
| S9  | Update milestone doc                    | 0.2 h            | S1 – S5  | Doc edits only                                                           |
| S10 | Update env var files                    | 0.1 h            | S3       | `terraform.tfvars`, Secrets in CI                                        |

_Total ≈ 4.8 h (buffered to 6 h)._\
Keep commits small and atomic per task.

---

## 2. Implementation Details

### S1 – Create `_shared.audit()` migration

1. Create the SQL file
   `supabase/migrations/20240722115000_shared_audit_function.sql` with the exact
   contents provided in `pre-task_completion_sprint.md`.
2. **Verify** locally:
   ```bash
   set -a && source ~/.bee_secrets/supabase.env && set +a
   supabase db reset --linked  # should succeed
   ```

### S2 – Scaffold `profiles` migration stub

Simply create an empty file with a `-- TODO` header. This guarantees ordering
before the milestone work lands.

### S3 – Add Terraform variable

Edit `infra/vars.tf`:

```hcl
variable "supabase_migration_tag" {
  description = "Tag of the latest database migration applied via Terraform"
  type        = string
}
```

Update `terraform.tfvars` (staging only) with:

```tfvars
supabase_migration_tag = "v1.6.1"
```

### S4 – Add `supabase_migration` resource

Add the HCL block (see pre-task doc). Run `terraform fmt`.

### S5 – Create deployment workflow

File: `.github/workflows/migrations-deploy.yml`

1. Trigger: push to `main` when files change in `supabase/migrations/**` or
   `infra/**`.
2. Steps outline:\
   a. Checkout\
   b. Setup Supabase CLI\
   c. `set -a && source ~/.bee_secrets/supabase.env && set +a`\
   d. **Rollback dump** –
   `supabase db dump --output backups/dump_8$(date +%s).sql`\
   e. `supabase db push --non-interactive`\
   f.
   `terraform init -backend=false && terraform validate && terraform apply -auto-approve`\
   g. **Password policy** – run command from S6\
   h. Upload dump as artifact.

### S6 – Password-policy step

Inside the same job, append:

```bash
supabase auth settings update \
  --password_min_length 8 \
  --password_require_special_char true
```

### S7 – Rollback dump step

Already part of S5. Consider retention rules on artifact.

### S8 – Extend tests

1. Add assertions in `tests/db/test_rls_audit.py`:\
   • Insert a row as user A, verify select allowed for A and denied for B.\
   • Check `select count(*)` from `_shared.audit_log` increased by 1 after
   insert.
2. Ensure test DB setup script creates the audit schema/table.

### S9 – Update milestone doc

Reflect new workflow filename and variable description.

### S10 – Update env vars

Set `supabase_migration_tag` in staging tfvars. **Prod left blank** until
promotion.

---

## 3. Validation Checklist

- `supabase db reset --linked` passes locally.
- `pytest tests/db/ -q` all green.
- `terraform validate` & `terraform plan` show no errors.
- Push branch; GH Actions for PR run in dry-run mode.
- Merge to `main` on staging fork triggers `migrations-deploy.yml` and finishes
  successfully (check artifacts).

---

## 4. Done Definition

Sprint is complete when:

1. All acceptance criteria in `pre-task_completion_sprint.md` are ticked.
2. CI pipeline green on branch **and** `main`.
3. Milestone document updated with commit SHA links.
4. Code reviewed & merged with no regressions in monitoring dashboards.

---

ℹ️ **Tip for next AI coder:** Use small PRs (< 400 LOC) and run `supabase start`
locally if you need to debug migrations interactively.
