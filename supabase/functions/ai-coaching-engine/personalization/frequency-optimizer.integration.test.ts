import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { FrequencyOptimizer } from './frequency-optimizer.ts'

// Lightweight mock of the Supabase client chain used inside optimizeInterventionTiming
function createMockSupabase(conversations: any[]) {
  return {
    from: (_table: string) => ({
      select: (_cols: string) => ({
        eq: (_field: string, _value: any) => ({
          eq: (_field2: string, _value2: any) => ({
            gte: (_field3: string, _value3: any) => ({
              order: (_col: string, _opts: { ascending: boolean }) => ({
                data: conversations,
                error: null,
              }),
              // When `.order(...)` is not chained in code path (older Deno versions)
              data: conversations,
              error: null,
            }),
          }),
        }),
      }),
    }),
  }
}

// deno-lint-ignore no-explicit-any
function getPrivate(obj: any, key: string): any {
  // @ts-ignore – accessing private member for test purposes only
  return obj[key]
}

Deno.test('FrequencyOptimizer.ensureReasonableSpacing enforces ≥3-hour gaps', () => {
  // Create instance without running constructor to avoid Supabase timers
  const optimizer: any = Object.create(FrequencyOptimizer.prototype)
  const ensureSpacing = getPrivate(optimizer, 'ensureReasonableSpacing') as (
    h: number[],
  ) => number[]

  const input = [5, 6, 8, 12, 15]
  const result = ensureSpacing(input)

  // Should keep 5, 8, 12, 15 because 6 is too close to 5 but 8 is exactly 3 hours apart
  assertEquals(result, [5, 8, 12, 15])
  // Verify gaps are ≥3 hours
  for (let i = 1; i < result.length; i++) {
    assertEquals(result[i] - result[i - 1] >= 3, true)
  }
})

Deno.test('FrequencyOptimizer.optimizeInterventionTiming falls back to defaults with insufficient data', async () => {
  const conversations: any[] = [] // Not enough data (<5)
  // Create instance without running constructor to avoid Supabase timers
  const optimizer: any = Object.create(FrequencyOptimizer.prototype)
  optimizer.supabase = createMockSupabase(conversations)

  // Access the private method
  const optimizeTiming = getPrivate(
    optimizer,
    'optimizeInterventionTiming',
  ) as (u: string, d: number) => Promise<number[]>

  const hours = await optimizeTiming('user-1', 14)
  assertEquals(hours, [9, 14, 19])
})
