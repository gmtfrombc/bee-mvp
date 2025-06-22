// services/daily-content.service.ts
// Utilities and helpers for generating daily health content.

// deno-lint-ignore-file no-explicit-any

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
    `You are a health-and-wellness content writer for a mobile app. Each day you create ONE compact but complete article.

IMPORTANT SAFETY GUIDELINES:
- Never provide medical advice or diagnose conditions.
- Always recommend consulting healthcare professionals for medical concerns.
- Focus on general wellness and lifestyle tips.
- Avoid claims about curing or treating diseases.
- Use evidence-based information when possible.

TASK:
Write engaging, actionable content for the topic category "${topicCategory}" for ${dayName}, ${monthName} ${date.getDate()}.
The **total word count of the article (all text inside full_content.elements) MUST be between 220 and 300 words** so users can finish it in about two minutes.

RESPONSE FORMAT (JSON ONLY):
{
  "title": "Engaging headline (<= 60 characters)",
  "summary": "Brief, actionable summary (<= 200 characters)",
  "key_points": ["Point 1", "Point 2", "Point 3"],
  "full_content": {
    "elements": [
      { "type": "paragraph", "text": "A ~120-150 word introductory paragraph that hooks the reader." },
      { "type": "paragraph", "text": "A second ~100-130 word paragraph that elaborates on the topic." },
      { "type": "bullet_list", "list_items": ["Tip 1", "Tip 2", "Tip 3"], "text": "" }
    ],
    "actionable_advice": "One short actionable takeaway.",
    "source_reference": "Source or reference here."
  }
}

RULES:
1. 'elements' MUST contain exactly two paragraphs followed by one bullet_list.
2. The combined word count of the two paragraphs PLUS bullet list items must be 220-300 words.
3. The bullet_list 'list_items' MUST have at least three tips.
4. Do NOT include markdown, HTML, or special formatting.
5. Respond **ONLY** with valid JSON that EXACTLY matches the schema above—no extra keys, no commentary.
6. If the first attempt does not meet every rule, think step-by-step, correct the JSON, and output again until it is valid.`

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
    // ------------------------------------------------------------
    // Strip common markdown code-fence wrappers (```json ... ```)
    // and any leading/trailing whitespace before parsing.
    // ------------------------------------------------------------
    const cleaned = aiResponse
      .trim()
      .replace(/^```(?:json)?/i, '')
      .replace(/```$/i, '')
      .trim()

    // Try to find the first JSON object inside the string;
    // fallback to the whole cleaned string if no match.
    const jsonMatch = cleaned.match(/\{[\s\S]*\}/)
    const jsonText = jsonMatch ? jsonMatch[0] : cleaned

    const parsed: any = JSON.parse(jsonText)

    if (!parsed.title || !parsed.summary) {
      throw new Error('Missing required fields in AI response')
    }

    const title = String(parsed.title).substring(0, 60)
    const summary = String(parsed.summary).substring(0, 200)

    const defaultFull = {
      elements: [
        { type: 'paragraph', text: summary },
        ...(Array.isArray(parsed.key_points) && parsed.key_points.length > 0
          ? [{ type: 'bullet_list', list_items: parsed.key_points, text: '' }]
          : []),
      ],
      actionable_advice: parsed.actionable_advice ?? undefined,
      source_reference: parsed.source_reference ?? undefined,
    } as unknown

    return {
      title,
      summary,
      topic_category: topicCategory,
      content_url: undefined,
      external_link: undefined,
      full_content: parsed.full_content ?? defaultFull,
    }
  } catch (error) {
    console.warn('⚠️  Error parsing AI content response (fallback will repair):', error)

    // ------------------------------------------------------------
    // Fallback heuristics when JSON.parse fails.
    // Try to extract title / summary from common key strings first.
    // ------------------------------------------------------------
    const titleMatch = aiResponse.match(/"title"\s*:\s*"([^"]{3,80})"/i)
    const summaryMatch = aiResponse.match(/"summary"\s*:\s*"([^"]{10,300})"/i)

    const rawLines = aiResponse.split('\n').filter((l) => l.trim())

    let title = (titleMatch ? titleMatch[1] : rawLines[0] ?? '').trim()
    if (title.startsWith('{')) title = ''
    title = title.substring(0, 60)
    if (title.length < 5) {
      title = `Daily ${topicCategory.charAt(0).toUpperCase()}${topicCategory.slice(1)} Tip`
    }

    let summary = (summaryMatch ? summaryMatch[1] : rawLines.slice(1, 3).join(' ')).trim()
    summary = summary.substring(0, 200)
    if (summary.length < 20) {
      summary = 'Focus on improving your health today.'
    }

    const defaultFull = {
      elements: [
        { type: 'paragraph', text: summary },
      ],
    } as unknown

    return {
      title,
      summary,
      topic_category: topicCategory,
      content_url: undefined,
      external_link: undefined,
      full_content: defaultFull,
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

function isFullContentValid(fullContent: unknown): boolean {
  const fc: any = fullContent
  if (!fc || !Array.isArray(fc.elements)) return false
  if (fc.elements.length < 3) return false
  const [first, second, third] = fc.elements
  const paragraphsValid = first?.type === 'paragraph' && typeof first.text === 'string' &&
    second?.type === 'paragraph' && typeof second.text === 'string'
  const bulletValid = third?.type === 'bullet_list' && Array.isArray(third.list_items) &&
    third.list_items.length >= 3
  return paragraphsValid && bulletValid
}

function isTitleValid(t: string): boolean {
  return t.trim().length >= 5 && !t.trim().startsWith('{') && !t.includes('"')
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

    let messages = buildDailyContentPrompt(topicCategory, contentDate)
    let parsedContent: Omit<GeneratedContent, 'confidence_score'> | null = null
    let aiResponse = ''
    const maxAttempts = 3

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      const aiRespObj = await callAIAPI(messages as any)
      aiResponse = aiRespObj.text
      if (!aiResponse) throw new Error('No response from AI API')

      parsedContent = parseAIContentResponse(aiResponse, topicCategory)
      if (
        parsedContent && isTitleValid(parsedContent.title) &&
        isFullContentValid(parsedContent.full_content)
      ) {
        break // valid content obtained
      }

      if (attempt < maxAttempts) {
        const correctionMsg =
          `Your previous output was invalid because it did not follow the RESPONSE FORMAT or RULES. Please output JSON ONLY that matches the schema exactly, ensuring 'full_content.elements' has at least two paragraphs followed by one bullet_list with three or more list_items.`
        messages = [
          ...messages,
          { role: 'assistant', content: aiResponse },
          { role: 'user', content: correctionMsg },
        ]
      }
    }

    if (!parsedContent) throw new Error('Failed to parse AI response after retries')

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

    // Ensure full_content passes validation; if not, fall back to simple safe content
    if (!isFullContentValid(parsedContent.full_content)) {
      const safeParagraph = { type: 'paragraph', text: parsedContent.summary }
      parsedContent.full_content = {
        elements: [
          safeParagraph,
          safeParagraph,
          {
            type: 'bullet_list',
            list_items: [
              'Stay mindful of your health today',
              'Apply the tips provided',
              'Consult a professional for personal advice',
            ],
            text: '',
          },
        ],
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
