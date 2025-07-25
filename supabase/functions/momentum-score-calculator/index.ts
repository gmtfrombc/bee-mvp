/// <reference path="./types.d.ts" />

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { getSupabaseClient } from '../_shared/supabase_client.ts'
import {
  createApiError,
  createCalculationError,
  createValidationError,
  DBSupabaseClient,
  MomentumErrorHandler,
} from './error-handler.ts'

// Types for momentum calculation
interface EngagementEvent {
  id: string
  user_id: string
  event_type: string
  event_subtype?: string
  event_date: string
  event_timestamp: string
  metadata: Record<string, unknown>
  points_awarded: number
}

interface DailyEngagementScore {
  user_id: string
  score_date: string
  raw_score: number
  normalized_score: number
  final_score: number
  momentum_state: 'Rising' | 'Steady' | 'NeedsCare'
  breakdown: Record<string, unknown>
  events_count: number
  algorithm_version: string
  calculation_metadata: Record<string, unknown>
}

interface CalculationResult {
  user_id: string
  score_date: string
  success: boolean
  score?: DailyEngagementScore
  error?: string
}

// Momentum calculation configuration
const MOMENTUM_CONFIG = {
  // Exponential decay parameters
  HALF_LIFE_DAYS: 10,
  DECAY_FACTOR: Math.log(2) / 10, // ln(2) / half_life

  // Zone thresholds
  RISING_THRESHOLD: 70,
  NEEDS_CARE_THRESHOLD: 45,

  // Hysteresis buffer
  HYSTERESIS_BUFFER: 2.0,

  // Event type weights
  EVENT_WEIGHTS: {
    'lesson_completion': 15,
    'lesson_start': 5,
    'journal_entry': 10,
    'coach_interaction': 20,
    'goal_setting': 12,
    'goal_completion': 18,
    'app_session': 3,
    'streak_milestone': 25,
    'assessment_completion': 15,
    'resource_access': 5,
    'peer_interaction': 8,
    'reminder_response': 7,
    'pes_entry': 10,
  },

  // Maximum daily score caps
  MAX_DAILY_SCORE: 100,
  MAX_EVENTS_PER_TYPE: 5, // Prevent gaming the system

  // Algorithm version
  VERSION: 'v1.0',
}

// Minimal structural type for Supabase client methods used here
type DBSupabaseClientLite = DBSupabaseClient

class MomentumScoreCalculator {
  private supabase: DBSupabaseClientLite
  private errorHandler: MomentumErrorHandler

  constructor(client: DBSupabaseClientLite, errorHandler: MomentumErrorHandler) {
    this.supabase = client
    this.errorHandler = errorHandler
  }

