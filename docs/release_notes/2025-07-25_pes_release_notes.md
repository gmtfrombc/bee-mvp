# Release Notes – Perceived Energy Score (PES)

Date: 2025-07-25

## ✨ New Feature

• **Perceived Energy Score (PES) Check-In** – users can now record a daily 1–5 energy rating from the Today Feed or Settings.
• **Momentum Integration** – each PES entry automatically adds +10 points to the Momentum Score and updates in real-time (< 5 s).

## 🖥️ UI Changes

• Added `EnergyInputSlider` widget and `PesTrendSparkline` to Today Feed.
• Settings now exposes a daily prompt time picker (via `DailyPromptController`).

## 🔧 Backend / Supabase

• New upsert to `pes_entries` table with duplicate-day guard trigger.
• `momentum-score-calculator` edge function updated with `'pes_entry': 10` weight.
• Legacy `energy_levels` table dropped; associated providers removed.

## ✅ Quality & Testing

• **Playwright e2e**: `pes_checkin_e2e.spec.ts` validates slider → DB row → momentum websocket flow.
• Unit & widget coverage ≥ 90 %.

## ⚠️ Deprecations

• Removed `energy_levels` table, related migrations, providers, and tests.

## 📚 Documentation

• Updated spec `M1.7.1_pes_production_spec.md` (all tasks complete).
• This release note added to `/docs/release_notes/` for future reference. 