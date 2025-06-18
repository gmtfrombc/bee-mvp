// Stub timer functions to prevent leaks
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

import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { afterEach, beforeEach, describe, it } from 'https://deno.land/std@0.168.0/testing/bdd.ts'

// Mock environment variables
const mockEnv = {
  'SUPABASE_URL': 'https://test.supabase.co',
  'SUPABASE_ANON_KEY': 'test-anon-key',
  'AI_API_KEY': 'test-ai-key',
  'AI_MODEL': 'claude-3-haiku-20240307',
  'DENO_TESTING': 'true',
}

// Mock external dependencies
const originalFetch = globalThis.fetch
const originalEnv = Deno.env.get
const originalReadTextFile = Deno.readTextFile

// Set environment variables before importing
for (const [key, value] of Object.entries(mockEnv)) {
  Deno.env.set(key, value)
}

// after env vars section
Deno.env.set('CACHE_ENABLED', 'false')
Deno.env.set('RATE_LIMIT_ENABLED', 'false')

// Import handler once at module level
const { default: handler } = await import('./mod.ts')

describe('AI Coaching Engine Handler', () => {
  beforeEach(() => {
    // Mock environment variables
    Deno.env.get = (key: string) => mockEnv[key as keyof typeof mockEnv] || undefined

    // Mock file reading for prompt templates
    Deno.readTextFile = (path: string | URL): Promise<string> => {
      const pathStr = typeof path === 'string' ? path : path.toString()
      if (pathStr.includes('safety.md')) {
        return Promise.resolve('You are a healthcare coach. Do not provide medical advice.')
      }
      if (pathStr.includes('system.md')) {
        return Promise.resolve('You are a supportive AI coach helping users with behavior change.')
      }
      return Promise.resolve('Mock template content')
    }

    // Mock fetch for AI API calls
    globalThis.fetch = (input: string | Request | URL, init?: RequestInit): Promise<Response> => {
      const url = typeof input === 'string' ? input : input.toString()

      // Mock AI API response
      if (url.includes('anthropic.com') || url.includes('openai.com')) {
        const mockResponse = url.includes('anthropic.com')
          ? { content: [{ text: "Great job reaching out! Let's work on this together." }] }
          : {
            choices: [{
              message: { content: "Great job reaching out! Let's work on this together." },
            }],
          }

        return Promise.resolve(new Response(JSON.stringify(mockResponse), { status: 200 }))
      }

      // Mock Supabase auth response - handle different URL patterns
      if (
        url.includes('supabase.co') && (url.includes('auth/v1/user') || url.includes('/auth/user'))
      ) {
        // Get authorization header from request
        const headers = init?.headers as Record<string, string> || {}
        const authHeader = headers['Authorization'] || headers['authorization'] || ''

        // If valid auth token present, return mock user data
        if (authHeader && authHeader.includes('valid-jwt-token')) {
          const mockAuthResponse = {
            id: 'test-user-id',
            email: 'test@example.com',
            aud: 'authenticated',
            role: 'authenticated',
          }
          return Promise.resolve(new Response(JSON.stringify(mockAuthResponse), { status: 200 }))
        } else {
          // Return auth error for invalid tokens
          return Promise.resolve(
            new Response(JSON.stringify({ message: 'Invalid JWT' }), { status: 401 }),
          )
        }
      }

      // Mock Supabase database queries (conversation_logs)
      if (url.includes('supabase.co') && url.includes('conversation_logs')) {
        // Mock conversation history as empty array
        return Promise.resolve(new Response(JSON.stringify([]), { status: 200 }))
      }

      // Default mock for any other requests (including other Supabase calls)
      return Promise.resolve(new Response('{}', { status: 200 }))
    }
  })

  afterEach(async () => {
    // Restore original functions
    globalThis.fetch = originalFetch
    Deno.env.get = originalEnv
    Deno.readTextFile = originalReadTextFile

    // Clear any cache/rate limit data to prevent leaks
    try {
      const { clearCache } = await import('./middleware/cache.ts')
      const { clearRateLimits } = await import('./middleware/rate-limit.ts')
      await clearCache()
      await clearRateLimits()
    } catch (_error) {
      // Ignore cleanup errors in tests
    }
  })

  it(
    'should handle valid coaching request and return structured JSON',
    { sanitizeOps: false, sanitizeResources: false },
    async () => {
      const request = new Request('https://test.com/generate-response', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer valid-jwt-token',
        },
        body: JSON.stringify({
          user_id: 'test-user-id',
          message: 'I feel overwhelmed with my goals today',
          momentum_state: 'NeedsCare',
        }),
      })

      const response = await handler(request)

      assertEquals(response.status, 200)

      const responseData = await response.json()

      // Verify response structure
      assertExists(responseData.assistant_message)
      assertExists(responseData.persona)
      assertExists(responseData.response_time_ms)
      assertEquals(typeof responseData.cache_hit, 'boolean')
      assertEquals(responseData.persona, 'supportive') // Should be supportive for NeedsCare state

      // Verify cache telemetry header
      const cacheStatus = response.headers.get('X-Cache-Status')
      assertExists(cacheStatus)
      assertEquals(cacheStatus === 'HIT' || cacheStatus === 'MISS', true)
    },
  )

  it(
    'should return 400 for missing required fields',
    { sanitizeOps: false, sanitizeResources: false },
    async () => {
      const request = new Request('https://test.com/generate-response', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer valid-jwt-token',
        },
        body: JSON.stringify({
          user_id: 'test-user-id',
          // Missing message field
        }),
      })

      const response = await handler(request)

      assertEquals(response.status, 400)

      const responseData = await response.json()
      assertExists(responseData.error)
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
          // Missing Authorization header
        },
        body: JSON.stringify({
          user_id: 'test-user-id',
          message: 'Test message',
        }),
      })

      const response = await handler(request)

      assertEquals(response.status, 401)
    },
  )

  it(
    'should handle OPTIONS request for CORS',
    { sanitizeOps: false, sanitizeResources: false },
    async () => {
      const request = new Request('https://test.com/generate-response', {
        method: 'OPTIONS',
      })

      const response = await handler(request)

      assertEquals(response.status, 200)
      assertExists(response.headers.get('Access-Control-Allow-Origin'))
    },
  )
})
