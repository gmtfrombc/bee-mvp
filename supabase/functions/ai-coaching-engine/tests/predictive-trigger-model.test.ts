import { predictTriggers } from '../services/predictive-trigger-model.ts'
import { WearableData } from '../types.ts'

Deno.test('predictTriggers falls back to rules when no model URL', async () => {
  Deno.env.set('PREDICTIVE_MODEL_URL', '') // ensure not set
  const data: WearableData = {
    timestamp: Date.now(),
    heart_rate: 130,
    steps: 300,
    sleep_hours: 5,
  }
  const triggers = await predictTriggers('user-1', data)
  if (triggers.length === 0) {
    throw new Error('Expected rule-based triggers when model unavailable')
  }
})
