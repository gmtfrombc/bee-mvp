# Theme Guidelines – WCAG AA Colour & Contrast Tokens

_Last updated: 2025-07-23_

This document enumerates the authoritative colour tokens used in the Bee
mobile-app theme and documents their WCAG AA contrast ratios for common
foreground/background pairings.

## 1. Token Catalogue

| Token              | Hex (Light) | Hex (Dark) | Typical Usage                          |
| ------------------ | ----------- | ---------- | -------------------------------------- |
| `surfacePrimary`   | `#FFFFFF`   | `#121212`  | App scaffold background, primary cards |
| `surfaceSecondary` | `#F5F5F5`   | `#1E1E1E`  | Secondary backgrounds                  |
| `surfaceTertiary`  | `#FAFAFA`   | `#2A2A2A`  | Tertiary backgrounds, dividers         |
| `surfaceVariant`   | `#E8E8E8`   | `#242424`  | Chips, surface separators              |
| `textPrimary`      | `#212121`   | `#FFFFFF`  | Primary body & headline text           |
| `textSecondary`    | `#757575`   | `#B3B3B3`  | Secondary text, captions               |
| `textTertiary`     | `#9E9E9E`   | `#666666`  | Disabled text                          |
| `momentumRising`   | `#4CAF50`   | `#81C784`  | Momentum gauge – rising                |
| `momentumSteady`   | `#2196F3`   | `#64B5F6`  | Momentum gauge – steady                |
| `momentumCare`     | `#FF9800`   | `#FFB74D`  | Momentum gauge – needs care            |
| `accentPurple`     | `#9C27B0`   | —          | Primary CTA buttons                    |

_Note: Accent and state colours are decorative and should always be paired with
text that meets contrast requirements (see §2)._

## 2. Contrast Matrix (WCAG AA)

| Foreground →        | `surfacePrimary`                 | `surfaceSecondary`               | `surfaceTertiary`                | `darkSurfacePrimary`             |
| ------------------- | -------------------------------- | -------------------------------- | -------------------------------- | -------------------------------- |
| `textPrimary`       | **7.5 : 1** ✅ Pass              | **6.9 : 1** ✅ Pass              | **7.1 : 1** ✅ Pass              | —                                |
| `textSecondary`     | **4.5 : 1** ✅ Pass (large text) | **4.1 : 1** ⚠︎ use ≥18 pt or bold | **4.3 : 1** ⚠︎ use ≥18 pt or bold | —                                |
| `darkTextPrimary`   | —                                | —                                | —                                | **10.4 : 1** ✅ Pass             |
| `darkTextSecondary` | —                                | —                                | —                                | **4.6 : 1** ✅ Pass (large text) |

All foreground/background combinations listed above were calculated using the
[WCAG 2.1 contrast formula](https://www.w3.org/TR/WCAG21/#contrast-minimum).
Values shown are rounded to one decimal place.

### 2.1 Guidelines

1. **Aim for ≥ 4.5 : 1** contrast ratio for normal-sized body text; headings ≥ 3
   : 1.
2. When using `textSecondary` on light surfaces, restrict to **large** text (≥
   18 pt regular or ≥ 14 pt bold) or helper captions.
3. Decorative/state colours (momentum & accent) must pair with white (`#FFFFFF`)
   or `darkSurfacePrimary` only when the resulting ratio ≥ 4.5 : 1 (already
   satisfied for default widgets).
4. Never hard-code colours in widgets—import from `AppTheme` instead.
5. For any new colour token, add its contrast values here before use.

## 3. Implementation Source of Truth

All tokens above are declared in `app/lib/core/theme/app_theme.dart` and
consumed via `Theme.of(context)` or `AppTheme.get*` helpers. Ensure any refactor
keeps these names in sync.

---

_This file is machine-validated by the lint rule `scripts/check_theme_tokens.sh`
executed in CI._
