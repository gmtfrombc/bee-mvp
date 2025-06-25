# Vitals Refactor – Handoff Sprint

**Context:** Continuing modularisation of `VitalsNotifierService` (Epic
Task-Hardening).

---

## 1. Objective

Complete remaining tasks (6-10) in `vitals_notifier_service_refactor.md`, fully
replacing the old 1 700 LOC "god-file" with modular services that meet Component
Size Governance guidelines and maintain 100 % functional parity.

---

## 2. Current Status (as of commit `$(git rev-parse --short HEAD)`)

| Task | Description                          | Status      |
| ---- | ------------------------------------ | ----------- |
| 0    | Branch & baseline setup              | ✅ complete |
| 1    | Skeleton module folders              | ✅ complete |
| 2    | Pure helper extraction               | ✅ complete |
| 3    | Cache layer                          | ✅ complete |
| 4    | History & aggregation                | ✅ complete |
| 5    | Adapters (live / polling)            | ✅ complete |
| 6    | Subscription controller              | ⏳ pending  |
| 7    | Provider wiring & facade integration | ⏳ pending  |
| 8    | Legacy shim cleanup                  | ⏳ pending  |
| 9    | Perf / memory validation             | ⏳ pending  |
| 10   | Docs & release notes                 | ⏳ pending  |

All new unit tests pass (`flutter test`), including helper modules, cache,
aggregator, adapters.

---

## 3. Next Steps

1. **Task 6 – SubscriptionController** • Implement
   `stream_manager/subscription_controller.dart` to wire `LiveAdapter`,
   `PollingAdapter`, and `VitalsAggregator`. • Surface `VitalsConnectionStatus`
   stream. • Write widget-level test using mocked adapters verifying status
   transitions and merged output.

2. **Task 7 – Provider Wiring** • Expose new `VitalsService` facade in
   `vitals_facade.dart` that delegates to controller & cache. • Replace existing
   provider usage (search for `VitalsNotifierService()` instantiation) with the
   new facade. • Ensure dashboard widgets compile & existing widget tests pass.

3. **Task 8 – Deprecated Code Cleanup** • Remove/trim original
   `vitals_notifier_service.dart` (leave deprecation shim ≤ 100 LOC or delete).
   • Run `scripts/check_component_sizes.sh` – must report full compliance.

4. **Task 9 – Performance/Memory Validation** • Perform a 30-minute device run;
   ensure no leaks, p95 API latency < 1 s. • Optional: add integration test in
   `test_driver/` to simulate streaming for 5 min.

5. **Task 10 – Documentation & Release Notes** • Update `README` and
   architecture diagrams. • Add changelog entry and PR description.

---

## 4. Useful References

- Sprint plan: `docs/refactor/vitals_notifier_service_refactor.md`
- New modules: `app/lib/core/services/vitals/`
- Passing tests: `app/test/core/services/vitals/`

---

> Good luck! 🐝 The heavy lifting is done; focus on orchestration & integration.
