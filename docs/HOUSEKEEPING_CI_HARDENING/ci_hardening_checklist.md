# CI Hardening Checklist for BEE‑MVP

> **Goal** – Eliminate environment drift and flaky, tool‑chain errors so tests pass locally _and_ in GitHub Actions.  
> **Audience** – AI Coder working on the BEE‑MVP repository.  
> **Outcome** – A reproducible, container‑based pipeline with fast feedback for PRs and full coverage on nightly builds.

---

## ☑️  Phase 0 – Pre‑work

| # | Task | Notes |
|---|------|-------|
| 0.1 | **Create a new feature branch** `ci‑hardening/<ticket>` | Keep changes isolated until the pipeline is green |
| 0.2 | **Install & update tooling**: Docker Desktop, `act`, Earthly (optional), Dagger (optional) | Needed for local reproduction |

---

## ☑️  Phase 1 – Lock the Toolchain

| # | Task | Acceptance |
|---|------|------------|
| 1.1 | Add versions to `/tools/versions.yml` & `asdf` or similar | Pin Flutter, Go, Node, Python, Deno |
| 1.2 | Update **`setup-*`** actions in every workflow:<br>`actions/setup-go@v5`, `subosito/flutter-action@v2`, `actions/setup-node@v4` | Explicit `go-version`, `flutter-version`, `node-version` |
| 1.3 | Commit lockfiles (`go.sum`, `package-lock.json`, etc.) | Prevent implicit upgrades |

---

## ☑️  Phase 2 – Build a Unified CI Docker Image

| # | Task | Acceptance |
|---|------|------------|
| 2.1 | Create `docker/ci-base/Dockerfile` that installs:<br>- Flutter SDK<br>- Go & gitleaks<br>- Python 3.12 & pytest<br>- Deno<br>- Supabase CLI<br>- `jq`, `bash`, `make` | Image builds locally with `docker build` |
| 2.2 | Push image to GHCR:`ghcr.io/bee/ci-base:latest` | Visible in repo packages |
| 2.3 | Replace `runs-on: ubuntu-latest` with: <br>`container:
  image: ghcr.io/bee/ci-base:latest` in every job | CI uses identical environment |

---

## ☑️  Phase 3 – Harden Shell Scripts

| # | Task | Acceptance |
|---|------|------------|
| 3.1 | Add `set -euo pipefail` to all project scripts | Fail fast on errors |
| 3.2 | Patch `scripts/check_secrets.sh` & any `jq` calls with null‑safe guards:<br>`jq -e '.[]? // empty'` | No more “Cannot iterate over null” |
| 3.3 | Audit Supabase CLI usage; export required env vars via `env:` in workflow | Secrets resolved at runtime |

---

## ☑️  Phase 4 – Split Fast vs. Slow Tests

| # | Task | Acceptance |
|---|------|------------|
| 4.1 | **Fast job** (`on: pull_request`):<br>- `flutter analyze && flutter test --coverage`<br>- `pytest -q`<br>- `deno lint`<br>- `gitleaks detect` | Finishes < 5 min |
| 4.2 | **Full job** (`on: schedule` + manual dispatch):<br>- Supabase Edge integration tests<br>- End‑to‑end tests | Runs nightly / on demand |

---

## ☑️  Phase 5 – Pre‑commit Layer

| # | Task | Acceptance |
|---|------|------------|
| 5.1 | Add `.pre-commit-config.yaml` with hooks:<br>`flutter format`, `flutter analyze`, `pytest -q`, `deno lint`, `gitleaks detect --staged` | Hooks pass locally |
| 5.2 | Document install in `CONTRIBUTING.md` | New devs run `pre-commit install` |

---

## ☑️ Phase 6 – Local Repro with `act`

| # | Task | Acceptance |
|---|------|------------|
| 6.1 | Configure `act` to pull the same container: <br>`-P ubuntu-latest=ghcr.io/bee/ci-base:latest` | `act pull_request` green |
| 6.2 | Add `make ci-local` shortcut that runs `act` plus common flags | One‑command local CI |

---

## ☑️ Phase 7 – Optional: Earthly / Dagger Migration

| # | Task | Acceptance |
|---|------|------------|
| 7.1 | Prototype an **Earthfile**: `earthly +all` spins up services & runs all tests | Replaces YAML eventually |
| 7.2 | Add small PoC job in Actions that calls Earthly | Works both locally & in CI |
| 7.3 | Evaluate Dagger SDK if Earthly doesn’t fit | Decision recorded in ADR |

---

## ☑️ Phase 8 – Cleanup & Documentation

| # | Task | Acceptance |
|---|------|------------|
| 8.1 | Remove redundant YAML steps now handled by Earthly/Docker | Workflows simplified |
| 8.2 | Update `README.md` and `docs/ci_overview.md` with new process | Docs in PR |
| 8.3 | Open follow‑up tickets for flaky test triage | List known flakes |

---

### Done ✓

Merge the feature branch only when **all** jobs pass on GitHub _Actions_ **and** via `act`, and the checklist items are ticked off in the PR description.
