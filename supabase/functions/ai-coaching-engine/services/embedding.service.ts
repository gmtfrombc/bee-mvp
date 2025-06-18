import { getCachedResponse, setCachedResponse } from '../middleware/cache.ts'

const OPENAI_URL = 'https://api.openai.com/v1/embeddings'
const MODEL = 'text-embedding-3-small'

export async function getEmbedding(text: string): Promise<number[]> {
  // First check global in-memory cache, then KV for cross-invocation sharing
  const cacheKey = `${MODEL}:${text}`

  const g = globalThis as { __embedCache?: Map<string, number[]> }
  if (!g.__embedCache) g.__embedCache = new Map<string, number[]>()
  const memCache = g.__embedCache
  if (memCache.has(cacheKey)) return memCache.get(cacheKey)!

  const kvCached = await getCachedResponse(cacheKey)
  if (kvCached) {
    const parsed = JSON.parse(kvCached) as number[]
    memCache.set(cacheKey, parsed)
    return parsed
  }

  // Testing or missing key -> deterministic pseudo-vector
  const isTest = Deno.env.get('DENO_TESTING') === 'true'
  const apiKey = Deno.env.get('OPENAI_API_KEY')
  if (isTest || !apiKey) {
    const pseudo = pseudoEmbedding(text)
    memCache.set(cacheKey, pseudo)
    await setCachedResponse(cacheKey, JSON.stringify(pseudo), 60 * 60 * 24)
    return pseudo
  }

  const body = {
    model: MODEL,
    input: text,
  }
  const res = await fetch(OPENAI_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      Connection: 'keep-alive',
    },
    body: JSON.stringify(body),
    // keepalive ensures connection reuse between requests in same worker
  })
  if (!res.ok) {
    console.error('[Embedding] OpenAI error', await res.text())
    return pseudoEmbedding(text)
  }
  const json = await res.json()
  const vector: number[] = json.data?.[0]?.embedding ?? []
  memCache.set(cacheKey, vector)
  await setCachedResponse(cacheKey, JSON.stringify(vector), 60 * 60 * 24)
  return vector
}

function pseudoEmbedding(text: string): number[] {
  // hash -> pseudo-random deterministic vector in [0,1)
  const bytes = new TextEncoder().encode(text)
  const sum = bytes.reduce((a, b) => a + b, 0)
  const len = 1536
  const vec = new Array(len)
  for (let i = 0; i < len; i++) {
    vec[i] = ((sum + i * 31) % 1000) / 1000 // 0-0.999
  }
  return vec
}
