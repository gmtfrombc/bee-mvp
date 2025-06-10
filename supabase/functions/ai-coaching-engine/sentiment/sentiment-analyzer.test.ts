import { assertEquals, assertExists } from 'https://deno.land/std@0.208.0/assert/mod.ts'
import { analyzeSentiment } from './sentiment-analyzer.ts'

// Happy-path test for positive sentiment
Deno.test('Sentiment analysis - positive text', async () => {
  const result = await analyzeSentiment('I feel great and amazing today!')

  assertEquals(result.label, 'positive')
})

// Critical edge-case: negative sentiment detection
Deno.test('Sentiment analysis - negative text', async () => {
  const result = await analyzeSentiment('I hate this terrible situation')

  assertEquals(result.label, 'negative')
})

// Critical edge-case: neutral text
Deno.test('Sentiment analysis - neutral text', async () => {
  const result = await analyzeSentiment('The weather is normal today')

  assertEquals(result.label, 'neutral')
})

// Test negation handling (critical business logic)
Deno.test('Sentiment analysis - negation handling', async () => {
  const result = await analyzeSentiment('I am not happy')

  assertEquals(result.label, 'negative')
})

Deno.test('Sentiment Analyzer - Positive sentiment detection', async () => {
  const result = await analyzeSentiment('I am feeling amazing and so excited about my progress!')

  assertEquals(result.label, 'positive')
  assertEquals(result.score > 0.2, true)
  assertExists(result.score)
})

Deno.test('Sentiment Analyzer - Negative sentiment detection', async () => {
  const result = await analyzeSentiment('I feel terrible and overwhelmed. This is hopeless.')

  assertEquals(result.label, 'negative')
  assertEquals(result.score < -0.2, true)
  assertExists(result.score)
})

Deno.test('Sentiment Analyzer - Neutral sentiment detection', async () => {
  const result = await analyzeSentiment('I went to the store today and bought some groceries.')

  assertEquals(result.label, 'neutral')
  assertEquals(Math.abs(result.score) < 0.2, true)
  assertExists(result.score)
})

Deno.test('Sentiment Analyzer - Strong positive with intensifiers', async () => {
  const result = await analyzeSentiment('I am absolutely thrilled and extremely excited!')

  assertEquals(result.label, 'positive')
  assertEquals(result.score > 0.4, true)
})

Deno.test('Sentiment Analyzer - Strong negative with intensifiers', async () => {
  const result = await analyzeSentiment(
    'I am extremely frustrated and absolutely hate this situation!',
  )

  assertEquals(result.label, 'negative')
  assertEquals(result.score < -0.5, true)
})

Deno.test('Sentiment Analyzer - Punctuation impact', async () => {
  const positiveWithExclamation = await analyzeSentiment('Great work!!')
  const positiveWithoutExclamation = await analyzeSentiment('Great work')

  assertEquals(positiveWithExclamation.score > positiveWithoutExclamation.score, true)
})

Deno.test('Sentiment Analyzer - Score bounds', async () => {
  const extremePositive = await analyzeSentiment(
    'extremely amazing fantastic wonderful excellent thrilled happy excited!',
  )
  const extremeNegative = await analyzeSentiment(
    'terrible awful horrible hate frustrated angry sad depressed hopeless!',
  )

  assertEquals(extremePositive.score <= 1, true)
  assertEquals(extremePositive.score >= -1, true)
  assertEquals(extremeNegative.score <= 1, true)
  assertEquals(extremeNegative.score >= -1, true)
})

Deno.test('Sentiment Analyzer - Empty text handling', async () => {
  const result = await analyzeSentiment('')

  assertEquals(result.label, 'neutral')
  assertEquals(result.score, 0)
})

Deno.test('Sentiment Analyzer - Mixed sentiment', async () => {
  const result = await analyzeSentiment('I love the progress but hate how difficult it is')

  // Should be close to neutral due to mixed signals
  assertEquals(Math.abs(result.score) < 0.4, true)
})
