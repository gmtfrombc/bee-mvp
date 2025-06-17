import { WearableData } from '../types.ts'

/**
 * Hashes a patient_id UUID/string into a deterministic float 0-1 using a simple rolling hash.
 * This is a placeholder for a proper learnt embedding / mixed-effects grouping.
 */
export function patientHash(patientId: string): number {
  let hash = 0
  for (let i = 0; i < patientId.length; i++) {
    // simple char code accumulation
    hash = (hash * 31 + patientId.charCodeAt(i)) >>> 0
  }
  // map to [0,1)
  return (hash % 1000) / 1000
}

/**
 * Builds feature vector [steps, avg_hr, sleep_hours, patient_code]
 */
export function buildFeatureVector(
  patientId: string,
  wearable: WearableData,
): number[] {
  const patientCode = patientHash(patientId)
  return [
    wearable.steps,
    wearable.heart_rate,
    wearable.sleep_hours,
    patientCode,
  ]
}
