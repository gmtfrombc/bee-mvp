// Stub Suggest Action Steps Edge Function
// Returns 200 OK with empty suggestions array.
// Use the built-in Deno.serve API (preferred over deprecated std/http serve).
Deno.serve((_req: Request) =>
  new Response("[]", {
    status: 200,
    headers: { "Content-Type": "application/json" },
  })
);
