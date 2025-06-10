/**
 * Tests for Cross-Patient Patterns Service
 * Epic 1.3.2.8: Cross-Patient Pattern Integration Preparation
 *
 * Testing Policy: ≥85% coverage on core logic
 * Focus: Happy-path and critical edge-cases only
 */

import {
  assertEquals,
  assertExists,
  assertRejects,
} from 'https://deno.land/std@0.208.0/assert/mod.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { type CrossPatientPattern, CrossPatientPatternsService } from './cross-patient-patterns.ts'

// Mock Supabase client for testing
class MockSupabaseClient {
  private mockData: any = {}
  private shouldError = false

  setMockData(table: string, data: any) {
    this.mockData[table] = data
  }

  setShouldError(error: boolean) {
    this.shouldError = error
  }

  from(table: string) {
    return {
      select: (columns?: string) => ({
        gte: (column: string, value: any) => ({
          lt: (column: string, value: any) => ({
            eq: (column: string, value: any) => this.mockQuery(table),
            order: (column: string, options?: any) => this.mockQuery(table),
          }),
          eq: (column: string, value: any) => this.mockQuery(table),
          order: (column: string, options?: any) => this.mockQuery(table),
        }),
        eq: (column: string, value: any) => this.mockQuery(table),
        order: (column: string, options?: any) => this.mockQuery(table),
      }),
      insert: (data: any) => ({
        select: (columns?: string) => ({
          single: () => this.mockInsert(table, data),
        }),
      }),
      upsert: (data: any, options?: any) => ({
        select: (columns?: string) => ({
          single: () => this.mockInsert(table, data),
        }),
      }),
    }
  }

  private mockQuery(table: string) {
    if (this.shouldError) {
      return { data: null, error: new Error('Mock database error') }
    }
    return { data: this.mockData[table] || [], error: null }
  }

  private mockInsert(table: string, data: any) {
    if (this.shouldError) {
      return { data: null, error: new Error('Mock insert error') }
    }
    return { data: { id: 'test-id-123', ...data }, error: null }
  }
}

Deno.test('CrossPatientPatternsService - Happy Path: Aggregate effectiveness patterns with sufficient data', async () => {
  const mockClient = new MockSupabaseClient()
  const service = new CrossPatientPatternsService(mockClient as any)

  // Mock sufficient effectiveness data (minimum 5 records for privacy)
  mockClient.setMockData('coaching_effectiveness', [
    {
      persona_used: 'supportive',
      feedback_type: 'helpful',
      user_rating: 5,
      momentum_state: 'Rising',
      intervention_trigger: 'morning_check_in',
    },
    {
      persona_used: 'supportive',
      feedback_type: 'helpful',
      user_rating: 4,
      momentum_state: 'Rising',
      intervention_trigger: 'evening_reflection',
    },
    {
      persona_used: 'challenging',
      feedback_type: 'not_helpful',
      user_rating: 2,
      momentum_state: 'Rising',
      intervention_trigger: 'goal_reminder',
    },
    {
      persona_used: 'educational',
      feedback_type: 'helpful',
      user_rating: 4,
      momentum_state: 'Rising',
      intervention_trigger: 'morning_check_in',
    },
    {
      persona_used: 'supportive',
      feedback_type: 'helpful',
      user_rating: 5,
      momentum_state: 'Rising',
      intervention_trigger: 'motivational_boost',
    },
  ])

  const weekStart = new Date('2025-01-06')
  const result = await service.aggregateEffectivenessPatterns(weekStart, 'Rising')

  assertExists(result, 'Should return pattern result with sufficient data')
  assertEquals(result.patternType, 'persona_effectiveness')
  assertEquals(result.momentumState, 'Rising')
  assertEquals(result.cohortSize, 5)

  // Verify effectiveness calculations
  assertEquals(result.aggregatedData.effectivenessScores['supportive'], 3 / 3) // 3 helpful out of 3 total
  assertEquals(result.aggregatedData.effectivenessScores['challenging'], 0 / 1) // 0 helpful out of 1 total

  // Verify common patterns identified
  assertExists(result.aggregatedData.commonPatterns)
  assertEquals(result.aggregatedData.commonPatterns.includes('morning_check_in'), true)
})

Deno.test('CrossPatientPatternsService - Privacy Edge Case: Insufficient data returns null', async () => {
  const mockClient = new MockSupabaseClient()
  const service = new CrossPatientPatternsService(mockClient as any)

  // Mock insufficient data (less than 5 records for privacy)
  mockClient.setMockData('coaching_effectiveness', [
    { persona_used: 'supportive', feedback_type: 'helpful', user_rating: 5 },
    { persona_used: 'challenging', feedback_type: 'not_helpful', user_rating: 2 },
  ])

  const weekStart = new Date('2025-01-06')
  const result = await service.aggregateEffectivenessPatterns(weekStart, 'Rising')

  assertEquals(
    result,
    null,
    'Should return null when insufficient data for privacy-safe aggregation',
  )
})

