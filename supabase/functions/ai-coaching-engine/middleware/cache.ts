export interface CacheOptions {
  ttlSeconds?: number
  enabled?: boolean
}

export class CacheError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'CacheError'
  }
}

// In-memory cache fallback – simple LRU using Map insertion order
const MAX_ENTRIES = parseInt(Deno.env.get('MEMORY_CACHE_CAP') ?? '1000')
const memoryCache = new Map<string, { value: string; expires: number }>()

function touchLRU(key: string, entry: { value: string; expires: number }) {
  memoryCache.delete(key)
  memoryCache.set(key, entry) // reinserts at the end (most recently used)
}

/**
 * Get cached response by key
 * Uses Deno KV first, falls back to in-memory cache
 */
export async function getCachedResponse(key: string): Promise<string | null> {
  const cacheEnabled = Deno.env.get('CACHE_ENABLED') !== 'false'
  if (!cacheEnabled) return null

  try {
    // Try Deno KV first
    const kv = await Deno.openKv?.()
    if (kv) {
      const result = await kv.get<{ value: string; expires: number }>(['cache', key])
      if (result.value && result.value.expires > Date.now()) {
        return result.value.value
      }
      // Clean up expired entry
      if (result.value) {
        await kv.delete(['cache', key])
      }
    }
  } catch (error) {
    console.warn('KV cache read failed, falling back to memory:', error)
  }

  // Fallback to in-memory cache
  const cached = memoryCache.get(key)
  if (cached && cached.expires > Date.now()) {
    // Refresh LRU order on access
    touchLRU(key, cached)
    return cached.value
  }

  // Clean up expired entry
  if (cached) {
    memoryCache.delete(key)
  }

  return null
}

/**
 * Set cached response with TTL
 * Uses Deno KV first, falls back to in-memory cache
 */
export async function setCachedResponse(
  key: string,
  value: string,
  ttlSecs: number = 900, // 15 minutes default
): Promise<void> {
  const cacheEnabled = Deno.env.get('CACHE_ENABLED') !== 'false'
  if (!cacheEnabled) return

  const expires = Date.now() + (ttlSecs * 1000)
  const cacheEntry = { value, expires }

  try {
    // Try Deno KV first
    const kv = await Deno.openKv?.()
    if (kv) {
      await kv.set(['cache', key], cacheEntry, { expireIn: ttlSecs * 1000 })
      return
    }
  } catch (error) {
    console.warn('KV cache write failed, falling back to memory:', error)
  }

  // Fallback to in-memory cache
  touchLRU(key, cacheEntry)

  // Evict least-recently-used entries if over capacity
  while (memoryCache.size > MAX_ENTRIES) {
    const oldestKey = memoryCache.keys().next().value as string | undefined
    if (oldestKey) memoryCache.delete(oldestKey)
    else break
  }
}

/**
 * Generate cache key from user context
 * Uses SHA-256 of user_id:message:persona:sentiment
 */
export async function generateCacheKey(
  userId: string,
  message: string,
  persona: string,
  sentiment: string = 'neutral',
): Promise<string> {
  const input = `${userId}:${message}:${persona}:${sentiment}`
  const msgBuffer = new TextEncoder().encode(input)
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('')
}

/**
 * Clear all cached entries (for testing)
 */
export async function clearCache(): Promise<void> {
  memoryCache.clear()

  try {
    const kv = await Deno.openKv?.()
    if (kv) {
      // Note: This is a simplified clear - in production, you might want
      // to iterate through keys with a specific prefix
      const entries = kv.list({ prefix: ['cache'] })
      for await (const entry of entries) {
        await kv.delete(entry.key)
      }
    }
  } catch (error) {
    console.warn('Failed to clear KV cache:', error)
  }
}
