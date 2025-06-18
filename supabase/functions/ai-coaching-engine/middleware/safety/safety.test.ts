import { assertEquals } from 'https://deno.land/std@0.196.0/testing/asserts.ts'
import { detectRedFlags, RedFlag as _RedFlag } from './red-flag-detector.ts'

Deno.test('Red Flag Detection - Self Harm Positive Cases', () => {
  const selfHarmInputs = [
    'I want to kill myself',
    'thinking about hurting myself',
    'I have thoughts of suicide',
    'no longer want to live',
  ]

  selfHarmInputs.forEach((input) => {
    const result = detectRedFlags(input)
    assertEquals(result, 'self_harm', `Should detect self_harm in: "${input}"`)
  })
})

Deno.test('Red Flag Detection - Violence Positive Cases', () => {
  const violenceInputs = [
    'I want to hurt others',
    'planning to attack people',
    'thoughts of violence against someone',
    'going to kill someone',
  ]

  violenceInputs.forEach((input) => {
    const result = detectRedFlags(input)
    assertEquals(result, 'violence', `Should detect violence in: "${input}"`)
  })
})

Deno.test('Red Flag Detection - Emergency Positive Cases', () => {
  const emergencyInputs = [
    'call 911 this is urgent',
    'having chest pain',
    "can't breathe help",
    'medical emergency happening',
  ]

  emergencyInputs.forEach((input) => {
    const result = detectRedFlags(input)
    assertEquals(result, 'emergency', `Should detect emergency in: "${input}"`)
  })
})

Deno.test('Red Flag Detection - PHI Request Positive Cases', () => {
  const phiInputs = [
    'show me my social security number',
    'what is my social security',
    'give me my personal information',
    'access me my private data',
  ]

  phiInputs.forEach((input) => {
    const result = detectRedFlags(input)
    assertEquals(result, 'phi_request', `Should detect phi_request in: "${input}"`)
  })
})

Deno.test('Red Flag Detection - Clean Input Negative Cases', () => {
  const cleanInputs = [
    'I feel motivated today',
    'How can I improve my exercise routine?',
    "I'm struggling with my habits",
    'Can you help me set better goals?',
    'What are some healthy breakfast options?',
    'I had a good day at work',
    'My momentum is steady today',
    'I want to build better habits',
  ]

  cleanInputs.forEach((input) => {
    const result = detectRedFlags(input)
    assertEquals(result, null, `Should NOT detect red flag in clean input: "${input}"`)
  })
})

Deno.test('Red Flag Detection - Edge Cases', () => {
  // Empty and whitespace
  assertEquals(detectRedFlags(''), null)
  assertEquals(detectRedFlags('   '), null)

  // Case sensitivity
  assertEquals(detectRedFlags('I WANT TO KILL MYSELF'), 'self_harm')
  assertEquals(detectRedFlags('Medical Emergency'), 'emergency')
})

Deno.test('Red Flag Detection - False Positive Prevention', () => {
  const falsePositives = [
    'I killed it at the gym today',
    'This workout is going to hurt tomorrow',
    "I'm dying to try that new restaurant",
    'That movie was so bad I wanted to die',
    "I'm attacking this goal with determination",
  ]

  falsePositives.forEach((input) => {
    const result = detectRedFlags(input)
    assertEquals(result, null, `Should NOT flag common expression: "${input}"`)
  })
})

Deno.test('Red Flag Detection - Multiple Flags Priority', () => {
  // Should return the first flag detected
  const mixedInput = 'I want to hurt myself and others too'
  const result = detectRedFlags(mixedInput)
  // Should detect self_harm first since it appears first in the patterns array
  assertEquals(result, 'self_harm')
})
