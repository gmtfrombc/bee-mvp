import { test, expect } from '@playwright/test';
import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'crypto';

/**
 * E2E: PES Slider → DB row → Momentum websocket update
 *
 * The test runs only when Supabase env vars are provided. This keeps CI fast
 * and allows local developers to skip heavy integration when not configured.
 *
 * Required env:
 *   – SUPABASE_URL
 *   – SUPABASE_SERVICE_ROLE_KEY
 *   – APP_URL  (defaults to http://localhost:5174)
 */

test.describe('Perceived Energy Score (PES) flow', () => {
  const SUPABASE_URL = process.env.SUPABASE_URL || '';
  const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
  const APP_URL = process.env.APP_URL || 'http://localhost:5174';

  // Skip entirely when credentials are missing.
  test.skip(!SUPABASE_URL || !SERVICE_ROLE_KEY, 'Supabase credentials not configured');

  test('slider → pes_entries row → momentum update', async ({ page }) => {
    // -------------------------------
    // Setup Supabase client + test user
    // -------------------------------
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const userId = randomUUID();
    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

    // Clean-up any previous test artefacts just in case
    await supabase.from('pes_entries').delete().eq('user_id', userId);
    await supabase.from('daily_engagement_scores').delete().eq('user_id', userId);

    // -------------------------------------------------------
    // 1️⃣  Simulate user interaction – select mid-range energy
    // -------------------------------------------------------
    await page.goto(APP_URL, { waitUntil: 'networkidle' });

    // For Flutter Web, semantics labels map to textual content. The slider
    // uses an emoji for each score. Tap the neutral face (score = 3).
    const neutralEmoji = '😐';
    await page.getByText(neutralEmoji).click();

    // The card collapses & shows a thanks toast – wait briefly for network I/O
    await page.waitForTimeout(750); // allow REST upsert to reach Supabase

    // -------------------------------------
    // 2️⃣  Validate pes_entries DB upsert
    // -------------------------------------
    const { data: pesRows, error: pesErr } = await supabase
      .from('pes_entries')
      .select('score')
      .eq('user_id', userId)
      .eq('date', today)
      .limit(1);

    expect(pesErr).toBeNull();
    expect(pesRows, 'no pes_entries row recorded').toBeTruthy();
    expect(pesRows![0].score).toBe(3);

    // ---------------------------------------------------
    // 3️⃣  Verify Momentum Score recalculation (<5 s)
    // ---------------------------------------------------
    // Wait (poll) up to 5 seconds for daily_engagement_scores row.
    const start = Date.now();
    let momentumRow: any = null;
    while (Date.now() - start < 5000) {
      /* eslint-disable no-await-in-loop */
      const { data } = await supabase
        .from('daily_engagement_scores')
        .select('final_score')
        .eq('user_id', userId)
        .eq('score_date', today)
        .limit(1);
      if (data && data.length) {
        momentumRow = data[0];
        break;
      }
      await new Promise((r) => setTimeout(r, 500));
    }

    expect(momentumRow, 'Momentum row not generated within 5 s').toBeTruthy();
    expect(momentumRow.final_score).toBeGreaterThan(0);
  });
}); 