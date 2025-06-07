import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { describe, it } from 'https://deno.land/std@0.168.0/testing/bdd.ts'

describe('AI Coaching Engine Basic Tests', () => {
    it('should handle CORS OPTIONS request', async () => {
        const { default: handler } = await import('./mod.ts')

        const request = new Request('https://test.com/generate-response', {
            method: 'OPTIONS'
        })

        const response = await handler(request)

        assertEquals(response.status, 200)
        assertExists(response.headers.get('Access-Control-Allow-Origin'))
        assertEquals(response.headers.get('Access-Control-Allow-Origin'), '*')
    })

    it('should reject non-POST requests', async () => {
        const { default: handler } = await import('./mod.ts')

        const request = new Request('https://test.com/generate-response', {
            method: 'GET'
        })

        const response = await handler(request)

        assertEquals(response.status, 405)
    })

    it('should return 400 for missing request body', async () => {
        const { default: handler } = await import('./mod.ts')

        const request = new Request('https://test.com/generate-response', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer test-token'
            },
            body: JSON.stringify({}) // Empty body
        })

        const response = await handler(request)

        assertEquals(response.status, 400)
        const data = await response.json()
        assertExists(data.error)
        assertEquals(data.error.includes('Missing required fields'), true)
    })

    it('should return 401 for missing authorization', async () => {
        const { default: handler } = await import('./mod.ts')

        const request = new Request('https://test.com/generate-response', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                user_id: 'test-user',
                message: 'Hello'
            })
        })

        const response = await handler(request)

        assertEquals(response.status, 401)
        const data = await response.json()
        assertExists(data.error)
        assertEquals(data.error, 'Missing authorization token')
    })
}) 