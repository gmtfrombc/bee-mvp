// deno-lint-ignore-file no-explicit-any

/**
 * Coaching Strategy Optimizer
 * Adjusts coaching personas and intervention timing based on effectiveness data
 * Part of T1.3.2.6 effectiveness measurement and adjustment system
 */

import { EffectivenessTracker } from './effectiveness-tracker.ts'

interface CoachingStrategy {
  preferredPersona: 'supportive' | 'challenging' | 'educational'
  backupPersona: 'supportive' | 'challenging' | 'educational'
  interventionFrequency: 'high' | 'medium' | 'low'
  tonality: 'gentle' | 'neutral' | 'direct'
  complexityLevel: 'simple' | 'moderate' | 'detailed'
  adaptationReasons: string[]
}

interface OptimizationContext {
  momentumState: 'Rising' | 'Steady' | 'NeedsCare'
  userEngagementLevel: 'high' | 'medium' | 'low'
  timeOfDay: 'morning' | 'afternoon' | 'evening'
  daysSinceLastInteraction: number
}

export class StrategyOptimizer {
  private effectivenessTracker: EffectivenessTracker

  constructor(effectivenessTracker: EffectivenessTracker) {
    this.effectivenessTracker = effectivenessTracker
  }

  /**
   * Get optimized coaching strategy for a user based on their effectiveness history
   */
  async optimizeStrategyForUser(
    userId: string,
    context: OptimizationContext,
  ): Promise<CoachingStrategy> {
    try {
      // Get user's effectiveness analysis
      const effectiveness = await this.effectivenessTracker.analyzeUserEffectiveness(userId, 14)

      // Get recent summary for additional context
      const summary = await this.effectivenessTracker.getEffectivenessSummary(userId)

      // Determine preferred persona based on effectiveness data
      const preferredPersona = this.selectOptimalPersona(effectiveness, context)

      // Determine backup persona (next best performing)
      const backupPersona = this.selectBackupPersona(effectiveness, preferredPersona)

      // Adjust intervention frequency based on response rates and trends
      const interventionFrequency = this.optimizeInterventionFrequency(
        effectiveness,
        summary,
        context,
      )

      // Determine tonality based on effectiveness and momentum
      const tonality = this.optimizeTonality(effectiveness, context)

      // Set complexity level based on user engagement patterns
      const complexityLevel = this.optimizeComplexity(effectiveness, summary, context)

      // Generate adaptation reasons for transparency
      const adaptationReasons = this.generateAdaptationReasons(
        effectiveness,
        summary,
        context,
        preferredPersona,
        interventionFrequency,
      )

      return {
        preferredPersona,
        backupPersona,
        interventionFrequency,
        tonality,
        complexityLevel,
        adaptationReasons,
      }
    } catch (error) {
      console.error('Error optimizing strategy for user:', error)

      // Return safe default strategy on error
      return this.getDefaultStrategy(context)
    }
  }

  /**
   * Select optimal persona based on effectiveness data and context
   */
  private selectOptimalPersona(
    effectiveness: any,
    context: OptimizationContext,
  ): 'supportive' | 'challenging' | 'educational' {
    const { personaEffectiveness, recommendedPersona } = effectiveness

    // Use effectiveness data as primary signal
    let selectedPersona = recommendedPersona

    // Context-based adjustments
    if (context.momentumState === 'NeedsCare') {
      // For users needing care, favor supportive approach
      if (personaEffectiveness.supportive >= 0.5) {
        selectedPersona = 'supportive'
      }
    } else if (context.momentumState === 'Rising') {
      // For rising momentum, challenging persona might be more effective
      if (personaEffectiveness.challenging > personaEffectiveness.supportive) {
        selectedPersona = 'challenging'
      }
    }

    // Time-based adjustments
    if (context.timeOfDay === 'morning' && personaEffectiveness.educational > 0.6) {
      selectedPersona = 'educational' // People are more receptive to learning in the morning
    }

    return selectedPersona as 'supportive' | 'challenging' | 'educational'
  }

