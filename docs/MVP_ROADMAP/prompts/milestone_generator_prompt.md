
# 📑 Milestone-Spec Generator – Prompt

You are an **AI senior engineer**.  
Your job is to transform each Milestone listed in an Epic-level document into its own _detailed engineering-spec_ file.

## 1️⃣ Inputs you will receive
• The Epic-level markdown file (e.g. `docs/MVP_ROADMAP/tasks/epic_1-6_registration_and_auth.md`).  
• The standard coding & architecture rules that already exist in the repo.
- Architecture rules in `.cursor/rules/`

## 2️⃣ Output files to create
Create **one markdown file per Milestone**, placed inside the Epic’s folder:

```
docs/MVP_ROADMAP/<Epic Folder>/M<id>_<slug>.md
```

Example for Epic 1.6:  
```
docs/MVP_ROADMAP/1-6 Registration and Auth/M1.6.1_supabase_auth_backend_setup.md
docs/MVP_ROADMAP/1-6 Registration and Auth/M1.6.2_flutter_registration_login_ui.md
...
```

## 3️⃣ Required document structure  
Model the depth of detail on `docs/zz_archive/1_2_Epic_Today_Feed/tasks-today-feed.md`, but use the section names below:

1. **Milestone Header**  
   ```
   ### M1.6.2 · Flutter Registration & Login UI  
   **Epic:** 1.6 Registration & Auth  
   **Status:** 🟡 Planned  
   ```

2. **Goal** – the “why” in 1-2 sentences.  

3. **Success Criteria** – bullet list, measurable (latency, coverage %, etc.).  

4. **Milestone Breakdown** – table of tasks, like:

   | Task ID | Description | Est. Hrs | Status |
   | ------- | ----------- | -------- | ------ |
   | T1      | …           | 4h       | 🟡     |

5. **Milestone Deliverables** – bullet list of concrete artifacts (code, migrations, Figma, etc.).

6. **Implementation Details** – enough depth for an AI coder to generate code without further prompting.  
   - Review and apply rules in `.cursor/rules/`, including architecture, component sizing, naming, and import rules.
   - If existing implementation exists or partially fulfills this milestone, reference it clearly and describe whether to extend, refactor, or leave untouched.
   • File paths / class or function names expected.  
   • DB DDL snippets or API contracts as needed.  
   • Non-obvious edge cases, performance budgets, security rules.  
   • Testing approach (unit / widget / integration).  
   • Any relevant architectural rule references (e.g. “use Riverpod v2”, “import theme.dart, responsive_services.dart – no magic numbers”).

7. **Acceptance Criteria** – checklist that QA/test must pass to call the milestone “Done”.

8. **Dependencies / Notes** – other Epics, secrets files, environment flags, etc.

### Formatting rules
• Markdown only.  
• Use code fences for SQL, JSON, or Dart snippets if included.  
• Keep each file ≤ ~200 lines; link to external docs instead of duplicating huge text blocks.  
• Use 🟡 Planned 🔵 In Progress ✅ Complete status emojis consistently.

## 4️⃣ Working process
For every Milestone found in the Epic file:

1. Parse its title and brief description.  
2. Expand it into the spec using the template above.  
3. Save it to the correct path with a kebab-case slug.  
4. Repeat until **all Milestones have their own file**.

## 5️⃣ Definition of Done for you (the AI-coder)
- [ ] A new markdown file exists for **each** milestone under its Epic folder.  
- [ ] Each file follows the exact structure & formatting rules above.  
- [ ] No lint/writing errors; all links and code fences close properly.  
- [ ] You output **only** the file contents or code-edit commands required to write them—no extra commentary.

Happy spec-building!