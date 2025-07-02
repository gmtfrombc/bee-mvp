# 🤖 BEE MVP - Automated Development Workflows

Below is a concise “playbook” for BEE-MVP builds and when to use each one.

--------------------------------------------------------------------
1. Local development - Flutter only  
   • **Command:** `./bee`  
   • What happens  
     – Loads `.env` (or `--dart-define`s you pass manually).  
     – Starts the iOS/Android simulator in **debug** mode (hot-reload, DevTools).  
   • When to use  
     – UI work, Riverpod logic, widget tests, rapid iteration.  
   • Caveats  
     – No local Supabase; API calls will 404/timeout unless you stub services or point to a remote backend.

--------------------------------------------------------------------
2. Local development - Full stack  
   • **Commands:**  
     ```
     ./supa      # launches Supabase CLI (db + edge funcs) on localhost
     ./bee       # same as above but now the app talks to localhost:54321
     ```  
   • What happens  
     – Supabase CLI spins up Postgres + Auth + Storage + Edge runtime.  
     – `bee` still runs in debug mode but now the app hits the **local** backend.  
   • When to use  
     – Schema or RLS changes, writing new Edge Functions, “offline” dev.  
   • Tips  
     – Keep your `.env` pointing at `http://127.0.0.1:54321` plus the local anon key.  
     – Use `supabase db reset` to wipe data fast.

--------------------------------------------------------------------
3. Production snapshot on your laptop  
   • **Command:** `./bee-prod`  
   • What happens  
     – Temporarily moves `app/.env` to `.env.backup`.  
     – Writes a temp `.env` with `ENVIRONMENT=production` and *production* URL/keys.  
     – Runs `flutter run` in **debug** mode so you still have hot-reload & logs, but the app talks to the real backend.  
     – On exit the script restores your local `.env`.  
   • When to use  
     – Quick sanity-check of prod data behaviour without TestFlight.  
     – Verifying RLS / auth flows against live infra.  
   • Caveats  
     – Debug builds run slower and include DevTools; don’t use for performance numbers.

--------------------------------------------------------------------
4. Release / TestFlight build  
   • **Command (iOS example):**  
     ```bash
     flutter build ios \
       --dart-define="SUPABASE_URL=https://<prod>.supabase.co" \
       --dart-define="SUPABASE_ANON_KEY=<prodAnonKey>" \
       --dart-define="ENVIRONMENT=production" \
       --release
     ```  
   • What happens  
     – Generates a **release** binary: no asserts, no hot-reload, full compiler optimisation.  
     – Xcode “Archive → Distribute” uploads to TestFlight.  
   • When to use  
     – Anything that will leave your machine (QA, TestFlight, App Store).  
   • Tips  
     – Add `--obfuscate --split-debug-info=build/debug-info` for smaller size.  
     – Use Fastlane or GitHub Actions to automate Archive / upload.

--------------------------------------------------------------------
5. Optional: Staging / pre-prod flavour  
   If you create a separate Supabase **staging project**, add another script:

   ```bash
   flutter run --flavor staging \
     --dart-define="ENVIRONMENT=staging" \
     --dart-define="SUPABASE_URL=https://staging.supabase.co" \
     --dart-define="SUPABASE_ANON_KEY=<stagingKey>"
   ```

   or a wrapper `./bee-staging`.  
   Keeps real prod data safe while testers use near-prod infra.

--------------------------------------------------------------------
6. Continuous Integration  
   • Have CI run `flutter test`, `flutter analyze`, and a headless  
     `flutter build apk --debug` to catch compile errors.  
   • For release builds CI can run the same command as (4) and upload the
     artefact to TestFlight/Play Internal Track automatically.

--------------------------------------------------------------------
Questions you asked
-------------------
Q: “Is my current workflow correct?” – Yes, and with the anonymous-session
fix you no longer need any dev hacks when you hit prod.

Q: “Am I missing anything?” – Consider:

1. A **staging** Supabase project and flavour if multiple testers work in
   parallel.  
2. CI automation so TestFlight builds come from a clean machine.  
3. Add `--dart-define-from-file=env.prod.json` instead of long inline
   keys; easier and safer.

Otherwise your scripts (`./bee`, `./supa`, `./bee-prod`, `flutter build …`)
cover the main lifecycle phases cleanly.