Deno.test('CrossPatientPatternsService - Error Handling: Database error returns null', async () => {
  const mockClient = new MockSupabaseClient()
  const service = new CrossPatientPatternsService(mockClient as any)

  // Force database error
  mockClient.setShouldError(true)

  const weekStart = new Date('2025-01-06')
  const result = await service.aggregateEffectivenessPatterns(weekStart, 'Rising')

  assertEquals(result, null, 'Should return null on database error')
})

Deno.test('CrossPatientPatternsService - Engagement Patterns: Returns null when engagement_events table missing', async () => {
  const mockClient = new MockSupabaseClient()
  const service = new CrossPatientPatternsService(mockClient as any)

  // Mock empty/missing engagement_events table (realistic since we don't have this table yet)
  mockClient.setMockData('engagement_events', [])

  const weekStart = new Date('2025-01-06')
  const result = await service.aggregateEngagementPatterns(weekStart)

  assertEquals(result, null, 'Should return null when insufficient engagement data')
})

Deno.test('CrossPatientPatternsService - Store Pattern Aggregate: Happy path', async () => {
  const mockClient = new MockSupabaseClient()
  const service = new CrossPatientPatternsService(mockClient as any)

  const testPattern: CrossPatientPattern = {
    patternType: 'persona_effectiveness',
    aggregatedData: {
      commonPatterns: ['morning_check_in', 'goal_reminder'],
      effectivenessScores: { supportive: 0.8, challenging: 0.6 },
      recommendedApproaches: ['Use supportive persona for optimal effectiveness'],
    },
    cohortSize: 10,
    confidenceLevel: 0.7,
    weeklyTimestamp: '2025-01-06',
    momentumState: 'Rising',
  }

  const result = await service.storePatternAggregate(testPattern)

  assertEquals(result, 'test-id-123', 'Should return the inserted pattern ID')
})

Deno.test('CrossPatientPatternsService - Weekly Aggregation: Full process with mixed results', async () => {
  const mockClient = new MockSupabaseClient()
  const service = new CrossPatientPatternsService(mockClient as any)

  // Mock sufficient data for some momentum states but not others
  mockClient.setMockData('coaching_effectiveness', [
    {
      persona_used: 'supportive',
      feedback_type: 'helpful',
      user_rating: 5,
      momentum_state: 'Rising',
    },
    {
      persona_used: 'challenging',
      feedback_type: 'helpful',
      user_rating: 4,
      momentum_state: 'Rising',
    },
    {
      persona_used: 'educational',
      feedback_type: 'helpful',
      user_rating: 4,
      momentum_state: 'Rising',
    },
    {
      persona_used: 'supportive',
      feedback_type: 'helpful',
      user_rating: 5,
      momentum_state: 'Rising',
    },
    {
      persona_used: 'supportive',
      feedback_type: 'helpful',
      user_rating: 5,
      momentum_state: 'Rising',
    },
  ])

  mockClient.setMockData('engagement_events', [
    { event_type: 'app_session', created_at: '2025-01-06T09:00:00Z', user_id: 'user1' },
    { event_type: 'goal_completion', created_at: '2025-01-06T14:00:00Z', user_id: 'user2' },
    { event_type: 'app_session', created_at: '2025-01-06T19:00:00Z', user_id: 'user3' },
    { event_type: 'momentum_check', created_at: '2025-01-06T09:30:00Z', user_id: 'user4' },
    { event_type: 'app_session', created_at: '2025-01-06T14:30:00Z', user_id: 'user5' },
  ])

  mockClient.setMockData('coaching_pattern_aggregates', [
    {
      id: 'pattern1',
      pattern_type: 'persona_effectiveness',
      pattern_data: { effectivenessScores: { supportive: 0.8 } },
      confidence_level: 0.7,
      user_count: 10,
    },
  ])

  const weekStart = new Date('2025-01-06')
  const result = await service.processWeeklyAggregation(weekStart)

  assertEquals(result.success, true, 'Weekly aggregation should succeed')
  assertEquals(result.patternsCreated >= 1, true, 'Should create at least one pattern')
  assertEquals(result.insightsGenerated >= 0, true, 'Should generate insights or handle gracefully')
})

Deno.test('CrossPatientPatternsService - Generate Insights: Empty patterns returns empty array', async () => {
  const mockClient = new MockSupabaseClient()
  const service = new CrossPatientPatternsService(mockClient as any)

  // Mock empty pattern data
  mockClient.setMockData('coaching_pattern_aggregates', [])

  const weekStart = new Date('2025-01-06')
  const result = await service.generateInsights(weekStart)

  assertEquals(result.length, 0, 'Should return empty array when no patterns available')
})
