import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'

// Ensure required env vars so module initialisation succeeds
Deno.env.set('SUPABASE_URL', 'https://test.supabase.co')
Deno.env.set('AI_API_KEY', 'test-ai-key')

const { parseAIContentResponse } = await import('./mod.ts')

Deno.test('parseAIContentResponse – cleans up malformed first-line bracket', () => {
  // Simulate response that previously produced title "{"
  const malformed =
    '{\n  "title": "Fuel Your Saturday with Fresh Fruits!",\n  "summary": "Enjoy seasonal fruit today…"\n}'

  const parsed = parseAIContentResponse(malformed, 'nutrition')
  assertExists(parsed)
  // Title should not be just a single curly bracket
  assertEquals(parsed.title.startsWith('{'), false)
  assertEquals(parsed.title.length > 5, true)
  assertEquals(parsed.topic_category, 'nutrition')
})
