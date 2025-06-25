# VitalsNotifier Service Modularisation Sprint

**Epic:** Task-Hardening ✓\
**Sprint Window:** _TBD_ (estimate ≈ 2.5 dev-days)\
**Owners:** @core-services team

---

## 1 Objective

Refactor `app/lib/core/services/vitals_notifier_service.dart` (≈ 1 740 LOC) into
a set of focused, maintainable modules while guaranteeing **zero functional
regressions**. Each extraction step must:

- Respect size limits defined in `docs/architecture/component_governance.md` (≤
  500 LOC/service).
- Preserve the existing public API consumed by widgets & providers.
- Land with passing **unit + widget + integration tests**.

---

## 2 Deliverables

1. New modular directory: `lib/core/services/vitals/` with ≤ 10 target files.
2. Updated Riverpod provider exposing the same facade (`VitalsService`).
3. ≥ 85 % test coverage for the new modules; 100 % of pre-refactor test suite
   green.
4. Migration guide & CHANGELOG entry.

---

## 3 Work-Breakdown & Quality Gates

| #  | Task                                                                                                 | Success Criteria                                                                                                                                       | Test/Gate                                               |
| -- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------- |
| 0  | **Branch & Baseline**✅<br/>`git checkout -b refactor/vitals-modularisation`                         | All existing lints & CI tests pass on branch.                                                                                                          | CI ✅                                                   |
| 1  | **Skeleton Folders**✅ in `lib/core/services/vitals/`                                                | Empty classes/interfaces scaffolded; no behavioural change.                                                                                            | CI ✅                                                   |
| 2  | **Extract Pure Helpers**<br/>`numeric_helpers.dart`, `step_deduplicator.dart`, `sleep_analyzer.dart` | • Helpers moved verbatim.<br/>• Public API unchanged.<br/>• New unit tests added (happy & edge cases).                                                 | `flutter test` ✅ + 85 % coverage on helpers            |
| 3  | **Cache Layer**<br/>`vitals_cache.dart`                                                              | • SharedPreferences logic isolated.<br/>• VitalsNotifier now delegates.<br/>• Backward-compat JSON schema maintained.                                  | Unit tests mocking `SharedPreferences`                  |
| 4  | **History & Aggregations**<br/>`vitals_aggregator.dart`                                              | • History buffer & retention, steps/energy/sleep aggregation extracted.<br/>• Public static test hooks preserved.<br/>• Coverage ≥ 90 % on aggregator. | Unit + golden snapshot of aggregates                    |
| 5  | **Adapters**<br/>`live_adapter.dart` & `polling_adapter.dart`                                        | • All stream/poll logic moved.<br/>• Retry/back-off handled inside polling adapter.<br/>• Facade still passes integration tests.                       | Mock WearableLiveService & Repository integration tests |
| 6  | **Subscription Controller**<br/>`subscription_controller.dart`                                       | • Orchestrates adapters ↔ aggregator.<br/>• Keeps connection status logic.<br/>• Service facade simplified to ≤ 150 LOC.                               | End-to-end widget test (Dashboard)                      |
| 7  | **Provider Wiring**                                                                                  | • New `vitals_facade.dart` exposes same Stream API.<br/>• Widgets compile & run without changes.                                                       | Full widget test suite                                  |
| 8  | **Deprecated Code Cleanup**                                                                          | • Remove legacy methods in original file.<br/>• Ensure file < 100 LOC (shim only) or delete if unused.                                                 | `scripts/check_component_sizes.sh` passes               |
| 9  | **Performance / Memory Validation**                                                                  | • p95 latency unchanged (< 1 s).<br/>• No memory leaks during 30-min profiling session.                                                                | Manual run + `integration_test/perf`                    |
| 10 | **Documentation & Release Notes**                                                                    | • Update `README`, add UML diagram.<br/>• Changelog entry for v0.x.x.                                                                                  | Docs review                                             |

---

## 4 Testing Strategy

- **Unit Tests** – for every new module (helpers, cache, aggregator, adapters).
- **Widget Tests** – Sleep & Steps tiles render with mocked streams.
- **Integration Tests** – End-to-end subscription flow using mocked HealthKit +
  Live service.
- **Regression Suite** – Run existing `test/` folder; must stay green after each
  task.
- **CI Enforcement** – PR must pass `scripts/check_component_sizes.sh`,
  `flutter analyze`, and `flutter test --coverage`.

---

## 5 Risk Mitigation

1. **Behaviour drift** – Use snapshot tests to compare aggregates before & after
   each step.
2. **Hidden state coupling** – Introduce clearly defined event/data classes;
   avoid singleton state outside aggregator.
3. **API breakage** – Keep facade signature identical; deprecate gradually.
4. **Timeline slip** – Each sub-task individually shippable; can halt after any
   green checkpoint.

---

## 6 Definition of Done

- All tasks #0-10 checked ✅.
- Size check passes for every new file.
- Test coverage report ≥ 85 %.
- App boots & dashboard displays live vitals on a physical device.
- PO/QA sign-off.

---

> _"Small modules make for a healthy heart-rate – both in code and in life."_ 🐝
