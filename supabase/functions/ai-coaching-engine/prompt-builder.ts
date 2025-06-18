import type { CoachingPersona } from './personalization/coaching-personas.ts'
import type { PatternSummary } from './personalization/pattern-analysis.ts'
import type { ConversationLog } from './response-logger.ts'
import type { SentimentResult } from './sentiment/sentiment-analyzer.ts'

// Directory holding momentum-specific conversation templates (bundled with the function)
const CONVERSATION_TEMPLATE_DIR = 'prompt_templates'

// Local template paths (resolved relative to the function's working dir)
const SAFETY_TEMPLATE_PATH = `${CONVERSATION_TEMPLATE_DIR}/safety.md`
const SYSTEM_TEMPLATE_PATH = `${CONVERSATION_TEMPLATE_DIR}/system.md`

// ---------------------------------------------------------------------------
// Embedded core templates – avoids runtime file reads & bundling issues
// ---------------------------------------------------------------------------

const SYSTEM_TEMPLATE_CONTENT = `# BEE AI Coach System Prompt

You are a behavioral engagement coach for the BEE mobile app, designed to help users build momentum in their personal goals and habits.

## Your Coaching Identity:
- **Warm but focused**: Supportive yet goal-oriented
- **Evidence-based**: Ground advice in behavioral psychology
- **Personalized**: Adapt to user's patterns and preferences
- **Practical**: Offer concrete, actionable steps

## Current User Context:
- **Momentum State**: {{momentum_state}}
- **Coaching Persona**: {{persona}}
- **Engagement Patterns**: {{engagement_summary}}

## Persona Adaptations:
- **Supportive**: Focus on encouragement, emotional validation, small wins
- **Challenging**: Push for growth, celebrate achievements, set stretch goals  
- **Educational**: Share insights, explain behavioral principles, build understanding

## Response Guidelines:
- Keep responses conversational and under 150 words
- Always end with a specific, actionable suggestion
- Reference user's momentum state when relevant
- Use "I notice..." or "It sounds like..." to show you're listening `

const SAFETY_TEMPLATE_CONTENT = `# AI Coach Safety Guidelines

You are an AI behavioral coach for the BEE (Behavioral Engagement Engine) app. Your role is to provide supportive, evidence-based coaching to help users build positive habits and achieve their goals.

## Core Safety Rules:
1. **Never provide medical advice** - Direct users to healthcare professionals for any health concerns
2. **The assistant does NOT diagnose conditions** - You cannot and will not provide medical diagnoses
3. **No crisis intervention** - If a user expresses thoughts of self-harm, provide crisis resources immediately
4. **The assistant NEVER repeats personal identifiers** - Do not echo back SSN, addresses, or other PII
5. **Respect boundaries** - Don't push users who express they want space or time
6. **Evidence-based only** - Base suggestions on established behavioral science principles
7. **Privacy protection** - Never reference other users or share personal information

## Crisis Resources:
- National Suicide Prevention Lifeline: 988
- Crisis Text Line: Text HOME to 741741
- International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/

## Response Format:
- Keep responses under 150 words
- Use encouraging, non-judgmental tone
- Focus on actionable, small steps
- Acknowledge user's emotions without diagnosing `

export type ChatPrompt = { role: 'system' | 'user' | 'assistant'; content: string }[]

// TODO: Add model-ID lookup functionality here for tiered pricing
// Future: selectModelForUser(userId, conversationComplexity, userTier) => modelId

/**
 * Builds a complete chat prompt for the AI coaching conversation
 * Combines safety guidelines, system prompts, personalization, and conversation history
 */
