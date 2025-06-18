/**
 * Coaching Frequency Optimizer
 * Determines optimal coaching frequency for each user based on behavior patterns (T1.3.2.7)
 */

import { getSupabaseClient } from '../_shared/supabase_client.ts'

interface FrequencyOptimization {
  userId: string
  currentFrequency: number // interventions per day
  responseRate: number // % of interventions responded to
  satisfactionScore: number // average user rating
  recommendedFrequency: number
  adjustmentReason: string
  optimalHours: number[] // Best hours for interventions
  minHoursBetween: number // Personalized spacing
}

interface UserCoachingPreferences {
  userId: string
  maxInterventionsPerDay: number
  preferredHours: number[]
  minHoursBetween: number
  frequencyPreference: 'high' | 'medium' | 'low'
  autoOptimized: boolean
}

export class FrequencyOptimizer {
  protected supabase: any = null

  constructor(_supabaseUrl?: string, overrideKey?: string) {
    ;(async () => {
      this.supabase = await getSupabaseClient({ overrideKey })
    })()
  }

  /**
   * Get user's current coaching preferences
   */
  async getUserPreferences(userId: string): Promise<UserCoachingPreferences | null> {
    try {
      const { data, error } = await this.supabase
        .from('user_coaching_preferences')
        .select('*')
        .eq('user_id', userId)
        .single()

      if (error && error.code !== 'PGRST116') { // PGRST116 = not found
        console.error('Error fetching user preferences:', error)
        throw error
      }

      if (!data) {
        return null
      }

      return {
        userId,
        maxInterventionsPerDay: data.max_interventions_per_day,
        preferredHours: data.preferred_hours || [9, 14, 19],
        minHoursBetween: data.min_hours_between,
        frequencyPreference: data.frequency_preference,
        autoOptimized: data.auto_optimized,
      }
    } catch (error) {
      console.error('Error getting user preferences:', error)
      throw error
    }
  }

  /**
   * Create default preferences for a new user
   */
  async createDefaultPreferences(userId: string): Promise<UserCoachingPreferences> {
    try {
      const defaultPrefs = {
        user_id: userId,
        max_interventions_per_day: 3,
        preferred_hours: [9, 14, 19],
        min_hours_between: 4,
        frequency_preference: 'medium' as const,
        auto_optimized: true,
      }

      const { error } = await this.supabase
        .from('user_coaching_preferences')
        .insert(defaultPrefs)

      if (error) {
        console.error('Error creating default preferences:', error)
        throw error
      }

      return {
        userId,
        maxInterventionsPerDay: defaultPrefs.max_interventions_per_day,
        preferredHours: defaultPrefs.preferred_hours,
        minHoursBetween: defaultPrefs.min_hours_between,
        frequencyPreference: defaultPrefs.frequency_preference,
        autoOptimized: defaultPrefs.auto_optimized,
      }
    } catch (error) {
      console.error('Error creating default preferences:', error)
      throw error
    }
  }

