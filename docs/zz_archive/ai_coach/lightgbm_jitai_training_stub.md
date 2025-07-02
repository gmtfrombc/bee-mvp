# LightGBM JITAI Training Notebook (Stub)

This stub stands in place of the final Jupyter notebook that will document data
preparation and training of the LightGBM-based JITAI predictive model.

Steps to complete in Sprint C:

1. Load historical `wearable_daily_summary` data (90 days backfill).
2. Feature engineering – rolling averages, momentum states, patient_id
   hierarchy.
3. Train LightGBM classifier to predict intervention necessity.
4. Export model with `m2cgen` to TypeScript and replace `lightgbm_model.ts`.

_Added by Sprint B (T1.3.9.14)._
