.PHONY: ci-local
ci-local:
	@JOB_FILTER=fast bash scripts/run_ci_locally.sh $(ARGS) 

.PHONY: ci-fast
ci-fast:
	@$(MAKE) db-smoke && \
	JOB_FILTER=fast $(MAKE) ci-local 

.PHONY: smart-test
smart-test:
	@bash scripts/smart_test.sh

.PHONY: ui-goldens
ui-goldens:
	@cd app && flutter test --update-goldens \
	  test/features/onboarding/ui/onboarding_pages_golden_test.dart 

.PHONY: db-start
db-start:
	@bash scripts/start_test_db.sh 

.PHONY: db-smoke
db-smoke:
	@echo "🏗  Running migration smoke test (Postgres)" && \
	eval $$(bash scripts/start_test_db.sh) && \
	set -e; files=$$(ls supabase/migrations/*.sql | sort); for f in $$files; do echo "→ $$f"; PGPASSWORD=postgres psql -h $$DB_HOST -p $$DB_PORT -U postgres -d test -v ON_ERROR_STOP=1 -f $$f; done && \
	echo "✅  Migrations applied successfully"

.PHONY: ci-lite
ci-lite:
	@echo "🚀 Running lightweight CI (lint + unit tests)"
	@cd app && flutter pub get >/dev/null && \
	  flutter analyze --fatal-warnings --fatal-infos && \
	  flutter test --exclude-tags golden 