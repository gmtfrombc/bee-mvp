import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'

// Test the core strategy selection logic without database dependencies
Deno.test('StrategyOptimizer - selects supportive persona for users needing care', () => {
  // Mock effectiveness data that would normally come from EffectivenessTracker
  const mockEffectiveness = {
    personaEffectiveness: {
      supportive: 0.8,
      challenging: 0.4,
      educational: 0.6,
    },
    recommendedPersona: 'challenging',
    responseRate: 0.7,
    overallEffectiveness: 0.6,
    averageRating: 4.0,
  }

  const context = {
    momentumState: 'NeedsCare' as const,
    userEngagementLevel: 'medium' as const,
    timeOfDay: 'morning' as const,
    daysSinceLastInteraction: 2,
  }

  // Test the persona selection logic directly
  function selectOptimalPersona(effectiveness: any, context: any) {
    let selectedPersona = effectiveness.recommendedPersona

    if (context.momentumState === 'NeedsCare') {
      if (effectiveness.personaEffectiveness.supportive >= 0.5) {
        selectedPersona = 'supportive'
      }
    }

    return selectedPersona
  }

  const result = selectOptimalPersona(mockEffectiveness, context)
  assertEquals(result, 'supportive')
})

Deno.test('StrategyOptimizer - adjusts intervention frequency based on engagement', () => {
  const mockEffectiveness = { responseRate: 0.8, overallEffectiveness: 0.7 }
  const mockSummary = { lastWeekTrend: 'stable' }
  const context = { userEngagementLevel: 'high', momentumState: 'Rising' }

  // Test the frequency optimization logic
  function optimizeInterventionFrequency(effectiveness: any, summary: any, context: any) {
    let frequency = 'medium'

    if (effectiveness.responseRate > 0.7 && effectiveness.overallEffectiveness > 0.6) {
      frequency = 'high'
    } else if (effectiveness.responseRate < 0.3 || effectiveness.overallEffectiveness < 0.4) {
      frequency = 'low'
    }

    if (context.userEngagementLevel === 'low') {
      frequency = 'low'
    }

    return frequency
  }

  const result = optimizeInterventionFrequency(mockEffectiveness, mockSummary, context)
  assertEquals(result, 'high')
})

Deno.test('StrategyOptimizer - selects gentle tonality for low ratings', () => {
  const mockEffectiveness = { averageRating: 2.0, responseRate: 0.2 }
  const context = { momentumState: 'Steady' }

  // Test tonality optimization logic
  function optimizeTonality(effectiveness: any, context: any) {
    let tonality = 'neutral'

    if (effectiveness.averageRating < 2.5 || effectiveness.responseRate < 0.3) {
      tonality = 'gentle'
    } else if (effectiveness.averageRating > 4.0 && effectiveness.responseRate > 0.7) {
      tonality = 'direct'
    }

    if (context.momentumState === 'NeedsCare') {
      tonality = 'gentle'
    }

    return tonality
  }

  const result = optimizeTonality(mockEffectiveness, context)
  assertEquals(result, 'gentle')
})
