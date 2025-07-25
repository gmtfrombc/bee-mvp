# BEE (Behavioral Engagement Engine) MVP

![Coverage](https://img.shields.io/badge/coverage-45%25-brightgreen.svg)

> **Start here.** This is the main repository for the BEE MVP project.

## Project Overview

BEE is a behavioral engagement platform focused on health and wellness tracking.
This repository contains the complete MVP implementation including:

- **Flutter Mobile App** (`app/`) - Cross-platform mobile application
- **Supabase Backend** (`supabase/`) - Database, authentication, and APIs
- **Cloud Functions** (`functions/`) - Serverless backend logic
- **Infrastructure** (`infra/`) - Terraform infrastructure as code
- **Documentation** (`docs/`) - Comprehensive project documentation

## Quick Start

### Prerequisites

- Flutter SDK (latest stable)
- Node.js 18+
- PostgreSQL 14+
- Python 3.8+ (for testing)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bee-mvp
   ```

2. **Set up Flutter app**
   ```bash
   cd app
   flutter pub get
   flutter run
   ```

3. **Set up Supabase locally**
   ```bash
   cd supabase
   npx supabase start
   ```

## Testing

### Database RLS Tests

Run the minimal Row-Level Security tests for the engagement events system:

```bash
pytest tests/db/test_rls.py
```

**Prerequisites for RLS tests:**

- PostgreSQL running locally (host=localhost, user=postgres, db=test)
- `psycopg2-binary` and `pytest` packages installed
- `engagement_events` table with RLS policies enabled

**Install test dependencies:**

```bash
# Recommended: Use virtual environment (especially on macOS)
python3 -m venv venv
source venv/bin/activate
pip install -r tests/requirements-minimal.txt

# Alternative: Install directly (may require --user flag on some systems)
pip install -r tests/requirements-minimal.txt
```

### Full Test Suite

Run all tests including comprehensive API and performance tests:

```bash
# Database tests
python tests/run_all_tests.py

# Flutter tests
cd app && flutter test

# API tests
cd tests/api && ./test_engagement_events_api.sh
```

## Project Structure

```
bee-mvp/
├── app/                    # Flutter mobile application
├── supabase/              # Database migrations and configuration
├── functions/             # Cloud Functions (serverless backend)
├── infra/                 # Terraform infrastructure
├── tests/                 # Test suites and scripts
├── docs/                  # Project documentation
└── modules/               # Feature modules and specifications
```

## Documentation

🎯 **[Project Structure](docs/0_Initial_docs/bee_project_structure.md)** -
**START HERE** for unified development plan

📖 **[Complete Documentation Hub](docs/README.md)** - Full navigation

**Quick Links:**

- **[Architecture](docs/0_Initial_docs/bee_mvp_architecture.md)** - Technical
  architecture
- **[API Usage Guide](docs/2_epic_2_1/implementation/api-usage-guide.md)** -
  Flutter integration examples
- **[Operational Runbook](docs/2_epic_2_1/docs/operational-runbook.md)** -
  Production operations

## Development Workflow

### Continuous Integration

The CI pipeline runs automatically on push and pull requests:

1. **Flutter Tests** - Unit and widget tests
2. **Terraform Validation** - Infrastructure code validation
3. **Database RLS Tests** - Row-Level Security verification

### Local CI with `act`

You can reproduce the **exact** GitHub Actions pipeline offline with one
command:

```bash
make ci-local              # full workflow (same as push to PR)
make ci-local ARGS="-j fast"  # only fast pull-request job
```

How it works:

1. `.actrc` maps `ubuntu-latest` → `ghcr.io/gmtfrombc/ci-base:latest` so the
   toolchain matches CI.
2. `scripts/run_ci_locally.sh` auto-creates a `.secrets` file (stubbed if
   missing) and forwards env vars.
3. Apple-silicon Macs are handled automatically via
   `--container-architecture linux/amd64`.

For advanced usage you can still invoke **`act`** directly; see
`docs/0_0_Core_docs/ACT_CLI/README.md` for flags.

```bash
# direct call example (build job only)
act pull_request -j fast \
  -P ubuntu-latest=ghcr.io/gmtfrombc/ci-base:latest \
  --container-architecture linux/amd64 \
  --secret-file .secrets
```

The workflow detects the `ACT` environment variable and automatically skips
Flutter and Postgres steps that require heavier containers, giving you a quick
green/red signal for Terraform, Python lint, and database migrations.

### Database Migrations

Apply database migrations:

```bash
cd supabase
npx supabase db push
```

### Deployment

Deploy to staging or production:

```bash
# Deploy infrastructure
cd infra && terraform apply

# Deploy Supabase database changes
cd supabase && npx supabase db push

# Deploy edge functions
cd supabase/functions && npm run deploy
```

## Contributing

1. Create a feature branch from `main`.
2. Commit code with accompanying tests (≥ 85 % coverage on logic-heavy modules).
3. Verify the full CI pipeline or run `act` locally.
4. Open a pull request and request review.

## License

[License information to be added]

---

_For detailed docs start with_
**[Project Overview](docs/0_Initial_docs/project_overview.md)**

## Security & Authentication

- Supabase email/password provider **enabled** (see project dashboard).
- **Password policy**: minimum 8 characters, at least 1 symbol.\
  This is enforced in Supabase Auth settings rather than in-code; no additional
  backend logic is required.
