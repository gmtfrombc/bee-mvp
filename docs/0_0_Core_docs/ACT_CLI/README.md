# Local CI Runs with `act` 🐳

> "Think globally, **act** locally" — run the exact GitHub Actions workflow the
> repo uses without pushing a single commit.

# Hardware: Macbook Air with M3 Apple chip

# NOTE: Run ACT with the following:

act push -W .github/workflows/ci.yml -P
ubuntu-latest=catthehacker/ubuntu:act-latest --env ACT=false --secret-file
.secrets --container-architecture linux/amd64 -j build

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
# Preferred – wraps all flags for you
./scripts/run_ci_locally.sh
```

Advanced: call `act` directly

```bash
act push \
  -W .github/workflows/ci.yml \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-22.04 \
  --container-architecture linux/amd64 \
  --env ACT=false \
  --secret-file .secrets
```

Flags explained:

- `push` – simulate a `push` event (same trigger used in CI).
- `-W` – limit execution to the main workflow file.
- `-P` – map `ubuntu-latest` to a runner image matching GitHub's toolchain
  (**act-22.04**, medium size).
- `--container-architecture linux/amd64` – some Apple-silicon Macs need this to
  avoid image-arch mismatch.
- `--env ACT=false` – ensures heavyweight steps **run** (they are skipped when
  `ACT=true`).
- `--secret-file` – inject the secrets created in step&nbsp;2.

ℹ️ The first invocation may take several minutes (image pull + Flutter SDK
install). Subsequent runs start almost instantly.

---

## 4. Useful commands

Partial-step execution (`--step`) was removed from `act` in v0.2.x. If you need
faster feedback, run the single job only:

```bash
act -j build \
  -W .github/workflows/ci.yml \
  --env ACT=false \
  --secret-file .secrets
```

That still spins up Flutter & Terraform—but avoids any other jobs (e.g. future
matrix builds).

---

## 5. Troubleshooting

| Symptom                              | Fix                                                                                                      |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| `docker: not found`                  | Start Docker Desktop or install Docker Engine.                                                           |
| "No such file or directory: flutter" | Ensure you pulled the large image (`-P ...act-latest`).                                                  |
| PostgreSQL port conflict             | Stop local DB containers, or change `port:` in the workflow and add `-e DB_PORT=...` when running `act`. |

---

## 6. CI parity & Terraform provider gotcha

Both GitHub-CI and local `act` runs now use exactly the same Docker runner image
(`ghcr.io/catthehacker/ubuntu:act-22.04`) plus identical env/secrets. If
something fails locally, it **will** fail remotely – and vice-versa.

Most common blocker: **Terraform Supabase provider**

```
Error: Invalid data source "supabase_project"
Error: Invalid resource type "supabase_migration"
```

The upstream provider (v1.x) no longer ships those legacy resources. In this
repo we stub them out (see `infra/main.tf`) so the `terraform validate` step can
pass. If you re-enable Supabase migrations, either:

1. Use the Supabase CLI in a separate CI step, or
2. Replace the removed blocks with supported provider resources (see Supabase
   docs).

> Tip: Want to iterate on application code but skip the heavy Terraform checks?
> Run:
>
> ```bash
> SKIP_TF=true ./scripts/run_ci_locally.sh -j build
> ```
>
> …after adding `if: env.SKIP_TF != 'true'` to the Terraform step in the
> workflow.

### Testing the Supabase migrations workflow locally

The Supabase DB-migration workflow lives in
`.github/workflows/migrations-deploy.yml` and defines a single job called
`deploy`.

Our helper script defaults to the **build** job used by backend & frontend
tests. To reproduce migration errors you must target the `deploy` job
explicitly:

```bash
# Run the deploy workflow and nothing else
./scripts/run_ci_locally.sh -j deploy
```

If you want to run **all** jobs (slower) simply omit the `-j` flag.

```bash
./scripts/run_ci_locally.sh   # build + deploy, identical to GitHub
```

⚠️ Without the extra `-j deploy` flag, local `act` runs will not touch the
Supabase CLI step, meaning provider/version errors can slip through. That's why
the GitHub run failed while our earlier local run (build-only) passed.

The helper script now **includes migrations by default**. If you only want the
fast build/test cycle (no Supabase calls), set:

```bash
SKIP_MIGRATIONS=true ./scripts/run_ci_locally.sh
```

---

Happy **offline-CI**! 🎉
