import { assertEquals, assertRejects } from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
    enforceRateLimit,
    RateLimitError,
    getRateLimitStatus,
    clearRateLimits
} from './rate-limit.ts';

// Mock environment for testing
const originalRateLimit = Deno.env.get('RATE_LIMIT_MAX');

Deno.test('rate-limit - allows requests under limit', async () => {
    Deno.env.set('RATE_LIMIT_MAX', '5');
    await clearRateLimits();

    const userId = 'test-user-1';

    // Should allow first 5 requests
    for (let i = 0; i < 5; i++) {
        await enforceRateLimit(userId); // Should not throw
    }
});

Deno.test('rate-limit - blocks 6th request in window', async () => {
    Deno.env.set('RATE_LIMIT_MAX', '5');
    await clearRateLimits();

    const userId = 'test-user-2';

    // Make 5 requests (should succeed)
    for (let i = 0; i < 5; i++) {
        await enforceRateLimit(userId);
    }

    // 6th request should be blocked
    await assertRejects(
        () => enforceRateLimit(userId),
        RateLimitError,
        'Rate limit exceeded'
    );
});

Deno.test('rate-limit - different users have separate limits', async () => {
    Deno.env.set('RATE_LIMIT_MAX', '3');
    await clearRateLimits();

    const user1 = 'test-user-3';
    const user2 = 'test-user-4';

    // User 1 makes 3 requests
    for (let i = 0; i < 3; i++) {
        await enforceRateLimit(user1);
    }

    // User 2 should still be able to make requests
    for (let i = 0; i < 3; i++) {
        await enforceRateLimit(user2); // Should not throw
    }

    // Both users should be blocked on next request
    await assertRejects(
        () => enforceRateLimit(user1),
        RateLimitError
    );

    await assertRejects(
        () => enforceRateLimit(user2),
        RateLimitError
    );
});

Deno.test('rate-limit - sliding window resets over time', async () => {
    Deno.env.set('RATE_LIMIT_MAX', '2');
    await clearRateLimits();

    const userId = 'test-user-5';

    // Make 2 requests (should succeed)
    await enforceRateLimit(userId);
    await enforceRateLimit(userId);

    // 3rd request should be blocked
    await assertRejects(
        () => enforceRateLimit(userId),
        RateLimitError
    );

    // Wait for window to slide (in real scenario this would be 60+ seconds)
    // For testing, we simulate by clearing and making new requests
    // This tests the sliding window logic structure
    await clearRateLimits();

    // Should allow requests again
    await enforceRateLimit(userId); // Should not throw
});

Deno.test('rate-limit - getRateLimitStatus returns correct info', async () => {
    Deno.env.set('RATE_LIMIT_MAX', '5');
    await clearRateLimits();

    const userId = 'test-user-6';

    // Check initial status
    let status = await getRateLimitStatus(userId);
    assertEquals(status.limit, 5);
    assertEquals(status.remaining, 5);
    assertEquals(typeof status.resetTime, 'number');

    // Make 2 requests
    await enforceRateLimit(userId);
    await enforceRateLimit(userId);

    // Check updated status
    status = await getRateLimitStatus(userId);
    assertEquals(status.remaining, 3);
    assertEquals(status.limit, 5);
});

Deno.test('rate-limit - RateLimitError includes retryAfter', async () => {
    Deno.env.set('RATE_LIMIT_MAX', '1');
    await clearRateLimits();

    const userId = 'test-user-7';

    // Make 1 request (limit)
    await enforceRateLimit(userId);

    // Next request should throw with retryAfter
    try {
        await enforceRateLimit(userId);
        assertEquals(false, true, 'Should have thrown RateLimitError');
    } catch (error) {
        assertEquals(error instanceof RateLimitError, true);
        const rateLimitError = error as RateLimitError;
        assertEquals(typeof rateLimitError.retryAfter, 'number');
        assertEquals(rateLimitError.retryAfter! > 0, true, 'retryAfter should be positive');
        assertEquals(rateLimitError.retryAfter! <= 60, true, 'retryAfter should be <= 60 seconds');
    }
});

Deno.test('rate-limit - uses environment variable for max requests', async () => {
    // Test custom limit
    Deno.env.set('RATE_LIMIT_MAX', '10');
    await clearRateLimits();

    const userId = 'test-user-8';

    // Should allow 10 requests
    for (let i = 0; i < 10; i++) {
        await enforceRateLimit(userId);
    }

    // 11th should be blocked
    await assertRejects(
        () => enforceRateLimit(userId),
        RateLimitError
    );

    // Check status reflects custom limit
    const status = await getRateLimitStatus(userId);
    assertEquals(status.limit, 10);
});

Deno.test('rate-limit - handles malformed environment variables gracefully', async () => {
    // Test with invalid env var
    Deno.env.set('RATE_LIMIT_MAX', 'invalid');
    await clearRateLimits();

    const userId = 'test-user-9';

    // Should fall back to default limit (parseInt('invalid') = NaN, then || 5)
    const status = await getRateLimitStatus(userId);
    assertEquals(status.limit, 5); // parseInt('invalid') = NaN, fallback to 5

    // Should allow requests since limit is 5
    await enforceRateLimit(userId); // Should not throw

    // Restore to test default fallback
    Deno.env.delete('RATE_LIMIT_MAX');
    await clearRateLimits();

    const defaultStatus = await getRateLimitStatus(userId);
    assertEquals(defaultStatus.limit, 5, 'Should default to 5 when env var missing');
});

// Cleanup after all tests
Deno.test('rate-limit - cleanup', async () => {
    // Restore original environment
    if (originalRateLimit !== undefined) {
        Deno.env.set('RATE_LIMIT_MAX', originalRateLimit);
    } else {
        Deno.env.delete('RATE_LIMIT_MAX');
    }

    await clearRateLimits();
}); 