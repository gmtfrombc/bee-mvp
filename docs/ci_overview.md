# Continuous Integration Overview

This document summarizes the BEE-MVP CI pipeline and how to reproduce it
locally.

---

## 1. Pipeline at a Glance

| Layer               | Workflow file                       | Trigger                            | Duration | Key Jobs                                                                    |
| ------------------- | ----------------------------------- | ---------------------------------- | -------- | --------------------------------------------------------------------------- |
| **Fast Tests**      | `.github/workflows/fast-tests.yml`  | `pull_request`                     | < 5 min  | Flutter analyze & unit tests, Python API unit tests, Deno lint, secret scan |
| **Full Suite**      | `.github/workflows/full-tests.yml`  | nightly `schedule` + manual        | ~30 min  | Fast jobs + Android build, integration tests, Supabase Edge tests           |
| **Specialised CIs** | `flutter-ci`, `coach_epic_ci`, etc. | per-feature branches               | variable | Feature-specific validation                                                 |
| **Docker Image**    | `build-ci-base.yml`                 | on changes under `docker/ci-base/` | ~8 min   | Builds & publishes `ghcr.io/gmtfrombc/ci-base`                              |

All workflows run inside the **same container image** so toolchains are
identical between local and GitHub runners.

---

## 2. Local Reproduction with `act`

The repository ships a helper script **`scripts/run_ci_locally.sh`** and a
convenience **Makefile** target so you can run CI offline.

```bash
# full CI (fast + feature workflows)
make ci-local

# run only the fast pull-request job
make ci-local ARGS="-j fast"
```

### How it works

1. `.actrc` maps the generic `ubuntu-latest` runner to the published image:
   ```text
   -P ubuntu-latest=ghcr.io/gmtfrombc/ci-base:latest --container-architecture linux/amd64 --secret-file .secrets
   ```
2. The helper script ensures a `.secrets` file exists, then forwards all
   required environment variables so secret-dependent steps behave like real CI.
3. When Apple-silicon Macs need `amd64`, the flag is set automatically.

> **Tip:** Supply extra `act` flags via `ARGS="…"` to the Make target, e.g.
> `ARGS="--verbose"`.

---

## 3. Directory Cheatsheet

```
.github/workflows/    # YAML workflow definitions
scripts/run_ci_locally.sh  # helper that wraps `act`
.actrc                # per-repo defaults so `act` “just works”
Makefile              # developer shortcuts (ci-local)
```

---

## 4. Troubleshooting

| Symptom                                   | Fix                                                                  |
| ----------------------------------------- | -------------------------------------------------------------------- |
| `manifest unknown` when pulling the image | Run `docker login ghcr.io` with a PAT that has `read:packages` scope |
| Git leaks stage fails                     | Ensure pre-commit hook cleaned secrets before committing             |
| Flutter download slow                     | Use `make ci-local ARGS="-j fast"` to skip heavy jobs                |

---

Happy **green builds**! 🎉