  /**
   * Calculate momentum score with comprehensive error handling
   */
  async calculateMomentumScore(userId: string, targetDate: string): Promise<Response> {
    return await this.errorHandler.withErrorHandling(async () => {
      // Validate inputs
      const userValidation = this.errorHandler.validateUserId(userId)
      if (!userValidation.isValid) {
        const error = createValidationError(
          'Invalid user ID',
          { validation_errors: userValidation.errors },
          userId,
        )
        await this.errorHandler.logError(error)
        return this.errorHandler.createErrorResponse(error, 400)
      }

      const dateValidation = this.errorHandler.validateDate(targetDate, 'target_date')
      if (!dateValidation.isValid) {
        const error = createValidationError(
          'Invalid target date',
          { validation_errors: dateValidation.errors },
          userId,
        )
        await this.errorHandler.logError(error)
        return this.errorHandler.createErrorResponse(error, 400)
      }

      // Check rate limits
      const rateLimitCheck = await this.errorHandler.checkRateLimit(
        userId,
        'calculate_momentum_score',
        50, // 50 requests per hour
        60,
      )
      if (!rateLimitCheck.isValid) {
        const error = createApiError(
          'Rate limit exceeded',
          { rate_limit_errors: rateLimitCheck.errors },
          userId,
        )
        await this.errorHandler.logError(error)
        return this.errorHandler.createErrorResponse(error, 429)
      }

      // Sanitize inputs
      const sanitizedUserId = this.errorHandler.sanitizeInput(userId) as string
      const sanitizedDate = this.errorHandler.sanitizeInput(targetDate) as string

      try {
        // Get engagement events with validation
        const { data: events, error: eventsError } = await (this.supabase
          .from('engagement_events')
          .select('*')
          .eq('user_id', sanitizedUserId)
          .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
          .order('created_at', { ascending: false }) as unknown as {
            data: EngagementEvent[] | null
            error: Error | null
          })

        if (eventsError) {
          const error = createApiError(
            'Failed to fetch engagement events',
            { database_error: eventsError },
            userId,
          )
          await this.errorHandler.logError(error)
          return this.errorHandler.createErrorResponse(error, 500)
        }

        // Validate events data
        const eventsValidation = this.errorHandler.validateEngagementEvents(events || [])
        if (!eventsValidation.isValid) {
          const error = createValidationError(
            'Invalid engagement events data',
            { validation_errors: eventsValidation.errors },
            userId,
          )
          await this.errorHandler.logError(error)
          return this.errorHandler.createErrorResponse(error, 400)
        }

        // Calculate scores with validation
        const calculation = await this.calculateUserMomentumScore(
          sanitizedUserId,
          sanitizedDate,
        )

        // Validate calculated scores
        const scoresValidation = this.errorHandler.validateScoreValues({
          rawScore: calculation.raw_score,
          normalizedScore: calculation.normalized_score,
          finalScore: calculation.final_score,
        })

        if (!scoresValidation.isValid) {
          const error = createCalculationError(
            'Invalid calculated scores',
            {
              validation_errors: scoresValidation.errors,
              calculated_values: calculation,
            },
            userId,
          )
          await this.errorHandler.logError(error)
          return this.errorHandler.createErrorResponse(error, 500)
        }

        // Validate momentum state
        const stateValidation = this.errorHandler.validateMomentumState(calculation.momentum_state)
        if (!stateValidation.isValid) {
          const error = createCalculationError(
            'Invalid momentum state',
            {
              validation_errors: stateValidation.errors,
              calculated_state: calculation.momentum_state,
            },
            userId,
          )
          await this.errorHandler.logError(error)
          return this.errorHandler.createErrorResponse(error, 500)
        }

        // Save to database with error handling
        const { data: _savedScore, error: saveError } = await (this.supabase
          .from('daily_engagement_scores')
          .upsert({
            user_id: sanitizedUserId,
            score_date: sanitizedDate,
            raw_score: calculation.raw_score,
            normalized_score: calculation.normalized_score,
            final_score: calculation.final_score,
            momentum_state: calculation.momentum_state,
            breakdown: calculation.breakdown,
            events_count: calculation.events_count,
            calculation_metadata: {
              calculated_at: new Date().toISOString(),
              algorithm_version: '1.0',
              events_processed: events?.length || 0,
            },
          })
          .select()
          .single()) as unknown as {
            data: DailyEngagementScore | null
            error: Error | null
          }

        if (saveError) {
          const error = createApiError(
            'Failed to save momentum score',
            { database_error: saveError },
            userId,
          )
          await this.errorHandler.logError(error)
          return this.errorHandler.createErrorResponse(error, 500)
        }

        // Return successful response
        return new Response(
          JSON.stringify({
            success: true,
            data: {
              user_id: sanitizedUserId,
              score_date: sanitizedDate,
              momentum_state: calculation.momentum_state,
              final_score: calculation.final_score,
              breakdown: calculation.breakdown,
              events_count: calculation.events_count,
              calculated_at: new Date().toISOString(),
            },
            warnings: scoresValidation.warnings || [],
          }),
          {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
          },
        )
      } catch (error) {
        const momentumError = createCalculationError(
          'Momentum calculation failed',
          {
            original_error: error instanceof Error ? error.message : String(error),
            stack_trace: error instanceof Error ? error.stack : undefined,
          },
          userId,
        )
        await this.errorHandler.logError(momentumError)
        return this.errorHandler.createErrorResponse(momentumError, 500)
      }
    }, {
      functionName: 'calculate_momentum_score',
      userId,
      operationType: 'CALCULATION',
    })
  }

