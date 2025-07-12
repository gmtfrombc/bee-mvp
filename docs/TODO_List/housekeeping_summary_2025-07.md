> _Generated automatically by Cursor AI on **2025-07-11** during the post-Epic 1.11 hardening pause._  
> This document aggregates the current state, risks, and recommended priority for every open “housekeeping” track in `docs/TODO_List/`.  
> **Legend**  
> • **Priority** – lower number = address sooner.  
> • **Blocking** – prevents work on the next user-facing Epic if unresolved.  
> • **Risk** – **S** (security / compliance), **P** (productivity / CI flake), **M** (maintainability), **L** (latent future break).

| # | Housekeeping Category | Blocking | Risk | Current Status | Key Gaps / Notes | Priority |
|---|----------------------|----------|------|----------------|------------------|----------|
| 1 | **Supabase Password-Policy Enforcement** | No (disabled) | **S** – HIPAA | Enforcement scripts short-circuited; CI always passes. | Production lacks automated guard-rail on password strength. | **1** |
| 2 | **CI Hardening** (`ci_hardening_checklist.md`) | No | **P** | Checklist drafted; no locked tool versions or unified container. | Tool-chain drift & env mismatch between local ⇄ Actions. | **2** |
| 3 | **Component Size Governance** (`component_size_refactor_sprint.md`) | No | **M** | Audit & sprint PRD created; ≈45 Dart, 4 TS, 4 large Py tests exceed limits. | Refactor & extend size checks to *.dart, *.ts, *.py. | **3** |
| 4 | **Deno + std Upgrade** (`edge_function_deno_upgrade_prd.md`) | No (for now) | **L** | All edge-functions import `std@0.168`; one file ≥ 870 LOC. | Future Supabase runtime upgrade will break builds. | **4** |
| 5 | **Improve Test Coverage** (`coverage_sprint.md`) | No | **M** | Coverage gate lowered to 40 %; target is 60 %. | Write tests & gradually raise thresholds. | **5** |
| 6 | **Local Supabase Mini-Stack** (`epic_local_supabase_mini_stack.md`) | No | **L** | No local service container; contract tests use in-memory stubs. | Needed for full RLS testing offline. | **6** |

---

## Recommended Next Steps

1. **Re-enable Supabase password-policy enforcement** (or formally accept risk).  
   • Migrate fragile Bash patch to a typed script (Node/TS).  
   • Run a weekly scheduled check instead of every PR to avoid flakes.

2. **Kick-off CI Hardening Phase 1** – pin tool versions & publish `ci-base` Docker image.  
   • Immediate gain: deterministic local ↔ CI behaviour; faster flake triage.

3. Execute **Component Size Governance sprint** (see detailed PRD).  
   • Improves maintainability and unblocks future feature work.

4. Plan a **Deno upgrade spike** in parallel with feature work; keep behind flag.  
   • Avoid forced hot-fix when Supabase Cloud bumps runtime.

5. Begin incremental **coverage tasks**; raise threshold to 45 % in the first PR.

6. Schedule **local Supabase mini-stack** build once the CI base image exists.

---

### Potential Additional Blockers Discovered

• `app/coverage/lcov.info` is committed – should be git-ignored to keep PRs clean.  
• Dozens of untracked docs/scripts (see `uncommitted_file_review_sprint.md`) – may cause merge conflicts; run a clean-up sprint. 