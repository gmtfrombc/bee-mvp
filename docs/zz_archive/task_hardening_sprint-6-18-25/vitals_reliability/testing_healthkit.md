

Step 1 – Launch clean
• From a clean app start (all Health permissions still ON), run the app in debug mode and watch the log.
Expected:
  – `Loaded … cached permissions` followed by several `• CACHE LOAD → … granted=true` lines  
  – Soon after: `checkPermissions final cache → {steps:true, …}`

Step 2 – Baseline UI confirmation
• Navigate to the Settings (or Vitals) screen that shows the Health permission toggle.
• Confirm it reads “Granted”.  
• In the log you should also see `permissionSummaryProvider: fresh permission check completed`.

Step 3 – Revoke while backgrounded
• Send the app to the background (home button / swipe-up).  
• In Apple Health, revoke **all** MomentumCoach permissions.  
• Bring the app back to the foreground.

Immediately copy the last ~50 log lines starting from any `Permission` / `CACHE` / `checkPermissions` prints and tell me:
  – Do you see the auto-refresh mixin calling `checkPermissions`?  
  – What does the newest `checkPermissions final cache → …` line show?  
  – Has the UI toggle flipped to “Not granted”?

Let me know these observations and we’ll proceed.