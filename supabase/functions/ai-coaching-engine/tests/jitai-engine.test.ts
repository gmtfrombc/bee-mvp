import { evaluateJITAITriggers } from '../services/jitai-engine.ts'
import { WearableData } from '../types.ts'

Deno.test('evaluateJITAITriggers returns trigger for high stress', () => {
  const sample: WearableData = {
    timestamp: Date.now(),
    heart_rate: 70,
    steps: 500,
    sleep_hours: 7,
    stress_level: 0.9,
  }
  const triggers = evaluateJITAITriggers('user-test', sample)
  if (triggers.length === 0) {
    throw new Error('Expected at least one trigger for high stress scenario')
  }
})
