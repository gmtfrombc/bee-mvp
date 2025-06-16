import { JITAITrigger, WearableData } from '../types.ts'

/**
 * Very first-pass, rule-based JITAI evaluator.
 * More sophisticated probabilistic & ML strategies will be layered on later.
 */
export function evaluateJITAITriggers(_userId: string, data: WearableData): JITAITrigger[] {
  const triggers: JITAITrigger[] = []
  let counter = 0

  const push = (type: JITAITrigger['type'], message: string) => {
    triggers.push({ id: `${type}-${Date.now()}-${counter++}`, type, message })
  }

  // -----------------------------
  // SIMPLE RULES (place-holders)
  // -----------------------------

  // Encourage movement: high resting HR & low steps
  if (data.heart_rate > 120 && data.steps < 1000) {
    push(
      'encourage_activity',
      'Your heart rate is elevated and activity is low—consider a short walk.',
    )
  }

  // Stress relief breathing prompt
  if (data.stress_level !== undefined && data.stress_level > 0.8) {
    push('relaxation_breath', 'A brief 60-second breathing exercise can help lower stress.')
  }

  // Hydration reminder if minimal steps but high heart rate (proxy for heat)
  if (data.heart_rate > 100 && data.steps > 3000 && data.steps < 5000) {
    push('hydration_reminder', 'Remember to hydrate during sustained activity!')
  }

  // Sleep hygiene suggestion
  if (data.sleep_hours < 6) {
    push('sleep_hygiene', "Try winding down earlier tonight to boost tomorrow's energy.")
  }

  return triggers
}
