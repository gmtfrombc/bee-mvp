// deno-lint-ignore-file no-explicit-any

import { getSupabaseClient } from '../_shared/supabase_client.ts'
import { EngagementEvent } from '../personalization/pattern-analysis.ts'

/**
 * Fetches real user engagement events from the database
 * Transforms database format to pattern analysis format
 */
export class EngagementDataService {
  private supabase: any

  constructor() {
    const isTestingEnvironment = Deno.env.get('DENO_TESTING') === 'true'
    if (isTestingEnvironment) {
      console.log(
        '🧪 Test environment: skipping Supabase client initialization in EngagementDataService',
      )
      this.supabase = null
      return
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
      Deno.env.get('SERVICE_ROLE_KEY')

    if (supabaseUrl && supabaseServiceRoleKey) {
      // Initialize client asynchronously to avoid blocking constructor
      getSupabaseClient({ overrideKey: supabaseServiceRoleKey })
        .then((c) => {
          this.supabase = c
        })
        .catch((err) => console.error('Supabase init failed', err))
    }
  }

  /**
   * Fetches user engagement events from the last 7 days
   * @param userId The user ID to fetch events for
   * @param authToken Optional auth token for user context
   * @returns Array of engagement events formatted for pattern analysis
   */
  async getUserEngagementEvents(userId: string, authToken?: string): Promise<EngagementEvent[]> {
    try {
      // Return fallback if Supabase client is not initialized
      if (!this.supabase) {
        console.warn('Supabase client not initialized, returning fallback events')
        return this.getFallbackEvents()
      }

      // Calculate 7 days ago for rolling window analysis
      const sevenDaysAgo = new Date()
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

      // Use service role key for system queries, but validate user context
      const isTestingEnvironment = Deno.env.get('DENO_TESTING') === 'true'
      if (isTestingEnvironment) {
        console.log(
          '🧪 Test environment: returning fallback events instead of creating Supabase client',
        )
        return this.getFallbackEvents()
      }

      const supabaseUrl = Deno.env.get('SUPABASE_URL')!
      const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

      const client: any = authToken
        ? (await (async () => {
          const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
          return (createClient as any)(supabaseUrl, supabaseServiceRoleKey, {
            global: { headers: { Authorization: `Bearer ${authToken}` } },
          }) as any
        })())
        : this.supabase

      // Query engagement events for the user in the last 7 days
      const { data: events, error } = await client
        .from('engagement_events')
        .select('event_type, timestamp, value')
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .gte('timestamp', sevenDaysAgo.toISOString())
        .order('timestamp', { ascending: false })
        .limit(500) // Limit to prevent excessive data processing

      if (error) {
        console.error('Error fetching engagement events:', error)
        return this.getFallbackEvents()
      }

      if (!events || events.length === 0) {
        console.log(`No engagement events found for user ${userId} in the last 7 days`)
        return this.getFallbackEvents()
      }

      // Transform database format to pattern analysis format
      const transformedEvents: EngagementEvent[] = events
        .map((event: any) => this.transformEventFormat(event))
        .filter((event: EngagementEvent) => this.isValidEventType(event.event_type))

      console.log(`Fetched ${transformedEvents.length} engagement events for user ${userId}`)
      return transformedEvents
    } catch (error) {
      console.error('Error in getUserEngagementEvents:', error)
      return this.getFallbackEvents()
    }
  }

  /**
   * Transforms database event format to pattern analysis format
   */
  private transformEventFormat(dbEvent: any): EngagementEvent {
    return {
      event_type: this.mapEventType(dbEvent.event_type),
      timestamp: dbEvent.timestamp,
      metadata: dbEvent.value || {},
    }
  }

  /**
   * Maps database event types to pattern analysis event types
   * Some database events are aggregated into broader categories for pattern analysis
   */
  private mapEventType(dbEventType: string): 'app_session' | 'goal_completion' | 'momentum_change' {
    switch (dbEventType) {
      case 'app_open':
      case 'app_session':
      case 'mood_log':
      case 'sleep_log':
      case 'steps_import':
        return 'app_session'

      case 'goal_complete':
      case 'goal_completion':
        return 'goal_completion'

      case 'momentum_change':
        return 'momentum_change'

      default:
        // Default unknown events to app_session for pattern analysis
        return 'app_session'
    }
  }

  /**
   * Validates that the event type is supported by pattern analysis
   */
  private isValidEventType(eventType: string): boolean {
    return ['app_session', 'goal_completion', 'momentum_change'].includes(eventType)
  }

  /**
   * Provides fallback events when real data is unavailable
   * Returns minimal engagement pattern to prevent analysis failures
   */
  private getFallbackEvents(): EngagementEvent[] {
    const now = new Date()
    return [
      {
        event_type: 'app_session',
        timestamp: now.toISOString(),
        metadata: { source: 'fallback', reason: 'no_real_data_available' },
      },
    ]
  }

  /**
   * Health check method to verify database connectivity
   */
  async healthCheck(): Promise<boolean> {
    try {
      if (!this.supabase) {
        return false
      }

      const { error } = await this.supabase
        .from('engagement_events')
        .select('id')
        .limit(1)

      return !error
    } catch {
      return false
    }
  }
}

// Export singleton instance
export const engagementDataService = new EngagementDataService()
