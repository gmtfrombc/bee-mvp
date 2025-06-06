export class RateLimitError extends Error {
    constructor(message: string, public retryAfter?: number) {
        super(message);
        this.name = 'RateLimitError';
    }
}

// In-memory rate limit tracking (fallback)
const memoryRateLimits = new Map<string, number[]>();

/**
 * Enforce rate limiting using sliding window approach
 * Throws RateLimitError if limit exceeded
 */
export async function enforceRateLimit(userId: string): Promise<void> {
    const maxRequests = parseInt(Deno.env.get('RATE_LIMIT_MAX') || '5') || 5;
    const windowMs = 60 * 1000; // 1 minute window
    const now = Date.now();
    const minuteBucket = Math.floor(now / 60_000);

    try {
        // Try Deno KV first
        const kv = await Deno.openKv?.();
        if (kv) {
            await enforceRateLimitKV(kv, userId, maxRequests, minuteBucket, windowMs);
            return;
        }
    } catch (error) {
        console.warn('KV rate limit check failed, falling back to memory:', error);
    }

    // Fallback to in-memory rate limiting
    await enforceRateLimitMemory(userId, maxRequests, now, windowMs);
}

/**
 * KV-based rate limiting with sliding window
 */
async function enforceRateLimitKV(
    kv: Deno.Kv,
    userId: string,
    maxRequests: number,
    minuteBucket: number,
    windowMs: number
): Promise<void> {
    const baseKey = ['rate_limit', userId];
    const currentKey = [...baseKey, minuteBucket];
    const previousKey = [...baseKey, minuteBucket - 1];

    // Get current and previous minute counts
    const [currentResult, previousResult] = await Promise.all([
        kv.get<number>(currentKey),
        kv.get<number>(previousKey)
    ]);

    const currentCount = currentResult.value || 0;
    const previousCount = previousResult.value || 0;

    // Calculate sliding window count
    const now = Date.now();
    const minuteProgress = (now % 60_000) / 60_000; // 0-1 progress through current minute
    const slidingCount = Math.floor(previousCount * (1 - minuteProgress) + currentCount);

    if (slidingCount >= maxRequests) {
        const retryAfter = Math.ceil((60_000 - (now % 60_000)) / 1000); // Seconds until next minute
        throw new RateLimitError(
            `Rate limit exceeded. Max ${maxRequests} requests per minute.`,
            retryAfter
        );
    }

    // Increment current minute counter
    await kv.set(currentKey, currentCount + 1, { expireIn: 120_000 }); // 2 minute TTL
}

/**
 * Memory-based rate limiting (fallback)
 */
async function enforceRateLimitMemory(
    userId: string,
    maxRequests: number,
    now: number,
    windowMs: number
): Promise<void> {
    const userRequests = memoryRateLimits.get(userId) || [];

    // Remove old requests outside the window
    const recentRequests = userRequests.filter(timestamp =>
        now - timestamp < windowMs
    );

    // Check if at limit
    if (recentRequests.length >= maxRequests) {
        const oldestRequest = Math.min(...recentRequests);
        const retryAfter = Math.ceil((windowMs - (now - oldestRequest)) / 1000);
        throw new RateLimitError(
            `Rate limit exceeded. Max ${maxRequests} requests per minute.`,
            retryAfter
        );
    }

    // Add current request
    recentRequests.push(now);
    memoryRateLimits.set(userId, recentRequests);

    // Periodic cleanup
    if (memoryRateLimits.size > 10000) {
        for (const [id, requests] of memoryRateLimits.entries()) {
            const validRequests = requests.filter(timestamp => now - timestamp < windowMs);
            if (validRequests.length === 0) {
                memoryRateLimits.delete(id);
            } else {
                memoryRateLimits.set(id, validRequests);
            }
        }
    }
}

/**
 * Get current rate limit status for a user
 */
export async function getRateLimitStatus(userId: string): Promise<{
    remaining: number;
    resetTime: number;
    limit: number;
}> {
    const maxRequests = parseInt(Deno.env.get('RATE_LIMIT_MAX') || '5') || 5;
    const now = Date.now();
    const minuteBucket = Math.floor(now / 60_000);

    try {
        const kv = await Deno.openKv?.();
        if (kv) {
            const baseKey = ['rate_limit', userId];
            const currentKey = [...baseKey, minuteBucket];
            const previousKey = [...baseKey, minuteBucket - 1];

            const [currentResult, previousResult] = await Promise.all([
                kv.get<number>(currentKey),
                kv.get<number>(previousKey)
            ]);

            const currentCount = currentResult.value || 0;
            const previousCount = previousResult.value || 0;

            const minuteProgress = (now % 60_000) / 60_000;
            const slidingCount = Math.floor(previousCount * (1 - minuteProgress) + currentCount);

            return {
                remaining: Math.max(0, maxRequests - slidingCount),
                resetTime: Math.ceil(now / 60_000) * 60_000, // Next minute boundary
                limit: maxRequests
            };
        }
    } catch (error) {
        console.warn('Failed to get KV rate limit status:', error);
    }

    // Fallback to memory-based status
    const userRequests = memoryRateLimits.get(userId) || [];
    const recentRequests = userRequests.filter(timestamp => now - timestamp < 60_000);

    return {
        remaining: Math.max(0, maxRequests - recentRequests.length),
        resetTime: Math.ceil(now / 60_000) * 60_000,
        limit: maxRequests
    };
}

/**
 * Clear rate limit data for testing
 */
export async function clearRateLimits(): Promise<void> {
    memoryRateLimits.clear();

    try {
        const kv = await Deno.openKv?.();
        if (kv) {
            const entries = kv.list({ prefix: ['rate_limit'] });
            for await (const entry of entries) {
                await kv.delete(entry.key);
            }
        }
    } catch (error) {
        console.warn('Failed to clear KV rate limits:', error);
    }
} 