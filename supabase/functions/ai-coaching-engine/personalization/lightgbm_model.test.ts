import { predictLightGBM, scoreFromSnapshot } from './lightgbm_model.ts'

Deno.test('predictLightGBM returns high probability for risky snapshot', () => {
  // Low steps, high HR, low sleep -> expect >0.6
  const prob = predictLightGBM([1500, 130, 5])
  if (prob <= 0.6) {
    throw new Error(`Expected high probability, got ${prob}`)
  }
})

Deno.test('scoreFromSnapshot handles nulls', () => {
  const prob = scoreFromSnapshot(null, null, null)
  if (typeof prob !== 'number' || isNaN(prob)) {
    throw new Error('Probability should be numeric even with null inputs')
  }
})

Deno.test('feature vector builder returns expected length', async () => {
  const { buildFeatureVector } = await import('./feature_vector.ts')
  const vec = buildFeatureVector('user-123', {
    timestamp: 0,
    heart_rate: 80,
    steps: 2000,
    sleep_hours: 7,
  })
  if (vec.length !== 4) throw new Error('Feature vector should have 4 elements')
})
