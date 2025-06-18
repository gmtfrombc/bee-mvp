import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { getSupabaseClient } from '../_shared/supabase_client.ts';

// Firebase Admin SDK for sending push notifications
interface FCMMessage {
  token: string;
  notification: {
    title: string;
    body: string;
  };
  data?: Record<string, string>;
  android?: {
    priority: 'high' | 'normal';
    notification: {
      channel_id: string;
      priority: 'high' | 'default' | 'low' | 'min';
    };
  };
  apns?: {
    payload: {
      aps: {
        alert: {
          title: string;
          body: string;
        };
        badge?: number;
        sound?: string;
      };
    };
  };
}

interface NotificationTriggerRequest {
  user_id?: string;
  trigger_type: 'momentum_change' | 'daily_check' | 'manual' | 'batch_process';
  momentum_data?: {
    current_state: 'Rising' | 'Steady' | 'NeedsCare';
    previous_state?: 'Rising' | 'Steady' | 'NeedsCare';
    score: number;
    date: string;
  };
}

interface ProcessingResult {
  success: boolean;
  user_id: string;
  notifications_sent: number;
  interventions_created: number;
  error?: string;
}

// Insert after existing interfaces
interface MomentumScoreState {
  score_date: string;
  momentum_state: 'Rising' | 'Steady' | 'NeedsCare';
  final_score: number;
}

interface Intervention {
  type:
    | 'coach_intervention'
    | 'supportive_notification'
    | 'celebration'
    | 'daily_motivation';
  priority: 'high' | 'medium' | 'low';
  reason: string;
  action: string;
  template_key: string;
  metadata: Record<string, unknown>;
}

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

interface NotificationTemplate {
  title: string;
  message: string;
  action_type: string;
  action_data: Record<string, unknown>;
}

class PushNotificationTrigger {
  private supabase: SupabaseClient;
  private firebaseProjectId: string;
  private firebaseServerKey: string;

  constructor(
    _supabaseUrl: string,
    supabaseKey: string,
    firebaseProjectId: string,
    firebaseServerKey: string,
  ) {
    // create client lazily to avoid bundle bloat
    getSupabaseClient(supabaseKey).then((c) => {
      this.supabase = c as SupabaseClient;
    });
    this.firebaseProjectId = firebaseProjectId;
    this.firebaseServerKey = firebaseServerKey;
  }

  /**
   * Process notification triggers for a specific user or all users
   */
  async processTriggers(request: NotificationTriggerRequest): Promise<ProcessingResult[]> {
    const results: ProcessingResult[] = [];

    try {
      if (request.user_id) {
        // Process single user
        const result = await this.processUserTriggers(request.user_id, request);
        results.push(result);
      } else if (request.trigger_type === 'batch_process') {
        // Process all active users
        const batchResults = await this.processBatchTriggers();
        results.push(...batchResults);
      } else {
        throw new Error('user_id required for non-batch processing');
      }
    } catch (error) {
      const err = error as Error;
      console.error('Error processing triggers:', err);
      results.push({
        success: false,
        user_id: request.user_id || 'unknown',
        notifications_sent: 0,
        interventions_created: 0,
        error: err.message,
      });
    }

    return results;
  }

  /**
   * Process notification triggers for a specific user
   */
  private async processUserTriggers(
    userId: string,
    _request: NotificationTriggerRequest,
  ): Promise<ProcessingResult> {
    let notificationsSent = 0;
    let interventionsCreated = 0;

    try {
      // Get user's FCM tokens
      const { data: tokens, error: tokenError } = await this.supabase
        .from('user_fcm_tokens')
        .select('fcm_token, platform')
        .eq('user_id', userId)
        .eq('is_active', true);

      if (tokenError || !tokens || tokens.length === 0) {
        console.log(`No active FCM tokens found for user ${userId}`);
        return {
          success: true,
          user_id: userId,
          notifications_sent: 0,
          interventions_created: 0,
        };
      }

      // Check what interventions are needed
      const interventions = await this.checkInterventionsNeeded(userId);

      if (interventions.length === 0) {
        console.log(`No interventions needed for user ${userId}`);
        return {
          success: true,
          user_id: userId,
          notifications_sent: 0,
          interventions_created: 0,
        };
      }

      // Process each intervention
      for (const intervention of interventions) {
        // Create notification record
        const notificationId = await this.createNotificationRecord(userId, intervention);
        interventionsCreated++;

        // Send push notification to all user's devices
        for (const tokenData of tokens) {
          const success = await this.sendPushNotification(
            tokenData.fcm_token,
            intervention,
            tokenData.platform,
            notificationId,
          );
          if (success) notificationsSent++;
        }

        // Create coach intervention if needed
        if (intervention.type === 'coach_intervention') {
          await this.createCoachIntervention(userId, intervention);
        }
      }

      return {
        success: true,
        user_id: userId,
        notifications_sent: notificationsSent,
        interventions_created: interventionsCreated,
      };
    } catch (error) {
      const err = error as Error;
      console.error(`Error processing triggers for user ${userId}:`, err);
      return {
        success: false,
        user_id: userId,
        notifications_sent: notificationsSent,
        interventions_created: interventionsCreated,
        error: err.message,
      };
    }
  }

