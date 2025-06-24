# Sprint PRD – "Clean-Up: Uncommitted File Review"

> **Purpose** — guide an AI assistant and product owner through deciding which
> of the remaining modified / untracked files should be committed to the
> repository, deleted, or ignored.
>
> **Created:** 2025-06-22 | **Owner:** TBD | **Status:** Backlog

---

## 1 Background

During the 2025-06-22 hardening session we pushed all intentional lint/CI fixes,
but a sizeable set of files remain in the working tree:

- Modified source files (Dart, TS) whose changes were not part of today's work.
- Generated artefacts – coverage *.info, analysis logs, placeholder images, etc.
- Experimental docs, SQL migrations, and helper scripts.

These changes may contain valuable work-in-progress—or just local noise.
Committing them blindly risks breaking CI or cluttering the repo, but discarding
them could lose useful updates.

## 2 Goal of this Sprint

Review every file that shows up in `git status` and decide one of:

1. **Keep** – stage & commit (with meaningful message).
2. **Delete** – remove if clearly generated or obsolete.
3. **Ignore** – add pattern to `.gitignore` (e.g. coverage reports).

Outcome: _clean working tree, zero "modified/??" entries, no accidental loss of
work._

## 3 Actors

- **Product Owner (you)** – answers domain questions, approves deletions.
- **AI Assistant** – walks through diffs, proposes actions, executes git
  commands.

## 4 Step-by-Step Process

| # | Action                                 | Command / Tool                                                                     | Notes                                                     |
| - | -------------------------------------- | ---------------------------------------------------------------------------------- | --------------------------------------------------------- |
| 1 | List current changes                   | `git status -s`                                                                    | capture baseline count                                    |
| 2 | Loop over **modified** (\`M\`) files   | `git diff <file>`                                                                  | assistant summarises diff → owner decides keep/discard    |
| 3 | Stage kept mods                        | `git add <file>`                                                                   | group by feature for clean commits                        |
| 4 | Loop over **untracked** (\`??\`) files | For large dirs use `tree -L 2 <dir>`                                               | classify as **source**, **generated**, **docs**, **data** |
| 5 | Generated? → ignore                    | add glob to `.gitignore` then `git rm --cached <file>`                             |                                                           |
| 6 | Docs or SQL that matter?               | rename & move under correct `docs/` or `supabase/migrations/` path, then `git add` |                                                           |
| 7 | Delete trash                           | `git rm <file>`                                                                    | confirm with owner first                                  |
| 8 | Commit logical chunks                  | `git commit -m "feat/X or chore/clean"`                                            | multiple commits preferred over one lump                  |
| 9 | Push branch & open PR                  | `git push -u origin clean/uncommitted-review`                                      | CI must pass                                              |

### Automation helpers

- To bulk ignore coverage files:
  ```bash
  echo 'app/coverage/*.info' >> .gitignore
  git rm --cached app/coverage/*.info
  ```
- Preview image folders quickly:\
  `ls -R app/assets/images/placeholders | head`.

## 5 Success Criteria

- `git status` is clean on main branch.
- `.gitignore` updated for all artefact patterns.
- No unintended functional changes (CI green, app builds).

## 6 Risks & Mitigations

| Risk                           | Mitigation                                                              |
| ------------------------------ | ----------------------------------------------------------------------- |
| Deleting in-progress work      | PO reviews every proposed deletion. Git history retains backup.         |
| Committed secrets              | `gitleaks` pre-commit hook runs automatically.                          |
| Large binary assets bloat repo | store in `assets/` only if used by app; otherwise, add to `.gitignore`. |

## 7 Time-box

- **2–3 h** pairing session with AI assistant should suffice.

## 8 Next Steps

1. Move this PRD to project board "Hardening – Backlog".
2. Schedule session.
3. Start with Step 1 above.

---

_Document generated automatically at the end of the 2025-06-22 hardening day._
