import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { ContentSafetyValidator } from './content-safety-validator.ts'

Deno.test('ContentSafetyValidator - validates safe content', () => {
  const result = ContentSafetyValidator.validateContent(
    'Daily Mindfulness Practice',
    'Research shows that mindful breathing can help reduce stress. Consider consulting your doctor about mindfulness techniques.',
    'stress',
  )

  assertEquals(result.is_safe, true)
  assertEquals(result.requires_review, false)
  assertEquals(result.flagged_issues.length, 0)
})

Deno.test('ContentSafetyValidator - flags medical red flags', () => {
  const result = ContentSafetyValidator.validateContent(
    'Medical Diagnosis',
    'This app can diagnose your condition and cure your disease.',
    'general',
  )

  assertEquals(result.is_safe, false)
  assertEquals(result.requires_review, true)
  assertEquals(result.flagged_issues.length > 0, true)
})

Deno.test('ContentSafetyValidator - flags dangerous nutrition advice', () => {
  const result = ContentSafetyValidator.validateContent(
    'Supplement Advice',
    'Take this supplement for urgent medical conditions.',
    'nutrition',
  )

  assertEquals(result.is_safe, false)
  assertEquals(result.requires_review, true)
})
