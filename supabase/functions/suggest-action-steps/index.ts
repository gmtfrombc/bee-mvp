/// <reference lib="deno.unstable" />
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { getSupabaseClient } from "../_shared/supabase_client.ts";

// ---------------------------------------------------------------------------
// Rate-limit helper – 1 request per hour per user (KV + in-memory fallback)
// ---------------------------------------------------------------------------
class HourlyRateLimiter {
  private memory = new Map<string, number>(); // userId -> epoch ms window start

  async enforce(userId: string): Promise<void> {
    const now = Date.now();
    const windowMs = 60 * 60 * 1000; // 1 hour
    const windowStart = Math.floor(now / windowMs) * windowMs;

    try {
      const kv = await (Deno.openKv?.());
      if (kv) {
        const key = ["suggest_action_steps", userId, windowStart];
        const countRes = await kv.get<number>(key);
        const count = countRes.value ?? 0;
        if (count >= 1) {
          const retryAfter = Math.ceil((windowStart + windowMs - now) / 1000);
          throw new RateLimitError("Too many requests", retryAfter);
        }
        await kv.set(key, count + 1, { expireIn: windowMs * 2 }); // 2-hour TTL
        return;
      }
    } catch (_err) {
      // Fallthrough to memory fallback
    }

    // In-memory (within same container) fallback
    const prevWindow = this.memory.get(userId);
    if (prevWindow === windowStart) {
      const retryAfter = Math.ceil((windowStart + windowMs - now) / 1000);
      throw new RateLimitError("Too many requests", retryAfter);
    }
    this.memory.set(userId, windowStart);
  }
}

class RateLimitError extends Error {
  constructor(message: string, public retryAfter: number) {
    super(message);
    this.name = "RateLimitError";
  }
}

const rateLimiter = new HourlyRateLimiter();

export interface ActionStepSuggestion {
  id: string;
  title: string;
  category: string;
  description: string;
}

function buildPlaceholderSuggestions(): ActionStepSuggestion[] {
  return [
    {
      id: "morning-stretch",
      title: "Morning Stretch Routine",
      category: "mobility",
      description:
        "Spend 5 minutes stretching major muscle groups after waking.",
    },
    {
      id: "water-breaks",
      title: "Hourly Water Breaks",
      category: "hydration",
      description: "Drink a glass of water every hour to stay hydrated.",
    },
    {
      id: "evening-reflection",
      title: "Evening Reflection Journal",
      category: "mindfulness",
      description: "Write 3 things you are grateful for before bedtime.",
    },
  ];
}

// Extracted pure algorithm for easier unit-testing
export type PlannedStep = {
  id: string;
  category: string | null;
  frequency?: number | null;
  week_start: string;
};
export type CompletionLog = { action_step_id: string; completed_on: string };

/**
 * Compute ranked suggestions from planned steps & completion logs.
 * Returns 3-5 suggestions or falls back to placeholder suggestions.
 */
