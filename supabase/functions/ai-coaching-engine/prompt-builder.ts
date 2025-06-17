import type { CoachingPersona } from './personalization/coaching-personas.ts'
import type { PatternSummary } from './personalization/pattern-analysis.ts'
import type { ConversationLog } from './response-logger.ts'
import type { SentimentResult } from './sentiment/sentiment-analyzer.ts'

// Directory holding momentum-specific conversation templates
const CONVERSATION_TEMPLATE_DIR = 'docs/ai_coach/prompt_templates'

export type ChatPrompt = { role: 'system' | 'user' | 'assistant'; content: string }[]

const SAFETY_TEMPLATE_PATH = 'docs/ai_coach/prompt_templates/safety.md'
const SYSTEM_TEMPLATE_PATH = 'docs/ai_coach/prompt_templates/system.md'

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
  // Attempt to read the template from multiple potential locations.
  const candidatePaths = [
    templatePath, // original relative path (when executed from project root)
    `../../${templatePath}`,
    `../../../${templatePath}`,
  ]

  for (const path of candidatePaths) {
    try {
      const content = await Deno.readTextFile(path)
      return content.trim()
    } catch (_) {
      // continue trying next path
    }
  }

  // Inline fallback templates (minimal) if file cannot be loaded
  const fallbackTemplates: Record<string, string> = {
    [SAFETY_TEMPLATE_PATH]:
      `You are an AI health coach. Follow HIPAA and privacy best practices. Never provide medical diagnosis. Encourage users to consult professionals for medical advice.`,
    [SYSTEM_TEMPLATE_PATH]:
      `You are a supportive digital coach.\n\nCurrent momentum state: {{momentum_state}}.\nPersona: {{persona}}.\nEngagement summary: {{engagement_summary}}.`,
  }

  console.error(`Failed to load template after checking paths: ${candidatePaths.join(', ')}`)

  if (fallbackTemplates[templatePath]) {
    console.log(`🧪 Using inline fallback for template: ${templatePath}`)
    return fallbackTemplates[templatePath]
  }

  throw new Error(`Template not found: ${templatePath}`)
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
      const content = await Deno.readTextFile(path)
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
