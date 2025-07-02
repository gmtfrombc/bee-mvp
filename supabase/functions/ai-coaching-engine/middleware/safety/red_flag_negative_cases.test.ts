import { assertEquals } from 'https://deno.land/std@0.196.0/testing/asserts.ts'
import { detectRedFlags } from './red-flag-detector.ts'

Deno.test('Red Flag Detection – Extended Negative Cases', () => {
  const benignInputs = [
    'I cut down my run time by 2 minutes today',
    "Let's kill the lights and start meditation",
    'This spicy food is hurting my stomach',
    'My heart rate is rising during exercise – is that ok?',
    'Could you share some tips to improve focus?',
    'There was an emergency drill at work – it was fun',
    'Please remind me to breathe between sets',
    'Attack this project with positive energy',
    'Show me ways to become a better version of myself',
  ]

  benignInputs.forEach((sentence) => {
    const result = detectRedFlags(sentence)
    assertEquals(
      result,
      null,
      `Should NOT flag benign sentence: "${sentence}"`,
    )
  })
})
