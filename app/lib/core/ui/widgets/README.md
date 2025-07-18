# UI Foundation Widgets

This directory houses **re-usable, theme-aware widgets** that form the UI
foundation layer for the Bee Flutter app.

## Design Principles

1. **Single Source of Truth** – All generic form elements (text fields,
   dropdowns, buttons, snackbars) live here so that style tweaks propagate
   app-wide.
2. **Composition over Inheritance** – Feature widgets should **compose** these
   base widgets instead of building new variants or extending Material widgets
   directly.
3. **No Magic Numbers** – Use `ResponsiveService` for spacing/sizing and
   `Theme.of(context)` for colours and typography. This keeps the UI responsive
   and WCAG-compliant.
4. **Lint Enforcement** – A custom rule in `analysis_options.yaml` forbids raw
   `TextFormField` usage outside `core/` to ensure adoption.

## Available Widgets (tap to open code)

| Widget                                 | Purpose                                                                                                                                    |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `BeeTextField`                         | Labelled text field with validation, optional password toggle, suffix icon.                                                                |
| `BeeDropdown`                          | Labelled dropdown matching BeeTextField padding & decoration.                                                                              |
| `BeePrimaryButton`                     | Primary action button with optional loading spinner & icon.                                                                                |
| _(Domain-specific)_ `HealthInputField` | Numeric field with inline unit toggle (kg ↔ lbs, cm ↔ ft). Lives under `core/health_data/widgets/`, but built on top of the widgets above. |

> **Need a new control?** Add it here, document it, and update this table –
> don’t put generic UI code inside features.

## Further Reading

• Sprint PRD –
[UI Foundation Layer Refactor](../../../../docs/0_0_Core_docs/Refactor_projects/ui_foundation_layer_refactor_sprint.md)\
• Architecture spec –
[`docs/architecture/auto_flutter_architecture.md`](../../../../docs/architecture/auto_flutter_architecture.md)

---

_Last updated: 2025-07-18_