  /**
   * Select backup persona (second best option)
   */
  private selectBackupPersona(
    effectiveness: any,
    preferredPersona: string,
  ): 'supportive' | 'challenging' | 'educational' {
    const { personaEffectiveness } = effectiveness

    // Sort personas by effectiveness, excluding the preferred one
    const sortedPersonas = Object.entries(personaEffectiveness)
      .filter(([persona]) => persona !== preferredPersona)
      .sort(([, a], [, b]) => (b as number) - (a as number))

    return sortedPersonas[0]?.[0] as 'supportive' | 'challenging' | 'educational' || 'supportive'
  }

  /**
   * Optimize intervention frequency based on response patterns
   */
  private optimizeInterventionFrequency(
    effectiveness: any,
    summary: any,
    context: OptimizationContext,
  ): 'high' | 'medium' | 'low' {
    const { responseRate, overallEffectiveness } = effectiveness
    const { lastWeekTrend } = summary

    // Base frequency on response rate and effectiveness
    let frequency: 'high' | 'medium' | 'low' = 'medium'

    if (responseRate > 0.7 && overallEffectiveness > 0.6) {
      frequency = 'high' // User is very engaged and finds coaching helpful
    } else if (responseRate < 0.3 || overallEffectiveness < 0.4) {
      frequency = 'low' // User is not responding well, reduce frequency
    }

    // Adjust based on trend
    if (lastWeekTrend === 'declining' && frequency === 'high') {
      frequency = 'medium' // Reduce frequency if effectiveness is declining
    }

    // Context adjustments
    if (context.userEngagementLevel === 'low') {
      frequency = 'low' // Don't overwhelm low-engagement users
    }

    if (context.momentumState === 'NeedsCare' && effectiveness.overallEffectiveness > 0.5) {
      frequency = 'high' // Increase support for users needing care if coaching is effective
    }

    return frequency
  }

  /**
   * Optimize coaching tonality based on effectiveness and context
   */
  private optimizeTonality(
    effectiveness: any,
    context: OptimizationContext,
  ): 'gentle' | 'neutral' | 'direct' {
    const { averageRating, responseRate } = effectiveness

    // Default to neutral
    let tonality: 'gentle' | 'neutral' | 'direct' = 'neutral'

    // Adjust based on user feedback
    if (averageRating < 2.5 || responseRate < 0.3) {
      tonality = 'gentle' // User seems sensitive, use gentler approach
    } else if (averageRating > 4.0 && responseRate > 0.7) {
      tonality = 'direct' // User responds well to direct communication
    }

    // Context adjustments
    if (context.momentumState === 'NeedsCare') {
      tonality = 'gentle' // Always use gentle tone for users who need care
    }

    if (context.timeOfDay === 'evening') {
      tonality = 'gentle' // Gentler tone in the evening
    }

    return tonality
  }

  /**
   * Optimize message complexity based on user patterns
   */
  private optimizeComplexity(
    effectiveness: any,
    summary: any,
    context: OptimizationContext,
  ): 'simple' | 'moderate' | 'detailed' {
    const { averageRating, responseRate } = effectiveness
    const { totalInteractions } = summary

    // Start with moderate complexity
    let complexity: 'simple' | 'moderate' | 'detailed' = 'moderate'

    // Adjust based on engagement patterns
    if (responseRate < 0.4 || averageRating < 3.0) {
      complexity = 'simple' // User struggling with current approach, simplify
    } else if (responseRate > 0.8 && averageRating > 4.0 && totalInteractions > 20) {
      complexity = 'detailed' // Highly engaged user, can handle more detail
    }

    // Context adjustments
    if (context.userEngagementLevel === 'low') {
      complexity = 'simple'
    }

    if (context.timeOfDay === 'morning') {
      complexity = 'detailed' // People have more attention in the morning
    }

    return complexity
  }

