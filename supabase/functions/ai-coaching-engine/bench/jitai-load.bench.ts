// deno run -A bench/jitai-load.bench.ts <BASE_URL>
// Simple load bench hitting /evaluate-jitai at ~100 RPS for 30 seconds.
// Logs p95 latency and error rate.

import { delay } from 'https://deno.land/std@0.168.0/async/delay.ts'

const BASE = Deno.args[0] ?? 'http://localhost:54321/functions/v1'
const ENDPOINT = `${BASE}/evaluate-jitai`
const DURATION_MS = 30_000
const RPS = 100
const CONCURRENCY = 20 // limit parallelism

interface Stat {
  ms: number
  ok: boolean
}
const stats: Stat[] = []

async function worker() {
  const body = JSON.stringify({ user_id: 'bench-user' })
  while (!stop) {
    const start = performance.now()
    try {
      const res = await fetch(ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Api-Version': '1' },
        body,
      })
      const ms = performance.now() - start
      stats.push({ ms, ok: res.ok })
    } catch (_) {
      stats.push({ ms: performance.now() - start, ok: false })
    }
    await delay(1000 / RPS)
  }
}

let stop = false

;(async () => {
  const workers = Array.from({ length: CONCURRENCY }, () => worker())
  await delay(DURATION_MS)
  stop = true
  await Promise.all(workers)

  // compute metrics
  const latencies = stats.map((s) => s.ms).sort((a, b) => a - b)
  const p95 = latencies[Math.floor(latencies.length * 0.95)] ?? 0
  const errors = stats.filter((s) => !s.ok).length
  const errorRate = (errors / stats.length) * 100

  console.log('Requests:', stats.length)
  console.log('Errors:', errors, `${errorRate.toFixed(2)}%`)
  console.log('p95 latency:', `${Math.round(p95)} ms`)
})()
