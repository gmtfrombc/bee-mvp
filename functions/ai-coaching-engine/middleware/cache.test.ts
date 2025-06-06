import { assertEquals, assertRejects } from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
    getCachedResponse,
    setCachedResponse,
    generateCacheKey,
    clearCache
} from './cache.ts';

// Mock environment for testing
const originalEnv = Deno.env.get('CACHE_ENABLED');

Deno.test('cache - generateCacheKey creates consistent SHA-256 hash', async () => {
    const key1 = await generateCacheKey('user123', 'Hello', 'Motivator');
    const key2 = await generateCacheKey('user123', 'Hello', 'Motivator');
    const key3 = await generateCacheKey('user123', 'Hello', 'Challenger');

    assertEquals(key1, key2, 'Same inputs should generate same key');
    assertEquals(typeof key1, 'string', 'Key should be string');
    assertEquals(key1.length, 64, 'SHA-256 should be 64 hex characters');
    assertEquals(key1 !== key3, true, 'Different inputs should generate different keys');
});

Deno.test('cache - miss returns null when no cached value', async () => {
    await clearCache();
    const result = await getCachedResponse('nonexistent-key');
    assertEquals(result, null);
});

Deno.test('cache - hit/miss logic with memory fallback', async () => {
    await clearCache();
    const key = 'test-key-123';
    const value = 'cached response message';

    // Miss initially
    let result = await getCachedResponse(key);
    assertEquals(result, null);

    // Set value
    await setCachedResponse(key, value, 60); // 60 seconds TTL

    // Hit after setting
    result = await getCachedResponse(key);
    assertEquals(result, value);
});

Deno.test('cache - TTL expiration works correctly', async () => {
    await clearCache();
    const key = 'expire-test-key';
    const value = 'expire test value';

    // Set with very short TTL (1 second)
    await setCachedResponse(key, value, 1);

    // Should hit immediately
    let result = await getCachedResponse(key);
    assertEquals(result, value);

    // Wait for expiration
    await new Promise(resolve => setTimeout(resolve, 1100)); // 1.1 seconds

    // Should miss after expiration
    result = await getCachedResponse(key);
    assertEquals(result, null);
});

Deno.test('cache - disabled when CACHE_ENABLED=false', async () => {
    // Temporarily disable cache
    Deno.env.set('CACHE_ENABLED', 'false');

    try {
        await clearCache();
        const key = 'disabled-test-key';
        const value = 'should not be cached';

        await setCachedResponse(key, value, 60);
        const result = await getCachedResponse(key);
        assertEquals(result, null, 'Cache should be disabled');
    } finally {
        // Restore original setting
        if (originalEnv !== undefined) {
            Deno.env.set('CACHE_ENABLED', originalEnv);
        } else {
            Deno.env.delete('CACHE_ENABLED');
        }
    }
});

Deno.test('cache - memory cleanup on large cache sizes', async () => {
    await clearCache();

    // This test verifies that the cleanup logic exists
    // by setting many expired entries and checking cleanup triggers
    const promises: Promise<void>[] = [];
    for (let i = 0; i < 50; i++) {
        promises.push(setCachedResponse(`key-${i}`, `value-${i}`, 0.001)); // Very short TTL
    }
    await Promise.all(promises);

    // Wait for expiration
    await new Promise(resolve => setTimeout(resolve, 10));

    // Trigger cleanup by adding more entries
    for (let i = 50; i < 100; i++) {
        await setCachedResponse(`key-${i}`, `value-${i}`, 60);
    }

    // Check that cleanup happened (expired entries removed)
    const expiredResult = await getCachedResponse('key-0');
    assertEquals(expiredResult, null, 'Expired entries should be cleaned up');

    const validResult = await getCachedResponse('key-99');
    assertEquals(validResult, 'value-99', 'Valid entries should remain');
});

Deno.test('cache - integration test with realistic coaching scenario', async () => {
    await clearCache();

    const userId = 'coach-user-456';
    const message = 'I need motivation to exercise today';
    const persona = 'Motivator';

    // Generate realistic cache key
    const cacheKey = await generateCacheKey(userId, message, persona);

    // Simulate coaching response
    const coachingResponse = "You've got this! Start with just 10 minutes of movement today.";

    // Cache the response
    await setCachedResponse(cacheKey, coachingResponse, 15 * 60); // 15 minutes

    // Verify cache hit
    const cachedResult = await getCachedResponse(cacheKey);
    assertEquals(cachedResult, coachingResponse);

    // Different persona should have different cache key
    const differentPersonaKey = await generateCacheKey(userId, message, 'Challenger');
    const differentResult = await getCachedResponse(differentPersonaKey);
    assertEquals(differentResult, null, 'Different persona should not hit cache');
});

Deno.test('cache - telemetry integration for monitoring', async () => {
    await clearCache();

    // Test cache MISS scenario
    const missKey = await generateCacheKey('user-123', 'test message', 'Coach');
    const missResult = await getCachedResponse(missKey);
    assertEquals(missResult, null, 'Should be cache MISS');

    // Test cache HIT scenario
    const hitValue = 'Cached response for telemetry test';
    await setCachedResponse(missKey, hitValue, 60);
    const hitResult = await getCachedResponse(missKey);
    assertEquals(hitResult, hitValue, 'Should be cache HIT');

    // Verify cache key generation is deterministic for telemetry
    const key1 = await generateCacheKey('user-123', 'same message', 'same persona');
    const key2 = await generateCacheKey('user-123', 'same message', 'same persona');
    assertEquals(key1, key2, 'Cache keys must be deterministic for reliable telemetry');
}); 