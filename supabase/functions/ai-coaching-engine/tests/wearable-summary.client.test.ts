import { getDailySleepScore, getRollingAvgHR } from '../services/wearable-summary.client.ts'

Deno.test('summary client returns null when endpoint unreachable', async () => {
  const score = await getDailySleepScore('user-x')
  if (score !== null) throw new Error('expected null in offline env')
  const hr = await getRollingAvgHR('user-x')
  if (hr !== null) throw new Error('expected null in offline env')
})