  /**
   * Process notification triggers for all active users (batch processing)
   */
  private async processBatchTriggers(): Promise<ProcessingResult[]> {
    const results: ProcessingResult[] = [];

    try {
      // Get all users who have momentum data in the last 7 days
      const { data: activeUsers, error: usersError } = await this.supabase
        .from('daily_engagement_scores')
        .select('user_id')
        .gte(
          'score_date',
          new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        )
        .order('user_id');

      if (usersError || !activeUsers) {
        throw new Error(`Failed to get active users: ${usersError?.message}`);
      }

      // Get unique user IDs with proper typing
      const uniqueUserIds = [
        ...new Set(activeUsers.map((u: { user_id: string }) => u.user_id)),
      ] as string[];
      console.log(`Processing batch triggers for ${uniqueUserIds.length} users`);

      // Process each user
      for (const userId of uniqueUserIds) {
        const result = await this.processUserTriggers(userId, {
          user_id: userId,
          trigger_type: 'batch_process',
        });
        results.push(result);

        // Add small delay to avoid overwhelming the system
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    } catch (error) {
      const err = error as Error;
      console.error('Error in batch processing:', err);
      results.push({
        success: false,
        user_id: 'batch',
        notifications_sent: 0,
        interventions_created: 0,
        error: err.message,
      });
    }

    return results;
  }

  /**
   * Check what interventions are needed for a user (reusing momentum intervention engine logic)
   */
  private async checkInterventionsNeeded(userId: string): Promise<Intervention[]> {
    const interventions: Intervention[] = [];

    // Get recent momentum history (last 7 days)
    const { data: stateHistory, error: historyError } = await this.supabase
      .from('daily_engagement_scores')
      .select('score_date, momentum_state, final_score')
      .eq('user_id', userId)
      .order('score_date', { ascending: false })
      .limit(7);

    if (historyError || !stateHistory || stateHistory.length === 0) {
      return interventions;
    }

    const currentState = stateHistory[0];
    const scoreHistory = stateHistory.map((s: MomentumScoreState) => s.final_score);

    // Check for consecutive NeedsCare days (high priority)
    if (this.checkConsecutiveNeedsCare(stateHistory)) {
      interventions.push({
        type: 'coach_intervention',
        priority: 'high',
        reason: 'consecutive_needs_care',
        action: 'schedule_coach_call',
        template_key: 'consecutive_needs_care',
        metadata: {
          consecutive_days: this.getConsecutiveNeedsCareDays(stateHistory),
          current_score: currentState.final_score,
        },
      });
    }

    // Check for significant score drop (medium priority)
    if (this.checkScoreDrop(scoreHistory)) {
      interventions.push({
        type: 'supportive_notification',
        priority: 'medium',
        reason: 'score_drop',
        action: 'send_encouragement',
        template_key: 'score_drop',
        metadata: {
          score_drop: this.calculateScoreDrop(scoreHistory),
          days_analyzed: scoreHistory.length,
        },
      });
    }

    // Check for celebration-worthy performance (low priority)
    if (this.checkCelebrationWorthy(stateHistory, currentState.momentum_state)) {
      interventions.push({
        type: 'celebration',
        priority: 'low',
        reason: 'sustained_rising',
        action: 'send_celebration',
        template_key: 'celebration',
        metadata: {
          rising_days: this.getRisingDaysCount(stateHistory),
          achievement_level: 'sustained_excellence',
        },
      });
    }

    // Daily motivation (if no recent notifications)
    const hasRecentNotification = await this.hasRecentNotification(userId, 24);
    if (!hasRecentNotification && this.shouldSendDailyMotivation(stateHistory)) {
      interventions.push({
        type: 'daily_motivation',
        priority: 'low',
        reason: 'daily_check_in',
        action: 'send_motivation',
        template_key: 'daily_motivation',
        metadata: {
          current_state: currentState.momentum_state,
          score: currentState.final_score,
        },
      });
    }

    return interventions;
  }

  /**
   * Send push notification via Firebase Cloud Messaging
   */
  private async sendPushNotification(
    fcmToken: string,
    intervention: Intervention,
    platform: string,
    notificationId: string,
  ): Promise<boolean> {
    try {
      const template = this.getNotificationTemplate(
        intervention.template_key,
        intervention.metadata,
      );

      const message: FCMMessage = {
        token: fcmToken,
        notification: {
          title: template.title,
          body: template.message,
        },
        data: {
          notification_id: notificationId,
          intervention_type: intervention.type,
          action_type: template.action_type,
          action_data: JSON.stringify(template.action_data || {}),
        },
      };

      // Platform-specific configuration
      if (platform === 'android') {
        message.android = {
          priority: intervention.priority === 'high' ? 'high' : 'normal',
          notification: {
            channel_id: 'momentum_notifications',
            priority: intervention.priority === 'high' ? 'high' : 'default',
          },
        };
      } else if (platform === 'ios') {
        message.apns = {
          payload: {
            aps: {
              alert: {
                title: template.title,
                body: template.message,
              },
              badge: 1,
              sound: 'default',
            },
          },
        };
      }

      // Send via Firebase Cloud Messaging
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${this.firebaseProjectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.firebaseServerKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ message }),
        },
      );