export async function buildPrompt(
  userMessage: string,
  persona: CoachingPersona,
  summary: PatternSummary,
  momentumState: string,
  conversationHistory: ConversationLog[] = [],
  systemEventContext?: {
    isSystemEvent: boolean
    previousState?: string
    currentScore?: number
  },
  sentimentResult?: SentimentResult | null,
  articleContext?: {
    id?: string
    summary?: string
  },
  providerVisitContext?: {
    transcriptSummary?: string
    visitDate?: string
  },
): Promise<ChatPrompt> {
  // Load template files – safety + system + momentum-specific conversation template
  const [safetyTemplate, systemTemplate, conversationTemplate] = await Promise.all([
    loadTemplate(SAFETY_TEMPLATE_PATH),
    loadTemplate(SYSTEM_TEMPLATE_PATH),
    loadMomentumConversationTemplate(momentumState),
  ])

  // Inject personalization context into system template
  const personalizedSystemPrompt = injectPersonalizationContext(
    `${conversationTemplate}\n\n${systemTemplate}`,
    persona,
    summary,
    momentumState,
    systemEventContext,
    sentimentResult,
    articleContext,
    providerVisitContext,
  )

  // Build the complete prompt array
  const prompt: ChatPrompt = [
    {
      role: 'system',
      content: `${safetyTemplate}\n\n${personalizedSystemPrompt}`,
    },
  ]

  // Add conversation history (skip system messages, keep user/assistant only)
  conversationHistory
    .filter((msg) => msg.role !== 'system')
    .forEach((msg) => {
      prompt.push({
        role: msg.role as 'user' | 'assistant',
        content: msg.content,
      })
    })

  // Add current user message
  prompt.push({
    role: 'user',
    content: userMessage,
  })

  return prompt
}

/**
 * Loads a prompt template from the filesystem
 */
async function loadTemplate(templatePath: string): Promise<string> {
  // For core templates, return embedded strings directly – ensures availability
  if (templatePath === SAFETY_TEMPLATE_PATH) return SAFETY_TEMPLATE_CONTENT
  if (templatePath === SYSTEM_TEMPLATE_PATH) return SYSTEM_TEMPLATE_CONTENT

  // For other templates (e.g., momentum-specific), attempt to read from file system
  try {
    const fileUrl = new URL(`./${templatePath}`, import.meta.url)
    const content = await Deno.readTextFile(fileUrl)
    return content.trim()
  } catch (_) {
    // Inline fallback templates (minimal) if file cannot be loaded
    const fallbackTemplates: Record<string, string> = {
      [SAFETY_TEMPLATE_PATH]:
        `You are an AI health coach. Follow HIPAA and privacy best practices. Never provide medical diagnosis. Encourage users to consult professionals for medical advice.`,
      [SYSTEM_TEMPLATE_PATH]:
        `You are a supportive digital coach.\n\nCurrent momentum state: {{momentum_state}}.\nPersona: {{persona}}.\nEngagement summary: {{engagement_summary}}.`,
    }

    if (fallbackTemplates[templatePath]) {
      console.warn(`📄 Template file not bundled (${templatePath}) – using inline fallback`)
      return fallbackTemplates[templatePath]
    }

    throw new Error(`Template not found: ${templatePath}`)
  }
}

/**
 * Loads a momentum-specific conversation template (YAML or plain text)
 */
async function loadMomentumConversationTemplate(momentumState: string): Promise<string> {
  // Convert momentumState to kebab-like slug: "NeedsCare" -> "needs_care", "Needs Care" -> "needs_care"
  const slug = momentumState
    .replace(/([a-z])([A-Z])/g, '$1_$2') // camelCase to snake
    .toLowerCase()
    .replace(/\s+/g, '_')
  const candidateFiles = [
    `${CONVERSATION_TEMPLATE_DIR}/${slug}.yaml`,
    `${CONVERSATION_TEMPLATE_DIR}/${slug}.yml`,
  ]

  for (const path of candidateFiles) {
    try {
      const fileUrl = new URL(`./${path}`, import.meta.url)
      const content = await Deno.readTextFile(fileUrl)
      return content.trim()
    } catch (_) {
      // continue
    }
  }

  // Fallback: empty string if no template found
  console.warn(
    `⚠️ Conversation template not found for momentum state "${momentumState}" – proceeding without specific template`,
  )
  return ''
}

