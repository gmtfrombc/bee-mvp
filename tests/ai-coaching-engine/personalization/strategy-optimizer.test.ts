/**
 * Test suite for StrategyOptimizer
 * Tests coaching strategy adaptation and optimization functionality
 */

import { StrategyOptimizer } from '../../../functions/ai-coaching-engine/personalization/strategy-optimizer.ts';
import { EffectivenessTracker } from '../../../functions/ai-coaching-engine/personalization/effectiveness-tracker.ts';

// Mock EffectivenessTracker
const mockEffectivenessTracker = {
    analyzeUserEffectiveness: jest.fn(),
    getEffectivenessSummary: jest.fn()
};

describe('StrategyOptimizer', () => {
    let optimizer: StrategyOptimizer;

    beforeEach(() => {
        optimizer = new StrategyOptimizer(mockEffectivenessTracker as any);
        jest.clearAllMocks();
    });

    describe('optimizeStrategyForUser', () => {
        const mockContext = {
            momentumState: 'Steady' as const,
            userEngagementLevel: 'medium' as const,
            timeOfDay: 'afternoon' as const,
            daysSinceLastInteraction: 1
        };

        it('should return optimized strategy based on effectiveness data', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.8,
                personaEffectiveness: {
                    supportive: 0.9,
                    challenging: 0.6,
                    educational: 0.7
                },
                averageRating: 4.2,
                responseRate: 0.85,
                recommendedPersona: 'supportive',
                adjustmentReasons: []
            };

            const mockSummary = {
                totalInteractions: 15,
                averageRating: 4.2,
                helpfulPercentage: 80,
                responseRate: 85,
                preferredPersona: 'supportive',
                lastWeekTrend: 'improving' as const
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);
            mockEffectivenessTracker.getEffectivenessSummary.mockResolvedValue(mockSummary);

            const strategy = await optimizer.optimizeStrategyForUser('user-123', mockContext);

            expect(strategy.preferredPersona).toBe('supportive');
            expect(strategy.interventionFrequency).toBe('high'); // High effectiveness + good response rate
            expect(strategy.tonality).toBe('direct'); // Good ratings
            expect(strategy.adaptationReasons.length).toBeGreaterThan(0);
        });

        it('should adapt persona for NeedsCare momentum state', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.5,
                personaEffectiveness: {
                    supportive: 0.7,
                    challenging: 0.4,
                    educational: 0.3
                },
                averageRating: 3.0,
                responseRate: 0.5,
                recommendedPersona: 'challenging',
                adjustmentReasons: []
            };

            const mockSummary = {
                totalInteractions: 5,
                averageRating: 3.0,
                helpfulPercentage: 50,
                responseRate: 50,
                preferredPersona: 'challenging',
                lastWeekTrend: 'stable' as const
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);
            mockEffectivenessTracker.getEffectivenessSummary.mockResolvedValue(mockSummary);

            const needsCareContext = {
                ...mockContext,
                momentumState: 'NeedsCare' as const
            };

            const strategy = await optimizer.optimizeStrategyForUser('user-123', needsCareContext);

            expect(strategy.preferredPersona).toBe('supportive'); // Should switch to supportive for NeedsCare
            expect(strategy.tonality).toBe('gentle'); // Gentle tone for users needing care
        });

        it('should reduce frequency for low response rates', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.3,
                personaEffectiveness: {
                    supportive: 0.3,
                    challenging: 0.2,
                    educational: 0.4
                },
                averageRating: 2.5,
                responseRate: 0.2, // Very low response rate
                recommendedPersona: 'educational',
                adjustmentReasons: []
            };

            const mockSummary = {
                totalInteractions: 10,
                averageRating: 2.5,
                helpfulPercentage: 30,
                responseRate: 20,
                preferredPersona: 'educational',
                lastWeekTrend: 'declining' as const
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);
            mockEffectivenessTracker.getEffectivenessSummary.mockResolvedValue(mockSummary);

            const strategy = await optimizer.optimizeStrategyForUser('user-123', mockContext);

            expect(strategy.interventionFrequency).toBe('low'); // Should reduce frequency
            expect(strategy.tonality).toBe('gentle'); // Gentle tone for low ratings
            expect(strategy.complexityLevel).toBe('simple'); // Simple messages for struggling users
        });

        it('should handle morning time preference for educational content', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.7,
                personaEffectiveness: {
                    supportive: 0.6,
                    challenging: 0.5,
                    educational: 0.8 // High educational effectiveness
                },
                averageRating: 4.0,
                responseRate: 0.7,
                recommendedPersona: 'supportive',
                adjustmentReasons: []
            };

            const mockSummary = {
                totalInteractions: 20,
                averageRating: 4.0,
                helpfulPercentage: 70,
                responseRate: 70,
                preferredPersona: 'supportive',
                lastWeekTrend: 'stable' as const
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);
            mockEffectivenessTracker.getEffectivenessSummary.mockResolvedValue(mockSummary);

            const morningContext = {
                ...mockContext,
                timeOfDay: 'morning' as const
            };

            const strategy = await optimizer.optimizeStrategyForUser('user-123', morningContext);

            expect(strategy.preferredPersona).toBe('educational'); // Should prefer educational in morning
            expect(strategy.complexityLevel).toBe('detailed'); // More detail in morning
        });

        it('should return default strategy on error', async () => {
            mockEffectivenessTracker.analyzeUserEffectiveness.mockRejectedValue(new Error('Database error'));

            const strategy = await optimizer.optimizeStrategyForUser('user-123', mockContext);

            expect(strategy.preferredPersona).toBe('supportive'); // Default for Steady state
            expect(strategy.adaptationReasons).toContain('Using default strategy - no effectiveness data available');
        });

        it('should adapt to Rising momentum state', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.6,
                personaEffectiveness: {
                    supportive: 0.5,
                    challenging: 0.8, // Challenging is more effective
                    educational: 0.6
                },
                averageRating: 3.8,
                responseRate: 0.7,
                recommendedPersona: 'supportive',
                adjustmentReasons: []
            };

            const mockSummary = {
                totalInteractions: 12,
                averageRating: 3.8,
                helpfulPercentage: 65,
                responseRate: 70,
                preferredPersona: 'supportive',
                lastWeekTrend: 'improving' as const
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);
            mockEffectivenessTracker.getEffectivenessSummary.mockResolvedValue(mockSummary);

            const risingContext = {
                ...mockContext,
                momentumState: 'Rising' as const
            };

            const strategy = await optimizer.optimizeStrategyForUser('user-123', risingContext);

            expect(strategy.preferredPersona).toBe('challenging'); // Should use challenging for Rising + high effectiveness
        });
    });

    describe('shouldUpdateStrategy', () => {
        const mockCurrentStrategy = {
            preferredPersona: 'supportive' as const,
            backupPersona: 'educational' as const,
            interventionFrequency: 'medium' as const,
            tonality: 'neutral' as const,
            complexityLevel: 'moderate' as const,
            adaptationReasons: []
        };

        it('should require update after 7 days', async () => {
            const result = await optimizer.shouldUpdateStrategy('user-123', mockCurrentStrategy, 8);

            expect(result.shouldUpdate).toBe(true);
            expect(result.reasons).toContain('Scheduled weekly strategy review');
        });

        it('should require update for low effectiveness', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.2, // Very low
                personaEffectiveness: {
                    supportive: 0.2,
                    challenging: 0.1,
                    educational: 0.3
                },
                averageRating: 2.0,
                responseRate: 0.15,
                recommendedPersona: 'educational',
                adjustmentReasons: []
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);

            const result = await optimizer.shouldUpdateStrategy('user-123', mockCurrentStrategy, 3);

            expect(result.shouldUpdate).toBe(true);
            expect(result.reasons).toContain('Low effectiveness detected - strategy adjustment needed');
        });

        it('should require update for very low response rate', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.5,
                personaEffectiveness: {
                    supportive: 0.5,
                    challenging: 0.4,
                    educational: 0.6
                },
                averageRating: 3.0,
                responseRate: 0.1, // Very low response rate
                recommendedPersona: 'educational',
                adjustmentReasons: []
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);

            const result = await optimizer.shouldUpdateStrategy('user-123', mockCurrentStrategy, 2);

            expect(result.shouldUpdate).toBe(true);
            expect(result.reasons).toContain('Very low response rate - reducing intervention frequency');
        });

        it('should require update when better persona is detected', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.7,
                personaEffectiveness: {
                    supportive: 0.5, // Current persona performance
                    challenging: 0.4,
                    educational: 0.8 // Much better performance
                },
                averageRating: 4.0,
                responseRate: 0.8,
                recommendedPersona: 'educational',
                adjustmentReasons: []
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);

            const result = await optimizer.shouldUpdateStrategy('user-123', mockCurrentStrategy, 4);

            expect(result.shouldUpdate).toBe(true);
            expect(result.reasons).toContain('Better performing persona detected: educational');
        });

        it('should not require update for stable performance', async () => {
            const mockEffectiveness = {
                overallEffectiveness: 0.7,
                personaEffectiveness: {
                    supportive: 0.7, // Current persona doing well
                    challenging: 0.6,
                    educational: 0.6
                },
                averageRating: 4.0,
                responseRate: 0.8,
                recommendedPersona: 'supportive',
                adjustmentReasons: []
            };

            mockEffectivenessTracker.analyzeUserEffectiveness.mockResolvedValue(mockEffectiveness);

            const result = await optimizer.shouldUpdateStrategy('user-123', mockCurrentStrategy, 3);

            expect(result.shouldUpdate).toBe(false);
        });

        it('should handle errors gracefully', async () => {
            mockEffectivenessTracker.analyzeUserEffectiveness.mockRejectedValue(new Error('Database error'));

            const result = await optimizer.shouldUpdateStrategy('user-123', mockCurrentStrategy, 3);

            expect(result.shouldUpdate).toBe(false);
            expect(result.reasons).toContain('Error checking strategy - maintaining current approach');
        });
    });

    describe('getDefaultStrategy', () => {
        it('should return educational persona for Rising momentum', async () => {
            const risingContext = {
                momentumState: 'Rising' as const,
                userEngagementLevel: 'medium' as const,
                timeOfDay: 'afternoon' as const,
                daysSinceLastInteraction: 1
            };

            // Use private method access for testing
            const strategy = (optimizer as any).getDefaultStrategy(risingContext);

            expect(strategy.preferredPersona).toBe('educational');
            expect(strategy.backupPersona).toBe('supportive');
            expect(strategy.adaptationReasons).toContain('Using default strategy - no effectiveness data available');
        });

        it('should return supportive persona for NeedsCare momentum', async () => {
            const needsCareContext = {
                momentumState: 'NeedsCare' as const,
                userEngagementLevel: 'low' as const,
                timeOfDay: 'evening' as const,
                daysSinceLastInteraction: 2
            };

            const strategy = (optimizer as any).getDefaultStrategy(needsCareContext);

            expect(strategy.preferredPersona).toBe('supportive');
            expect(strategy.backupPersona).toBe('supportive');
        });
    });
}); 