export function computeSuggestions(
  steps: PlannedStep[],
  logs: CompletionLog[],
): ActionStepSuggestion[] {
  // ---------------------------------------------------------------------------
  // 🧮 Compute per-category stats (identical logic to original inline version)
  // ---------------------------------------------------------------------------
  type Stats = {
    plannedPerWeek: Map<string, number>; // week_start -> planned count
    completedPerWeek: Map<string, number>;
  };
  const byCategory = new Map<string, Stats>();

  for (const step of steps) {
    const cat = String(step.category ?? "uncategorized");
    const week = step.week_start;
    const stats = byCategory.get(cat) ??
      { plannedPerWeek: new Map(), completedPerWeek: new Map() };
    stats.plannedPerWeek.set(
      week,
      (stats.plannedPerWeek.get(week) ?? 0) + (step.frequency ?? 1),
    );
    byCategory.set(cat, stats);
  }

  for (const log of logs) {
    const step = steps.find((s) => s.id === log.action_step_id);
    if (!step) continue;
    const cat = String(step.category ?? "uncategorized");
    const week = step.week_start;
    const stats = byCategory.get(cat);
    if (!stats) continue;
    stats.completedPerWeek.set(
      week,
      (stats.completedPerWeek.get(week) ?? 0) + 1,
    );
  }

  // Helper to check 3 consecutive skipped weeks
  function skippedThreeWeeks(stats: Stats): boolean {
    const today = new Date();
    for (let i = 0; i < 3; i++) {
      const weekStart = new Date(today.getTime() - i * 7 * 24 * 60 * 60 * 1000);
      weekStart.setUTCDate(weekStart.getUTCDate() - weekStart.getUTCDay()); // previous Sunday
      const key = weekStart.toISOString().slice(0, 10);
      const completed = stats.completedPerWeek.get(key) ?? 0;
      if (completed > 0) return false; // Completed at least once – not skipped
    }
    return true;
  }

  type Ranked = { category: string; score: number };
  const ranked: Ranked[] = [];
  byCategory.forEach((stats, category) => {
    if (skippedThreeWeeks(stats)) return; // exclude

    let totalPlanned = 0;
    let totalCompleted = 0;
    stats.plannedPerWeek.forEach((v) => (totalPlanned += v));
    stats.completedPerWeek.forEach((v) => (totalCompleted += v));

    const completionRatio = totalPlanned === 0
      ? 0
      : totalCompleted / totalPlanned;
    const score = 1 - completionRatio; // higher score ⇒ lower completion
    ranked.push({ category, score });
  });

  ranked.sort((a, b) => b.score - a.score);

  const top = ranked.slice(0, 5);

  // ---------------------------------------------------------------------------
  // ✨ Build suggestions per top category (simple template)
  // ---------------------------------------------------------------------------
  const suggestions: ActionStepSuggestion[] = top.map((entry, idx) => {
    const cat = entry.category;
    const prettyCat = cat.charAt(0).toUpperCase() + cat.slice(1);
    return {
      id: `${cat}-suggestion-${idx + 1}`,
      title: `${prettyCat} Focus`,
      category: cat,
      description:
        `Choose a small, attainable goal to improve your ${cat} this week.`,
    };
  });

  const finalSuggestions = suggestions.length >= 3
    ? suggestions.slice(0, Math.min(5, suggestions.length))
    : buildPlaceholderSuggestions();

  return finalSuggestions;
}

export async function handler(req: Request): Promise<Response> {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const userId = (body as { user_id?: string }).user_id;
  if (!userId) {
    return new Response(JSON.stringify({ error: "Missing user_id" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ---------------------------------------------------------------------------
  // 🍯 Rate limiting – 1 request / hr
  // ---------------------------------------------------------------------------
  try {
    await rateLimiter.enforce(userId);
  } catch (e) {
    if (e instanceof RateLimitError) {
      return new Response(
        JSON.stringify({
          code: "RATE_LIMITED",
          message: e.message,
          retry_after: e.retryAfter,
        }),
        {
          status: 429,
          headers: {
            "Content-Type": "application/json",
            "Retry-After": String(e.retryAfter),
            "Access-Control-Allow-Origin": "*",
          },
        },
      );
    }
    throw e;
  }

  // ---------------------------------------------------------------------------
  // 🔍 Fetch past 4 weeks of action steps & completions
  // ---------------------------------------------------------------------------
  const fourWeeksAgo = new Date(Date.now() - 28 * 24 * 60 * 60 * 1000);
  const sinceIso = fourWeeksAgo.toISOString().slice(0, 10); // YYYY-MM-DD

  // Lazy init to avoid cold-start Supabase JS cost when rate-limited
  let supabase: Awaited<ReturnType<typeof getSupabaseClient>>;
  try {
    supabase = await getSupabaseClient();
  } catch (err) {
    console.error("Supabase client init failed", err);
    // Fallback to placeholder suggestions
    const suggestions = buildPlaceholderSuggestions();
    return new Response(JSON.stringify({ suggestions }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }

  // 1. Fetch action steps (planned)
  const { data: steps, error: stepsErr } = await supabase
    .from("action_steps")
    .select("id, category, frequency, week_start")
    .eq("user_id", userId)
    .gte("week_start", sinceIso);

  if (stepsErr) {
    console.error("fetch action_steps error", stepsErr);
  }

  const stepIds = (steps ?? []).map((s: { id: string }) => s.id);

  // 2. Fetch completion logs
  let logs: { action_step_id: string; completed_on: string }[] = [];
  if (stepIds.length > 0) {
    const { data: logsData, error: logsErr } = await supabase
      .from("action_step_logs")
      .select("action_step_id, completed_on")
      .in("action_step_id", stepIds);
    if (!logsErr) logs = logsData ?? [];
    else console.error("fetch action_step_logs error", logsErr);
  }

  // ---------------------------------------------------------------------------
  // ✨ Build & return suggestions via extracted helper
  // ---------------------------------------------------------------------------
  const suggestions = computeSuggestions(steps ?? [], logs);

  return new Response(JSON.stringify({ suggestions }), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

// Supabase entry point – only run when executed as a script, not when imported in tests
if (import.meta.main) {
  serve(handler);
}