  /**
   * Generate explanation for why strategy was adapted
   */
  private generateAdaptationReasons(
    effectiveness: any,
    summary: any,
    context: OptimizationContext,
    selectedPersona: string,
    frequency: string,
  ): string[] {
    const reasons: string[] = []

    // Persona selection reasons
    if (effectiveness.personaEffectiveness[selectedPersona] > 0.7) {
      reasons.push(
        `Using ${selectedPersona} persona - high effectiveness score (${
          Math.round(effectiveness.personaEffectiveness[selectedPersona] * 100)
        }%)`,
      )
    } else if (effectiveness.overallEffectiveness < 0.4) {
      reasons.push(`Switching to ${selectedPersona} persona due to low overall effectiveness`)
    }

    // Frequency reasons
    if (frequency === 'low' && effectiveness.responseRate < 0.3) {
      reasons.push(
        `Reduced frequency due to low response rate (${
          Math.round(effectiveness.responseRate * 100)
        }%)`,
      )
    } else if (frequency === 'high' && effectiveness.overallEffectiveness > 0.7) {
      reasons.push(`Increased frequency due to high coaching effectiveness`)
    }

    // Trend-based reasons
    if (summary.lastWeekTrend === 'improving') {
      reasons.push('Maintaining current approach - effectiveness improving')
    } else if (summary.lastWeekTrend === 'declining') {
      reasons.push('Adjusting approach due to declining effectiveness')
    }

    // Context reasons
    if (context.momentumState === 'NeedsCare') {
      reasons.push('Prioritizing supportive approach for momentum recovery')
    }

    // Default reason if no specific adaptations
    if (reasons.length === 0) {
      reasons.push('Using balanced approach based on user preferences')
    }

    return reasons
  }

  /**
   * Get default strategy for new users or error cases
   */
  private getDefaultStrategy(context: OptimizationContext): CoachingStrategy {
    let defaultPersona: 'supportive' | 'challenging' | 'educational' = 'supportive'

    // Adjust default based on context
    if (context.momentumState === 'Rising') {
      defaultPersona = 'educational'
    } else if (context.momentumState === 'NeedsCare') {
      defaultPersona = 'supportive'
    }

    return {
      preferredPersona: defaultPersona,
      backupPersona: 'supportive',
      interventionFrequency: 'medium',
      tonality: 'gentle',
      complexityLevel: 'simple',
      adaptationReasons: ['Using default strategy - no effectiveness data available'],
    }
  }

  /**
   * Check if strategy should be updated based on recent performance
   */
  async shouldUpdateStrategy(
    userId: string,
    currentStrategy: CoachingStrategy,
    daysSinceLastUpdate: number,
  ): Promise<{ shouldUpdate: boolean; reasons: string[] }> {
    try {
      // Always update if it's been more than 7 days
      if (daysSinceLastUpdate > 7) {
        return {
          shouldUpdate: true,
          reasons: ['Scheduled weekly strategy review'],
        }
      }

      // Get recent effectiveness data
      const recentEffectiveness = await this.effectivenessTracker.analyzeUserEffectiveness(
        userId,
        3,
      )

      const reasons: string[] = []
      let shouldUpdate = false

      // Check for significant performance changes
      if (recentEffectiveness.overallEffectiveness < 0.3) {
        shouldUpdate = true
        reasons.push('Low effectiveness detected - strategy adjustment needed')
      }

      if (recentEffectiveness.responseRate < 0.2) {
        shouldUpdate = true
        reasons.push('Very low response rate - reducing intervention frequency')
      }

      // Check if recommended persona has changed significantly
      const currentPersonaScore =
        recentEffectiveness.personaEffectiveness[currentStrategy.preferredPersona]
      const recommendedPersona = recentEffectiveness.recommendedPersona

      if (
        recommendedPersona !== currentStrategy.preferredPersona &&
        recentEffectiveness.personaEffectiveness[recommendedPersona] > currentPersonaScore + 0.2
      ) {
        shouldUpdate = true
        reasons.push(`Better performing persona detected: ${recommendedPersona}`)
      }

      return { shouldUpdate, reasons }
    } catch (error) {
      console.error('Error checking strategy update need:', error)
      return {
        shouldUpdate: false,
        reasons: ['Error checking strategy - maintaining current approach'],
      }
    }
  }
}
