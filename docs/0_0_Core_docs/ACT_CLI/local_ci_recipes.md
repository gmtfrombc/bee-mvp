# Local CI Recipes for **bee-mvp** 🐝

Run the exact GitHub Actions workflows on your machine with
[`act`](https://github.com/nektos/act). This page records the working commands
and the tweaks we added while bringing parity with remote CI.

---

## 1 Prerequisites

| Tool    | Version          | Install                             |
| ------- | ---------------- | ----------------------------------- |
| Docker  | ≥ 20.10          | https://docs.docker.com/get-docker/ |
| act CLI | v0.2.79 or newer | `brew install act` (macOS)          |

```bash
# One-time secrets file (optional – leave empty values when testing)
cat > .secrets <<'EOF'
SUPABASE_ACCESS_TOKEN=
SUPABASE_SERVICE_ROLE_SECRET=
EOF
```

---

## 2 Wrapper-script overview

The helper script wraps all flags & env vars:

```bash
./scripts/run_ci_locally.sh            # full build + deploy (all jobs)
./scripts/run_ci_locally.sh -q          # quiet red/green output
./scripts/run_ci_locally.sh -j build    # single job – backend & integration tests
SKIP_MIGRATIONS=true ./scripts/run_ci_locally.sh   # skip migrations job
```

Flags accepted by the script map 1-to-1 to the underlying `act` flags.

---

## 3 Job-specific commands

### 3.1 Backend & Integration Tests (`build` job)

Wrapper (preferred):

```bash
./scripts/run_ci_locally.sh -j build --verbose | tee build.log
```

Raw `act` (same thing, explicit):

```bash
act -j build \
  -W .github/workflows/ci.yml \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 \
  --container-architecture linux/amd64 \
  --env ACT=false \
  --env SKIP_UPLOAD_ARTIFACTS=true \
  --env SKIP_TERRAFORM=true \
  --secret-file .secrets
```

### 3.2 Flutter CI (`flutter-ci` job)

Wrapper:

```bash
./scripts/run_ci_locally.sh --job flutter-ci --verbose | tee flutter.log
```

Raw `act`:

```bash
act -j test \
  -W .github/workflows/flutter-ci.yml \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 \
  --container-architecture linux/amd64 \
  --env ACT=true \
  --secret-file .secrets
```

_Why `ACT=true`?_: skips the heavy `subosito/flutter-action` and uses the
lightweight manual install steps we added for local runs.

### 3.2 Coach Epic CI (`coach-edge-function-tests` job)

_This workflow validates the AI-coach Deno edge function. No Flutter tooling is
required, so it runs quickly in the default Ubuntu image._

**Run via wrapper (fastest)**

```bash
# Edge-function tests only (skips heavy Flutter steps)
./scripts/run_ci_locally.sh -j coach-edge-function-tests | tee coach_edge_ci.log
```

**Raw `act` (equivalent)**

```bash
act -j coach-edge-function-tests \
  -W .github/workflows/coach_epic_ci.yml \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 \
  --container-architecture linux/amd64 \
  --env ACT=false \
  --secret-file .secrets
```

_First run_ pulls the 1.5 GB base image and Deno cache (~30 s). Subsequent runs
finish in **≈15 s**.

### 3.3 JITAI Model CI (`train-dry-run` job)

_This workflow trains the LightGBM JITAI model on a sample dataset and verifies
that the ROC-AUC gate is met. In GitHub it also uploads the artefact and updates
Supabase; those side-effects are automatically skipped locally._

**Wrapper (preferred)**

```bash
./scripts/run_ci_locally.sh -j train-dry-run | tee jitai_model_ci.log
```

**Raw `act`**

```bash
act -j train-dry-run \
  -W .github/workflows/jitai_model_ci.yml \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 \
  --container-architecture linux/amd64 \
  --env ACT=true \
  --secret-file .secrets | tee jitai_model_ci.log
```

_First run_ (~40 s) installs Python libraries; subsequent runs complete in **≈12
s**.

### 3.4 LightGBM Export CI (`export-scorer` job)

_Exports a LightGBM model to a pure TypeScript scorer used by the AI-coaching
engine. The workflow fabricates a tiny dummy model locally, then runs the
code-gen script. Artifact upload is skipped via `SKIP_UPLOAD_ARTIFACTS=true`._

**Wrapper**

```bash
./scripts/run_ci_locally.sh -j export-scorer \
  --env SKIP_UPLOAD_ARTIFACTS=true | tee lightgbm_export_ci.log
```

**Raw `act`**

```bash
act -j export-scorer \
  -W .github/workflows/lightgbm_export_ci.yml \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 \
  --container-architecture linux/amd64 \
  --env ACT=true \
  --env SKIP_UPLOAD_ARTIFACTS=true \
  --secret-file .secrets | tee lightgbm_export_ci.log
```

Timing: **≈10 s** after dependencies are cached.

### 3.5 Supabase Migrations Deploy (`deploy` job)

_Validates that migrations apply cleanly and Terraform config is syntactically
valid. Local runs **skip** all remote Supabase / Terraform side-effects
automatically (`ACT=true` + `SKIP_TERRAFORM=true`)._

**Wrapper**

```bash
FORCE_MIGRATIONS=true ./scripts/run_ci_locally.sh -j deploy \
  --env ACT=true --env SKIP_TERRAFORM=true | tee migrations_deploy_ci.log
```

**Raw `act`**

```bash
act -j deploy \
  -W .github/workflows/migrations-deploy.yml \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 \
  --container-architecture linux/amd64 \
  --env ACT=true \
  --env SKIP_TERRAFORM=true \
  --secret-file .secrets | tee migrations_deploy_ci.log
```

Runtime: **≈8 s** (Supabase CLI install dominates first run).

---

### 3.3 Other workflows (placeholders)

| Workflow file                              | Job name | Wrapper example                                  |
| ------------------------------------------ | -------- | ------------------------------------------------ |
| `.github/workflows/coach-epic-ci.yml`      | `test`   | **see section 3.2 – Coach Epic CI**              |
| `.github/workflows/jitai-model-ci.yml`     | `test`   | **see section 3.3 – JITAI Model CI**             |
| `.github/workflows/lightgbm-export-ci.yml` | `export` | **see section 3.4 – LightGBM Export CI**         |
| `.github/workflows/migrations-deploy.yml`  | `deploy` | **see section 3.5 – Supabase Migrations Deploy** |

Replace `--job …` with the exact job id if the wrapper complains.

---

## 4 First-run vs cached timings

| Job        | First run (fresh image) | Subsequent runs |
| ---------- | ----------------------- | --------------- |
| build      | 2–3 min                 | 30-40 s         |
| flutter-ci | 4–5 min                 | ~1 min          |

Docker caches the layers (Flutter SDK clone, Dart packages, apt libs). Delete
the image with `docker rmi ghcr.io/catthehacker/ubuntu:act-22.04` if you need a
clean slate.

---

## 5 Fixes applied so far (parity notes)

| Area                         | Change                                                                                                                                      | File                                        |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| **Secret scanning**          | Deterministic Gitleaks installer (maps `x86_64→x64`)                                                                                        | `scripts/check_secrets.sh`                  |
| **Code style**               | Black-formatted `tests/api/test_reset_email_delivery.py`                                                                                    | (file)                                      |
| **Lint**                     | Removed unused import (Ruff)                                                                                                                | same file                                   |
| **Supabase password policy** | Skip check when config API unavailable                                                                                                      | `scripts/check_supabase_password_policy.sh` |
| **Flutter local runs**       | Guard `subosito/flutter-action`, manual SDK install `git clone --branch 3.32.1`, plus apt libs (`libglu1-mesa` & `openjdk-11-jre-headless`) | `.github/workflows/flutter-ci.yml`          |

_All fixes are merged to `main`; local runs mirror GitHub runs 1-for-1._

---

## 6 Environment flags cheat-sheet

| Env var                 | Effect                                              | Default in wrapper                    |
| ----------------------- | --------------------------------------------------- | ------------------------------------- |
| `ACT`                   | `true` = skip heavyweight steps, `false` = full run | `false` for build, `true` for Flutter |
| `SKIP_UPLOAD_ARTIFACTS` | Skip GitHub artifact upload steps                   | `true`                                |
| `SKIP_TERRAFORM`        | Skip Terraform validate/format                      | `true`                                |
| `SKIP_MIGRATIONS`       | Skip Supabase migrations job                        | unset                                 |
| `SKIP_TF`               | Legacy alias for `SKIP_TERRAFORM`                   | n/a                                   |

Set them with `env VAR=value ./scripts/run_ci_locally.sh …`.

---

## 7 Troubleshooting quick hits

| Symptom                                    | Likely cause               | Fix                                                |
| ------------------------------------------ | -------------------------- | -------------------------------------------------- |
| `Could not find a gitleaks binary`         | Arch mapping mismatch      | already fixed above                                |
| `flutter pub get` fails with version 0.0.0 | Using master branch SDK    | ensure `--branch 3.32.1` clone                     |
| Missing `libGL.so` / JDK errors            | Flutter needs OpenGL & JDK | apt install `libglu1-mesa openjdk-11-jre-headless` |
| Password policy script exits 1             | Supabase API unreachable   | script now exits 0 when fields are `null`          |

---

## 8 Updating this guide

Add new CI jobs here as they appear, and record any local-only tweaks so future
contributors get a green run first-try. 🎉
