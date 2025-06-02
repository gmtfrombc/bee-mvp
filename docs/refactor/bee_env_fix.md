
# Permanent .env Asset Fix for BEE‑MVP

Follow these three quick edits to stop the recurring “No file or variants found for asset: .env” error.

---

## 1 — Update `app/pubspec.yaml`

```diff
 flutter:
   uses-material-design: true

   assets:
     - assets/images/
     - assets/animations/
     - assets/icons/
-    - .env
+    - .env.example
```

*Keep the indentation exactly the same (two spaces before each dash).*

---

## 2 — Update `.gitignore` (repository root)

Append these lines anywhere in the file (typically near other environment exclusions):

```gitignore
# Local environment (developer‑only) – keep secrets out of VCS
.env
```

---

## 3 — Commit a safe template

Create **`app/.env.example`** with placeholder values:

```ini
# Environment Configuration Template
ENVIRONMENT=development
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key-here
FIREBASE_PROJECT_ID=bee-mvp-3ab43
APP_VERSION=1.0.0
```

Commit this file. CI can still overwrite it, but Flutter’s asset scanner will always find **`.env.example`**, eliminating the Groundhog‑Day build failure.

---

### Why this works

* **Deterministic asset** — The template is always present, so `flutter pub get` and the asset bundler never fail.
* **Secrets stay secret** — Real credentials remain in `.env` (git‑ignored) or are generated in CI.
* **No more re‑appearing errors** — Cleaning, re‑cloning, or rebasing cannot remove a committed asset.

Happy coding! 🚀
