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
    `You are a health and wellness content writer creating daily tips for a mobile health app.

IMPORTANT SAFETY GUIDELINES:
- Never provide medical advice or diagnose conditions.
- Always recommend consulting healthcare professionals for medical concerns.
- Focus on general wellness and lifestyle tips.
- Avoid claims about curing or treating diseases.
- Use evidence-based information when possible.

TASK:
Write engaging, actionable content for the topic category "${topicCategory}" for ${dayName}, ${monthName} ${date.getDate()}.

RESPONSE FORMAT (JSON ONLY):
{
  "title": "Engaging headline (<= 60 characters)",
  "summary": "Brief, actionable summary (<= 200 characters)",
  "key_points": ["Point 1", "Point 2", "Point 3"],
  "full_content": {
    "elements": [
      { "type": "paragraph", "text": "A rich introductory paragraph (50-75 words) that hooks the reader." },
      { "type": "paragraph", "text": "A second paragraph (50-75 words) that elaborates on the topic, bringing the total article length to roughly 100-150 words." },
      { "type": "bullet_list", "list_items": ["Tip 1", "Tip 2", "Tip 3"], "text": "" }
    ],
    "actionable_advice": "One short actionable takeaway.",
    "source_reference": "Source or reference here."
  }
}

RULES:
1. The 'elements' array MUST contain **exactly two paragraphs followed by** one bullet_list (3 elements total).
2. The combined word count of the two paragraphs MUST fall between **100 and 150 words**. Aim for ~120 words total.
3. The bullet_list 'list_items' MUST have at least three concise tips.
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
    let jsonMatch = aiResponse.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      jsonMatch = [aiResponse]
    }

    const parsed: any = JSON.parse(jsonMatch[0])

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

// ------------------------------------------------------------
// Utility – quick word counter (tokens separated by whitespace)
// ------------------------------------------------------------
function wordCount(txt: string): number {
  return txt.trim().split(/\s+/).length
}

function isFullContentValid(fullContent: unknown, summary?: string): boolean {
  const fc: any = fullContent
  if (!fc || !Array.isArray(fc.elements) || fc.elements.length < 3) return false

  const [first, second, third] = fc.elements

  // Ensure two proper paragraphs
  const paragraphsValid = first?.type === 'paragraph' && typeof first.text === 'string' &&
    second?.type === 'paragraph' && typeof second.text === 'string'
  if (!paragraphsValid) return false

  // Word-count rule (each 40+ words, combined 100-160 words)
  const firstWords = wordCount(first.text)
  const secondWords = wordCount(second.text)
  const totalWords = firstWords + secondWords
  if (firstWords < 40 || secondWords < 40 || totalWords < 100 || totalWords > 160) {
    return false
  }

  // Prevent duplicate paragraphs / summary clones
  const sTrim = (summary ?? '').trim()
  if (first.text.trim() === second.text.trim()) return false
  if (sTrim && (first.text.trim() === sTrim || second.text.trim() === sTrim)) return false

  // Bullet list validation (≥3 items)
  const bulletValid = third?.type === 'bullet_list' && Array.isArray(third.list_items) &&
    third.list_items.length >= 3

  return bulletValid
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
    const maxAttempts = 5

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      console.log(`🌀 AI generation attempt ${attempt}/${maxAttempts}`)
      const aiRespObj = await callAIAPI(messages as any)
      aiResponse = aiRespObj.text
      if (!aiResponse) throw new Error('No response from AI API')

      parsedContent = parseAIContentResponse(aiResponse, topicCategory)
      if (
        parsedContent && isTitleValid(parsedContent.title) &&
        isFullContentValid(parsedContent.full_content, parsedContent.summary)
      ) {
        break // valid content obtained
      }

      if (attempt < maxAttempts) {
        const correctionMsg =
          `Your previous output was invalid because it did not follow the RESPONSE FORMAT or RULES. Please output JSON ONLY that matches the schema exactly.\nREQUIREMENTS:\n1. Exactly two paragraphs followed by one bullet_list.\n2. Each paragraph must be 50-75 words; combined 100-150 words.\n3. Paragraphs must be different from each other and from the summary.\n4. Bullet_list must have at least three concise tips.\n\nEXAMPLE (do NOT copy):\n{\n  \"full_content\": {\n    \"elements\": [\n      { \"type\": \"paragraph\", \"text\": \"Start your morning with a nutritious breakfast that balances protein, complex carbs, and healthy fats to fuel your body...\" },\n      { \"type\": \"paragraph\", \"text\": \"Later in the day, keep energy steady by choosing snacks like Greek yogurt with berries or a handful of nuts; planning meals in advance prevents...\" },\n      { \"type\": \"bullet_list\", \"list_items\": [\"Include colorful vegetables at lunch\", \"Hydrate with at least 8 cups of water\", \"Plan tomorrow's grocery list\"], \"text\": \"\" }\n    ]\n  }\n}`
        messages = [
          ...messages,
          { role: 'assistant', content: aiResponse },
          { role: 'user', content: correctionMsg },
        ]
      }
    }

    if (!parsedContent) throw new Error('Failed to parse AI response after retries')

    // ------------------------------------------------------------------
    // Secondary fallback – if, after retries, the full_content is still
    // invalid, ask the AI to expand the summary into two paragraphs of the
    // desired length.  This keeps long-form quality >95 % with minimal cost.
    // ------------------------------------------------------------------
    if (!isFullContentValid(parsedContent.full_content, parsedContent.summary)) {
      try {
        console.log('🔄 Attempting secondary expansion call…')

        const expansionPrompt: AIMessage[] = [
          {
            role: 'system',
            content:
              `You are a health-and-wellness copywriter. Expand the user summary into exactly two distinct paragraphs, each 50-75 words (total 100-150 words). Respond with JSON ONLY:\n{ "paragraphs": [ "para1", "para2" ] }`,
          },
          {
            role: 'user',
            content: parsedContent.summary,
          },
        ]

        const expansionResp = await callAIAPI(expansionPrompt as any)

        let para1 = ''
        let para2 = ''
        try {
          const parsedExp: any = JSON.parse(expansionResp.text)
          if (Array.isArray(parsedExp.paragraphs) && parsedExp.paragraphs.length >= 2) {
            para1 = String(parsedExp.paragraphs[0])
            para2 = String(parsedExp.paragraphs[1])
          }
        } catch (_) {
          // Fallback: naive split by double new line
          const parts = expansionResp.text.split(/\n\s*\n/).filter((p) => p.trim().length > 40)
          if (parts.length >= 2) {
            ;[para1, para2] = parts
          }
        }

        if (para1 && para2 && wordCount(para1) >= 40 && wordCount(para2) >= 40) {
          parsedContent.full_content = {
            elements: [
              { type: 'paragraph', text: para1 },
              { type: 'paragraph', text: para2 },
              {
                type: 'bullet_list',
                list_items: [
                  "Apply today's insight in a small way",
                  'Share it with a friend for accountability',
                  'Consult a professional for personalised advice',
                ],
                text: '',
              },
            ],
          }

          // Re-validate to update confidence
          if (isFullContentValid(parsedContent.full_content, parsedContent.summary)) {
            console.log('✅ Secondary expansion succeeded')
          } else {
            console.warn('⚠️ Expansion paragraphs still invalid, falling back to static content')
          }
        } else {
          console.warn('⚠️ Expansion call did not return valid paragraphs')
        }
      } catch (expErr) {
        console.warn('⚠️ Secondary expansion call failed:', expErr)
      }
    }

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
    if (!isFullContentValid(parsedContent.full_content, parsedContent.summary)) {
      const para1 = { type: 'paragraph', text: parsedContent.summary }
      const topicSecond: Record<string, string> = {
        nutrition:
          'Consistently choosing balanced meals lays the foundation for long-term health and sustained energy throughout the week.',
        exercise:
          'Regular movement, even in short sessions, supports strength, mobility, and a positive mood—schedule it like any important appointment.',
        sleep:
          'A calming wind-down ritual signals your body that it is time to rest, improving both sleep quality and overall wellbeing.',
        stress:
          'Brief mindful pauses sprinkled through the day can lower stress hormones and train your brain for greater resilience.',
        prevention:
          'Small protective choices today—like sunscreen or a flu shot—compound into significant long-term health benefits.',
        lifestyle:
          'Tiny healthy habits performed daily accumulate, creating meaningful lifestyle change you can sustain for years.',
      }
      const para2 = {
        type: 'paragraph',
        text: topicSecond[topicCategory] ?? topicSecond['lifestyle'],
      }

      parsedContent.full_content = {
        elements: [
          para1,
          para2,
          {
            type: 'bullet_list',
            list_items: [
              "Apply today's insight in a small way",
              'Share it with a friend for accountability',
              'Consult a professional for personalised advice',
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