  /**
   * Analyze user's response patterns and optimize frequency
   */
  async optimizeFrequency(userId: string, daysPeriod: number = 14): Promise<FrequencyOptimization> {
    try {
      // Get current preferences or create defaults
      let preferences = await this.getUserPreferences(userId)
      if (!preferences) {
        preferences = await this.createDefaultPreferences(userId)
      }

      // Get effectiveness data for analysis
      const cutoffDate = new Date()
      cutoffDate.setDate(cutoffDate.getDate() - daysPeriod)

      const { data: effectivenessData, error } = await this.supabase
        .from('coaching_effectiveness')
        .select('*')
        .eq('user_id', userId)
        .gte('created_at', cutoffDate.toISOString())
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching effectiveness data:', error)
        throw error
      }

      // Calculate current metrics
      const totalInteractions = effectivenessData?.length || 0
      const respondedInteractions = effectivenessData?.filter((d) =>
        d.feedback_type !== 'ignored'
      ).length || 0
      const helpfulInteractions = effectivenessData?.filter((d) =>
        d.feedback_type === 'helpful'
      ).length || 0
      const ratedInteractions = effectivenessData?.filter((d) => d.user_rating !== null) || []

      const currentFrequency = preferences.maxInterventionsPerDay
      const responseRate = totalInteractions > 0 ? respondedInteractions / totalInteractions : 0
      const helpfulRate = totalInteractions > 0 ? helpfulInteractions / totalInteractions : 0
      const averageRating = ratedInteractions.length > 0
        ? ratedInteractions.reduce((sum, d) => sum + (d.user_rating || 0), 0) /
          ratedInteractions.length
        : 3.0

      const satisfactionScore = (averageRating / 5.0) * 0.6 + helpfulRate * 0.4

      // Determine optimal frequency based on user behavior
      let recommendedFrequency = currentFrequency
      let adjustmentReason = 'Current frequency maintained'

      // High engagement users can handle more coaching
      if (responseRate > 0.8 && satisfactionScore > 0.7 && currentFrequency < 5) {
        recommendedFrequency = Math.min(currentFrequency + 1, 5)
        adjustmentReason = 'High engagement detected - increasing frequency'
      } // Low engagement users need reduced frequency
      else if (responseRate < 0.3 || satisfactionScore < 0.3) {
        recommendedFrequency = Math.max(currentFrequency - 1, 1)
        adjustmentReason = 'Low engagement detected - reducing frequency'
      } // Moderate engagement with poor satisfaction
      else if (responseRate > 0.5 && satisfactionScore < 0.5) {
        // Don't change frequency but adjust timing
        adjustmentReason = 'Adjusting timing rather than frequency'
      } // Very responsive users who are overwhelmed
      else if (responseRate > 0.9 && averageRating < 2.5) {
        recommendedFrequency = Math.max(currentFrequency - 1, 1)
        adjustmentReason = 'User responsive but ratings low - reducing frequency'
      }

      // Optimize timing based on user patterns
      const optimalHours = await this.optimizeInterventionTiming(userId, daysPeriod)

      // Adjust spacing based on response patterns
      let minHoursBetween = preferences.minHoursBetween
      if (responseRate < 0.4) {
        minHoursBetween = Math.min(minHoursBetween + 2, 8) // More space for low responders
      } else if (responseRate > 0.8 && satisfactionScore > 0.7) {
        minHoursBetween = Math.max(minHoursBetween - 1, 2) // Less space for engaged users
      }

      return {
        userId,
        currentFrequency,
        responseRate,
        satisfactionScore,
        recommendedFrequency,
        adjustmentReason,
        optimalHours,
        minHoursBetween,
      }
    } catch (error) {
      console.error('Error optimizing frequency:', error)
      throw error
    }
  }

  /**
   * Analyze user engagement patterns to determine optimal intervention hours
   */
  private async optimizeInterventionTiming(userId: string, daysPeriod: number): Promise<number[]> {
    try {
      // Get conversation logs to analyze timing patterns
      const cutoffDate = new Date()
      cutoffDate.setDate(cutoffDate.getDate() - daysPeriod)

      const { data: conversations, error } = await this.supabase
        .from('conversation_logs')
        .select('created_at, message_type')
        .eq('user_id', userId)
        .eq('message_type', 'user')
        .gte('created_at', cutoffDate.toISOString())

      if (error) {
        console.error('Error fetching conversation data:', error)
        // Return default hours if we can't fetch data
        return [9, 14, 19]
      }

      if (!conversations || conversations.length < 5) {
        // Not enough data, return default hours
        return [9, 14, 19]
      }

      // Count user responses by hour
      const hourCounts: Record<number, number> = {}
      conversations.forEach((conv) => {
        const hour = new Date(conv.created_at).getHours()
        hourCounts[hour] = (hourCounts[hour] || 0) + 1
      })

      // Find top 3 most active hours
      const sortedHours = Object.entries(hourCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([hour]) => parseInt(hour))

      // Ensure we have at least 3 hours with reasonable spacing
      const optimalHours = this.ensureReasonableSpacing(sortedHours)

      return optimalHours.length >= 3 ? optimalHours : [9, 14, 19]
    } catch (error) {
      console.error('Error optimizing timing:', error)
      return [9, 14, 19] // Default fallback
    }
  }

  /**
   * Ensure hours are reasonably spaced (at least 3 hours apart)
   */
  private ensureReasonableSpacing(hours: number[]): number[] {
    if (hours.length < 2) return hours

    const sortedHours = [...hours].sort((a, b) => a - b)
    const spacedHours = [sortedHours[0]]

    for (let i = 1; i < sortedHours.length; i++) {
      const currentHour = sortedHours[i]
      const lastHour = spacedHours[spacedHours.length - 1]

      if (currentHour - lastHour >= 3) {
        spacedHours.push(currentHour)
      }
    }

    return spacedHours
  }

  /**
   * Update user preferences with optimized settings
   */
  async updateUserPreferences(
    userId: string,
    optimization: FrequencyOptimization,
    forceUpdate: boolean = false,
  ): Promise<void> {
    try {
      const preferences = await this.getUserPreferences(userId)

      // Only update if auto-optimization is enabled or forced
      if (!preferences?.autoOptimized && !forceUpdate) {
        console.log('Auto-optimization disabled for user, skipping update')
        return
      }

      const updates = {
        max_interventions_per_day: optimization.recommendedFrequency,
        preferred_hours: optimization.optimalHours,
        min_hours_between: optimization.minHoursBetween,
        updated_at: new Date().toISOString(),
      }

      const { error } = await this.supabase
        .from('user_coaching_preferences')
        .update(updates)
        .eq('user_id', userId)

      if (error) {
        console.error('Error updating user preferences:', error)
        throw error
      }

      console.log(
        `Updated coaching preferences for user ${userId}: ${optimization.adjustmentReason}`,
      )
    } catch (error) {
      console.error('Error updating user preferences:', error)
      throw error
    }
  }

  /**
   * Get optimal coaching frequency for a user (used by intervention triggers)
   */
  async getOptimalFrequency(userId: string): Promise<{
    maxPerDay: number
    minHoursBetween: number
    preferredHours: number[]
  }> {
    try {
      const preferences = await this.getUserPreferences(userId)

      if (!preferences) {
        // Create defaults for new user
        const newPrefs = await this.createDefaultPreferences(userId)
        return {
          maxPerDay: newPrefs.maxInterventionsPerDay,
          minHoursBetween: newPrefs.minHoursBetween,
          preferredHours: newPrefs.preferredHours,
        }
      }

      return {
        maxPerDay: preferences.maxInterventionsPerDay,
        minHoursBetween: preferences.minHoursBetween,
        preferredHours: preferences.preferredHours,
      }
    } catch (error) {
      console.error('Error getting optimal frequency:', error)
      // Return safe defaults on error
      return {
        maxPerDay: 3,
        minHoursBetween: 4,
        preferredHours: [9, 14, 19],
      }
    }
  }

  /**
   * Run frequency optimization for a user and apply the results
   */
  async runOptimization(userId: string): Promise<FrequencyOptimization> {
    try {
      const optimization = await this.optimizeFrequency(userId)

      // Apply the optimization if it differs from current settings
      if (optimization.recommendedFrequency !== optimization.currentFrequency) {
        await this.updateUserPreferences(userId, optimization)
      }

      return optimization
    } catch (error) {
      console.error('Error running frequency optimization:', error)
      throw error
    }
  }
}
