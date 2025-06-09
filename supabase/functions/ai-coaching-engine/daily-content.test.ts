import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'

// Set up test environment variables to avoid module initialization errors
Deno.env.set('SUPABASE_URL', 'https://test.supabase.co')
Deno.env.set('SUPABASE_ANON_KEY', 'test-key')
Deno.env.set('AI_API_KEY', 'test-ai-key')

const { chooseTopicForDate, buildDailyContentPrompt, parseAIContentResponse } = await import('./mod.ts')

// Happy path test - as required by testing policy  
Deno.test('Daily Content Generation - topic rotation works deterministically', () => {
    const topics = ['nutrition', 'exercise', 'sleep', 'stress', 'prevention', 'lifestyle']

    // Same date should always return same topic
    const topic1 = chooseTopicForDate('2024-01-15', topics)
    const topic2 = chooseTopicForDate('2024-01-15', topics)
    assertEquals(topic1, topic2)

    // Different dates should rotate through topics
    const topic3 = chooseTopicForDate('2024-01-16', topics)
    const topic4 = chooseTopicForDate('2024-01-17', topics)

    // Should be valid topics
    assertEquals(topics.includes(topic1), true)
    assertEquals(topics.includes(topic3), true)
    assertEquals(topics.includes(topic4), true)
})

// Critical edge case - prompt building validation
Deno.test('Daily Content Generation - builds valid prompts for all topics', () => {
    const topics = ['nutrition', 'exercise', 'sleep', 'stress', 'prevention', 'lifestyle']
    const testDate = '2024-01-15'

    for (const topic of topics) {
        const prompt = buildDailyContentPrompt(topic, testDate)

        // Should return array with system and user messages
        assertEquals(Array.isArray(prompt), true)
        assertEquals(prompt.length, 2)

        // Should have required structure
        assertEquals(prompt[0].role, 'system')
        assertEquals(prompt[1].role, 'user')
        assertExists(prompt[0].content)
        assertExists(prompt[1].content)

        // Should include topic and safety guidelines
        assertEquals(prompt[0].content.includes(topic), true)
        assertEquals(prompt[0].content.includes('SAFETY GUIDELINES'), true)
        assertEquals(prompt[0].content.includes('Never provide medical advice'), true)
    }
})

// Critical edge case - response parsing validation
Deno.test('Daily Content Generation - parses valid AI responses correctly', () => {
    const validJsonResponse = JSON.stringify({
        title: 'Test Health Tip',
        summary: 'A valid summary for testing purposes.',
        key_points: ['Point 1', 'Point 2', 'Point 3']
    })

    const parsed = parseAIContentResponse(validJsonResponse, 'nutrition')

    assertExists(parsed)
    assertEquals(parsed.title, 'Test Health Tip')
    assertEquals(parsed.summary, 'A valid summary for testing purposes.')
    assertEquals(parsed.topic_category, 'nutrition')
})

// Critical edge case - handles malformed responses  
Deno.test('Daily Content Generation - handles malformed AI responses gracefully', () => {
    const malformedResponses = [
        'not json at all',
        '{"title": "Missing summary"}',
        '{"summary": "Missing title"}',
        '{}',
        ''
    ]

    for (const response of malformedResponses) {
        const parsed = parseAIContentResponse(response, 'nutrition')

        // Should return fallback content instead of null
        assertExists(parsed, `Should handle malformed response: ${response}`)
        assertEquals(parsed.topic_category, 'nutrition')
        assertExists(parsed.title)
        assertExists(parsed.summary)

        // Title and summary should be reasonable fallbacks
        assertEquals(parsed.title.length > 0, true)
        assertEquals(parsed.summary.length > 0, true)
    }
})

// Critical edge case - content length validation
Deno.test('Daily Content Generation - enforces content length limits', () => {
    const longTitleResponse = JSON.stringify({
        title: 'A'.repeat(100), // Too long
        summary: 'Valid summary',
        key_points: ['Point 1']
    })

    const longSummaryResponse = JSON.stringify({
        title: 'Valid title',
        summary: 'B'.repeat(300), // Too long
        key_points: ['Point 1']
    })

    const longTitleParsed = parseAIContentResponse(longTitleResponse, 'nutrition')
    const longSummaryParsed = parseAIContentResponse(longSummaryResponse, 'nutrition')

    // Should truncate to limits
    assertExists(longTitleParsed)
    assertEquals(longTitleParsed.title.length <= 60, true)

    assertExists(longSummaryParsed)
    assertEquals(longSummaryParsed.summary.length <= 200, true)
}) 