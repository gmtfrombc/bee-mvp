# Security Hardening Checklist

## Required Status Checks

Make the following jobs **required** in GitHub Branch Protection settings:

| Job Name            | Purpose                                   |
| ------------------- | ----------------------------------------- |
| `pre-commit-checks` | Runs full local hook suite incl. gitleaks |
| `gitleaks`          | Full-repo secret scan via GitHub Action   |

Navigate to **Settings → Branches → Branch protection rules** and add both jobs
under **Require status checks to pass**.

## Local Setup for Developers

```bash
brew install pre-commit gitleaks
pre-commit install
```

This ensures the same hooks run before every commit.
