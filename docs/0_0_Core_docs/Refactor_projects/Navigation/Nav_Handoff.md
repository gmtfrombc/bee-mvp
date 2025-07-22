AI CODER SESSION SUMMARY
========================================================

Session Goal  
• Refactor routing so auth pages are top-level (`/login`, `/auth`, `/confirm`) and main app lives under ShellRoute (`/`).  
• Fix bug: tapping “Don’t have an account? Create one” on LoginPage should navigate to AuthPage.

Work Completed  
1. **Route restructuring**  
   – Added `kLoginRoute`, flattened `/login`, `/auth`, `/confirm`.  
   – Wrapped authenticated area in `ShellRoute`.  
   – Removed all legacy “/launch” usages; LaunchController now at `/`.  

2. **Redirect logic**  
   – LaunchController no longer builds LoginPage; instead relies on router redirects.  
   – OnboardingGuard extended: unauthenticated users are redirected to `/login` at the global level.

3. **Tests & CI**  
   – Updated ~20 integration/widget tests (`/launch` → `/login`/`/`).  
   – Added new login→auth integration test. All 768 Flutter tests green.

4. **Diagnostics**  
   – Verbose prints added to LaunchController, LoginPage, OnboardingGuard, NavigatorObserver.  
   – Confirmed runtime flow up to `/login` works on device.

Current Blocker  
Pressing “Create one” logs:  
```
👉 context.go(/auth)
📍 after context.go: immediate uri=/auth
📍 microtask uri=/auth
```
…but **NO** follow-up logs:  
– No OnboardingGuard evaluation for `/auth`  
– No `didPush: /auth`  
– No `AuthPage BUILT`

Analysis  
Router location changes to `/auth`, yet no new page is rendered. This indicates GoRouter considers the existing page (LoginPage) the correct match for `/auth`. Likely causes:

1. Route list places `/login` and `/auth` as separate GoRoutes without unique `name`/`pageBuilder`, so GoRouter re-uses the current page when path changes but match depth stays identical.  
2. Both routes share identical `key`s (default) causing widget diff to treat them as the same.

Recommended Fix Strategy  
A. Easiest: switch navigation call to `context.push(kAuthRoute)` instead of `go`. `push` forces a new page even if match depth is equal.  
B. Better: keep `go` (preferred for deep-linking) but ensure `/login` and `/auth` produce distinct pages:  
   • Use `pageBuilder` with different `key`s:  
     ```dart
     GoRoute(
       path: kLoginRoute,
       pageBuilder: (_, __) => const MaterialPage(key: ValueKey('Login'), child: LoginPage()),
     ),
     GoRoute(
       path: kAuthRoute,
       pageBuilder: (_, __) => const MaterialPage(key: ValueKey('Auth'), child: AuthPage()),
     ),
     ```  
   • or assign different `name`s and navigate via `goNamed`.

C. Verify by watching for `didPush: /auth` and `🔧 AuthPage BUILT`.

Cleanup To-Do  
• Remove debugging prints once verified.  
• Re-run full test suite and add a widget test asserting login → auth navigation.
