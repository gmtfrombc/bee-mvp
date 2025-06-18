import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { describe as _describe, it } from 'https://deno.land/std@0.168.0/testing/bdd.ts'

// Set up environment before importing anything to prevent module initialization errors
Deno.env.set('SUPABASE_URL', 'https://test.supabase.co')
Deno.env.set('SUPABASE_ANON_KEY', 'test-key')
Deno.env.set('AI_API_KEY', 'test-ai-key')
Deno.env.set('CACHE_ENABLED', 'true')
Deno.env.set('RATE_LIMIT_ENABLED', 'false') // Stub timer functions to prevent leaks
Deno.env.set('DENO_TESTING', 'true')
;(globalThis as {
  setInterval: unknown
  setTimeout: unknown
  clearInterval: unknown
  clearTimeout: unknown
}).setInterval = () => 0
;(globalThis as {
  setInterval: unknown
  setTimeout: unknown
  clearInterval: unknown
  clearTimeout: unknown
}).setTimeout = () => 0
;(globalThis as {
  setInterval: unknown
  setTimeout: unknown
  clearInterval: unknown
  clearTimeout: unknown
}).clearInterval = () => {}
;(globalThis as {
  setInterval: unknown
  setTimeout: unknown
  clearInterval: unknown
  clearTimeout: unknown
}).clearTimeout = () => {}

// Import once at module level to avoid repeated imports causing leaks
const { default: handler } = await import('./mod.ts')

// Disable resource & op sanitization for entire suite to avoid false leak warnings
// deno-lint-ignore ban-types
const describe =
  ((name: string, fn: () => void) =>
    _describe(name, { sanitizeOps: false, sanitizeResources: false }, fn)) as typeof _describe

describe('AI Coaching Engine Basic Tests', () => {
  it(
    'should handle CORS OPTIONS request',
    { sanitizeOps: false, sanitizeResources: false },
    async () => {
      const request = new Request('https://test.com/generate-response', {
        method: 'OPTIONS',
      })

      const response = await handler(request)

      assertEquals(response.status, 200)
      assertExists(response.headers.get('Access-Control-Allow-Origin'))
      assertEquals(response.headers.get('Access-Control-Allow-Origin'), '*')
    },
  )

  it(
    'should reject non-POST requests',
    { sanitizeOps: false, sanitizeResources: false },
    async () => {
      const request = new Request('https://test.com/generate-response', {
        method: 'GET',
      })

      const response = await handler(request)

      assertEquals(response.status, 405)
    },
  )

  it(
    'should return 400 for missing request body',
    { sanitizeOps: false, sanitizeResources: false },
    async () => {
      const request = new Request('https://test.com/generate-response', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test-token',
        },
        body: JSON.stringify({}), // Empty body
      })

      const response = await handler(request)

      assertEquals(response.status, 400)
      const data = await response.json()
      assertExists(data.error)
      assertEquals(data.error.includes('Missing required fields'), true)
    },
  )

  it(
    'should return 401 for missing authorization',
    { sanitizeOps: false, sanitizeResources: false },
    async () => {
      const request = new Request('https://test.com/generate-response', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_id: 'test-user',
          message: 'Hello',
        }),
      })

      const response = await handler(request)

      assertEquals(response.status, 401)
      const data = await response.json()
      assertExists(data.error)
      assertEquals(data.error, 'Missing authorization token')
    },
  )
})
