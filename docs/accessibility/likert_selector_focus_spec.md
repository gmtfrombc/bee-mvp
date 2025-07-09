# LikertSelector – Keyboard Focus & Accessibility Specification

_Last updated: {{DATE}} _

## 1. Purpose

The **LikertSelector** is a reusable widget that lets users choose a value on a
1–5 Likert scale. This specification defines the required keyboard navigation,
screen-reader semantics, and WCAG alignment so that the component is fully
operable by assistive technologies (AT) out-of-the-box.

## 2. Keyboard Navigation Behaviour

| Action               | Expected Behaviour                                                                        |
| -------------------- | ----------------------------------------------------------------------------------------- |
| `Tab` on first entry | Sets focus **to the entire group** (semantic `RadioGroup`). The first option gains focus. |
| `← / →` Arrow        | Move focus **and** selection one step left/right, wrapping is **not** allowed.            |
| `Space` or `Enter`   | Confirms current option (sets `selected = true`).                                         |
| `Esc`                | Cancels changes _within_ the group & returns focus to previous element.                   |
| `Shift + Tab`        | Leaves the group, moving focus back to the previous focusable element.                    |

### Focus Order Example

1. _Previous form field_
2. **LikertSelector Group**
   1. Option 1 (value 1)
   2. Option 2 (value 2)
   3. Option 3 (value 3)
   4. Option 4 (value 4)
   5. Option 5 (value 5)
3. _Next form field_

## 3. Semantics & Roles

- The entire widget exposes `role="radiogroup"` with an accessible name equal to
  the question prompt (provided via `semanticLabel`).
- Each chip exposes `role="radio"` with attributes:
  - `value` – the Likert score (1 … 5)
  - `checked` – **true** if selected
  - `tabIndex` – **0** only for the currently focused chip, **-1** for others
    (roving tabindex pattern).
- Screen-reader announcement example (VoiceOver macOS):
  > “Importance scale, radio group, five items. Three of five, selected. To
  > change selection, press arrow keys.”

## 4. WCAG 2.2 Mapping

| Guideline                   | Conformance Notes                                                                     |
| --------------------------- | ------------------------------------------------------------------------------------- |
| 2.1.1 Keyboard              | All functionality operable via keyboard (arrow keys & space).                         |
| 2.4.3 Focus Order           | Sequential focus order preserved as per example list above.                           |
| 3.3.2 Labels & Instructions | Question prompt used as accessible name.                                              |
| 4.1.2 Name / Role / Value   | Radiogroup & radios expose correct roles **and** update `checked` state on selection. |

## 5. Testing Requirements

1. **Widget test** – Simulate `Tab` then arrow keys; verify controller state
   changes & `SemanticsTester` emits correct flags.
2. **Manual AT test** – Checklist executed on:
   - VoiceOver (macOS / iOS)
   - TalkBack (Android)
   - NVDA (Windows)
3. Performance: P95 latency < 50 ms on selection.

## 6. Related Docs & References

- Design-system governance:
  [`component_governance.md`](../architecture/component_governance.md)
- [ARIA Authoring Practices – Radiogroup Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/radiobutton/)
- WCAG 2.2 specification – [w3.org/TR/WCAG22](https://www.w3.org/TR/WCAG22/)
