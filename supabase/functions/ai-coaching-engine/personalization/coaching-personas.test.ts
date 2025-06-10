import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { derivePersona, getPersonaDescription, isValidMomentumState } from './coaching-personas.ts'

// Happy-path test for high volatility (supportive persona)
Deno.test('CoachingPersonas - high volatility gets supportive persona', () => {
  const mockSummary = {
    volatilityScore: 0.8,
    engagementPeaks: [],
    engagementFrequency: 'medium' as const,
  }

  const result = derivePersona(mockSummary, 'Rising')
  assertEquals(result, 'supportive')
})

// Critical edge-case: NeedsCare momentum always gets supportive
Deno.test('CoachingPersonas - NeedsCare momentum gets supportive persona', () => {
  const mockSummary = {
    volatilityScore: 0.2,
    engagementPeaks: [],
    engagementFrequency: 'low' as const,
  }

  const result = derivePersona(mockSummary, 'NeedsCare')
  assertEquals(result, 'supportive')
})

// Core business logic: Rising momentum with low volatility gets challenging
Deno.test('CoachingPersonas - Rising momentum with low volatility gets challenging', () => {
  const mockSummary = {
    volatilityScore: 0.3,
    engagementPeaks: [],
    engagementFrequency: 'high' as const,
  }

  const result = derivePersona(mockSummary, 'Rising')
  assertEquals(result, 'challenging')
})

// Test persona descriptions
Deno.test('CoachingPersonas - persona descriptions are returned', () => {
  const description = getPersonaDescription('supportive')
  assertEquals(description.includes('Encouraging'), true)
})

// Test momentum state validation
Deno.test('CoachingPersonas - validates momentum states correctly', () => {
  assertEquals(isValidMomentumState('Rising'), true)
  assertEquals(isValidMomentumState('invalid'), false)
})
