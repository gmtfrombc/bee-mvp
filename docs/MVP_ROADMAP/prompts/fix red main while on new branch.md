Below is a concise “script” you can paste into any hand-off so your AI Coder knows exactly what to do when main turns red while she’s mid-task on a feature branch.

⸻

Step-by-step recovery workflow

#	Command / Action	Purpose & key tips
1 · Safeguard WIP	git add -A && git commit -m "wip: save progress" (or git stash push -m wip)﻿	Make sure no uncommitted edits are lost when switching branches.  ￼
2 · Check out a hot-fix branch	bash<br>git switch main && git pull --rebase<br>git switch -c hotfix/main-red-YYYYMMDD<br>	Start from the exact failing commit on main; naming pattern mirrors Git-flow hot-fixes.  ￼
3 · Fix the break	Edit files, run fast tests (make ci-fast), iterate locally until green.	Local green guarantees remote green because Docker/ACT matches the CI image.  ￼
4 · Commit & push the hot-fix	git add -A && git commit -m "fix: <brief>" && git push -u origin hotfix/main-red-YYYYMMDD	
5 · Open PR → merge once CI passes	Required-checks protection blocks other merges until this is green.  ￼	
6 · Return to your feature branch	git switch epic-1.12/T1-xyz	
7 · Rebase onto updated main	bash<br>git fetch origin<br>git rebase origin/main --autostash<br>	Replays WIP atop the fixed main; resolves any conflicts now, not later.  ￼ ￼
8 · Resolve conflicts (if any)	Follow the usual conflict markers, then git add -u && git rebase --continue.	GitHub docs on conflict resolution.  ￼
9 · Rerun full local CI	make ci-local	Ensures the rebase didn’t break your feature.
10 · Force-with-lease update of the feature branch	git push --force-with-lease	Safe overwrite because only your history changed.  ￼
11 · Continue coding	Resume the task; future CI runs now include the hot-fix.	


⸻

Why this is safe and standard
	•	Hot-fix branches are the canonical way to patch a broken default branch without blocking parallel work.  ￼
	•	Saving WIP (commit or stash) prevents accidental file bleed between branches.  ￼
	•	Rebasing your feature after the fix keeps history linear and avoids merge bubbles.  ￼
	•	--force-with-lease guarantees you only overwrite if nobody else pushed.  ￼
	•	If only a single commit caused the failure, you could cherry-pick it instead of rebasing the whole branch.  ￼

Give these 11 lines to the AI Coder; she can follow them verbatim and you’ll never lose work—or time—when main suddenly goes red.