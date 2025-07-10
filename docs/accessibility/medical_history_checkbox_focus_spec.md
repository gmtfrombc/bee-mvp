# Accessibility Focus Spec – Medical History Checkbox Grid

**Component**: `MedicalHistoryPage` → paginated `SliverGrid` of check-box tiles.

**Context**: Section 6 of onboarding collects health conditions. Users navigate
a paginated grid (3 cols × _n_ rows per page) of check-box tiles. Supports
keyboard & switch-access users.

---

## 1. Keyboard Navigation Model

Use the **Roving Tab-Index** pattern:

1. **Tab** enters the grid container once per page.
2. **Arrow keys** move focus _within_ the grid. • **← / →**: previous / next
   column.\
   • **↑ / ↓**: previous / next row.
3. **Space / Enter** toggles the focused checkbox.
4. **Page Down / Page Up** (or **Ctrl + ← / →**) moves to the next / previous
   page while preserving column index.
5. **Shift + Tab** exits the grid container.

### Focus Order Example (Page 1)

```
Row1: [0,0] Prediabetes   [0,1] Type 2 Diabetes  [0,2] Hypertension
Row2: [1,0] High Chol     [1,1] Triglycerides   [1,2] Obesity
Row3: [2,0] PCOS          [2,1] Fatty Liver     [2,2] CVD
```

Initial **Tab** → `[0,0]`. Arrow navigation then proceeds as matrix indices.

## 2. Semantic Mark-up Guidelines

• Each tile is a `Semantics` widget wrapping a `CheckboxListTile`.\
• Provide
`Semantics(label: <localized condition>, checked: …, inMutuallyExclusiveGroup: false)`.
• Announce page status via `Semantics(liveRegion: true)` – e.g. “Page 2 of 4”.

## 3. Focus Restoration

On return from helper dialogs, restore focus to last-focused tile via
`FocusNode` stored in state.

## 4. Switch-Access & Screen Readers

• Ensure row/column coordinates announced: “High cholesterol, row 2 column 1,
unchecked”.\
• Pagination buttons are standard `ElevatedButton`s placed _after_ grid in
traversal order.

## 5. WCAG Checklist

| Guideline                   | Status | Notes                                |
| --------------------------- | ------ | ------------------------------------ |
| 2.1.1 Keyboard              | ✅     | Full keyboard support per spec       |
| 2.4.3 Focus Order           | ✅     | Logical SR order matches visual grid |
| 1.3.1 Info & Relationships  | ✅     | Proper roles/labels via Semantics    |
| 3.2.1 Consistent Navigation | ✅     | Pagination controls consistent       |

---

_Last updated: {{DATE}}_
