// services/daily-content.service.ts
// Utilities and helpers for generating daily health content.

import { ContentSafetyValidator } from '../safety/content-safety-validator.ts'
import { callAIAPI } from './ai-client.ts'
import { AIMessage, GeneratedContent } from '../types.ts'

/**
 * Choose topic deterministically based on date.
 */
export function chooseTopicForDate(contentDate: string, topics: string[]): string {
  const date = new Date(contentDate)
  const dayOfYear = Math.floor(
    (date.getTime() - new Date(date.getFullYear(), 0, 0).getTime()) / (1000 * 60 * 60 * 24),
  )
  return topics[dayOfYear % topics.length]
}

/**
 * Build AI prompt for daily content generation.
 */
export function buildDailyContentPrompt(topicCategory: string, contentDate: string): AIMessage[] {
  const date = new Date(contentDate)
  const dayName = date.toLocaleDateString('en-US', { weekday: 'long' })
  const monthName = date.toLocaleDateString('en-US', { month: 'long' })

  const systemPrompt =
    `You are a health and wellness content writer creating daily tips for a mobile health app. 

IMPORTANT SAFETY GUIDELINES:
- Never provide medical advice or diagnose conditions
- Always recommend consulting healthcare professionals for medical concerns
- Focus on general wellness and lifestyle tips
- Avoid claims about curing or treating diseases
- Use evidence-based information when possible

Your task is to create engaging, actionable health content for the topic: ${topicCategory}

Today is ${dayName}, ${monthName} ${date.getDate()}.

Please respond with a JSON object in this exact format:
{
  "title": "Engaging headline (max 60 characters)",
  "summary": "Brief, actionable summary (max 200 characters)",
  "key_points": ["Point 1", "Point 2", "Point 3"]
}

The content should be:
- Practical and actionable
- Appropriate for general audiences
- Evidence-based but accessible
- Motivational and positive
- Safe and not prescriptive`

  const userPrompt =
    `Generate daily health content for ${topicCategory} that users can apply today. Make it relevant for a ${dayName} and include specific, actionable advice.`

  return [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userPrompt },
  ]
}

/**
 * Parse AI response and extract structured content.
 */
export function parseAIContentResponse(
  aiResponse: string,
  topicCategory: string,
): Omit<GeneratedContent, 'confidence_score'> | null {
  try {
    let jsonMatch = aiResponse.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      jsonMatch = [aiResponse]
    }

    // deno-lint-ignore no-explicit-any
    const parsed: any = JSON.parse(jsonMatch[0])

    if (!parsed.title || !parsed.summary) {
      throw new Error('Missing required fields in AI response')
    }

    const title = String(parsed.title).substring(0, 60)
    const summary = String(parsed.summary).substring(0, 200)

    return {
      title,
      summary,
      topic_category: topicCategory,
      content_url: undefined,
      external_link: undefined,
    }
  } catch (error) {
    console.error('Error parsing AI content response:', error)

    const lines = aiResponse.split('\n').filter((l) => l.trim())
    const title = lines[0]?.substring(0, 60) || `Daily ${topicCategory} Tip`
    const summary = lines.slice(1, 3).join(' ').substring(0, 200) ||
      'Focus on improving your health today.'

    return {
      title,
      summary,
      topic_category: topicCategory,
      content_url: undefined,
      external_link: undefined,
    }
  }
}

/**
 * Simple heuristic to estimate confidence of generated content.
 */
export function calculateContentConfidence(
  content: Omit<GeneratedContent, 'confidence_score'>,
  topicCategory: string,
): number {
  let confidence = 0.7

  if (content.title.length >= 20 && content.title.length <= 60) confidence += 0.1
  if (content.summary.length >= 50 && content.summary.length <= 200) confidence += 0.1

  const topicKeywords: Record<string, string[]> = {
    nutrition: ['food', 'eat', 'diet', 'nutrition', 'meal', 'vitamin', 'nutrient'],
    exercise: ['exercise', 'workout', 'fitness', 'movement', 'activity', 'strength', 'cardio'],
    sleep: ['sleep', 'rest', 'bedtime', 'morning', 'dream', 'tired', 'energy'],
    stress: ['stress', 'anxiety', 'calm', 'relax', 'mindful', 'peace', 'tension'],
    prevention: ['prevent', 'avoid', 'protect', 'health', 'immune', 'wellness', 'safety'],
    lifestyle: ['lifestyle', 'habit', 'routine', 'balance', 'wellness', 'daily', 'healthy'],
  }

  const text = `${content.title} ${content.summary}`.toLowerCase()
  const matches = (topicKeywords[topicCategory] ?? []).filter((k) => text.includes(k)).length
  if (matches >= 2) confidence += 0.1

  return Math.min(confidence, 1.0)
}

/**
 * High-level function to generate daily content, including safety validation.
 */
export async function generateDailyHealthContent(
  contentDate: string,
  requestedTopic?: string,
): Promise<GeneratedContent | null> {
  try {
    const healthTopics = [
      'nutrition',
      'exercise',
      'sleep',
      'stress',
      'prevention',
      'lifestyle',
    ]

    const topicCategory = requestedTopic || chooseTopicForDate(contentDate, healthTopics)

    const prompt = buildDailyContentPrompt(topicCategory, contentDate)
    const aiResponse = await callAIAPI(prompt)
    if (!aiResponse) throw new Error('No response from AI API')

    const parsedContent = parseAIContentResponse(aiResponse, topicCategory)
    if (!parsedContent) throw new Error('Failed to parse AI response')

    const safety = ContentSafetyValidator.validateContent(
      parsedContent.title,
      parsedContent.summary,
      topicCategory,
    )

    if (!safety.is_safe || safety.requires_review) {
      const fallback = ContentSafetyValidator.generateSafeFallback(topicCategory)
      return {
        ...fallback,
        topic_category: topicCategory,
        confidence_score: 0.7,
      }
    }

    return {
      ...parsedContent,
      confidence_score: Math.min(
        calculateContentConfidence(parsedContent, topicCategory),
        safety.safety_score,
      ),
    }
  } catch (err) {
    console.error('Error generating daily health content:', err)
    return null
  }
}
