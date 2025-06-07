import { PatternSummary } from './pattern-analysis.ts';

export type CoachingPersona = 'supportive' | 'challenging' | 'educational';

type MomentumState = 'Rising' | 'Steady' | 'NeedsCare';

type PersonaRule = {
    condition: (summary: PatternSummary, momentum: MomentumState) => boolean;
    persona: CoachingPersona;
    priority: number; // Higher number = higher priority
};

/**
 * Derives the appropriate coaching persona based on user patterns and momentum state
 * Uses simple rule-based mapping for MVP implementation
 */
export function derivePersona(summary: PatternSummary, momentumState: string): CoachingPersona {
    const momentum = momentumState as MomentumState;

    // Define persona rules in priority order
    const rules: PersonaRule[] = [
        // High volatility users need supportive approach regardless of momentum
        {
            condition: (s, _) => s.volatilityScore > 0.7,
            persona: 'supportive',
            priority: 10
        },

        // Users needing care get supportive coaching
        {
            condition: (_, m) => m === 'NeedsCare',
            persona: 'supportive',
            priority: 9
        },

        // Rising momentum with moderate volatility can handle challenges
        {
            condition: (s, m) => m === 'Rising' && s.volatilityScore < 0.4,
            persona: 'challenging',
            priority: 8
        },

        // Steady users with consistent patterns get educational content
        {
            condition: (s, m) => m === 'Steady' && s.volatilityScore < 0.3,
            persona: 'educational',
            priority: 7
        },

        // Users with clear engagement peaks get educational approach
        {
            condition: (s, _) => s.engagementPeaks.length >= 2 && s.volatilityScore < 0.5,
            persona: 'educational',
            priority: 6
        },

        // Rising momentum with some volatility gets supportive approach
        {
            condition: (s, m) => m === 'Rising' && s.volatilityScore >= 0.4,
            persona: 'supportive',
            priority: 5
        },

        // Steady users with moderate volatility get supportive approach
        {
            condition: (s, m) => m === 'Steady' && s.volatilityScore >= 0.3,
            persona: 'supportive',
            priority: 4
        }
    ];

    // Apply rules in priority order
    const matchingRules = rules
        .filter(rule => rule.condition(summary, momentum))
        .sort((a, b) => b.priority - a.priority);

    if (matchingRules.length > 0) {
        return matchingRules[0].persona;
    }

    // Default fallback based on momentum state
    return getDefaultPersonaForMomentum(momentum);
}

/**
 * Get default persona based on momentum state when no specific rules match
 */
function getDefaultPersonaForMomentum(momentum: MomentumState): CoachingPersona {
    switch (momentum) {
        case 'Rising':
            return 'challenging';
        case 'Steady':
            return 'educational';
        case 'NeedsCare':
            return 'supportive';
        default:
            return 'supportive'; // Safe default
    }
}

/**
 * Get a description of what each persona represents for debugging/logging
 */
export function getPersonaDescription(persona: CoachingPersona): string {
    const descriptions = {
        supportive: 'Encouraging, empathetic, focuses on small wins and emotional well-being',
        challenging: 'Goal-oriented, pushes for achievement, celebrates progress with stretch targets',
        educational: 'Informative, skill-building, provides insights and learning opportunities'
    };

    return descriptions[persona];
}

/**
 * Validate momentum state input
 */
export function isValidMomentumState(state: string): state is MomentumState {
    return ['Rising', 'Steady', 'NeedsCare'].includes(state);
} 