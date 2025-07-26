// deno-lint-ignore-file no-explicit-any
import { assertEquals } from 'https://deno.land/std@0.208.0/assert/mod.ts'
import { MomentumErrorHandler } from './error-handler.ts'
import * as mod from './index.ts'

// -----------------------------------------------------------------------------
// Environment
// -----------------------------------------------------------------------------
Deno.env.set('DENO_TESTING', 'true')
Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-key')
Deno.env.set('SUPABASE_URL', 'http://localhost:54321')

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------
const stubQueryBuilder = {
  select: () => Promise.resolve({ data: null, error: null }),
  insert: () => Promise.resolve({ data: null, error: null }),
  upsert: () => Promise.resolve({ data: null, error: null }),
  eq: () => stubQueryBuilder,
  gte: () => stubQueryBuilder,
  lt: () => stubQueryBuilder,
  order: () => stubQueryBuilder,
  single: () => Promise.resolve({ data: null, error: null }),
}

const stubClient = {
  from: () => stubQueryBuilder,
  rpc: () => Promise.resolve({ data: null, error: null }),
} as unknown as any

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------
Deno.test('MOMENTUM_CONFIG loads weights & daily cap from JSON', () => {
  const CONFIG = (mod as any).MOMENTUM_CONFIG
  assertEquals(CONFIG.MAX_DAILY_SCORE, 10)
  assertEquals(CONFIG.EVENT_WEIGHTS.chat_message, 2)
  assertEquals(CONFIG.EVENT_WEIGHTS.biometric_sync, 1)
})

Deno.test('calculateRawScore respects max_weight_per_day cap', () => {
  const Calculator = (mod as any).MomentumScoreCalculator
  const errorHandler = new MomentumErrorHandler(stubClient)
  const calc = new Calculator(stubClient, errorHandler)

  // Create 20 events of the same type (weight 3 each)
  const events = Array.from({ length: 20 }).map((_, idx) => ({
    id: `${idx}`,
    user_id: 'test-user',
    event_type: 'action_step_complete',
    event_date: '2025-01-01',
    event_timestamp: new Date().toISOString(),
    metadata: {},
    points_awarded: 0,
  }))

  const raw = (calc as any).calculateRawScore(events)
  assertEquals(raw, 10)
})
