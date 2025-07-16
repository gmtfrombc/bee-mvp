// Stub Suggest Action Steps Edge Function
// Returns 200 OK with empty suggestions array.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve((_req: Request) =>
  new Response("[]", {
    status: 200,
    headers: { "Content-Type": "application/json" },
  })
);
