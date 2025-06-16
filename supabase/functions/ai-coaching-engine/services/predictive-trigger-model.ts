import { JITAITrigger, WearableData } from '../types.ts'
import { evaluateJITAITriggers } from './jitai-engine.ts'

/**
 * Placeholder predictive model wrapper.
 * If `PREDICTIVE_MODEL_URL` env var is provided, attempts remote inference.
 * Otherwise falls back to rule-based engine to keep behaviour unchanged.
 */
export async function predictTriggers(userId: string, data: WearableData): Promise<JITAITrigger[]> {
  const modelUrl = Deno.env.get('PREDICTIVE_MODEL_URL')

  if (!modelUrl) {
    // Fallback to current deterministic rules
    return evaluateJITAITriggers(userId, data)
  }

  try {
    const resp = await fetch(modelUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: userId, wearable: data }),
    })
    if (!resp.ok) throw new Error(`Model responded with ${resp.status}`)
    const json = await resp.json()
    if (Array.isArray(json.triggers)) return json.triggers as JITAITrigger[]
  } catch (err) {
    console.error('Predictive model fetch failed, falling back to rules:', err)
  }

  // Always guarantee we return triggers
  return evaluateJITAITriggers(userId, data)
}
