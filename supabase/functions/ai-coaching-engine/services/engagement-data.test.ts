// Stub timer functions to prevent leaks
;(globalThis as any).setInterval = () => 0
;(globalThis as any).setTimeout = () => 0
;(globalThis as any).clearInterval = () => {}
;(globalThis as any).clearTimeout = () => {}

import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { EngagementDataService } from './engagement-data.ts'

Deno.test('EngagementDataService - returns fallback in test environment', async () => {
  Deno.env.set('DENO_TESTING', 'true')

  const service = new EngagementDataService()
  const events = await service.getUserEngagementEvents('test-user')

  assertEquals(events.length, 1)
  assertEquals(events[0].event_type, 'app_session')
  assertEquals(events[0].metadata.source, 'fallback')

  Deno.env.delete('DENO_TESTING')
})

Deno.test('EngagementDataService - maps event types correctly', () => {
  const service = new EngagementDataService()

  assertEquals((service as any).mapEventType('app_open'), 'app_session')
  assertEquals((service as any).mapEventType('goal_complete'), 'goal_completion')
  assertEquals((service as any).mapEventType('momentum_change'), 'momentum_change')
  assertEquals((service as any).mapEventType('unknown_event'), 'app_session')
})

Deno.test('EngagementDataService - healthCheck returns false without client', async () => {
  const service = new EngagementDataService()
  ;(service as any).supabase = null

  const isHealthy = await service.healthCheck()
  assertEquals(isHealthy, false)
})

Deno.test('EngagementDataService - validates event types correctly', () => {
  const service = new EngagementDataService()

  assertEquals((service as any).isValidEventType('app_session'), true)
  assertEquals((service as any).isValidEventType('goal_completion'), true)
  assertEquals((service as any).isValidEventType('momentum_change'), true)
  assertEquals((service as any).isValidEventType('invalid_type'), false)
})