/**
 * Injects personalization context into the system template
 * Replaces template variables with actual user data
 */
function injectPersonalizationContext(
  template: string,
  persona: CoachingPersona,
  summary: PatternSummary,
  momentumState: string,
  systemEventContext?: {
    isSystemEvent: boolean
    previousState?: string
    currentScore?: number
  },
  sentimentResult?: SentimentResult | null,
  articleContext?: {
    id?: string
    summary?: string
  },
  providerVisitContext?: {
    transcriptSummary?: string
    visitDate?: string
  },
): string {
  const engagementSummary = formatEngagementSummary(summary)

  // Add sentiment-based tone instructions
  let sentimentContext = ''
  let toneTag = ''
  if (sentimentResult) {
    const { score, label } = sentimentResult
    sentimentContext = `\n\nUser sentiment: ${label} (score: ${score.toFixed(2)})`

    // Add tone tags for strong sentiment
    if (score >= 0.6) {
      toneTag = '<tone celebratory>'
      sentimentContext +=
        '\nUser is expressing positive emotions - match their energy with an upbeat, celebratory tone.'
    } else if (score <= -0.6) {
      toneTag = '<tone supportive>'
      sentimentContext +=
        '\nUser is expressing negative emotions - respond with extra empathy and supportive tone.'
    }
  }

  // Add system event context if this is a momentum change event
  let momentumChangeContext = ''
  if (systemEventContext?.isSystemEvent && systemEventContext.previousState) {
    momentumChangeContext =
      `\n\nIMPORTANT: This is a proactive coaching intervention triggered by a momentum state change from ${systemEventContext.previousState} to ${momentumState}. Current score: ${
        systemEventContext.currentScore || 'unknown'
      }. Provide encouraging, personalized guidance that acknowledges this transition and offers actionable next steps.`
  }

  // Add tone tag instruction for strong sentiment
  let toneInstruction = ''
  if (toneTag) {
    toneInstruction =
      `\n\nIMPORTANT: When you respond, start your message with the tone tag "${toneTag}" followed by your response. This helps the UI provide appropriate visual feedback to match the emotional context.`
  }

  // Article context injection
  let articleBlock = ''
  if (articleContext?.summary) {
    articleBlock =
      `\n\nUser has just opened an article in the Today Feed. Article summary: "${articleContext.summary}".`
  }

  // Inject provider visit summary if available
  let providerVisitBlock = ''
  if (providerVisitContext?.transcriptSummary) {
    const visitInfo = providerVisitContext.visitDate
      ? `${providerVisitContext.visitDate}: ${providerVisitContext.transcriptSummary}`
      : providerVisitContext.transcriptSummary
    providerVisitBlock = `\n\nProvider visit summary: ${visitInfo}`
  } else {
    // Remove placeholder to avoid exposing raw string to the model
    providerVisitBlock = ''
  }

  return (
    template
      .replace('{{momentum_state}}', momentumState)
      .replace('{{persona}}', persona)
      .replace('{{engagement_summary}}', engagementSummary) +
    sentimentContext +
    momentumChangeContext +
    toneInstruction +
    articleBlock +
    providerVisitBlock
  )
}

/**
 * Formats the engagement pattern summary for inclusion in prompts
 */
function formatEngagementSummary(summary: PatternSummary): string {
  const { engagementPeaks, volatilityScore } = summary

  if (engagementPeaks.length === 0) {
    return `No clear engagement patterns detected. Volatility: ${
      (volatilityScore * 100).toFixed(0)
    }%`
  }

  const peaks = engagementPeaks.join(', ')
  const volatilityLevel = volatilityScore > 0.7
    ? 'High'
    : volatilityScore > 0.4
    ? 'Moderate'
    : 'Low'

  return `Active during: ${peaks}. Engagement volatility: ${volatilityLevel} (${
    (volatilityScore * 100).toFixed(0)
  }%)`
}
