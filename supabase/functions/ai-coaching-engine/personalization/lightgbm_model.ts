/**
 * LightGBM-style decision-tree ensemble converted to plain TypeScript.
 * -------------------------------------------------------------------
 * WARNING – This is ONLY a placeholder model bundled with the repo so
 * that we have working code paths and unit tests for Sprint B (T1.3.9.14).
 * Replace with an auto-generated file from m2cgen once the real model is
 * trained.
 *
 * Input order (all numbers, no nulls):
 *   0 → steps_total (int)
 *   1 → avg_hr      (int, bpm)
 *   2 → sleep_hours (float)
 *
 * Output: probability 0-1 that a JITAI intervention should be triggered.
 *
 * The tiny tree below is *not* predictive – it simply produces a sensible
 * curve for testing (>0.6 when user is tired + inactive + high HR).
 */
export function predictLightGBM(features: number[]): number {
  const [steps, hr, sleep] = features // patient code ignored in placeholder

  // Tree 0
  let score = 0
  if (steps < 3000) {
    score += 0.8
  } else if (steps < 7000) {
    score += 0.3
  } else {
    score += -0.2
  }

  // Tree 1
  if (hr > 120) {
    score += 1.0
  } else if (hr > 90) {
    score += 0.4
  } else {
    score += -0.1
  }

  // Tree 2
  if (sleep < 6) {
    score += 0.5
  } else if (sleep < 7.5) {
    score += 0.1
  } else {
    score += -0.3
  }

  // Average the trees (3 trees)
  const raw = score / 3
  // Logistic transformation → probability
  return 1 / (1 + Math.exp(-raw))
}

/**
 * Convenience helper that clamps inputs & handles missing values.
 */
export function scoreFromSnapshot(
  stepsTotal: number | null | undefined,
  avgHr: number | null | undefined,
  sleepHours: number | null | undefined,
): number {
  const safe = (v: number | null | undefined, d = 0): number =>
    typeof v === 'number' && !isNaN(v) ? v : d
  return predictLightGBM([
    safe(stepsTotal),
    safe(avgHr),
    safe(sleepHours),
  ])
}
