/**
 * Coaching Effectiveness Tracker
 * Tracks coaching interaction outcomes and user satisfaction for T1.3.2.6
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';

interface EffectivenessMetrics {
    userId: string;
    conversationLogId: string;
    feedbackType?: 'helpful' | 'not_helpful' | 'ignored';
    userRating?: number; // 1-5 scale
    responseTimeSeconds?: number;
    personaUsed?: 'supportive' | 'challenging' | 'educational';
    interventionTrigger?: string;
    momentumState?: 'Rising' | 'Steady' | 'NeedsCare';
}

interface EffectivenessAnalysis {
    overallEffectiveness: number; // 0-1 score
    personaEffectiveness: Record<string, number>;
    averageRating: number;
    responseRate: number;
    recommendedPersona: string;
    adjustmentReasons: string[];
}

export class EffectivenessTracker {
    private supabase;

    constructor(supabaseUrl: string, supabaseKey: string) {
        this.supabase = createClient(supabaseUrl, supabaseKey);
    }

    /**
     * Record effectiveness metrics for a coaching interaction
     */
    async recordInteractionEffectiveness(metrics: EffectivenessMetrics): Promise<void> {
        try {
            const { error } = await this.supabase
                .from('coaching_effectiveness')
                .insert({
                    user_id: metrics.userId,
                    conversation_log_id: metrics.conversationLogId,
                    feedback_type: metrics.feedbackType,
                    user_rating: metrics.userRating,
                    response_time_seconds: metrics.responseTimeSeconds,
                    persona_used: metrics.personaUsed,
                    intervention_trigger: metrics.interventionTrigger,
                    momentum_state: metrics.momentumState,
                });

            if (error) {
                console.error('Error recording effectiveness metrics:', error);
                throw error;
            }

            console.log('Effectiveness metrics recorded successfully');
        } catch (error) {
            console.error('Failed to record effectiveness metrics:', error);
            throw error;
        }
    }

    /**
     * Analyze coaching effectiveness for a user over the past period
     */
    async analyzeUserEffectiveness(
        userId: string,
        daysPeriod: number = 7
    ): Promise<EffectivenessAnalysis> {
        try {
            const cutoffDate = new Date();
            cutoffDate.setDate(cutoffDate.getDate() - daysPeriod);

            // Get effectiveness data for the period
            const { data: effectivenessData, error } = await this.supabase
                .from('coaching_effectiveness')
                .select('*')
                .eq('user_id', userId)
                .gte('created_at', cutoffDate.toISOString())
                .order('created_at', { ascending: false });

            if (error) {
                console.error('Error fetching effectiveness data:', error);
                throw error;
            }

            if (!effectivenessData || effectivenessData.length === 0) {
                // Return default analysis for new users
                return {
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
                };
            }

            // Calculate metrics
            const totalInteractions = effectivenessData.length;
            const ratedInteractions = effectivenessData.filter(d => d.user_rating !== null);
            const helpfulInteractions = effectivenessData.filter(d => d.feedback_type === 'helpful');
            const respondedInteractions = effectivenessData.filter(d => d.feedback_type !== 'ignored');

            // Overall effectiveness (combination of ratings and helpful feedback)
            const averageRating = ratedInteractions.length > 0
                ? ratedInteractions.reduce((sum, d) => sum + (d.user_rating || 0), 0) / ratedInteractions.length
                : 3.0;

            const helpfulRate = totalInteractions > 0
                ? helpfulInteractions.length / totalInteractions
                : 0;

            const responseRate = totalInteractions > 0
                ? respondedInteractions.length / totalInteractions
                : 0;

            const overallEffectiveness = (averageRating / 5.0) * 0.6 + helpfulRate * 0.4;

            // Persona effectiveness analysis
            const personaEffectiveness: Record<string, number> = {};
            const personas = ['supportive', 'challenging', 'educational'];

            personas.forEach(persona => {
                const personaData = effectivenessData.filter(d => d.persona_used === persona);
                if (personaData.length > 0) {
                    const personaRatings = personaData.filter(d => d.user_rating !== null);
                    const personaHelpful = personaData.filter(d => d.feedback_type === 'helpful');

                    const avgRating = personaRatings.length > 0
                        ? personaRatings.reduce((sum, d) => sum + (d.user_rating || 0), 0) / personaRatings.length
                        : 3.0;

                    const helpfulRate = personaData.length > 0
                        ? personaHelpful.length / personaData.length
                        : 0;

                    personaEffectiveness[persona] = (avgRating / 5.0) * 0.6 + helpfulRate * 0.4;
                } else {
                    personaEffectiveness[persona] = 0.5; // Default for unused personas
                }
            });

            // Recommend best performing persona
            const recommendedPersona = Object.entries(personaEffectiveness)
                .reduce((best, [persona, score]) =>
                    score > personaEffectiveness[best] ? persona : best
                    , 'supportive');

            // Generate adjustment reasons
            const adjustmentReasons: string[] = [];

            if (overallEffectiveness < 0.4) {
                adjustmentReasons.push('Low overall effectiveness - consider persona change');
            }

            if (responseRate < 0.3) {
                adjustmentReasons.push('Low response rate - reduce coaching frequency');
            }

            if (averageRating < 2.5) {
                adjustmentReasons.push('Low user ratings - adjust coaching approach');
            }

            const bestPersonaScore = personaEffectiveness[recommendedPersona];
            if (bestPersonaScore > 0.7) {
                adjustmentReasons.push(`${recommendedPersona} persona performing well - continue using`);
            } else if (bestPersonaScore < 0.4) {
                adjustmentReasons.push('All personas performing poorly - review intervention strategies');
            }

            return {
                overallEffectiveness,
                personaEffectiveness,
                averageRating,
                responseRate,
                recommendedPersona,
                adjustmentReasons
            };

        } catch (error) {
            console.error('Error analyzing user effectiveness:', error);
            throw error;
        }
    }

    /**
     * Record user feedback (helpful/not helpful) for a coaching interaction
     */
    async recordUserFeedback(
        userId: string,
        conversationLogId: string,
        feedbackType: 'helpful' | 'not_helpful'
    ): Promise<void> {
        try {
            // First check if effectiveness record exists
            const { data: existing, error: fetchError } = await this.supabase
                .from('coaching_effectiveness')
                .select('id')
                .eq('user_id', userId)
                .eq('conversation_log_id', conversationLogId)
                .single();

            if (fetchError && fetchError.code !== 'PGRST116') {
                throw fetchError;
            }

            if (existing) {
                // Update existing record
                const { error } = await this.supabase
                    .from('coaching_effectiveness')
                    .update({ feedback_type: feedbackType })
                    .eq('id', existing.id);

                if (error) throw error;
            } else {
                // Create new record
                await this.recordInteractionEffectiveness({
                    userId,
                    conversationLogId,
                    feedbackType
                });
            }

            console.log(`User feedback recorded: ${feedbackType}`);
        } catch (error) {
            console.error('Error recording user feedback:', error);
            throw error;
        }
    }

    /**
     * Record user rating (1-5 scale) for a coaching interaction
     */
    async recordUserRating(
        userId: string,
        conversationLogId: string,
        rating: number
    ): Promise<void> {
        if (rating < 1 || rating > 5) {
            throw new Error('Rating must be between 1 and 5');
        }

        try {
            // First check if effectiveness record exists
            const { data: existing, error: fetchError } = await this.supabase
                .from('coaching_effectiveness')
                .select('id')
                .eq('user_id', userId)
                .eq('conversation_log_id', conversationLogId)
                .single();

            if (fetchError && fetchError.code !== 'PGRST116') {
                throw fetchError;
            }

            if (existing) {
                // Update existing record
                const { error } = await this.supabase
                    .from('coaching_effectiveness')
                    .update({ user_rating: rating })
                    .eq('id', existing.id);

                if (error) throw error;
            } else {
                // Create new record
                await this.recordInteractionEffectiveness({
                    userId,
                    conversationLogId,
                    userRating: rating
                });
            }

            console.log(`User rating recorded: ${rating}/5`);
        } catch (error) {
            console.error('Error recording user rating:', error);
            throw error;
        }
    }

    /**
     * Get effectiveness summary for dashboard/monitoring
     */
    async getEffectivenessSummary(userId: string): Promise<{
        totalInteractions: number;
        averageRating: number;
        helpfulPercentage: number;
        responseRate: number;
        preferredPersona: string;
        lastWeekTrend: 'improving' | 'declining' | 'stable';
    }> {
        try {
            const currentAnalysis = await this.analyzeUserEffectiveness(userId, 7);
            const previousAnalysis = await this.analyzeUserEffectiveness(userId, 14);

            // Get total interactions count
            const { data: totalData, error } = await this.supabase
                .from('coaching_effectiveness')
                .select('id', { count: 'exact' })
                .eq('user_id', userId);

            if (error) throw error;

            const totalInteractions = totalData?.length || 0;

            // Calculate trend
            let lastWeekTrend: 'improving' | 'declining' | 'stable' = 'stable';
            const effectivenessDiff = currentAnalysis.overallEffectiveness - previousAnalysis.overallEffectiveness;

            if (effectivenessDiff > 0.1) {
                lastWeekTrend = 'improving';
            } else if (effectivenessDiff < -0.1) {
                lastWeekTrend = 'declining';
            }

            return {
                totalInteractions,
                averageRating: currentAnalysis.averageRating,
                helpfulPercentage: Math.round(
                    (Object.values(currentAnalysis.personaEffectiveness).reduce((sum, v) => sum + v, 0) / 3) * 100
                ),
                responseRate: Math.round(currentAnalysis.responseRate * 100),
                preferredPersona: currentAnalysis.recommendedPersona,
                lastWeekTrend
            };

        } catch (error) {
            console.error('Error getting effectiveness summary:', error);
            throw error;
        }
    }
} 