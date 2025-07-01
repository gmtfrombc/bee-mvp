// deno-lint-ignore-file no-explicit-any

/** Minimal assertion helpers (avoid external deps) */
function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}
function assertEquals(actual: unknown, expected: unknown, msg?: string) {
  if (actual !== expected) {
    throw new Error(msg ?? `Expected ${expected}, got ${actual}`);
  }
}

// Environment values
const PROJECT_ID = Deno.env.get("PROJECT_ID");
const SERVICE_ROLE_SECRET = Deno.env.get("SERVICE_ROLE_SECRET") ??
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if (!PROJECT_ID || !SERVICE_ROLE_SECRET) {
  console.warn("⏩ Skipping daily_content_pipeline test – env vars not set");
}
const SUPABASE_URL = `https://${PROJECT_ID}.supabase.co`;

const REST_ENDPOINT = `${SUPABASE_URL}/rest/v1`;

// Headers helper
function authHeaders(extra: Record<string, string> = {}) {
  return {
    "Content-Type": "application/json",
    "apikey": SERVICE_ROLE_SECRET!,
    "Authorization": `Bearer ${SERVICE_ROLE_SECRET}`,
    ...extra,
  } as Record<string, string>;
}

function buildRow(i: number) {
  const today = new Date().toISOString().substring(0, 10); // YYYY-MM-DD
  return {
    content_date: today,
    title: `Test title ${i}`,
    summary: `Summary ${i}`,
    topic_category: "nutrition",
  };
}

Deno.test({
  name: "daily_feed_content retains max 20 rows and only latest active",
  ignore: true,
  fn: async () => {
    // 1. Insert 25 rows individually to mimic real edge-function behaviour.
    for (let i = 0; i < 25; i++) {
      const insertRes = await fetch(`${REST_ENDPOINT}/daily_feed_content`, {
        method: "POST",
        headers: authHeaders({ "Prefer": "return=minimal" }),
        body: JSON.stringify(buildRow(i)),
      });
      assert(insertRes.ok, `insert ${i} failed: ${insertRes.status}`);
    }

    // 2. Query count (Prefer: count=exact gives Content-Range header)
    const countRes = await fetch(
      `${REST_ENDPOINT}/daily_feed_content?select=id`,
      { headers: authHeaders({ "Prefer": "count=exact" }) },
    );
    assert(countRes.ok, `count query failed: ${countRes.status}`);
    const range = countRes.headers.get("content-range");
    // format: 0-19/20  -> extract total after /
    const total = range ? parseInt(range.split("/").pop() ?? "0") : 0;
    assert(total <= 20, `row count ${total} exceeds 20`);

    // 3. Verify only one active row via view
    const viewRes = await fetch(
      `${REST_ENDPOINT}/daily_feed_content_current`,
      { headers: authHeaders() },
    );
    assert(viewRes.ok, `view query failed: ${viewRes.status}`);
    const viewBody: any[] = await viewRes.json();
    assertEquals(viewBody.length, 1, "view should return exactly one row");

    // 4. Cleanup test rows
    await fetch(
      `${REST_ENDPOINT}/daily_feed_content?title=ilike.Test%20title%25`,
      { method: "DELETE", headers: authHeaders() },
    );
  },
});
