/**
 * Cross-Patient Pattern Integration Service
 * Epic 1.3.2.8: Privacy-safe pattern aggregation for cross-patient learning
 *
 * This service prepares anonymized coaching patterns for Epic 3.1 enhanced learning
 * while maintaining strict privacy controls.
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface CrossPatientPattern {
  patternType:
    | 'engagement_peak'
    | 'volatility_trend'
    | 'persona_effectiveness'
    | 'intervention_timing'
    | 'response_frequency'
  aggregatedData: {
    commonPatterns: string[]
    effectivenessScores: Record<string, number>
    recommendedApproaches: string[]
    timeDistribution?: Record<string, number>
    personaPreferences?: Record<string, number>
  }
  cohortSize: number
  confidenceLevel: number
  weeklyTimestamp: string
  momentumState?: 'Rising' | 'Steady' | 'NeedsCare'
}

export interface CrossPatientInsight {
  insightType:
    | 'optimal_timing'
    | 'effective_personas'
    | 'intervention_patterns'
    | 'engagement_trends'
  insightData: Record<string, any>
  recommendation: string
  supportingPatterns: string[]
  confidenceScore: number
  applicableWeek: string
}

export class CrossPatientPatternsService {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Aggregate coaching effectiveness patterns across users (anonymized)
   * Minimum 5 users required for privacy protection
   */
  async aggregateEffectivenessPatterns(
    weekStart: Date,
    momentumState?: 'Rising' | 'Steady' | 'NeedsCare',
  ): Promise<CrossPatientPattern | null> {
    try {
      // Query effectiveness data for the week (anonymized)
      let query = this.supabase
        .from('coaching_effectiveness')
        .select(`
          persona_used,
          feedback_type,
          user_rating,
          momentum_state,
          intervention_trigger,
          response_time_seconds
        `)
        .gte('created_at', weekStart.toISOString())
        .lt('created_at', new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString())

      if (momentumState) {
        query = query.eq('momentum_state', momentumState)
      }

      const { data: effectivenessData, error } = await query

      if (error) throw error
      if (!effectivenessData || effectivenessData.length < 5) {
        console.log('Insufficient data for privacy-safe aggregation (minimum 5 users required)')
        return null
      }

      // Calculate persona effectiveness
      const personaStats: Record<string, { helpful: number; total: number; avgRating: number }> = {}

      effectivenessData.forEach((record) => {
        if (!record.persona_used) return

        if (!personaStats[record.persona_used]) {
          personaStats[record.persona_used] = { helpful: 0, total: 0, avgRating: 0 }
        }

        personaStats[record.persona_used].total++
        if (record.feedback_type === 'helpful') {
          personaStats[record.persona_used].helpful++
        }
        if (record.user_rating) {
          personaStats[record.persona_used].avgRating += record.user_rating
        }
      })

      // Calculate effectiveness scores
      const effectivenessScores: Record<string, number> = {}
      const personaPreferences: Record<string, number> = {}

      Object.keys(personaStats).forEach((persona) => {
        const stats = personaStats[persona]
        effectivenessScores[persona] = stats.helpful / stats.total
        personaPreferences[persona] = stats.avgRating / stats.total
      })

      // Extract common intervention patterns
      const triggerCounts: Record<string, number> = {}
      effectivenessData.forEach((record) => {
        if (record.intervention_trigger) {
          triggerCounts[record.intervention_trigger] =
            (triggerCounts[record.intervention_trigger] || 0) + 1
        }
      })

      const commonPatterns = Object.entries(triggerCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 5)
        .map(([pattern]) => pattern)

      // Generate recommendations
      const bestPersona = Object.entries(effectivenessScores).reduce(
        (best, [persona, score]) => score > (effectivenessScores[best] || 0) ? persona : best,
        'supportive',
      )

      const recommendedApproaches = [
        `Use ${bestPersona} persona for optimal effectiveness`,
        `Focus on ${commonPatterns[0]} interventions`,
        `Monitor ${momentumState || 'general'} momentum state patterns`,
      ]

      return {
        patternType: 'persona_effectiveness',
        aggregatedData: {
          commonPatterns,
          effectivenessScores,
          recommendedApproaches,
          personaPreferences,
        },
        cohortSize: effectivenessData.length,
        confidenceLevel: Math.min(effectivenessData.length / 50, 1), // Higher confidence with more data
        weeklyTimestamp: weekStart.toISOString().split('T')[0],
        momentumState,
      }
    } catch (error) {
      console.error('Error aggregating effectiveness patterns:', error)
      return null
    }
  }

  /**
   * Aggregate engagement timing patterns (anonymized)
   */
  async aggregateEngagementPatterns(weekStart: Date): Promise<CrossPatientPattern | null> {
    try {
      // Query engagement events for timing analysis
      const { data: engagementData, error } = await this.supabase
        .from('engagement_events')
        .select('event_type, created_at, user_id')
        .gte('created_at', weekStart.toISOString())
        .lt('created_at', new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString())

      if (error) throw error
      if (!engagementData || engagementData.length < 5) return null

      // Count unique users for privacy check
      const uniqueUsers = new Set(engagementData.map((e) => e.user_id)).size
      if (uniqueUsers < 5) return null

      // Analyze hourly engagement patterns
      const hourlyDistribution: Record<string, number> = {}
      engagementData.forEach((event) => {
        const hour = new Date(event.created_at).getUTCHours()
        const hourKey = `${hour}:00`
        hourlyDistribution[hourKey] = (hourlyDistribution[hourKey] || 0) + 1
      })

      // Find peak engagement hours
      const peakHours = Object.entries(hourlyDistribution)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([hour]) => hour)

      const commonPatterns = [
        `Peak engagement at ${peakHours[0]}`,
        `Secondary peak at ${peakHours[1]}`,
        `Active hours: ${peakHours.join(', ')}`,
      ]

      const recommendedApproaches = [
        `Schedule interventions during ${peakHours[0]} for optimal engagement`,
        `Avoid low-activity periods for coaching`,
        `Consider timezone variations in timing`,
      ]

      return {
        patternType: 'engagement_peak',
        aggregatedData: {
          commonPatterns,
          effectivenessScores: hourlyDistribution,
          recommendedApproaches,
          timeDistribution: hourlyDistribution,
        },
        cohortSize: uniqueUsers,
        confidenceLevel: Math.min(uniqueUsers / 20, 1),
        weeklyTimestamp: weekStart.toISOString().split('T')[0],
      }
    } catch (error) {
      console.error('Error aggregating engagement patterns:', error)
      return null
    }
  }

  /**
   * Store anonymized pattern aggregate in database
   */
  async storePatternAggregate(pattern: CrossPatientPattern): Promise<string | null> {
    try {
      const { data, error } = await this.supabase
        .from('coaching_pattern_aggregates')
        .insert([{
          pattern_type: pattern.patternType,
          pattern_data: pattern.aggregatedData,
          user_count: pattern.cohortSize,
          effectiveness_score:
            Object.values(pattern.aggregatedData.effectivenessScores || {}).reduce(
                (sum, score) => sum + score,
                0,
              ) / Object.keys(pattern.aggregatedData.effectivenessScores || {}).length || 0,
          confidence_level: pattern.confidenceLevel,
          created_week: pattern.weeklyTimestamp,
          momentum_state: pattern.momentumState,
        }])
        .select('id')
        .single()

      if (error) throw error
      return data?.id || null
    } catch (error) {
      console.error('Error storing pattern aggregate:', error)
      return null
    }
  }

  /**
   * Generate cross-patient insights from pattern aggregates
   */
  async generateInsights(weekStart: Date): Promise<CrossPatientInsight[]> {
    try {
      // Query recent pattern aggregates
      const { data: patterns, error } = await this.supabase
        .from('coaching_pattern_aggregates')
        .select('*')
        .gte(
          'created_week',
          new Date(weekStart.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        )
        .order('created_at', { ascending: false })

      if (error) throw error
      if (!patterns || patterns.length === 0) return []

      const insights: CrossPatientInsight[] = []

      // Generate timing optimization insights
      const engagementPatterns = patterns.filter((p) => p.pattern_type === 'engagement_peak')
      if (engagementPatterns.length > 0) {
        const topPattern = engagementPatterns[0]
        insights.push({
          insightType: 'optimal_timing',
          insightData: topPattern.pattern_data,
          recommendation:
            `Optimize intervention timing based on ${topPattern.user_count} user patterns`,
          supportingPatterns: [topPattern.id],
          confidenceScore: topPattern.confidence_level,
          applicableWeek: weekStart.toISOString().split('T')[0],
        })
      }

      // Generate persona effectiveness insights
      const personaPatterns = patterns.filter((p) => p.pattern_type === 'persona_effectiveness')
      if (personaPatterns.length > 0) {
        const topPattern = personaPatterns[0]
        insights.push({
          insightType: 'effective_personas',
          insightData: topPattern.pattern_data,
          recommendation: `Apply persona strategies with ${
            (topPattern.effectiveness_score * 100).toFixed(1)
          }% effectiveness`,
          supportingPatterns: [topPattern.id],
          confidenceScore: topPattern.confidence_level,
          applicableWeek: weekStart.toISOString().split('T')[0],
        })
      }

      return insights
    } catch (error) {
      console.error('Error generating insights:', error)
      return []
    }
  }

  /**
   * Weekly batch process to aggregate patterns across all users
   * This is designed to be called by a scheduled function
   */
  async processWeeklyAggregation(
    weekStart?: Date,
  ): Promise<{ success: boolean; patternsCreated: number; insightsGenerated: number }> {
    const processWeek = weekStart || new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)

    try {
      let patternsCreated = 0

      // Process effectiveness patterns for each momentum state
      for (const momentumState of ['Rising', 'Steady', 'NeedsCare'] as const) {
        const pattern = await this.aggregateEffectivenessPatterns(processWeek, momentumState)
        if (pattern) {
          const patternId = await this.storePatternAggregate(pattern)
          if (patternId) patternsCreated++
        }
      }

      // Process engagement timing patterns
      const engagementPattern = await this.aggregateEngagementPatterns(processWeek)
      if (engagementPattern) {
        const patternId = await this.storePatternAggregate(engagementPattern)
        if (patternId) patternsCreated++
      }

      // Generate insights from patterns
      const insights = await this.generateInsights(processWeek)

      // Store insights
      let insightsGenerated = 0
      for (const insight of insights) {
        const { error } = await this.supabase
          .from('cross_patient_insights')
          .insert([{
            insight_type: insight.insightType,
            insight_data: insight.insightData,
            recommendation: insight.recommendation,
            supporting_patterns: insight.supportingPatterns,
            confidence_score: insight.confidenceScore,
            applicable_week: insight.applicableWeek,
          }])

        if (!error) insightsGenerated++
      }

      return {
        success: true,
        patternsCreated,
        insightsGenerated,
      }
    } catch (error) {
      console.error('Error in weekly aggregation process:', error)
      return {
        success: false,
        patternsCreated: 0,
        insightsGenerated: 0,
      }
    }
  }
}
