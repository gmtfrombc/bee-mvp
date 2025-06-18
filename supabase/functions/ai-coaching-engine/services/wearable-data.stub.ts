import { WearableData } from '../types.ts'

/**
 * Temporary mock service that returns pseudo-random wearable data.
 * This unblocks JITAI rules engine development until Epic 2.2 provides
 * real-time physiological streaming.
 */
export function getLatestWearableData(userId: string): WearableData {
  let pseudoSeed = [...userId].reduce((acc, char) => acc + char.charCodeAt(0), 0)
  const rand = (min: number, max: number): number => {
    const x = Math.sin(pseudoSeed++) * 10000
    return Math.floor((x - Math.floor(x)) * (max - min + 1) + min)
  }

  const now = Date.now()
  return {
    timestamp: now,
    heart_rate: rand(55, 140),
    resting_heart_rate: rand(45, 70),
    steps: rand(0, 8000),
    sleep_hours: rand(4, 9),
    stress_level: parseFloat((Math.random()).toFixed(2)),
  }
}
