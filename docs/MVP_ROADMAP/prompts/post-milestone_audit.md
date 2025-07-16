# ✅ Post-Milestone QA Audit Prompt

You are an **AI Senior Developer**.\
Your task is to **review completed code** and verify whether it fulfills the
specifications defined in the milestone document.

---

## 1️⃣ Inputs

- The final milestone specification document
- The committed implementation codebase
- The architecture and coding standards in `.cursor/rules/`

---

## 2️⃣ Review Scope

### ✅ Acceptance Criteria Check

- Verify that **every acceptance criterion** listed in the milestone spec is
  clearly addressed in the implementation.
- Flag any criteria that are ambiguous or only partially implemented.

### 📦 Deliverables Audit

- Confirm that all deliverables (code files, migrations, tests, assets, etc.)
  exist and are placed in expected locations. Insure that the code changes did not unduly increase complexity and reduce stability of the codebase

### 🧪 Testing Validation

- Review if the described test types (unit, widget, integration) were
  implemented.
- Ensure edge cases from the spec or pre-review are covered.
- If available, run tests (`flutter test`, `pytest`, etc.) to confirm they pass.

### 🔒 Rules & Constraints Compliance

- Confirm that architectural rules were followed.
- Validate performance/security requirements (e.g., p95 latency, auth guards).

---

## 3️⃣ Output

Produce a clean markdown QA report with:

1. **PASS/FAIL Status**
2. Table of acceptance criteria with ✅/❌
3. Missing or incomplete deliverables
4. Code smells, unncessary or overly complex additons,  or architectural violations
5. Recommended remediation tasks
6. Produce a table with task # ('R'), description and status flag: '🟡 Planned '
6. Use the file @M1.11.1_post-milestone_mini-sprint.md as your template for the
   document and place in the folder: docs/MVP_ROADMAP/1-11
   Onboarding/Milestones, Tasks, and Epic Docs/post-milestone mini-sprints/

---

## 🔄 Developer Wrap-Up Playbook (run _after_ audit ✅ PASS)

## To complete the wrap up milestone process for <CURRENT_MILESTONE>, do the following:

1. Ensure the working tree on branch feature/<CURRENT_MILESTONE> is clean; if not, STOP and ask me.
2. git fetch --prune, then git rebase origin/main to bring the branch up-to-date with main.
3. Run local health checks:
   - flutter analyze --fatal-infos  
   - flutter test --no-pub  
- Abort and report if anything fails.
4. Push the rebased branch (git push --force-with-lease).
5. If a PR already exists, convert it from draft to ready for review. Otherwise, open a PR targeting main titled “<CURRENT_MILESTONE>: <milestone title>”.
6. Report the PR URL and confirm all CI checks have started.
7. Stop once CI is green; do not delete the branch—GitHub will handle that on merge.”