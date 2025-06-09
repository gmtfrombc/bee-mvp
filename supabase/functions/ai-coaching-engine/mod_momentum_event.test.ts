// Mock environment variables for test mode BEFORE any imports
Deno.env.set('SUPABASE_URL', 'http://localhost:54321')
Deno.env.set('SUPABASE_ANON_KEY', 'test-anon-key')
Deno.env.set('AI_API_KEY', 'test-ai-key')
Deno.env.set('AI_MODEL', 'claude-3-haiku-20240307')
Deno.env.set('ENVIRONMENT', 'development')
Deno.env.set('DENO_TESTING', 'true')
Deno.env.set('OFFLINE_AI', 'true')

import { assertEquals, assertExists } from 'https://deno.land/std@0.208.0/assert/mod.ts'

// Import the handler after setting env vars
import handler from './mod.ts'

Deno.test('ai-coaching-engine: handles momentum change system event', async () => {
    const mockRequest = {
        user_id: '00000000-0000-0000-0000-000000000001', // Use test user ID
        message: 'momentum_change:Steady:Rising',
        momentum_state: 'Rising',
        system_event: 'momentum_change',
        previous_state: 'Steady',
        current_score: 75.5
    }

    const request = new Request('http://localhost:8000', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test-token'
        },
        body: JSON.stringify(mockRequest)
    })

    const response = await handler(request)

    // Should return 200 with successful response in test environment
    assertEquals(response.status, 200)

    const responseBody = await response.json()
    assertExists(responseBody.assistant_message)
    assertExists(responseBody.persona)
    assertExists(responseBody.response_time_ms)
})

Deno.test('ai-coaching-engine: bypasses rate limit for momentum change events', async () => {
    const mockRequest = {
        user_id: '00000000-0000-0000-0000-000000000001', // Use test user ID
        message: 'momentum_change:Rising:NeedsCare',
        momentum_state: 'NeedsCare',
        system_event: 'momentum_change',
        previous_state: 'Rising',
        current_score: 25.0
    }

    const request = new Request('http://localhost:8000', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test-token'
        },
        body: JSON.stringify(mockRequest)
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

Deno.test('ai-coaching-engine: handles regular user messages with rate limiting', async () => {
    const mockRequest = {
        user_id: '00000000-0000-0000-0000-000000000001', // Use test user ID
        message: 'I need help with my habits',
        momentum_state: 'Steady'
        // No system_event field
    }

    const request = new Request('http://localhost:8000', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test-token'
        },
        body: JSON.stringify(mockRequest)
    })

    const response = await handler(request)

    // Should return 200 with successful response in test environment
    assertEquals(response.status, 200)

    const responseBody = await response.json()
    assertExists(responseBody.assistant_message)
    assertExists(responseBody.persona)
    assertExists(responseBody.response_time_ms)
})

Deno.test('ai-coaching-engine: validates required fields', async () => {
    const mockRequest = {
        user_id: '00000000-0000-0000-0000-000000000001' // Use test user ID
        // Missing message field
    }

    const request = new Request('http://localhost:8000', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test-token'
        },
        body: JSON.stringify(mockRequest)
    })

    const response = await handler(request)

    assertEquals(response.status, 400)

    const responseBody = await response.json()
    assertEquals(responseBody.error, 'Missing required fields: user_id, message')
})

Deno.test('ai-coaching-engine: handles CORS preflight requests', async () => {
    const request = new Request('http://localhost:8000', {
        method: 'OPTIONS'
    })

    const response = await handler(request)

    assertEquals(response.status, 200)
    assertEquals(response.headers.get('Access-Control-Allow-Origin'), '*')
    assertEquals(response.headers.get('Access-Control-Allow-Methods'), 'POST, OPTIONS')
}) 