/**
 * Request-ID middleware – generates a stable correlation id for each request
 * if the client did not provide one, and ensures the value is propagated to
 * response headers so clients and logs can correlate requests end-to-end.
 *
 * Usage (inside the Edge Function entry-point):
 *   const reqId = ensureRequestId(req)
 *   const res  = await handler(req)
 *   return withRequestId(res, reqId)
 */

/** Header key used for request correlation */
const HEADER_KEY = 'X-Request-Id'

/**
 * Ensure there is a request id for the given request.
 *
 * If the incoming request already contains an `X-Request-Id` header that value
 * is returned unchanged. Otherwise a new rfc-4122 UUID (v4) is generated via
 * `crypto.randomUUID()` (available in Deno runtimes) and returned.
 */
export function ensureRequestId(req: Request): string {
  const incoming = req.headers.get(HEADER_KEY)
  return incoming ?? crypto.randomUUID()
}

/**
 * Return a new Response instance with the provided request id attached as an
 * `X-Request-Id` header (preserving all existing headers, status and body).
 */
export function withRequestId(res: Response, requestId: string): Response {
  const headers = new Headers(res.headers)
  headers.set(HEADER_KEY, requestId)
  return new Response(res.body, {
    status: res.status,
    headers,
  })
}
