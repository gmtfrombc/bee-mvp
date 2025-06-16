const base = Deno.env.get('WEARABLE_SUMMARY_BASE_URL') || '/wearable-summary-api'

export async function getDailySleepScore(userId: string, date?: string): Promise<number | null> {
  const d = date ?? new Date().toISOString().split('T')[0]
  try {
    const url = `${base}/daily-sleep-score?user_id=${encodeURIComponent(userId)}&date=${d}`
    const res = await fetch(url)
    if (!res.ok) throw new Error('status ' + res.status)
    const json = await res.json()
    return typeof json.score === 'number' ? json.score : null
  } catch (err) {
    console.warn('[summary] sleep score failed', err)
    return null
  }
}

export async function getRollingAvgHR(userId: string, minutes = 60): Promise<number | null> {
  try {
    const url = `${base}/rolling-hr?user_id=${encodeURIComponent(userId)}&minutes=${minutes}`
    const res = await fetch(url)
    if (!res.ok) throw new Error('status ' + res.status)
    const json = await res.json()
    return typeof json.avg_hr === 'number' ? json.avg_hr : null
  } catch (err) {
    console.warn('[summary] avg HR failed', err)
    return null
  }
}
