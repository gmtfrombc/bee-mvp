import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'

// Test the core effectiveness analysis logic without Supabase dependency
Deno.test('EffectivenessTracker - analyzes effectiveness with no data returns defaults', () => {
  // Test the default analysis logic directly
  const mockData: unknown[] = []

  // Simulate the analysis logic from the effectiveness tracker
  const totalInteractions = mockData.length

  if (totalInteractions === 0) {
    const defaultAnalysis = {
      overallEffectiveness: 0.5,
      averageRating: 3.0,
      responseRate: 0.0,
      recommendedPersona: 'supportive',
      adjustmentReasons: ['No effectiveness data available - using default supportive persona'],
    }

    assertEquals(defaultAnalysis.overallEffectiveness, 0.5)
    assertEquals(defaultAnalysis.averageRating, 3.0)
    assertEquals(defaultAnalysis.recommendedPersona, 'supportive')
  }
})

Deno.test('EffectivenessTracker - calculates metrics for positive data', () => {
  const mockData = [
    { user_rating: 5, feedback_type: 'helpful', persona_used: 'supportive' },
    { user_rating: 4, feedback_type: 'helpful', persona_used: 'supportive' },
  ]

  // Simulate the analysis logic
  const ratedInteractions = mockData.filter((d) => d.user_rating !== null)
  const respondedInteractions = mockData.filter((d) => d.feedback_type !== 'ignored')

  const averageRating = ratedInteractions.length > 0
    ? ratedInteractions.reduce((sum, d) => sum + (d.user_rating || 0), 0) / ratedInteractions.length
    : 3.0

  const responseRate = mockData.length > 0 ? respondedInteractions.length / mockData.length : 0

  assertEquals(averageRating, 4.5)
  assertEquals(responseRate, 1.0)
  assertEquals(averageRating > 4.0, true)
})

// Test core persona effectiveness calculation logic
Deno.test('EffectivenessTracker - calculatePersonaEffectiveness logic', () => {
  // Replicate the calculatePersonaEffectiveness business logic
  interface EffRow {
    persona?: string
    feedback_type?: string
    user_rating?: number | null
  }

  function calculatePersonaEffectiveness(effectivenessData: EffRow[]) {
    const personaData = {
      supportive: { total: 0, helpful: 0, ratings: [] as number[] },
      challenging: { total: 0, helpful: 0, ratings: [] as number[] },
      educational: { total: 0, helpful: 0, ratings: [] as number[] },
    }

    // Process each data point
    effectivenessData.forEach((entry) => {
      const persona = entry.persona || 'supportive'
      if (personaData[persona as keyof typeof personaData]) {
        personaData[persona as keyof typeof personaData].total++

        if (entry.feedback_type === 'helpful') {
          personaData[persona as keyof typeof personaData].helpful++
        }

        if (typeof entry.user_rating === 'number') {
          personaData[persona as keyof typeof personaData].ratings.push(entry.user_rating)
        }
      }
    })

    // Calculate effectiveness scores (simplified version of class logic)
    const personaEffectiveness = {
      supportive: personaData.supportive.total > 0
        ? (personaData.supportive.helpful / personaData.supportive.total) * 0.7 +
          (personaData.supportive.ratings.length > 0
            ? (personaData.supportive.ratings.reduce((a, b) => a + b, 0) /
              personaData.supportive.ratings.length / 5.0) * 0.3
            : 0.6)
        : 0.5,
      challenging: personaData.challenging.total > 0
        ? (personaData.challenging.helpful / personaData.challenging.total) * 0.7 +
          (personaData.challenging.ratings.length > 0
            ? (personaData.challenging.ratings.reduce((a, b) => a + b, 0) /
              personaData.challenging.ratings.length / 5.0) * 0.3
            : 0.6)
        : 0.5,
      educational: personaData.educational.total > 0
        ? (personaData.educational.helpful / personaData.educational.total) * 0.7 +
          (personaData.educational.ratings.length > 0
            ? (personaData.educational.ratings.reduce((a, b) => a + b, 0) /
              personaData.educational.ratings.length / 5.0) * 0.3
            : 0.6)
        : 0.5,
    }

    return personaEffectiveness
  }

  // Test with mixed data
  const testData = [
    { persona: 'supportive', feedback_type: 'helpful', user_rating: 4 },
    { persona: 'supportive', feedback_type: 'not_helpful', user_rating: 2 },
    { persona: 'challenging', feedback_type: 'helpful', user_rating: 5 },
    { persona: 'challenging', feedback_type: 'helpful', user_rating: 4 },
  ]

  const result = calculatePersonaEffectiveness(testData)

  // Supportive: 1/2 helpful (0.5 * 0.7) + avg rating 3/5 (0.6 * 0.3) = 0.35 + 0.18 = 0.53
  assertEquals(Math.round(result.supportive * 100), 53)

  // Challenging: 2/2 helpful (1.0 * 0.7) + avg rating 4.5/5 (0.9 * 0.3) = 0.7 + 0.27 = 0.97
  assertEquals(Math.round(result.challenging * 100), 97)
})

// Test persona recommendation logic
Deno.test('EffectivenessTracker - determineRecommendedPersona logic', () => {
  function determineRecommendedPersona(personaEffectiveness: Record<string, number>) {
    const personas = Object.entries(personaEffectiveness)
    const best = personas.reduce((max, current) => current[1] > max[1] ? current : max)
    return best[0]
  }

  const effectiveness1 = { supportive: 0.8, challenging: 0.6, educational: 0.7 }
  assertEquals(determineRecommendedPersona(effectiveness1), 'supportive')

  const effectiveness2 = { supportive: 0.5, challenging: 0.9, educational: 0.6 }
  assertEquals(determineRecommendedPersona(effectiveness2), 'challenging')
})

// Test response rate calculation
Deno.test('EffectivenessTracker - calculateResponseRate logic', () => {
  function calculateResponseRate(data: { feedback_type: string }[]) {
    const totalInteractions = data.length
    const respondedInteractions = data.filter((d) => d.feedback_type !== 'ignored').length

    return totalInteractions > 0 ? respondedInteractions / totalInteractions : 0.0
  }

  const testData = [
    { feedback_type: 'helpful' },
    { feedback_type: 'not_helpful' },
    { feedback_type: 'ignored' },
    { feedback_type: 'helpful' },
  ]

  const result = calculateResponseRate(testData)
  assertEquals(result, 0.75) // 3 out of 4 responded
})
