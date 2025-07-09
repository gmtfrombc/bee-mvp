# Debug Report: Botched Migration Investigation

**Date:** $(date +%Y-%m-%d) **Branch:** `debug/migration-failure`

---

## 1. Summary

A failing migration
(`20240715211000_enable_rls_for_daily_engagement_scores.sql`) attempted to
enable Row-Level Security on `daily_engagement_scores` before that table
existed. This prevented rebuilding a clean database from scratch.

## 2. Root Cause

- Table `public.daily_engagement_scores` is first created in later migrations
  (`20241215000000_momentum_meter.sql` and
  `20241227000001_create_momentum_tables.sql`).
- The earlier RLS-only migration therefore throws
  `ERROR: relation "public.daily_engagement_scores" does not exist`.

## 3. Fix Implemented

- Deleted the redundant migration file.
- Re-ran `supabase db reset` – all migrations now apply successfully (see
  `migration_reset2.log`).

## 4. Validation

| Check                              | Result         |
| ---------------------------------- | -------------- |
| `supabase db reset` on clean stack | ✅ Pass        |
| Sequential `psql` bisect           | ✅ No failures |

## 5. Recommendation

No further action required. New migrations should never assume prior objects
without creating them. Consider enabling pre-commit CI that performs a clean
`db reset` on every PR.

---

_Logs:_ `supabase_start2.log`, `migration_reset2.log`

---

_Prepared by:_ Expert AI Pair-Programmer
