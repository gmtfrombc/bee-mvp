# CI Hardening — Phase 0 Setup (2025-07-12)

> **Scope**: Replace default GitHub `ubuntu-latest` runners with a single,
> version-pinned Docker image (`ghcr.io/gmtfrombc/ci-base:2025-07-12`) and make
> all backend / integration / Flutter tests run deterministically in both GitHub
> Actions _and_ local `act`.

## TL;DR

- ✅ All workflows (`Build & Publish Image`, `Gitleaks`,
  `Backend & Integration`, `Flutter CI`) now pass in GitHub Actions and `act`.
- 🐳 **Single base image** supplies Flutter 3.32.6, Node 20.9, Deno 2.3.5,
  Supabase CLI, Python 3.12, Gitleaks, plus core CLI tooling.
- Postgres is provided by a lightweight service container; Android APK build is
  temporarily disabled until the SDK is baked into the image.

---

## Chronology of Issues & Fixes

| # | Symptom                                                      | Root Cause                                                                                                           | Fix                                                                                               | Commit / Action                                                 |
| - | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| 1 | `psql: not found` during **Setup PostgreSQL @ v7**           | Image lacked the Postgres _client_ binaries; the action only installed server packages under `/usr/lib/postgresql/…` | Added `postgresql-client` to `docker/ci-base/Dockerfile`; rebuilt & pushed `:2025-07-12`          | `ci: add postgresql-client to ci-base image`                    |
| 2 | Job container exited early with platform mismatch warning    | Manual push from M-chip Mac produced an **ARM-only** manifest; GitHub runners are AMD64                              | Rebuilt image via workflow (multi-arch) and re-triggered jobs                                     | Empty commit `ci: trigger backend job with fresh ci-base image` |
| 3 | SQLFluff failed: `disable_progress_bar` attribute error      | Upstream changed `click` ≥8.2 behaviour                                                                              | Pinned `click==8.1.7` in `tests/requirements-minimal.txt`                                         | `ci: fix backend job – …`                                       |
| 4 | Postgres step silently skipped in cloud runs                 | `SKIP_TERRAFORM` defaulted to `true` (meant for local `act`)                                                         | Set default to `"false"` in `.github/workflows/ci.yml`                                            | same as #3                                                      |
| 5 | **Setup PostgreSQL** action still flaky & slow               | Action installs server via `apt`; duplicate work & network flake                                                     | Replaced action with a `services:`-block: runs official `postgres:14` container with health-check | `ci: switch to Postgres service container`                      |
| 6 | Residual failures: psql & tests looked for `localhost:54322` | Service hostname inside workflow network is `postgres:5432`                                                          | Updated psql commands & `DB_HOST/DB_PORT` envs in workflow                                        | `ci: connect to Postgres service via hostname and default port` |
| 7 | **Flutter CI** failed at _Build APK_                         | Android SDK not yet installed in `ci-base`                                                                           | Added env flag `SKIP_ANDROID_BUILD=true` and wrapped _Build/Upload APK_ steps in conditionals     | `ci: temporarily skip Android APK build (no SDK in ci-base)`    |

All subsequent runs went green.

---

## Key Takeaways

1. **Bake runtime dependencies into the base image** (psql, Android SDK, etc.)
   to avoid network installs during workflow execution.
2. **Multi-arch pushes**: always push via CI to guarantee both `linux/amd64` &
   `linux/arm64` manifests.
3. Prefer **workflow `services:`** over third-party “setup” actions for
   databases—less magic, easier health-checks, deterministic.
4. Pin breaking Python deps (e.g., `click`) in `tests/requirements-minimal.txt`
   and periodically audit them.
5. Use feature flags like `SKIP_TERRAFORM` and `SKIP_ANDROID_BUILD` to harmonise
   cloud vs local (`act`) runs.

---

## Next Steps (Phase 1 Wishlist)

- Add Android command-line tools & SDK into `ci-base`, then re-enable APK build.
- Revisit Flutter widget performance thresholds (>800 ms) once emulator caching
  is tuned.
- Integrate Supabase CLI “DB reset” into the workflow to guarantee clean schema
  snapshots.
- Explore parallel test execution to cut job runtime.

---

_Compiled after six AI pairing sessions • Author: AI assistant • Date:
2025-07-12_
