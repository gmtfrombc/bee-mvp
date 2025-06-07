/**
 * Test suite for EffectivenessTracker
 * Tests coaching effectiveness measurement and adjustment functionality
 */

import { EffectivenessTracker } from '../../../functions/ai-coaching-engine/personalization/effectiveness-tracker.ts';

// Mock Supabase client
const mockSupabase = {
    from: jest.fn(() => ({
        insert: jest.fn(() => ({ error: null })),
        select: jest.fn(() => ({
            eq: jest.fn(() => ({
                gte: jest.fn(() => ({
                    order: jest.fn(() => ({ data: [], error: null }))
                })),
                single: jest.fn(() => ({ data: { id: 'test-id' }, error: null }))
            })),
            count: jest.fn(() => ({ data: [], error: null }))
        })),
        update: jest.fn(() => ({
            eq: jest.fn(() => ({ error: null }))
        }))
    }))
};

// Mock createClient
jest.mock('https://esm.sh/@supabase/supabase-js@2.38.4', () => ({
    createClient: jest.fn(() => mockSupabase)
}));

describe('EffectivenessTracker', () => {
    let tracker: EffectivenessTracker;

    beforeEach(() => {
        tracker = new EffectivenessTracker('test-url', 'test-key');
        jest.clearAllMocks();
    });

    describe('recordInteractionEffectiveness', () => {
        it('should record effectiveness metrics successfully', async () => {
            const metrics = {
                userId: 'user-123',
                conversationLogId: 'conv-456',
                feedbackType: 'helpful' as const,
                userRating: 4,
                responseTimeSeconds: 30,
                personaUsed: 'supportive' as const,
                interventionTrigger: 'user_message',
                momentumState: 'Steady' as const
            };

            await tracker.recordInteractionEffectiveness(metrics);

            expect(mockSupabase.from).toHaveBeenCalledWith('coaching_effectiveness');
            expect(mockSupabase.from().insert).toHaveBeenCalledWith({
                user_id: 'user-123',
                conversation_log_id: 'conv-456',
                feedback_type: 'helpful',
                user_rating: 4,
                response_time_seconds: 30,
                persona_used: 'supportive',
                intervention_trigger: 'user_message',
                momentum_state: 'Steady'
            });
        });

        it('should handle database errors gracefully', async () => {
            const mockError = new Error('Database error');
            mockSupabase.from.mockReturnValueOnce({
                insert: jest.fn(() => ({ error: mockError }))
            });

            const metrics = {
                userId: 'user-123',
                conversationLogId: 'conv-456',
                feedbackType: 'helpful' as const
            };

            await expect(tracker.recordInteractionEffectiveness(metrics))
                .rejects.toThrow('Database error');
        });
    });

    describe('analyzeUserEffectiveness', () => {
        it('should return default analysis for new users with no data', async () => {
            mockSupabase.from.mockReturnValueOnce({
                select: jest.fn(() => ({
                    eq: jest.fn(() => ({
                        gte: jest.fn(() => ({
                            order: jest.fn(() => ({ data: [], error: null }))
                        }))
                    }))
                }))
            });

            const analysis = await tracker.analyzeUserEffectiveness('user-123', 7);

            expect(analysis).toEqual({
                overallEffectiveness: 0.5,
                personaEffectiveness: {
                    supportive: 0.5,
                    challenging: 0.5,
                    educational: 0.5
                },
                averageRating: 3.0,
                responseRate: 0.0,
                recommendedPersona: 'supportive',
                adjustmentReasons: ['No effectiveness data available - using default supportive persona']
            });
        });

        it('should calculate effectiveness metrics correctly with real data', async () => {
            const mockData = [
                {
                    user_rating: 4,
                    feedback_type: 'helpful',
                    persona_used: 'supportive'
                },
                {
                    user_rating: 5,
                    feedback_type: 'helpful',
                    persona_used: 'supportive'
                },
                {
                    user_rating: 3,
                    feedback_type: 'not_helpful',
                    persona_used: 'challenging'
                },
                {
                    user_rating: null,
                    feedback_type: 'ignored',
                    persona_used: 'educational'
                }
            ];

            mockSupabase.from.mockReturnValueOnce({
                select: jest.fn(() => ({
                    eq: jest.fn(() => ({
                        gte: jest.fn(() => ({
                            order: jest.fn(() => ({ data: mockData, error: null }))
                        }))
                    }))
                }))
            });

            const analysis = await tracker.analyzeUserEffectiveness('user-123', 7);

            expect(analysis.averageRating).toBe(4.0); // (4+5+3)/3
            expect(analysis.responseRate).toBe(0.75); // 3 responded out of 4 total
            expect(analysis.recommendedPersona).toBe('supportive');
            expect(analysis.personaEffectiveness.supportive).toBeGreaterThan(0.8); // 2 helpful out of 2
        });

        it('should generate appropriate adjustment reasons', async () => {
            const mockData = [
                {
                    user_rating: 2,
                    feedback_type: 'not_helpful',
                    persona_used: 'challenging'
                }
            ];

            mockSupabase.from.mockReturnValueOnce({
                select: jest.fn(() => ({
                    eq: jest.fn(() => ({
                        gte: jest.fn(() => ({
                            order: jest.fn(() => ({ data: mockData, error: null }))
                        }))
                    }))
                }))
            });

            const analysis = await tracker.analyzeUserEffectiveness('user-123', 7);

            expect(analysis.adjustmentReasons).toContain('Low user ratings - adjust coaching approach');
        });
    });

    describe('recordUserFeedback', () => {
        it('should update existing effectiveness record', async () => {
            // Mock finding existing record
            mockSupabase.from.mockReturnValueOnce({
                select: jest.fn(() => ({
                    eq: jest.fn(() => ({
                        eq: jest.fn(() => ({
                            single: jest.fn(() => ({ data: { id: 'existing-id' }, error: null }))
                        }))
                    }))
                }))
            }).mockReturnValueOnce({
                update: jest.fn(() => ({
                    eq: jest.fn(() => ({ error: null }))
                }))
            });

            await tracker.recordUserFeedback('user-123', 'conv-456', 'helpful');

            expect(mockSupabase.from().update).toHaveBeenCalledWith({ feedback_type: 'helpful' });
        });

        it('should create new record if none exists', async () => {
            // Mock no existing record found
            mockSupabase.from.mockReturnValueOnce({
                select: jest.fn(() => ({
                    eq: jest.fn(() => ({
                        eq: jest.fn(() => ({
                            single: jest.fn(() => ({ data: null, error: { code: 'PGRST116' } }))
                        }))
                    }))
                }))
            }).mockReturnValueOnce({
                insert: jest.fn(() => ({ error: null }))
            });

            await tracker.recordUserFeedback('user-123', 'conv-456', 'not_helpful');

            expect(mockSupabase.from().insert).toHaveBeenCalled();
        });
    });

    describe('recordUserRating', () => {
        it('should validate rating range', async () => {
            await expect(tracker.recordUserRating('user-123', 'conv-456', 0))
                .rejects.toThrow('Rating must be between 1 and 5');

            await expect(tracker.recordUserRating('user-123', 'conv-456', 6))
                .rejects.toThrow('Rating must be between 1 and 5');
        });

        it('should record valid rating successfully', async () => {
            // Mock no existing record
            mockSupabase.from.mockReturnValueOnce({
                select: jest.fn(() => ({
                    eq: jest.fn(() => ({
                        eq: jest.fn(() => ({
                            single: jest.fn(() => ({ data: null, error: { code: 'PGRST116' } }))
                        }))
                    }))
                }))
            }).mockReturnValueOnce({
                insert: jest.fn(() => ({ error: null }))
            });

            await tracker.recordUserRating('user-123', 'conv-456', 4);

            expect(mockSupabase.from().insert).toHaveBeenCalled();
        });
    });

    describe('getEffectivenessSummary', () => {
        it('should return comprehensive summary', async () => {
            // Mock analyzeUserEffectiveness calls
            const currentAnalysis = {
                overallEffectiveness: 0.8,
                personaEffectiveness: { supportive: 0.8, challenging: 0.6, educational: 0.7 },
                averageRating: 4.2,
                responseRate: 0.85,
                recommendedPersona: 'supportive',
                adjustmentReasons: []
            };

            const previousAnalysis = {
                overallEffectiveness: 0.7,
                personaEffectiveness: { supportive: 0.7, challenging: 0.6, educational: 0.6 },
                averageRating: 3.8,
                responseRate: 0.8,
                recommendedPersona: 'supportive',
                adjustmentReasons: []
            };

            // Mock database calls
            mockSupabase.from
                .mockReturnValueOnce({
                    select: jest.fn(() => ({
                        eq: jest.fn(() => ({
                            gte: jest.fn(() => ({
                                order: jest.fn(() => ({ data: [{}], error: null }))
                            }))
                        }))
                    }))
                })
                .mockReturnValueOnce({
                    select: jest.fn(() => ({
                        eq: jest.fn(() => ({
                            gte: jest.fn(() => ({
                                order: jest.fn(() => ({ data: [{}], error: null }))
                            }))
                        }))
                    }))
                })
                .mockReturnValueOnce({
                    select: jest.fn(() => ({
                        eq: jest.fn(() => ({ data: [{}, {}, {}], error: null }))
                    }))
                });

            // Mock the analyzeUserEffectiveness method
            jest.spyOn(tracker, 'analyzeUserEffectiveness')
                .mockResolvedValueOnce(currentAnalysis)
                .mockResolvedValueOnce(previousAnalysis);

            const summary = await tracker.getEffectivenessSummary('user-123');

            expect(summary.totalInteractions).toBe(3);
            expect(summary.averageRating).toBe(4.2);
            expect(summary.preferredPersona).toBe('supportive');
            expect(summary.lastWeekTrend).toBe('improving'); // 0.8 > 0.7 + 0.1
        });
    });
}); 