      if (response.ok) {
        console.log(`Push notification sent successfully to ${fcmToken}`);

        // Update notification record as sent
        await this.supabase
          .from('momentum_notifications')
          .update({
            sent_at: new Date().toISOString(),
            delivery_status: 'sent',
          })
          .eq('id', notificationId);

        return true;
      } else {
        const error = await response.text();
        console.error(`Failed to send push notification: ${error}`);

        // Update notification record as failed
        await this.supabase
          .from('momentum_notifications')
          .update({
            delivery_status: 'failed',
            error_message: error,
          })
          .eq('id', notificationId);

        return false;
      }
    } catch (error) {
      const err = error as Error;
      console.error(`Error sending push notification:`, err);
      return false;
    }
  }

  /**
   * Create notification record in database
   */
  private async createNotificationRecord(
    userId: string,
    intervention: Intervention,
  ): Promise<string> {
    const template = this.getNotificationTemplate(intervention.template_key, intervention.metadata);

    const { data, error } = await this.supabase
      .from('momentum_notifications')
      .insert({
        user_id: userId,
        notification_type: intervention.reason,
        trigger_date: new Date().toISOString().split('T')[0],
        trigger_metadata: intervention.metadata || {},
        title: template.title,
        message: template.message,
        action_type: template.action_type,
        action_data: template.action_data || {},
        priority: intervention.priority,
        delivery_status: 'pending',
      })
      .select('id')
      .single();

    if (error) {
      throw new Error(`Failed to create notification record: ${error.message}`);
    }

    return data.id;
  }

  /**
   * Create coach intervention record
   */
  private async createCoachIntervention(userId: string, intervention: Intervention): Promise<void> {
    const { error } = await this.supabase
      .from('coach_interventions')
      .insert({
        user_id: userId,
        intervention_type: intervention.reason,
        priority: intervention.priority,
        trigger_date: new Date().toISOString().split('T')[0],
        trigger_metadata: intervention.metadata || {},
        status: 'pending',
        created_at: new Date().toISOString(),
      });

    if (error) {
      console.error(`Failed to create coach intervention: ${error.message}`);
    }
  }

  /**
   * Get notification template based on intervention type
   */
  private getNotificationTemplate(
    templateKey: string,
    metadata: Record<string, unknown> = {},
  ): NotificationTemplate {
    const templates: Record<string, NotificationTemplate> = {
      consecutive_needs_care: {
        title: "Let's grow together! 🌱",
        message:
          `We've noticed you might need some extra support. Your coach is here to help you get back on track!`,
        action_type: 'schedule_call',
        action_data: { priority: 'high', intervention_type: 'support_call' },
      },
      score_drop: {
        title: "You've got this! 💪",
        message:
          "Everyone has ups and downs. Let's focus on small wins today - you're stronger than you know!",
        action_type: 'complete_lesson',
        action_data: { suggested_lesson: 'resilience_basics' },
      },
      celebration: {
        title: 'Amazing momentum! 🎉',
        message: `You've been consistently Rising for ${
          metadata.rising_days || 'several'
        } days! Your dedication is truly inspiring. Keep up the fantastic work!`,
        action_type: 'view_momentum',
        action_data: { celebration: true },
      },
      daily_motivation: {
        title: this.getDailyMotivationTitle(metadata.current_state as string),
        message: this.getDailyMotivationMessage(
          metadata.current_state as string,
          metadata.score as number,
        ),
        action_type: 'open_app',
        action_data: { focus: 'momentum_meter' },
      },
    };

    return templates[templateKey as keyof typeof templates] || templates['daily_motivation'];
  }

  /**
   * Get daily motivation title based on current state
   */
  private getDailyMotivationTitle(state: string): string {
    const titles = {
      'Rising': ['Keep soaring! 🚀', 'Momentum master! ⭐', 'On fire today! 🔥'],
      'Steady': ['Steady wins the race! 🏃‍♀️', 'Consistent progress! 📈', 'Building momentum! 💪'],
      'NeedsCare': [
        'Every step counts! 🌱',
        "You're not alone! 🤝",
        'Small steps, big changes! ✨',
      ],
    } as const;

    const stateKey = (state in titles ? state : 'Steady') as keyof typeof titles;
    const stateTitle = titles[stateKey];
    return stateTitle[Math.floor(Math.random() * stateTitle.length)];
  }

  /**
   * Get daily motivation message based on current state and score
   */
  private getDailyMotivationMessage(state: string, score: number): string {
    if (state === 'Rising') {
      return `Your momentum is incredible at ${score}%! You're proving that consistency creates magic. What will you accomplish today?`;
    } else if (state === 'Steady') {
      return `Steady progress at ${score}% is still progress! Every small step is building toward something amazing. Keep going!`;
    } else {
      return `At ${score}%, you're exactly where you need to be to start fresh. Today is a new opportunity to take one small step forward. We believe in you!`;
    }
  }

  // Helper methods (reusing logic from momentum intervention engine)
  private checkConsecutiveNeedsCare(stateHistory: MomentumScoreState[]): boolean {
    let consecutiveCount = 0;
    for (const state of stateHistory) {
      if (state.momentum_state === 'NeedsCare') {
        consecutiveCount++;
      } else {
        break;
      }
    }
    return consecutiveCount >= 3;
  }

  private getConsecutiveNeedsCareDays(stateHistory: MomentumScoreState[]): number {
    let count = 0;
    for (const state of stateHistory) {
      if (state.momentum_state === 'NeedsCare') {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  private checkScoreDrop(scoreHistory: number[]): boolean {
    if (scoreHistory.length < 3) return false;
    const recent = scoreHistory.slice(0, 3);
    const older = scoreHistory.slice(3, 6);
    if (older.length === 0) return false;

    const recentAvg = recent.reduce((a, b) => a + b, 0) / recent.length;
    const olderAvg = older.reduce((a, b) => a + b, 0) / older.length;

    return (olderAvg - recentAvg) > 15;
  }

  private calculateScoreDrop(scoreHistory: number[]): number {
    if (scoreHistory.length < 2) return 0;
    return Math.max(0, scoreHistory[1] - scoreHistory[0]);
  }

  private checkCelebrationWorthy(
    stateHistory: MomentumScoreState[],
    currentState: string,
  ): boolean {
    if (currentState !== 'Rising') return false;

    let risingCount = 0;
    for (const state of stateHistory) {
      if (state.momentum_state === 'Rising') {
        risingCount++;
      } else {
        break;
      }
    }
    return risingCount >= 3;
  }

  private getRisingDaysCount(stateHistory: MomentumScoreState[]): number {
    let count = 0;
    for (const state of stateHistory) {
      if (state.momentum_state === 'Rising') {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  private shouldSendDailyMotivation(stateHistory: MomentumScoreState[]): boolean {
    // Send daily motivation if user has been active in last 3 days
    return stateHistory.length > 0 && stateHistory.length <= 3;
  }

  private async hasRecentNotification(userId: string, hoursAgo: number): Promise<boolean> {
    const cutoffTime = new Date(Date.now() - hoursAgo * 60 * 60 * 1000).toISOString();

    const { data, error } = await this.supabase
      .from('momentum_notifications')
      .select('id')
      .eq('user_id', userId)
      .gte('created_at', cutoffTime)
      .limit(1);

    return !error && data && data.length > 0;
  }
}

// Main handler
serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID') || 'bee-mvp-3ab43';
    const firebaseServerKey = Deno.env.get('FIREBASE_SERVER_KEY')!;

    if (!supabaseUrl || !supabaseKey || !firebaseServerKey) {
      throw new Error('Missing required environment variables');
    }

    const triggerService = new PushNotificationTrigger(
      supabaseUrl,
      supabaseKey,
      firebaseProjectId,
      firebaseServerKey,
    );

    const requestData: NotificationTriggerRequest = await req.json();
    const results = await triggerService.processTriggers(requestData);

    return new Response(
      JSON.stringify({
        success: true,
        results,
        summary: {
          total_users_processed: results.length,
          total_notifications_sent: results.reduce((sum, r) => sum + r.notifications_sent, 0),
          total_interventions_created: results.reduce((sum, r) => sum + r.interventions_created, 0),
          failed_users: results.filter((r) => !r.success).length,
        },
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    );
  } catch (error) {
    const err = error as Error;
    console.error('Error in push notification triggers:', err);
    return new Response(err.message, { status: 500, headers: corsHeaders });
  }
});
