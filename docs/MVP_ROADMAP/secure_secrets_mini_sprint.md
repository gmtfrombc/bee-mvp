# Mini-Sprint · Secrets Purge & Hardening

**Sprint ID:** SEC-01 | **Owner:** Security / DevOps | **Est. Duration:** 4 hrs
(single dev)

---

## 1 · Goals

1. Revoke every credential leaked in commits `7bb2491` → `HEAD`.
2. Generate fresh Supabase + GCP secrets and store them **outside** the repo.
3. Scrub all history of `.secrets` and any other secret artefacts.
4. Reinforce tooling (pre-commit + CI) so a missing scanner or weak rules can
   _never_ allow a leak.

---

## 2 · Success Criteria

- [ ] Old Supabase tokens/DB password are revoked and unusable.
- [ ] New secrets live in GitHub Secrets **and** `~/.bee_secrets/supabase.env`
      only.
- [ ] `.secrets` no longer exists in git history; repo passes GitGuardian scan.
- [ ] Pre-commit hook **fails** when `gitleaks` is absent.
- [ ] CI secret-scan blocks any commit that introduces real credentials.
- [ ] Documentation updated (`SECURITY.md`) with hardened process.

---

## 3 · Task Breakdown

| ID  | Description                                                                            | Est. | Owner  | Dep.   |
| --- | -------------------------------------------------------------------------------------- | ---- | ------ | ------ |
| T1  | **Revoke Supabase access token / service-role key / DB password** from dashboard       | 15 m | DevOps | —      |
| T2  | **Generate new Supabase creds**; update GitHub Secrets + `~/.bee_secrets/supabase.env` | 15 m | DevOps | T1     |
| T3  | **Create new GCP service-account key**, base-64 encode, add to GitHub Secrets          | 20 m | DevOps | —      |
| T4  | **Purge `.secrets` from git history** using `git filter-repo`; force-push              | 25 m | DevOps | T2, T3 |
| T5  | Add placeholder file `.secrets.example`; reinforce `.gitignore` entry                  | 5 m  | Dev    |        |
| T6  | **Update pre-commit hook** → exit non-zero if `gitleaks` not installed                 | 15 m | Dev    |        |
| T7  | **Tighten `.gitleaks.toml`**: re-enable `generic-api-key`, add Supabase/GCP regexes    | 20 m | Dev    |        |
| T8  | **CI:** ensure `scripts/check_secrets.sh` runs _and_ fails build on findings           | 10 m | Dev    |        |
| T9  | **Validate**: run `gitleaks detect --source .` and GitGuardian scan → zero findings    | 10 m | QA     | T4–T8  |
| T10 | Update `SECURITY.md` & README with new workflow                                        | 10 m | Docs   | T9     |

_Total ≈ 140 min (buffered to 4 hrs)._

---

## 4 · Detailed Steps & CLI Snippets

> The following commands assume you’re on the `main` branch and have the GitHub
> CLI + Supabase CLI installed.

### 4.1 · Revoke & Regenerate Supabase Credentials

```bash
# Login to Supabase CLI (opens browser)
supabase login

# Switch to project
supabase switch okptsizou   # replace with your project ref if different

# 1. Revoke old keys in dashboard → Settings > API (manual UI step)
# 2. Generate new Service Role & anon keys, plus DB password (dashboard)
# 3. Copy them locally

cat > ~/.bee_secrets/supabase.env <<'EOF'
SUPABASE_ACCESS_TOKEN="<NEW_ACCESS_TOKEN>"
SUPABASE_SERVICE_ROLE_SECRET="<NEW_SERVICE_ROLE_KEY>"
SUPABASE_URL="https://<project>.supabase.co"
SUPABASE_PROJECT_REF="<project-ref>"
SUPABASE_DB_PASSWORD="<new-db-pass>"
EOF
```

### 4.2 · Rotate GCP Service-Account Key

```bash
# In Google Cloud console → IAM & Admin → Service Accounts
# 1. Select the CI account, click “Keys” → “Add key” → JSON → Create.
# 2. Base-64 encode and store ONLY in GitHub Secrets + env vault.
base64 -w0 ./ci-account-key.json > /tmp/gcp_key.b64
```

Add `GCP_SA_KEY` in GitHub Secrets from the `/tmp/gcp_key.b64` output.

### 4.3 · Purge `.secrets` from History

```bash
pip install git-filter-repo  # if not installed

# Backup
git clone --mirror git@github.com:your_org/bee-mvp.git bee-mvp_backup.git

# Purge the file in current repo
git filter-repo --path .secrets --invert-paths --force

# Force-push (make sure collaborators are aware!)
git push --force origin main
```

### 4.4 · Reinforce Tooling

1. **Pre-commit hook** (`.githooks/pre-commit`):
   ```bash
   # If gitleaks missing → abort commit
   if ! command -v gitleaks >/dev/null 2>&1; then
       echo "❌  Gitleaks is not installed. Install it before committing." >&2
       exit 1
   fi
   ```
2. **Gitleaks config** (`.gitleaks.toml`):
   ```toml
   # Remove from disabledRules
   # disabledRules = ["generic-api-key"]

   # Add explicit Supabase key pattern
   [[rules]]
   id          = "supabase-access-token"
   description = "Supabase Access Token"
   regex       = '''sbp_[A-Za-z0-9]{32,}'''
   secretGroup = 0
   entropy     = 3.5
   ```
3. Keep **`.secrets.example`** (placeholders only); never generate `.secrets`
   in-tree.

### 4.5 · Validation & Documentation

```bash
# Local scan
gitleaks detect --source . --no-banner --exit-code 1
# GitGuardian
curl -X POST https://api.gitguardian.com/v1/scan ...
```

Update `SECURITY.md` with the tightened process and remind devs to run
`brew install gitleaks`.

---

## 5 · Roll-out Checklist

- [ ] Notify all collaborators about force-push & ask them to re-clone.
- [ ] Remove any CI/CD secrets cached in runners.
- [ ] Invalidate old Docker image layers that might contain secrets.
- [ ] Confirm production deploys succeed with new credentials.

---

## 6 · References

- Supabase: docs → Project API keys & Access Tokens
- GitLeaks: <https://github.com/gitleaks/gitleaks>
- GitHub Docs: Removing sensitive data from a repository
