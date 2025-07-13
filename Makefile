.PHONY: ci-local
ci-local:
	@bash scripts/run_ci_locally.sh $(ARGS) 

.PHONY: ci-fast
ci-fast:
	@JOB_FILTER=fast $(MAKE) ci-local 