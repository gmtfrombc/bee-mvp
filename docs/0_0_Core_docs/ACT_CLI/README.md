# Local CI Runs with `act` 🐳

> "Think globally, **act** locally" — run the exact GitHub Actions workflow the
> repo uses without pushing a single commit.

---

## 1. Prerequisites

| Tool        | Version          | Install                                                                         |
| ----------- | ---------------- | ------------------------------------------------------------------------------- |
| **Docker**  | ≥ 20.10          | https://docs.docker.com/get-docker/                                             |
| **act** CLI | v0.2.79 or newer | `brew install act` (macOS) · [Releases](https://github.com/nektos/act/releases) |

Make sure Docker Desktop is running before invoking `act`.

---

## 2. One-time setup

1. **Clone** the repository and open a terminal at the repo root:
   ```bash
   git clone https://github.com/your-org/bee-mvp.git
   cd bee-mvp
   ```
2. **Create a secrets file** (optional). The CI workflow only needs a few
   Supabase secrets — you may leave them blank when testing locally:
   ```bash
   cat > .secrets <<'EOF'
   SUPABASE_ACCESS_TOKEN=
   SUPABASE_SERVICE_ROLE_SECRET=
   EOF
   ```
3. **Choose a base image**. Our workflow installs Flutter & Terraform, so the
   "large" Ubuntu image is recommended. The first run will download ~1.5 GB but
   will be cached afterwards.

---

## 3. Run the full CI workflow

```bash
# Runs `.github/workflows/ci.yml` exactly as GitHub does
act push \
  -W .github/workflows/ci.yml \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest \
  --env ACT=false \
  --secret-file .secrets
```

Flags explained:

- `push` – simulate a `push` event (same trigger used in CI).
- `-W` – limit execution to the main workflow file.
- `-P` – map the `ubuntu-latest` runner to the large pre-built image that has
  most tooling pre-installed.
- `--env ACT=false` – tells the workflow **not** to short-circuit the heavy
  database/test steps guarded with `if: ${{ env.ACT != 'true' }}` so the run
  mirrors GitHub-CI exactly.
- `--secret-file` – inject the secrets created in step 2.

ℹ️ The first invocation may take several minutes (image pull + Flutter SDK
install). Subsequent runs start almost instantly.

---

## 4. Running only fast Python/DB tests

If you just want to iterate on the backend tests and skip Flutter & Terraform
steps:

```bash
# Run only the database & Python sections of the job
act -j build --step 20 \
  -W .github/workflows/ci.yml \
  --secret-file .secrets
```

`--step 20` tells `act` to start at step 20 ("Setup PostgreSQL"), bypassing the
slow early phases. Adjust as needed (`act -l` lists numbered steps).

---

## 5. Useful commands

```bash
act -l                          # list all workflows / jobs detected
act -j build -n                 # dry-run (no containers executed)
act workflow_dispatch -l        # list dispatchable workflows
```

---

## 6. Troubleshooting

| Symptom                              | Fix                                                                                                      |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| `docker: not found`                  | Start Docker Desktop or install Docker Engine.                                                           |
| "No such file or directory: flutter" | Ensure you pulled the large image (`-P ...act-latest`).                                                  |
| PostgreSQL port conflict             | Stop local DB containers, or change `port:` in the workflow and add `-e DB_PORT=...` when running `act`. |

---

Happy **offline-CI**! 🎉
