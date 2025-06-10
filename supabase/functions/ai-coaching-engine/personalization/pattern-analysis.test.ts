import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { analyzeEngagement, EngagementEvent } from './pattern-analysis.ts'

function createTestEvent(
  eventType: 'app_session' | 'goal_completion' | 'momentum_change',
  timestamp: string,
): EngagementEvent {
  return {
    event_type: eventType,
    timestamp,
    metadata: {},
  }
}

Deno.test('analyzeEngagement - returns default pattern for empty events', () => {
  const result = analyzeEngagement([])

  assertEquals(result.engagementPeaks, [])
  assertEquals(result.volatilityScore, 0)
  assertEquals(result.engagementFrequency, 'low')
})

Deno.test('analyzeEngagement - detects morning engagement peak', () => {
  const events = [
    createTestEvent('app_session', '2024-01-15T08:00:00Z'),
    createTestEvent('app_session', '2024-01-15T09:00:00Z'),
    createTestEvent('app_session', '2024-01-15T10:00:00Z'),
    createTestEvent('app_session', '2024-01-15T11:00:00Z'),
  ]

  const result = analyzeEngagement(events)

  assertEquals(result.engagementPeaks.includes('morning'), true)
  assertEquals(result.engagementFrequency, 'medium')
})

Deno.test('analyzeEngagement - calculates high engagement frequency', () => {
  const events = Array.from(
    { length: 10 },
    (_, i) =>
      createTestEvent('app_session', `2024-01-15T${(8 + i).toString().padStart(2, '0')}:00:00Z`),
  )

  const result = analyzeEngagement(events)

  assertEquals(result.engagementFrequency, 'high')
})
