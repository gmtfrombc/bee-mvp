import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
    shouldTrigger,
    hasReachedDailyLimit,
    getNextAllowedInterventionTime,
    getHoursUntilNextIntervention,
    getInterventionLimits,
    analyzeTriggerConditions
} from "../../../functions/ai-coaching-engine/personalization/intervention-triggers.ts";
import { PatternSummary } from "../../../functions/ai-coaching-engine/personalization/pattern-analysis.ts";

Deno.test("shouldTrigger - respects minimum time between interventions", () => {
    const summary: PatternSummary = {
        engagementPeaks: [],
        volatilityScore: 0.9 // High volatility should trigger
    };

    const now = new Date('2025-01-15T12:00:00Z');
    const lastIntervention = new Date('2025-01-15T10:00:00Z'); // 2 hours ago (< 4 hour minimum)

    const result = shouldTrigger(summary, lastIntervention, now);

    assertEquals(result, false);
});

Deno.test("shouldTrigger - triggers on high volatility after minimum time", () => {
    const summary: PatternSummary = {
        engagementPeaks: ['morning'],
        volatilityScore: 0.9
    };

    const now = new Date('2025-01-15T12:00:00Z');
    const lastIntervention = new Date('2025-01-15T07:00:00Z'); // 5 hours ago (> 4 hour minimum)

    const result = shouldTrigger(summary, lastIntervention, now);

    assertEquals(result, true);
});

Deno.test("shouldTrigger - no trigger for normal patterns", () => {
    const summary: PatternSummary = {
        engagementPeaks: ['morning', 'evening'],
        volatilityScore: 0.3
    };

    const now = new Date('2025-01-15T12:00:00Z');
    const lastIntervention = new Date('2025-01-15T07:00:00Z'); // 5 hours ago

    const result = shouldTrigger(summary, lastIntervention, now);

    assertEquals(result, false);
});

Deno.test("hasReachedDailyLimit - correctly counts daily interventions", () => {
    const now = new Date('2025-01-15T15:00:00Z');

    // 3 interventions today (at limit)
    const interventions = [
        new Date('2025-01-15T08:00:00Z'),
        new Date('2025-01-15T12:00:00Z'),
        new Date('2025-01-15T14:00:00Z')
    ];

    const result = hasReachedDailyLimit(interventions, now);

    assertEquals(result, true);
});

Deno.test("hasReachedDailyLimit - excludes previous day interventions", () => {
    const now = new Date('2025-01-15T15:00:00Z');

    // 2 interventions today + 1 yesterday (under limit)
    const interventions = [
        new Date('2025-01-14T20:00:00Z'), // Yesterday
        new Date('2025-01-15T08:00:00Z'), // Today
        new Date('2025-01-15T12:00:00Z')  // Today
    ];

    const result = hasReachedDailyLimit(interventions, now);

    assertEquals(result, false);
});

Deno.test("getNextAllowedInterventionTime - calculates correct next time", () => {
    const lastIntervention = new Date('2025-01-15T10:00:00Z');

    const nextAllowed = getNextAllowedInterventionTime(lastIntervention);

    assertEquals(nextAllowed.getTime(), new Date('2025-01-15T14:00:00Z').getTime());
});

Deno.test("getHoursUntilNextIntervention - calculates remaining hours", () => {
    const now = new Date('2025-01-15T12:00:00Z');
    const lastIntervention = new Date('2025-01-15T10:00:00Z');

    const hoursRemaining = getHoursUntilNextIntervention(lastIntervention, now);

    assertEquals(hoursRemaining, 2); // 2 hours until 4-hour minimum is met
});

Deno.test("analyzeTriggerConditions - returns correct trigger for high volatility", () => {
    const summary: PatternSummary = {
        engagementPeaks: ['morning'],
        volatilityScore: 0.9
    };

    const now = new Date('2025-01-15T12:00:00Z');
    const lastIntervention = new Date('2025-01-15T07:00:00Z');

    const result = analyzeTriggerConditions(summary, lastIntervention, now);

    assertEquals(result.shouldTrigger, true);
    assertEquals(result.urgency, 'high');
    assertEquals(typeof result.reason, 'string');
});

Deno.test("getInterventionLimits - returns correct constants", () => {
    const limits = getInterventionLimits();

    assertEquals(limits.maxPerDay, 3);
    assertEquals(limits.minHoursBetween, 4);
}); 