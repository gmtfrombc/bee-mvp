import { PatternSummary } from './pattern-analysis.ts';

// Constants from ai_coaching_architecture.md
const MAX_INTERVENTIONS_PER_DAY = 3;
const MIN_HOURS_BETWEEN_INTERVENTIONS = 4;
const MILLISECONDS_PER_HOUR = 60 * 60 * 1000;
const MILLISECONDS_PER_DAY = 24 * MILLISECONDS_PER_HOUR;

type InterventionTrigger = {
    reason: string;
    urgency: 'low' | 'medium' | 'high';
    shouldTrigger: boolean;
};

/**
 * Determines if a proactive coaching intervention should be triggered
 * Respects rate limits: max 3 interventions per day, min 4 hours between
 */
export function shouldTrigger(
    summary: PatternSummary,
    lastIntervention: Date,
    now: Date = new Date()
): boolean {
    const timeSinceLastIntervention = now.getTime() - lastIntervention.getTime();

    // Check minimum time between interventions (4 hours)
    if (timeSinceLastIntervention < MIN_HOURS_BETWEEN_INTERVENTIONS * MILLISECONDS_PER_HOUR) {
        return false;
    }

    // Analyze trigger conditions
    const trigger = analyzeTriggerConditions(summary, lastIntervention, now);

    return trigger.shouldTrigger;
}

/**
 * Analyzes pattern data to determine if intervention is warranted
 * Returns trigger decision with reasoning
 */
export function analyzeTriggerConditions(
    summary: PatternSummary,
    lastIntervention: Date,
    now: Date = new Date()
): InterventionTrigger {
    // High volatility indicates user may be struggling
    if (summary.volatilityScore > 0.8) {
        return {
            reason: 'High engagement volatility detected - user may need support',
            urgency: 'high',
            shouldTrigger: true
        };
    }

    // No engagement peaks suggests disengagement
    if (summary.engagementPeaks.length === 0) {
        return {
            reason: 'No clear engagement patterns - potential disengagement',
            urgency: 'medium',
            shouldTrigger: true
        };
    }

    // Check for significant gaps in engagement
    const hoursSinceLastIntervention = (now.getTime() - lastIntervention.getTime()) / MILLISECONDS_PER_HOUR;

    // If user has consistent patterns but hasn't been engaged recently, gentle check-in
    if (summary.engagementPeaks.length >= 2 && summary.volatilityScore < 0.3 && hoursSinceLastIntervention > 24) {
        return {
            reason: 'Consistent user with potential engagement gap - proactive check-in',
            urgency: 'low',
            shouldTrigger: true
        };
    }

    // Moderate volatility with some engagement patterns - selective intervention
    if (summary.volatilityScore > 0.5 && summary.engagementPeaks.length >= 1) {
        return {
            reason: 'Moderate volatility with engagement patterns - coaching opportunity',
            urgency: 'medium',
            shouldTrigger: hoursSinceLastIntervention > 12
        };
    }

    return {
        reason: 'No intervention triggers met',
        urgency: 'low',
        shouldTrigger: false
    };
}

/**
 * Check if daily intervention limit has been reached
 */
export function hasReachedDailyLimit(interventionTimestamps: Date[], now: Date = new Date()): boolean {
    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);

    const todaysInterventions = interventionTimestamps.filter(timestamp =>
        timestamp >= startOfDay && timestamp <= now
    );

    return todaysInterventions.length >= MAX_INTERVENTIONS_PER_DAY;
}

/**
 * Get next allowed intervention time based on rate limits
 */
export function getNextAllowedInterventionTime(lastIntervention: Date): Date {
    return new Date(lastIntervention.getTime() + MIN_HOURS_BETWEEN_INTERVENTIONS * MILLISECONDS_PER_HOUR);
}

/**
 * Calculate hours until next intervention is allowed
 */
export function getHoursUntilNextIntervention(lastIntervention: Date, now: Date = new Date()): number {
    const nextAllowed = getNextAllowedInterventionTime(lastIntervention);
    const hoursRemaining = Math.max(0, (nextAllowed.getTime() - now.getTime()) / MILLISECONDS_PER_HOUR);
    return Math.ceil(hoursRemaining);
}

/**
 * Get intervention rate limiting constants for external reference
 */
export function getInterventionLimits() {
    return {
        maxPerDay: MAX_INTERVENTIONS_PER_DAY,
        minHoursBetween: MIN_HOURS_BETWEEN_INTERVENTIONS
    };
} 