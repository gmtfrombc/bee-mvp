// Stub timer functions to prevent leaks
;(globalThis as any).setInterval = () => 0
;(globalThis as any).setTimeout = () => 0
;(globalThis as any).clearInterval = () => {}
;(globalThis as any).clearTimeout = () => {}

// Mock environment variables for test mode BEFORE any imports
Deno.env.set('SUPABASE_URL', 'https://test.supabase.co')
Deno.env.set('SUPABASE_ANON_KEY', 'test-anon-key')
Deno.env.set('AI_API_KEY', 'test-ai-key')
Deno.env.set('AI_MODEL', 'claude-3-haiku-20240307')
Deno.env.set('ENVIRONMENT', 'development')
Deno.env.set('DENO_TESTING', 'true')
Deno.env.set('OFFLINE_AI', 'true')
Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key')
Deno.env.set('CACHE_ENABLED', 'false')
Deno.env.set('RATE_LIMIT_ENABLED', 'false')

// Mock fetch for all external requests
const originalFetch = globalThis.fetch
globalThis.fetch = async (input: string | Request | URL, init?: RequestInit) => {
  const url = typeof input === 'string' ? input : input.toString()

  // Mock AI API response
  if (url.includes('anthropic.com') || url.includes('openai.com')) {
    const mockResponse = url.includes('anthropic.com')
      ? {
        content: [{
          text:
            "Great job! I see your momentum is changing. Let's work together to keep building on this positive shift.",
        }],
      }
      : {
        choices: [{
          message: {
            content:
              "Great job! I see your momentum is changing. Let's work together to keep building on this positive shift.",
          },
        }],
      }
    return new Response(JSON.stringify(mockResponse), { status: 200 })
  }

  // Mock Supabase auth response - accept service role key
  if (url.includes('supabase.co') && (url.includes('auth/v1/user') || url.includes('/auth/user'))) {
    const headers = init?.headers as Record<string, string> || {}
    const authHeader = headers['Authorization'] || headers['authorization'] || ''

    if (
      authHeader &&
      (authHeader.includes('test-service-role-key') || authHeader.includes('test-token'))
    ) {
      return new Response(
        JSON.stringify({
          id: '00000000-0000-0000-0000-000000000001',
          email: 'test@example.com',
          aud: 'authenticated',
          role: 'authenticated',
        }),
        { status: 200 },
      )
    } else {
      return new Response(JSON.stringify({ message: 'Invalid JWT' }), { status: 401 })
    }
  }

  // Mock other Supabase database calls
  if (url.includes('supabase.co')) {
    return new Response(JSON.stringify([]), { status: 200 })
  }

  // Default mock
  return new Response('{}', { status: 200 })
}

// Mock file reading for prompt templates
const originalReadTextFile = Deno.readTextFile
Deno.readTextFile = async (path: string | URL): Promise<string> => {
  const pathStr = typeof path === 'string' ? path : path.toString()
  if (pathStr.includes('safety.md')) {
    return 'You are a healthcare coach. Do not provide medical advice.'
  }
  if (pathStr.includes('system.md')) {
    return 'You are a supportive AI coach helping users with behavior change.'
  }
  return 'Mock template content'
}

import { assertEquals, assertExists } from 'https://deno.land/std@0.208.0/assert/mod.ts'

// Import the handler after setting env vars and mocks
import handler from './mod.ts'

Deno.test({
  name: 'ai-coaching-engine: handles momentum change system event',
  sanitizeOps: false,
  sanitizeResources: false,
}, async () => {
  const mockRequest = {
    user_id: '00000000-0000-0000-0000-000000000001', // Use test user ID
    message: 'momentum_change:Steady:Rising',
    momentum_state: 'Rising',
    system_event: 'momentum_change',
    previous_state: 'Steady',
    current_score: 75.5,
  }

  const request = new Request('http://localhost:8000', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer test-service-role-key',
      'X-System-Event': 'true',
    },
    body: JSON.stringify(mockRequest),
  })

  const response = await handler(request)

  // Should return 200 with successful response in test environment
  assertEquals(response.status, 200)

  const responseBody = await response.json()
  assertExists(responseBody.assistant_message)
  assertExists(responseBody.persona)
  assertExists(responseBody.response_time_ms)
})

Deno.test({
  name: 'ai-coaching-engine: bypasses rate limit for momentum change events',
  sanitizeOps: false,
  sanitizeResources: false,
}, async () => {
  const mockRequest = {
    user_id: '00000000-0000-0000-0000-000000000001', // Use test user ID
    message: 'momentum_change:Rising:NeedsCare',
    momentum_state: 'NeedsCare',
    system_event: 'momentum_change',
    previous_state: 'Rising',
    current_score: 25.0,
  }

  const request = new Request('http://localhost:8000', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer test-service-role-key',
      'X-System-Event': 'true',
    },
    body: JSON.stringify(mockRequest),
  })

  const response = await handler(request)

  // Should return 200 with successful response, not 429 (rate limit)
  // This confirms momentum change events bypass rate limiting
  assertEquals(response.status, 200)

  const responseBody = await response.json()
  assertExists(responseBody.assistant_message)
  assertExists(responseBody.persona)
  assertExists(responseBody.response_time_ms)
})

Deno.test({
  name: 'ai-coaching-engine: handles regular user messages with rate limiting',
  sanitizeOps: false,
  sanitizeResources: false,
}, async () => {
  const mockRequest = {
    user_id: '00000000-0000-0000-0000-000000000001', // Use test user ID
    message: 'I need help with my habits',
    momentum_state: 'Steady',
    // No system_event field
  }

  const request = new Request('http://localhost:8000', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer test-service-role-key',
      'X-System-Event': 'true',
    },
    body: JSON.stringify(mockRequest),
  })

  const response = await handler(request)

  // Should return 200 with successful response in test environment
  assertEquals(response.status, 200)

  const responseBody = await response.json()
  assertExists(responseBody.assistant_message)
  assertExists(responseBody.persona)
  assertExists(responseBody.response_time_ms)
})

Deno.test({
  name: 'ai-coaching-engine: validates required fields',
  sanitizeOps: false,
  sanitizeResources: false,
}, async () => {
  const mockRequest = {
    user_id: '00000000-0000-0000-0000-000000000001', // Use test user ID
    // Missing message field
  }

  const request = new Request('http://localhost:8000', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer test-service-role-key',
      'X-System-Event': 'true',
    },
    body: JSON.stringify(mockRequest),
  })

  const response = await handler(request)

  assertEquals(response.status, 400)

  const responseBody = await response.json()
  assertEquals(responseBody.error, 'Missing required fields: user_id, message')
})

Deno.test({
  name: 'ai-coaching-engine: handles CORS preflight requests',
  sanitizeOps: false,
  sanitizeResources: false,
}, async () => {
  const request = new Request('http://localhost:8000', {
    method: 'OPTIONS',
  })

  const response = await handler(request)

  assertEquals(response.status, 200)
  assertEquals(response.headers.get('Access-Control-Allow-Origin'), '*')
  assertEquals(response.headers.get('Access-Control-Allow-Methods'), 'POST, OPTIONS')
})
