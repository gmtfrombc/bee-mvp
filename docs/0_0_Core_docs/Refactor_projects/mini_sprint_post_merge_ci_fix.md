### Mini-Sprint · Post-Merge CI Fix

**Scope:** Repair the two failing CI workflows on `main` (JITAI Model CI &
Supabase Migrations CI) and restore a green default branch. All tasks are
assigned to _AI Coder_ and reference local CI tooling in
`docs/0_0_Core_docs/ACT_CLI/local_ci_recipes.md`.

**Timeline:** 1–2 days (focused hot-fix).

**References:**

- Local CI guide: `docs/0_0_Core_docs/ACT_CLI/local_ci_recipes.md`
- Failing workflows: `.github/workflows/jitai_model_ci.yml`,
  `.github/workflows/migrations-deploy.yml`
- Branch protection policy settings

---

| Task ID | Description                                                                                                            | Est. Hrs | Status      |
| ------- | ---------------------------------------------------------------------------------------------------------------------- | -------- | ----------- |
| T1      | Checkout latest `main`; reproduce _both_ failing jobs locally via commands available in @local_ci_recipes.md.          | 1h       | ✅ Complete |
| T2      | Investigate & identify root cause of **JITAI Model CI** failure (code, data, threshold change, env).                   | 2h       | ✅ Complete |
| T3      | Implement minimal patch (code/tests/config) so JITAI job passes locally; update fixtures if needed.                    | 2h       | ✅ Complete |
| T4      | Investigate & identify root cause of **Supabase Migrations CI** failure (SQL syntax, dependency order, metadata).      | 2h       | ✅ Complete |
| T5      | Implement migration fix; run `FORCE_MIGRATIONS=true ./scripts/run_ci_locally.sh -j deploy` until green.                | 2h       | ✅ Complete |
| T6      | Execute **full** local CI (`./scripts/run_ci_locally.sh`) to confirm all jobs green; archive logs in `build/ci_logs/`. | 1h       | ✅ Complete |
| T7      | Create hot-fix branch `fix/post-merge-ci`; commit patches & push; open PR targeting `main`.                            | 0.5h     | ✅ Complete |
| T8      | Ensure GitHub Actions CI passes on PR; request review; merge once green.                                               | 0.5h     | ✅ Complete |
| T9      | Pull latest `main`; rebase/merge into active feature branch `feature/M1.11.6`.                                         | 0.5h     | ✅ Complete |
| T10     | Update branch protection rules: require JITAI & Migrations workflows before merge to `main`.                           | 0.5h     | ✅ Complete |

---

#### Acceptance Criteria

- `main` branch CI status badge returns green.
- Both JITAI Model and Supabase Migrations workflows succeed locally and in
  GitHub.
- Feature branches are updated without conflicts.
- Branch protection enforces the two critical jobs.

---

_End of mini-sprint plan._
