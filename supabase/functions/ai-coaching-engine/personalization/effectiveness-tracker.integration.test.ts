// deno-lint-ignore-file no-explicit-any

import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { EffectivenessTracker } from './effectiveness-tracker.ts'

// Mock chain generator for EffectivenessTracker queries
function createMockSupabase(effectivenessRows: any[]) {
  return {
    from: (_table: string) => ({
      select: (_cols: string) => ({
        eq: (_field: string, _value: any) => ({
          gte: (_field2: string, _value2: any) => ({
            order: (_col: string, _opts: { ascending: boolean }) => ({
              data: effectivenessRows,
              error: null,
            }),
            data: effectivenessRows,
            error: null,
          }),
        }),
      }),
    }),
  }
}

Deno.test('EffectivenessTracker.analyzeUserEffectiveness returns defaults for new users', async () => {
  const tracker: any = Object.create(EffectivenessTracker.prototype)
  tracker.supabase = createMockSupabase([])

  const result = await tracker.analyzeUserEffectiveness('user-1')

  assertEquals(result.overallEffectiveness, 0.5)
  assertEquals(result.recommendedPersona, 'supportive')
  assertEquals(result.responseRate, 0)
})

Deno.test('EffectivenessTracker.analyzeUserEffectiveness ranks persona with highest score', async () => {
  const now = new Date().toISOString()
  const effectivenessRows = [
    {
      created_at: now,
      user_rating: 5,
      feedback_type: 'helpful',
      persona_used: 'challenging',
    },
    {
      created_at: now,
      user_rating: 4,
      feedback_type: 'helpful',
      persona_used: 'challenging',
    },
    {
      created_at: now,
      user_rating: 3,
      feedback_type: 'not_helpful',
      persona_used: 'supportive',
    },
  ]

  const tracker: any = Object.create(EffectivenessTracker.prototype)
  tracker.supabase = createMockSupabase(effectivenessRows)

  const result = await tracker.analyzeUserEffectiveness('user-1')

  assertEquals(result.recommendedPersona, 'challenging')
  // Challenging should have higher effectiveness than supportive
  assertEquals(
    result.personaEffectiveness['challenging'] > result.personaEffectiveness['supportive'],
    true,
  )
})
