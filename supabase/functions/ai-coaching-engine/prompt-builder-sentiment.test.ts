import { assertEquals, assertStringIncludes } from 'https://deno.land/std@0.208.0/assert/mod.ts'
import { buildPrompt } from './prompt-builder.ts'
import type { SentimentResult } from './sentiment/sentiment-analyzer.ts'

// Mock template files for testing
const mockSafetyTemplate = 'Safety guidelines for AI coaching'
const mockSystemTemplate =
  'Coach persona: {{persona}}\nMomentum: {{momentum_state}}\nEngagement: {{engagement_summary}}'

// Mock Deno.readTextFile
const originalReadTextFile = Deno.readTextFile
globalThis.Deno.readTextFile = (path: string | URL): Promise<string> => {
  const pathStr = typeof path === 'string' ? path : path.toString()
  if (pathStr.includes('safety.md')) {
    return Promise.resolve(mockSafetyTemplate)
  }
  if (pathStr.includes('system.md')) {
    return Promise.resolve(mockSystemTemplate)
  }
  return Promise.reject(new Error(`Unexpected file path: ${pathStr}`))
}

Deno.test('Prompt Builder - Positive sentiment integration', async () => {
  const sentimentResult: SentimentResult = {
    score: 0.8,
    label: 'positive',
  }

  const prompt = await buildPrompt(
    'I am so excited about my progress!',
    'challenging',
    { engagementPeaks: ['morning'], volatilityScore: 0.3, engagementFrequency: 'medium' },
    'Rising',
    [],
    undefined,
    sentimentResult,
  )

  const systemMessage = prompt[0].content
  assertStringIncludes(systemMessage, 'User sentiment: positive (score: 0.80)')
  assertStringIncludes(systemMessage, '<tone celebratory>')
  assertStringIncludes(systemMessage, 'celebratory tone')
})

Deno.test('Prompt Builder - Negative sentiment integration', async () => {
  const sentimentResult: SentimentResult = {
    score: -0.7,
    label: 'negative',
  }

  const prompt = await buildPrompt(
    'I feel overwhelmed and frustrated',
    'supportive',
    { engagementPeaks: ['evening'], volatilityScore: 0.5, engagementFrequency: 'medium' },
    'NeedsCare',
    [],
    undefined,
    sentimentResult,
  )

  const systemMessage = prompt[0].content
  assertStringIncludes(systemMessage, 'User sentiment: negative (score: -0.70)')
  assertStringIncludes(systemMessage, '<tone supportive>')
  assertStringIncludes(systemMessage, 'supportive tone')
})

Deno.test('Prompt Builder - Neutral sentiment integration', async () => {
  const sentimentResult: SentimentResult = {
    score: 0.1,
    label: 'neutral',
  }

  const prompt = await buildPrompt(
    'I went for a walk today',
    'educational',
    { engagementPeaks: ['afternoon'], volatilityScore: 0.2, engagementFrequency: 'low' },
    'Steady',
    [],
    undefined,
    sentimentResult,
  )

  const systemMessage = prompt[0].content
  assertStringIncludes(systemMessage, 'User sentiment: neutral (score: 0.10)')
  // Should not include tone tags for neutral sentiment
  assertEquals(systemMessage.includes('<tone'), false)
})

Deno.test('Prompt Builder - No sentiment provided', async () => {
  const prompt = await buildPrompt(
    'Hello coach',
    'educational',
    { engagementPeaks: ['morning'], volatilityScore: 0.3, engagementFrequency: 'medium' },
    'Steady',
    [],
  )

  const systemMessage = prompt[0].content
  // Should not include sentiment context when not provided
  assertEquals(systemMessage.includes('User sentiment:'), false)
  assertEquals(systemMessage.includes('<tone'), false)
})

Deno.test('Prompt Builder - Borderline positive sentiment', async () => {
  const sentimentResult: SentimentResult = {
    score: 0.5, // Below 0.6 threshold
    label: 'positive',
  }

  const prompt = await buildPrompt(
    'Things are going okay',
    'educational',
    { engagementPeaks: ['morning'], volatilityScore: 0.3, engagementFrequency: 'medium' },
    'Steady',
    [],
    undefined,
    sentimentResult,
  )

  const systemMessage = prompt[0].content
  assertStringIncludes(systemMessage, 'User sentiment: positive (score: 0.50)')
  // Should not include celebratory tone for borderline scores
  assertEquals(systemMessage.includes('<tone celebratory>'), false)
})

Deno.test('Prompt Builder - Borderline negative sentiment', async () => {
  const sentimentResult: SentimentResult = {
    score: -0.5, // Above -0.6 threshold
    label: 'negative',
  }

  const prompt = await buildPrompt(
    'Not feeling great',
    'supportive',
    { engagementPeaks: ['evening'], volatilityScore: 0.4, engagementFrequency: 'medium' },
    'NeedsCare',
    [],
    undefined,
    sentimentResult,
  )

  const systemMessage = prompt[0].content
  assertStringIncludes(systemMessage, 'User sentiment: negative (score: -0.50)')
  // Should not include supportive tone for borderline scores
  assertEquals(systemMessage.includes('<tone supportive>'), false)
})

// Cleanup
Deno.test('Cleanup - Restore original readTextFile', () => {
  globalThis.Deno.readTextFile = originalReadTextFile
})
