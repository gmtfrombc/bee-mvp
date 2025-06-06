import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { analyzeEngagement, EngagementEvent, PatternSummary } from "../../../functions/ai-coaching-engine/personalization/pattern-analysis.ts";

Deno.test("analyzeEngagement - happy path with mixed events", () => {
    const events: EngagementEvent[] = [
        {
            event_type: 'app_session',
            timestamp: '2025-01-15T09:00:00Z',
            metadata: { duration: 300 }
        },
        {
            event_type: 'goal_completion',
            timestamp: '2025-01-15T09:30:00Z',
            metadata: { goal_id: 'goal1' }
        },
        {
            event_type: 'app_session',
            timestamp: '2025-01-15T19:00:00Z',
            metadata: { duration: 180 }
        },
        {
            event_type: 'momentum_change',
            timestamp: '2025-01-16T09:15:00Z',
            metadata: { from: 'Steady', to: 'Rising' }
        },
        {
            event_type: 'app_session',
            timestamp: '2025-01-16T19:30:00Z',
            metadata: { duration: 240 }
        }
    ];

    const result = analyzeEngagement(events);

    assertExists(result);
    assertEquals(typeof result.volatilityScore, 'number');
    assertEquals(Array.isArray(result.engagementPeaks), true);

    // Should identify morning and evening peaks
    assertEquals(result.engagementPeaks.includes('morning'), true);
    assertEquals(result.engagementPeaks.includes('evening'), true);

    // Volatility should be within valid range
    assertEquals(result.volatilityScore >= 0, true);
    assertEquals(result.volatilityScore <= 1, true);
});

Deno.test("analyzeEngagement - empty events array", () => {
    const events: EngagementEvent[] = [];

    const result = analyzeEngagement(events);

    assertEquals(result.engagementPeaks, []);
    assertEquals(result.volatilityScore, 0);
});

Deno.test("analyzeEngagement - single event", () => {
    const events: EngagementEvent[] = [
        {
            event_type: 'app_session',
            timestamp: '2025-01-15T14:00:00Z',
            metadata: { duration: 120 }
        }
    ];

    const result = analyzeEngagement(events);

    assertExists(result);
    assertEquals(result.volatilityScore, 0); // No volatility with single event
    assertEquals(result.engagementPeaks.length >= 0, true);
});

Deno.test("analyzeEngagement - high volatility pattern", () => {
    // Create events with very uneven distribution
    const events: EngagementEvent[] = [];

    // 10 events on one day
    for (let i = 0; i < 10; i++) {
        events.push({
            event_type: 'app_session',
            timestamp: `2025-01-15T${(i + 8).toString().padStart(2, '0')}:00:00Z`,
            metadata: { duration: 60 }
        });
    }

    // 1 event on another day (7 days later)
    events.push({
        event_type: 'app_session',
        timestamp: '2025-01-22T10:00:00Z',
        metadata: { duration: 60 }
    });

    const result = analyzeEngagement(events);

    // Should detect high volatility due to uneven distribution
    assertEquals(result.volatilityScore > 0.5, true);
    assertEquals(result.engagementPeaks.length > 0, true);
}); 