# Component Architecture & Size Governance – BEE MVP

**Version:** 2.0\
**Last Updated:** 2025-01-15\
**Status:** Active

This document merges the former _Component Size Governance System_ and
_Component Architecture Guidelines_ into a single reference for all developers
and Cursor AI coders.

---

## 1 🎯 Core Principles

1. **Single Responsibility** – each file/class does one thing.
2. **Composition over Inheritance** – build UIs from smaller widgets.
3. **Clear Separation of Concerns** – UI ↔ services ↔ models live in distinct
   files.
4. **No God Files** – split any file that exceeds size limits or mixes layers.
5. **Consistent Naming & Structure** – predictable paths and identifiers.

---

## 2 📏 Size Limits

| Component Type        | Line Limit | Rationale                                    |
| --------------------- | ---------- | -------------------------------------------- |
| **Services**          | ≤ 500      | Maintain single responsibility & testability |
| **UI Widgets**        | ≤ 300      | Promote reuse & reduce complexity            |
| **Screen Components** | ≤ 400      | Allow complex layouts without bloat          |
| **Modal Components**  | ≤ 250      | Keep modals focused & lightweight            |
| **Models**            | Flexible   | Complex data structures acceptable           |

_Critical threshold:_ >50 % over limit blocks CI. _Warning threshold:_ >20 %
requires refactor plan.

---

## 3 🗂️ Directory & Naming Conventions

```
app/lib/
├── core/                 # shared widgets, services, utils
│   ├── services/
│   ├── providers/
│   ├── models/
│   └── theme/
├── features/
│   └── {feature}/
│       ├── data/services/
│       ├── domain/models/
│       └── presentation/
│           ├── screens/
│           ├── widgets/
│           └── providers/
└── shared/widgets/       # reused UI components
```

File naming: `snake_case`, descriptive (`momentum_daily_score_card.dart`).\
Class naming: `PascalCase`, include type suffix (`MomentumGaugeWidget`).

---

## 4 🔧 State Management

- **Global/business state:** Riverpod v2 (`StateNotifier`, `AsyncNotifier`).
- **UI-only concerns:** local `StatefulWidget` state.
- One provider per data concern; avoid provider composition inside widgets.

---

## 5 🧪 Testing Guidelines

- Aim for ≥ 85 % coverage on business logic.
- Each _public_ method/service: 1 happy-path + 1 edge-case test.
- Tools: `flutter_test`, `mocktail`; `golden_toolkit` only when visual diffs
  matter.
- Test surface, not implementation details.

---

## 6 ⚡ Performance & Memory

- Prefer `const` constructors.
- Use `RepaintBoundary` for complex, frequently changing widgets.
- Avoid heavy calculations in `build()`; move to services or compute once.
- Dispose timers/streams in `dispose()`.

---

## 7 🛠️ Automated Governance

### 7.1 Tooling

| Tool / Script                      | Purpose                             |
| ---------------------------------- | ----------------------------------- |
| `.git/hooks/pre-commit`            | Blocks commits with size violations |
| `scripts/check_component_sizes.sh` | Local size scan                     |
| `scripts/component_size_audit.sh`  | Weekly compliance report            |
| `.github/workflows/ci.yml`         | CI enforcement + PR comments        |

### 7.2 Workflow

1. Run `./scripts/check_component_sizes.sh` before committing.
2. Fix or extract code if over threshold.
3. Commit – pre-commit hook enforces limits.
4. CI reruns checks; failure blocks merge.

---

## 8 🚀 Developer Quick Reference

| Action                      | Command / Tip                          |
| --------------------------- | -------------------------------------- |
| Quick size check            | `./scripts/check_component_sizes.sh`   |
| Generate audit report       | `./scripts/component_size_audit.sh`    |
| Test pre-commit hook        | `git add . && git commit -m "Test"`    |
| Extract oversized widget    | Split into header/body/footer widgets  |
| Refactor monolithic service | Decompose into focused service classes |

---

## 9 📚 Additional Resources

- CI workflow for size governance: `.github/workflows/ci.yml`
- Refactor examples: `docs/development/component_size_workflow.md`
- Code review checklist: `docs/development/code_review_checklist.md`

---

_End of document_
