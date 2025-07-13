.PHONY: ci-local
ci-local:
	@bash scripts/run_ci_locally.sh $(ARGS) 

.PHONY: ci-fast
ci-fast:
	@JOB_FILTER=fast $(MAKE) ci-local 

.PHONY: smart-test
smart-test:
	@changed=$$(git diff --name-only HEAD~1 | grep -E '^app/test/.*\.dart$$' || true); \
	if [ -z "$$changed" ]; then \
	  echo "No Dart test files changed in last commit. Skipping smart-test."; \
	else \
	  echo "Running updated tests:" $$changed; \
	  cd app && flutter test $$changed; \
	fi

.PHONY: ui-goldens
ui-goldens:
	@cd app && flutter test --update-goldens \
	  test/features/onboarding/ui/onboarding_pages_golden_test.dart 

.PHONY: ci-lite
ci-lite:
	@echo "🚀 Running lightweight CI (lint + unit tests)"; \
	cd app && flutter pub get >/dev/null; \
	flutter analyze --fatal-warnings --fatal-infos; \
	flutter test --exclude-tags golden; 