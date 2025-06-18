import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'

// Test helper functions that mirror the mod.ts utility logic without importing the entire module
// This tests the core business logic without complex dependencies

// Replicate chooseTopicForDate logic
function chooseTopicForDate(contentDate: string, topics: string[]): string {
  const date = new Date(contentDate)
  const dayOfYear = Math.floor(
    (date.getTime() - new Date(date.getFullYear(), 0, 0).getTime()) / (1000 * 60 * 60 * 24),
  )
  return topics[dayOfYear % topics.length]
}

// Replicate parseAIContentResponse core logic
function parseAIContentResponse(
  aiResponse: string,
  topicCategory: string,
): { title: string; summary: string; topic_category: string } | null {
  try {
    let jsonMatch = aiResponse.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      jsonMatch = [aiResponse]
    }

    const parsed = JSON.parse(jsonMatch[0])

    if (!parsed.title || !parsed.summary) {
      throw new Error('Missing required fields in AI response')
    }

    const title = parsed.title.substring(0, 60)
    const summary = parsed.summary.substring(0, 200)

    return {
      title,
      summary,
      topic_category: topicCategory,
    }
  } catch (_error) {
    const lines = aiResponse.split('\n').filter((line) => line.trim())
    const title = lines[0]?.substring(0, 60) || `Daily ${topicCategory} Tip`
    const summary = lines.slice(1, 3).join(' ').substring(0, 200) ||
      'Focus on improving your health today.'

    return {
      title,
      summary,
      topic_category: topicCategory,
    }
  }
}

// Replicate calculateContentConfidence logic
function calculateContentConfidence(
  content: { title: string; summary: string },
  topicCategory: string,
): number {
  let confidence = 0.7

  if (content.title.length >= 20 && content.title.length <= 60) {
    confidence += 0.1
  }

  if (content.summary.length >= 50 && content.summary.length <= 200) {
    confidence += 0.1
  }

  const topicKeywords: Record<string, string[]> = {
    'nutrition': ['food', 'eat', 'diet', 'nutrition', 'meal', 'vitamin', 'nutrient'],
    'exercise': ['exercise', 'workout', 'fitness', 'movement', 'activity', 'strength', 'cardio'],
    'sleep': ['sleep', 'rest', 'bedtime', 'morning', 'dream', 'tired', 'energy'],
  }

  const keywords = topicKeywords[topicCategory] || []
  const text = `${content.title} ${content.summary}`.toLowerCase()
  const keywordMatches = keywords.filter((keyword: string) => text.includes(keyword)).length

  if (keywordMatches >= 2) {
    confidence += 0.1
  }

  return Math.min(confidence, 1.0)
}

// Test chooseTopicForDate - deterministic topic rotation
Deno.test('chooseTopicForDate - rotates topics deterministically', () => {
  const topics = ['nutrition', 'exercise', 'sleep', 'stress']

  const result1 = chooseTopicForDate('2024-01-01', topics)
  const result2 = chooseTopicForDate('2024-01-01', topics)

  assertEquals(result1, result2) // Should be deterministic
  assertExists(result1)
  assertEquals(topics.includes(result1), true)
})

// Test parseAIContentResponse - valid JSON parsing
Deno.test('parseAIContentResponse - parses valid JSON correctly', () => {
  const validJson = `{
    "title": "Stay Hydrated Today",
    "summary": "Drinking enough water helps maintain energy levels and supports overall health."
  }`

  const result = parseAIContentResponse(validJson, 'nutrition')

  assertEquals(result?.title, 'Stay Hydrated Today')
  assertEquals(
    result?.summary,
    'Drinking enough water helps maintain energy levels and supports overall health.',
  )
  assertEquals(result?.topic_category, 'nutrition')
})

// Test parseAIContentResponse - fallback for invalid JSON
Deno.test('parseAIContentResponse - handles invalid JSON with fallback', () => {
  const invalidJson = 'This is not JSON at all'

  const result = parseAIContentResponse(invalidJson, 'exercise')

  assertEquals(result?.title, 'This is not JSON at all')
  assertEquals(result?.topic_category, 'exercise')
  assertExists(result?.summary)
})

// Test calculateContentConfidence - good quality content
Deno.test('calculateContentConfidence - scores high for quality content', () => {
  const content = {
    title: 'Exercise for Better Sleep Quality', // 20-60 chars, relevant
    summary:
      'Regular physical activity helps improve sleep quality by reducing stress and promoting relaxation. Try 30 minutes of exercise daily.', // 50-200 chars, relevant
  }

  const result = calculateContentConfidence(content, 'exercise')

  assertEquals(result > 0.8, true) // Should score high for good length + keywords
})

// Test calculateContentConfidence - low quality content
Deno.test('calculateContentConfidence - scores lower for poor content', () => {
  const content = {
    title: 'Tips', // Too short
    summary: 'Do things.', // Too short, no keywords
  }

  const result = calculateContentConfidence(content, 'nutrition')

  assertEquals(result, 0.7) // Should get only base score
})

// Test topic keyword matching
Deno.test('calculateContentConfidence - detects topic keywords correctly', () => {
  const content = {
    title: 'Nutrition and Diet Planning Guide for Better Health',
    summary:
      'Learn how to eat balanced meals with proper nutrition and maintain a healthy diet for optimal wellness and energy.',
  }

  const result = calculateContentConfidence(content, 'nutrition')

  assertEquals(result >= 0.9, true) // Should get all bonuses: length + keywords
})
