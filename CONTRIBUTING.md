# Contributing to BEE-MVP

Welcome! 🎉 Follow these quick steps to get your environment ready and keep our
CI pipeline green.

## 1. Clone & Branch

```bash
# Fork then clone
 git clone https://github.com/your-username/bee-mvp.git
 cd bee-mvp

# Always branch from up-to-date main
 git checkout main && git pull origin main --ff-only
 git checkout -b feature/your-task
```

## 2. Install Local Tooling

The project uses [pre-commit](https://pre-commit.com/) hooks to run the same
checks that GitHub Actions executes in CI (formatters, linters, secret scans).

```bash
# macOS (Homebrew)
brew install pre-commit gitleaks

# Debian/Ubuntu
sudo apt-get install -y pre-commit && \
  curl -sSL https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz | \
  tar -xz && sudo mv gitleaks /usr/local/bin
```

## 3. Activate the Hooks (one-time)

```bash
pre-commit install  # sets up .git/hooks/pre-commit
```

That’s it! Every `git commit` will now automatically:

1. Block accidental commits of `.env` files.
2. Scan your staged changes with **gitleaks**.
3. Run language-specific linters/formatters: • `flutter format` &
   `flutter analyze` • `pytest -q` (fast API tests)\
   • `deno lint` (Supabase edge functions)

If any check fails the commit is aborted with a helpful message. Fix the issue,
`git add` the changes, and commit again.

## 4. Typical Workflow

```bash
# Make changes
code .

# Run hooks manually (optional)
pre-commit run --all-files

# Commit
git commit -m "feat: add new momentum widget"

git push -u origin feature/your-task
```

Open a Pull Request and wait for the CI checks in GitHub Actions – they mirror
the local hooks for consistent results.

## 5. Need Help?

• **CI Failing locally?** Run `scripts/run_ci_locally.sh` (see
`docs/0_0_Core_docs/ACT_CLI/README.md`). • **Pre-commit unknown command?**
Ensure Homebrew (or your package manager) added it to `$PATH`. • **Gitleaks not
found?** Check the install section above.

Happy contributing! 🚀
