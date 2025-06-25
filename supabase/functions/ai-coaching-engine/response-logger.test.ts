import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { getRecentMessages, logConversation } from './response-logger.ts'

Deno.test('logConversation - skips logging in test environment', async () => {
  Deno.env.set('DENO_TESTING', 'true')

  const result = await logConversation('', 'test-user', 'user', 'Hello world')

  assertEquals(result, null)

  Deno.env.delete('DENO_TESTING')
})

Deno.test('getRecentMessages - returns empty array in test environment', async () => {
  Deno.env.set('DENO_TESTING', 'true')

  const messages = await getRecentMessages('test-user', 10)

  assertEquals(messages, [])

  Deno.env.delete('DENO_TESTING')
})
