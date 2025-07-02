import { assertEquals, assertMatch } from 'https://deno.land/std@0.208.0/assert/mod.ts'
import { ensureRequestId, withRequestId } from './request-id.ts'

Deno.test('ensureRequestId returns existing header when present', () => {
  const req = new Request('http://localhost', {
    headers: { 'X-Request-Id': 'abc-123' },
  })
  const id = ensureRequestId(req)
  assertEquals(id, 'abc-123')
})

Deno.test('ensureRequestId generates uuid when header missing', () => {
  const req = new Request('http://localhost')
  const id = ensureRequestId(req)
  // Simple UUID v4 shape check – 36 chars with 4 hyphens
  assertMatch(id, /^[0-9a-fA-F-]{36}$/)
})

Deno.test('withRequestId attaches header to response', () => {
  const base = new Response('ok', { status: 200 })
  const resp = withRequestId(base, 'xyz-789')
  assertEquals(resp.headers.get('X-Request-Id'), 'xyz-789')
  assertEquals(resp.status, 200)
})