  /**
   * Handle batch calculation with error handling
   */
  async handleBatchCalculation(request: Request): Promise<Response> {
    try {
      const body = await request.json()

      // Validate request body
      const bodyValidation = this.errorHandler.validateRequestBody(
        body,
        ['user_ids', 'target_date'],
        ['force_recalculate', 'batch_size'],
      )

      if (!bodyValidation.isValid) {
        const error = createValidationError(
          'Invalid request body',
          { validation_errors: bodyValidation.errors },
        )
        await this.errorHandler.logError(error)
        return this.errorHandler.createErrorResponse(error, 400)
      }

      const {
        user_ids,
        target_date,
        force_recalculate: _force_recalculate = false,
        batch_size = 10,
      } = body

      // Validate user IDs array
      if (!Array.isArray(user_ids) || user_ids.length === 0) {
        const error = createValidationError(
          'user_ids must be a non-empty array',
        )
        await this.errorHandler.logError(error)
        return this.errorHandler.createErrorResponse(error, 400)
      }

      if (user_ids.length > 100) {
        const error = createValidationError(
          'Maximum 100 users per batch',
        )
        await this.errorHandler.logError(error)
        return this.errorHandler.createErrorResponse(error, 400)
      }

      // Validate each user ID
      const invalidUsers: string[] = []
      for (const userId of user_ids) {
        const validation = this.errorHandler.validateUserId(userId)
        if (!validation.isValid) {
          invalidUsers.push(userId)
        }
      }

      if (invalidUsers.length > 0) {
        const error = createValidationError(
          'Invalid user IDs found',
          { invalid_user_ids: invalidUsers },
        )
        await this.errorHandler.logError(error)
        return this.errorHandler.createErrorResponse(error, 400)
      }

      // Process batch with error tracking
      const results: unknown[] = []
      const errors: unknown[] = []

      for (let i = 0; i < user_ids.length; i += batch_size) {
        const batch = user_ids.slice(i, i + batch_size)

        const batchPromises = batch.map(async (userId: string) => {
          try {
            const response = await this.calculateMomentumScore(userId, target_date)
            const result = await response.json()

            if (result.success) {
              results.push(result.data)
            } else {
              errors.push({
                user_id: userId,
                error: result.error,
              })
            }
          } catch (error) {
            errors.push({
              user_id: userId,
              error: {
                type: 'system_error',
                message: error instanceof Error ? error.message : 'Unknown error',
              },
            })
          }
        })

        await Promise.all(batchPromises)
      }

      return new Response(
        JSON.stringify({
          success: true,
          data: {
            processed: results.length,
            failed: errors.length,
            total: user_ids.length,
            results,
            errors: errors.length > 0 ? errors : undefined,
          },
          timestamp: new Date().toISOString(),
        }),
        {
          status: 200,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    } catch (error) {
      const momentumError = createApiError(
        'Batch calculation failed',
        {
          original_error: error instanceof Error ? error.message : String(error),
        },
      )
      await this.errorHandler.logError(momentumError)
      return this.errorHandler.createErrorResponse(momentumError, 500)
    }
  }

  /**
   * Health check endpoint with error monitoring
   */
  async handleHealthCheck(): Promise<Response> {
    try {
      const health = await this.errorHandler.getSystemHealth()

      return new Response(
        JSON.stringify({
          status: health.status,
          timestamp: new Date().toISOString(),
          error_stats: {
            total_errors_last_hour: health.errors,
            critical_errors: health.criticalErrors,
            status_message: health.status === 'healthy'
              ? 'System operating normally'
              : health.status === 'degraded'
              ? 'System experiencing elevated error rates'
              : 'System experiencing critical issues',
          },
          service_info: {
            name: 'momentum-score-calculator',
            version: '1.0.0',
            uptime: Math.floor(Date.now() / 1000), // Using timestamp instead of process.uptime for Deno compatibility
          },
        }),
        {
          status: health.status === 'critical' ? 503 : 200,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    } catch (_error) {
      return new Response(
        JSON.stringify({
          status: 'critical',
          error: 'Health check failed',
          timestamp: new Date().toISOString(),
        }),
        {
          status: 503,
          headers: { 'Content-Type': 'application/json' },
        },
      )
    }
  }

  /**
   * Main request handler with routing and error handling
   */
  async handleRequest(request: Request): Promise<Response> {
    const url = new URL(request.url)
    const path = url.pathname

    try {
      // Add CORS headers
      const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      }

      if (request.method === 'OPTIONS') {
        return new Response(null, { status: 200, headers: corsHeaders })
      }

      let response: Response

      switch (path) {
        case '/calculate': {
          if (request.method !== 'POST') {
            const error = createApiError('Method not allowed')
            return this.errorHandler.createErrorResponse(error, 405)
          }

          const body = await request.json()
          response = await this.calculateMomentumScore(
            body.user_id,
            body.target_date,
          )
          break
        }

        case '/batch': {
          if (request.method !== 'POST') {
            const error = createApiError('Method not allowed')
            return this.errorHandler.createErrorResponse(error, 405)
          }

          response = await this.handleBatchCalculation(request)
          break
        }

        case '/health': {
          response = await this.handleHealthCheck()
          break
        }

        default: {
          const error = createApiError('Endpoint not found')
          return this.errorHandler.createErrorResponse(error, 404)
        }
      }

      // Add CORS headers to response
      const responseHeaders = new Headers(response.headers)
      Object.entries(corsHeaders).forEach(([key, value]) => {
        responseHeaders.set(key, value)
      })

      return new Response(response.body, {
        status: response.status,
        headers: responseHeaders,
      })
    } catch (error) {
      const momentumError = createApiError(
        'Request handling failed',
        {
          path,
          method: request.method,
          original_error: error instanceof Error ? error.message : String(error),
        },
      )
      await this.errorHandler.logError(momentumError)
      return this.errorHandler.createErrorResponse(momentumError, 500)
    }
  }

  /**
   * Calculate momentum score for a specific user and date
   */
  async calculateUserMomentumScore(
    userId: string,
    targetDate: string,
  ): Promise<DailyEngagementScore> {
    // Get engagement events for the target date
    const events = await this.getEngagementEvents(userId, targetDate)

    // Calculate raw score from events
    const rawScore = this.calculateRawScore(events)

    // Get historical scores for trend analysis
    const historicalScores = await this.getHistoricalScores(userId, targetDate, 30)

    // Apply exponential decay weighting
    const normalizedScore = this.applyExponentialDecay(rawScore, historicalScores, targetDate)

    // Determine momentum state with hysteresis
    const momentumState = this.classifyMomentumState(
      userId,
      normalizedScore,
      historicalScores,
    )

    // Create breakdown analysis
    const breakdown = this.createScoreBreakdown(events, rawScore, normalizedScore)

    // Prepare calculation metadata
    const metadata = {
      events_processed: events.length,
      raw_score: rawScore,
      decay_applied: normalizedScore !== rawScore,
      historical_days_analyzed: historicalScores.length,
      calculation_timestamp: new Date().toISOString(),
      algorithm_config: {
        half_life_days: MOMENTUM_CONFIG.HALF_LIFE_DAYS,
        rising_threshold: MOMENTUM_CONFIG.RISING_THRESHOLD,
        needs_care_threshold: MOMENTUM_CONFIG.NEEDS_CARE_THRESHOLD,
      },
    }

    return {
      user_id: userId,
      score_date: targetDate,
      raw_score: rawScore,
      normalized_score: normalizedScore,
      final_score: normalizedScore,
      momentum_state: momentumState,
      breakdown,
      events_count: events.length,
      algorithm_version: MOMENTUM_CONFIG.VERSION,
      calculation_metadata: metadata,
    }
  }

  /**
   * Get engagement events for a specific user and date
   */
  private async getEngagementEvents(userId: string, date: string): Promise<EngagementEvent[]> {
    const { data, error } = await (this.supabase
      .from('engagement_events')
      .select('*')
      .eq('user_id', userId)
      .gte('event_date', date)
      .lt('event_date', this.addDays(date, 1))
      .order('event_timestamp', { ascending: true }) as unknown as {
        data: EngagementEvent[] | null
        error: Error | null
      })

    if (error) {
      throw new Error(`Failed to fetch engagement events: ${error.message}`)
    }

    return data || []
  }

  /**
   * Calculate raw score from engagement events
   */
  private calculateRawScore(events: EngagementEvent[]): number {
    const eventTypeCounts: Record<string, number> = {}
    let totalScore = 0

    for (const event of events) {
      const eventType = event.event_type
      const weight = MOMENTUM_CONFIG.EVENT_WEIGHTS[eventType] || 1

      // Count events by type to enforce limits
      eventTypeCounts[eventType] = (eventTypeCounts[eventType] || 0) + 1

      // Only count up to max events per type to prevent gaming
      if (eventTypeCounts[eventType] <= MOMENTUM_CONFIG.MAX_EVENTS_PER_TYPE) {
        totalScore += weight
      }
    }

    // Apply daily score cap
    return Math.min(totalScore, MOMENTUM_CONFIG.MAX_DAILY_SCORE)
  }

  /**
   * Get historical scores for trend analysis
   */
  private async getHistoricalScores(
    userId: string,
    beforeDate: string,
    days: number,
  ): Promise<DailyEngagementScore[]> {
    const startDate = this.addDays(beforeDate, -days)

    const { data, error } = await (this.supabase
      .from('daily_engagement_scores')
      .select('*')
      .eq('user_id', userId)
      .gte('score_date', startDate)
      .lt('score_date', beforeDate)
      .order('score_date', { ascending: false }) as unknown as {
        data: DailyEngagementScore[] | null
        error: Error | null
      })

    if (error) {
      throw new Error(`Failed to fetch historical scores: ${error.message}`)
    }

    return data || []
  }

  /**
   * Apply exponential decay weighting based on historical performance
   */
  private applyExponentialDecay(
    rawScore: number,
    historicalScores: DailyEngagementScore[],
    targetDate: string,
  ): number {
    if (historicalScores.length === 0) {
      return rawScore // No history, return raw score
    }

    let weightedSum = rawScore // Today's score with weight 1.0
    let totalWeight = 1.0

    for (const historicalScore of historicalScores) {
      const daysDiff = this.daysBetween(historicalScore.score_date, targetDate)
      const weight = Math.exp(-MOMENTUM_CONFIG.DECAY_FACTOR * daysDiff)

      weightedSum += historicalScore.final_score * weight
      totalWeight += weight
    }

    const decayAdjustedScore = weightedSum / totalWeight

    // Blend raw score with decay-adjusted score (70% raw, 30% historical)
    const blendedScore = (rawScore * 0.7) + (decayAdjustedScore * 0.3)

    return Math.round(blendedScore * 100) / 100 // Round to 2 decimal places
  }

  /**
   * Classify momentum state with hysteresis to prevent rapid changes
   */
  private classifyMomentumState(
    _userId: string,
    score: number,
    historicalScores: DailyEngagementScore[],
  ): 'Rising' | 'Steady' | 'NeedsCare' {
    // Get current state from most recent score
    const currentState = historicalScores.length > 0 ? historicalScores[0].momentum_state : null

    // Basic classification
    let newState: 'Rising' | 'Steady' | 'NeedsCare'
    if (score >= MOMENTUM_CONFIG.RISING_THRESHOLD) {
      newState = 'Rising'
    } else if (score >= MOMENTUM_CONFIG.NEEDS_CARE_THRESHOLD) {
      newState = 'Steady'
    } else {
      newState = 'NeedsCare'
    }

    // Apply hysteresis if we have a current state
    if (currentState) {
      const buffer = MOMENTUM_CONFIG.HYSTERESIS_BUFFER

      if (currentState === 'Rising' && score >= MOMENTUM_CONFIG.RISING_THRESHOLD - buffer) {
        newState = 'Rising'
      } else if (
        currentState === 'NeedsCare' && score <= MOMENTUM_CONFIG.NEEDS_CARE_THRESHOLD + buffer
      ) {
        newState = 'NeedsCare'
      }
    }

    return newState
  }

  /**
   * Create detailed breakdown of score calculation
   */
  private createScoreBreakdown(
    events: EngagementEvent[],
    rawScore: number,
    finalScore: number,
  ): Record<string, unknown> {
    const eventsByType: Record<string, number> = {}
    const pointsByType: Record<string, number> = {}

    for (const event of events) {
      const eventType = event.event_type
      eventsByType[eventType] = (eventsByType[eventType] || 0) + 1

      const weight = MOMENTUM_CONFIG.EVENT_WEIGHTS[eventType] || 1
      pointsByType[eventType] = (pointsByType[eventType] || 0) + weight
    }

    return {
      total_events: events.length,
      events_by_type: eventsByType,
      points_by_type: pointsByType,
      raw_score: rawScore,
      final_score: finalScore,
      decay_adjustment: finalScore - rawScore,
      top_activities: Object.entries(pointsByType)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([type, points]) => ({ type, points })),
    }
  }

  // Utility methods
  private addDays(date: string, days: number): string {
    const d = new Date(date)
    d.setDate(d.getDate() + days)
    return d.toISOString().split('T')[0]
  }

  private daysBetween(date1: string, date2: string): number {
    const d1 = new Date(date1)
    const d2 = new Date(date2)
    const diffTime = Math.abs(d2.getTime() - d1.getTime())
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  }
}

// Main handler
serve(async (request: Request) => {
  const client = await getSupabaseClient() as unknown as DBSupabaseClientLite
  const errorHandler = new MomentumErrorHandler(client)

  const calculator = new MomentumScoreCalculator(client, errorHandler)
  return await calculator.handleRequest(request)
})
