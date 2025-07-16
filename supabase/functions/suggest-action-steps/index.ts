import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

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

  // TODO: Task T2 – replace placeholder with real suggestion generation + rate limiting.
  const suggestions = buildPlaceholderSuggestions();

  return new Response(JSON.stringify({ suggestions }), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

// Supabase entry point
serve(handler);
