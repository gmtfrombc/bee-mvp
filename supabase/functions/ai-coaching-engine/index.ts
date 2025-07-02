// Edge Function entry point for Supabase deployment
import handler from './mod.ts'
import { ensureRequestId, withRequestId } from './middleware/request-id.ts'

// Wrap base handler to inject/propagate `X-Request-Id` correlation header
Deno.serve(async (req: Request): Promise<Response> => {
  // Retrieve existing id or generate a new UUID v4
  const reqId = ensureRequestId(req)

  // Call main business logic handler
  const res = await handler(req)

  // Attach request id to response for client correlation
  const responseWithId = withRequestId(res, reqId)

  // Structured console log for observability (will appear in Supabase logs)
  const { method } = req
  const path = new URL(req.url).pathname
  console.log(`[${reqId}] ${method} ${path} -> ${responseWithId.status}`)

  return responseWithId
})
