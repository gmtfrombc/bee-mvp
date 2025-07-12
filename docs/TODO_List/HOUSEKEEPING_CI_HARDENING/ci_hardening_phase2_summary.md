 > **Scope**  
> Replace GitHub’s default `ubuntu-latest` runners with a single, version-pinned Docker image  
> `ghcr.io/gmtfrombc/ci-base:2025-07-12`, and make *all* backend, integration, and Flutter
> tests run deterministically in both GitHub Actions **and** local `act`.

---

## TL;DR

* ✅ Every workflow (`Build & Publish Image`, `Gitleaks`, `Backend & Integration`,
  `Flutter CI`) now passes in GitHub Actions **and** `act`.
* 🐳 **Single base image** provides:
  * Flutter 3.32.6
  * Node 20.9
  * Deno 2.3.5
  * Supabase CLI
  * Python 3.12
  * Gitleaks
  * Core CLI tools (`sudo`, `wget`, `jq`, etc.).
* PostgreSQL supplied via a lightweight service container (`postgres:14`);
  Android APK build is **temporarily skipped** until the SDK is baked into the image.

---

## Chronology of Issues & Fixes

| # | Symptom (failed step) | Root Cause | Fix / Commit |
|---|-----------------------|-----------|--------------|
| 1 | `psql: not found` during **Setup PostgreSQL @ v7** | Base image had server libs, but no client; health-check required `/usr/bin/psql`. | Added `postgresql-client` to `docker/ci-base/Dockerfile`; rebuilt & pushed image (`ci: add postgresql-client…`) |
| 2 | Container exited immediately with platform mismatch warning | Image was built on M-chip Mac → pushed **ARM-only** manifest; runners are AMD64. | CI job rebuilt multi-arch image; pushed by workflow. Re-ran Backend job (`ci: trigger backend job with fresh ci-base image`). |
| 3 | `disable_progress_bar` attribute error in SQLFluff lint step | SQLFluff 2.3.5 incompatible with `click` 8.2+. | Pinned `click==8.1.7` in `tests/requirements-minimal.txt` (`ci: fix backend job – pin click…`). |
| 4 | Postgres action still flaky under `act` / PATH trouble | `ikalnytskyi/action-setup-postgres` installs via `apt`; PATH & port mapping fragile. | Replaced action with **service container** in `.github/workflows/ci.yml` (`ci: switch to Postgres service container`). |
| 5 | Tests couldn’t connect: `psql: could not connect to server` | Steps still pointed to `localhost:54322`; service container hostname is `postgres:5432`. | Updated all psql commands & `DB_HOST/DB_PORT` envs (`ci: connect to Postgres service via hostname…`). |
| 6 | Flutter job failed at **Build APK** | Base image lacks Android SDK / NDK. | Introduced `SKIP_ANDROID_BUILD` env flag to skip APK build & upload (`ci: temporarily skip Android APK build…`). |

---

## Key Takeaways

1. **Pin everything.** A single immutable image removes “works-on-my-machine” drift.
2. **Service containers beat custom setup actions** for databases—simpler + reproducible.
3. Build multi-arch images from CI, not local M-series Macs, to avoid manifest snafus.
4. Keep Python test deps minimal & version-pinned; SQLFluff is especially picky.
5. When adding heavy toolchains (e.g., Android), bump base image *once* rather than
   installing on every CI run.

---

## Phase 1 Wishlist

* Add Android SDK & NDK to `ci-base`; re-enable APK build + upload.
* Slim the image layers (multi-stage build or `apt-get --no-install-recommends` everywhere).
* Parallelise Flutter widget tests; investigate >800 ms performance outliers.
* Cache Supabase CLI & Deno deps between jobs to shave minutes off `act` runs.
* Push nightly image rebuilds to catch upstream CVE fixes automatically.
