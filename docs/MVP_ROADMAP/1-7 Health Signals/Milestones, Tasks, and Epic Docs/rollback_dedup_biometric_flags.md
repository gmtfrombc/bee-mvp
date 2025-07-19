### Biometric Flags – Rollback & Dedup Procedure

_Belonging to Epic **1.7 Health Signals** · Applies to Milestone **M1.7.3 –
Biometric-Trigger Logic**_

---

## 1️⃣ When to Use This Guide

1. **False Positive Flag** – Edge-function logic incorrectly triggers a
   `low_steps` or `low_sleep` flag.
2. **User Correction** – User indicates data anomaly (e.g., forgot to wear
   wearable).
3. **Bulk Import** – Historical backfill inserts duplicate flags.

---

## 2️⃣ Deduplication Rules

| Rule | Condition                                                                                           | Resolution                                                                                                           |
| ---- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| R1   | Multiple flags with **identical** `user_id`, `flag_type`, `detected_on::date`                       | Keep the **earliest** record; delete the rest.                                                                       |
| R2   | A **resolved** flag exists and a **new unresolved** flag of the _same type_ arrives **within 24 h** | Mark the new flag as `resolved = true` and add JSON note `{ "source": "dedup", "note": "auto-resolved duplicate" }`. |
| R3   | Flag row later deemed **false positive** by manual QA                                               | Update row → `resolved = true`, append `details->>'qa_note'`.                                                        |
| R4   | User requests deletion of a flag (privacy request)                                                  | Hard‐delete the row using service role; log action in `audit_log`.                                                   |

---

## 3️⃣ Rollback Workflow (Manual)

> **Tip:** Always run in a transaction when rolling back multiple rows.

1. **Identify Flag(s)**
   ```sql
   SELECT *
   FROM biometric_flags
   WHERE user_id = '<uuid>'
     AND detected_on::date BETWEEN '<start>' AND '<end>';
   ```
2. **Resolve or Delete** – if keeping historical trace, prefer resolve:
   ```sql
   UPDATE biometric_flags
   SET resolved = TRUE,
       details = jsonb_set(coalesce(details, '{}'::jsonb), '{rollback_reason}', '"manual_rollback"')
   WHERE id = '<flag_id>';
   ```
   For hard delete:
   ```sql
   DELETE FROM biometric_flags WHERE id = '<flag_id>';
   ```
3. **Backfill Momentum Score** – if Momentum penalties were applied:
   ```sql
   -- Example: revert -10 penalty
   INSERT INTO momentum_adjustments (user_id, delta, reason)
   VALUES ('<uuid>', 10, 'rollback_biometric_flag');
   ```
4. **Broadcast Correction (Optional)** – notify clients to refresh flag list.
   ```typescript
   realtime.broadcast("biometric_flag_correction", { id: "<flag_id>" });
   ```

---

## 4️⃣ Automated Nightly Job

A cron‐based edge function `biometric_flag_deduper@1.0.0` should run daily at
02:00 UTC to enforce R1 & R2 rules:

```ts
// pseudocode
for (const flag of flagsFromLast7Days()) {
    if (duplicateExists(flag)) {
        resolveDuplicate(flag);
    }
}
```

The job must finish in < 300 ms (p95) and log actions to `audit_log`.

---

## 5️⃣ Audit & Monitoring

- All rollbacks/dedups write to `audit_log` with `action`, `actor`, `target_id`,
  and `metadata` JSON.
- Grafana panel **Biometric Flags – Daily Dedups** tracks count per day.
- Alert if nightly job resolves >1 % of new flags (potential logic regression).
