/// <reference path="./types.d.ts" />

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Types for intervention system
interface MomentumState {
    date: string
    momentum_state: 'Rising' | 'Steady' | 'NeedsCare'
    final_score: number
    user_id: string
}

interface InterventionRule {
    type: string
    priority: 'low' | 'medium' | 'high'
    reason: string
    action: string
    metadata?: Record<string, any>
}

interface NotificationTemplate {
    title: string
    message: string
    action_type: string
    action_data?: Record<string, any>
}

interface ProcessingResult {
    user_id: string
    interventions_count: number
}

// Notification templates for different intervention types
const NOTIFICATION_TEMPLATES: Record<string, NotificationTemplate> = {
    consecutive_needs_care: {
        title: "Let's grow together! 🌱",
        message: "We've noticed you might need some extra support. Your coach is here to help you get back on track!",
        action_type: "schedule_call",
        action_data: { priority: "high", intervention_type: "support_call" }
    },
    score_drop: {
        title: "You've got this! 💪",
        message: "Everyone has ups and downs. Let's focus on small wins today - you're stronger than you know!",
        action_type: "complete_lesson",
        action_data: { suggested_lesson: "resilience_basics" }
    },
    celebration: {
        title: "Amazing momentum! 🎉",
        message: "You've been consistently Rising for days! Your dedication is truly inspiring. Keep up the fantastic work!",
        action_type: "view_momentum",
        action_data: { celebration: true }
    },
    consistency_reminder: {
        title: "Consistency is key 🗝️",
        message: "Small, regular steps lead to big changes. Let's find a rhythm that works for you!",
        action_type: "journal_entry",
        action_data: { prompt: "What's one small thing you can do today?" }
    },
    momentum_drop: {
        title: "Let's reconnect 🤝",
        message: "We're here to support you through any challenges. Every step forward counts!",
        action_type: "open_app",
        action_data: { focus: "support_resources" }
    }
}

class InterventionEngine {
    private supabase: any

    constructor(supabaseUrl: string, supabaseKey: string) {
        this.supabase = createClient(supabaseUrl, supabaseKey)
    }

    /**
     * Get Supabase client for external access
     */
    public getSupabaseClient() {
        return this.supabase
    }

    /**
     * Check if interventions are needed for a user based on their momentum history
     */
    async checkInterventionsNeeded(userId: string): Promise<InterventionRule[]> {
        const interventions: InterventionRule[] = []

        // Get recent momentum history (last 7 days)
        const { data: stateHistory, error: historyError } = await this.supabase
            .from('daily_engagement_scores')
            .select('score_date, momentum_state, final_score')
            .eq('user_id', userId)
            .order('score_date', { ascending: false })
            .limit(7)

        if (historyError || !stateHistory || stateHistory.length === 0) {
            console.log(`No momentum history found for user ${userId}`)
            return interventions
        }

        const currentState = stateHistory[0]
        const scoreHistory = stateHistory.map((s: any) => s.final_score)

        // Check for consecutive NeedsCare days
        if (this.checkConsecutiveNeedsCare(stateHistory)) {
            interventions.push({
                type: 'coach_intervention',
                priority: 'high',
                reason: 'consecutive_needs_care',
                action: 'schedule_coach_call',
                metadata: {
                    consecutive_days: this.getConsecutiveNeedsCareDays(stateHistory),
                    current_score: currentState.final_score
                }
            })
        }

        // Check for significant score drop
        if (this.checkScoreDrop(scoreHistory)) {
            interventions.push({
                type: 'supportive_notification',
                priority: 'medium',
                reason: 'score_drop',
                action: 'send_encouragement',
                metadata: {
                    score_drop: this.calculateScoreDrop(scoreHistory),
                    days_analyzed: scoreHistory.length
                }
            })
        }

        // Check for celebration-worthy performance
        if (this.checkCelebrationWorthy(stateHistory, currentState.momentum_state)) {
            interventions.push({
                type: 'celebration',
                priority: 'low',
                reason: 'sustained_rising',
                action: 'send_celebration',
                metadata: {
                    rising_days: this.getRisingDaysCount(stateHistory),
                    achievement_level: 'sustained_excellence'
                }
            })
        }

        // Check for consistency reminder
        if (this.checkConsistencyReminder(stateHistory)) {
            interventions.push({
                type: 'consistency_reminder',
                priority: 'low',
                reason: 'irregular_pattern',
                action: 'send_reminder',
                metadata: {
                    transition_count: this.countStateTransitions(stateHistory),
                    pattern_type: 'irregular'
                }
            })
        }

        return interventions
    }

    /**
     * Process interventions by creating notifications and coach interventions
     */
    async processInterventions(userId: string, interventions: InterventionRule[]): Promise<void> {
        for (const intervention of interventions) {
            try {
                // Create notification
                await this.createNotification(userId, intervention)

                // Create coach intervention if needed
                if (intervention.type === 'coach_intervention') {
                    await this.createCoachIntervention(userId, intervention)
                }

                console.log(`Processed intervention: ${intervention.type} for user ${userId}`)
            } catch (error) {
                console.error(`Failed to process intervention ${intervention.type} for user ${userId}:`, error)
            }
        }
    }

    /**
     * Create a notification record in the database
     */
    private async createNotification(userId: string, intervention: InterventionRule): Promise<void> {
        const template = NOTIFICATION_TEMPLATES[intervention.reason] || NOTIFICATION_TEMPLATES.momentum_drop

        const { error } = await this.supabase
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
                status: 'pending'
            })

        if (error) {
            throw new Error(`Failed to create notification: ${error.message}`)
        }
    }

    /**
     * Create a coach intervention record for high-priority cases
     */
    private async createCoachIntervention(userId: string, intervention: InterventionRule): Promise<void> {
        const { error } = await this.supabase
            .from('coach_interventions')
            .insert({
                user_id: userId,
                intervention_type: 'automated_call_schedule',
                trigger_date: new Date().toISOString().split('T')[0],
                trigger_reason: intervention.reason,
                trigger_momentum_state: 'NeedsCare',
                trigger_pattern: intervention.metadata || {},
                status: 'scheduled',
                priority: intervention.priority,
                automated: true
            })

        if (error) {
            throw new Error(`Failed to create coach intervention: ${error.message}`)
        }
    }

    // Intervention detection methods
    private checkConsecutiveNeedsCare(stateHistory: any[]): boolean {
        if (stateHistory.length < 2) return false

        const recentStates = stateHistory.slice(0, 2).map((s: any) => s.momentum_state)
        return recentStates.every((state: string) => state === 'NeedsCare')
    }

    private getConsecutiveNeedsCareDays(stateHistory: any[]): number {
        let count = 0
        for (const state of stateHistory) {
            if (state.momentum_state === 'NeedsCare') {
                count++
            } else {
                break
            }
        }
        return count
    }

    private checkScoreDrop(scoreHistory: number[]): boolean {
        if (scoreHistory.length < 3) return false

        const recentScores = scoreHistory.slice(0, 3)
        const scoreDrop = recentScores[0] - recentScores[recentScores.length - 1]
        return scoreDrop >= 15.0
    }

    private calculateScoreDrop(scoreHistory: number[]): number {
        if (scoreHistory.length < 2) return 0
        return scoreHistory[0] - scoreHistory[scoreHistory.length - 1]
    }

    private checkCelebrationWorthy(stateHistory: any[], currentState: string): boolean {
        if (currentState !== 'Rising' || stateHistory.length < 5) return false

        const recentStates = stateHistory.slice(0, 5).map((s: any) => s.momentum_state)
        const risingCount = recentStates.filter((state: string) => state === 'Rising').length
        return risingCount >= 4 // 4 out of 5 days Rising
    }

    private getRisingDaysCount(stateHistory: any[]): number {
        return stateHistory.filter((s: any) => s.momentum_state === 'Rising').length
    }

    private checkConsistencyReminder(stateHistory: any[]): boolean {
        if (stateHistory.length < 7) return false

        const transitions = this.countStateTransitions(stateHistory)
        return transitions > 4 // More than 4 transitions in 7 days suggests inconsistency
    }

    private countStateTransitions(stateHistory: any[]): number {
        let transitions = 0
        for (let i = 1; i < stateHistory.length; i++) {
            if (stateHistory[i].momentum_state !== stateHistory[i - 1].momentum_state) {
                transitions++
            }
        }
        return transitions
    }
}

serve(async (req) => {
    try {
        // CORS headers
        if (req.method === 'OPTIONS') {
            return new Response('ok', {
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
                },
            })
        }

        // Only allow POST requests
        if (req.method !== 'POST') {
            return new Response(
                JSON.stringify({ error: 'Method not allowed' }),
                { status: 405, headers: { 'Content-Type': 'application/json' } }
            )
        }

        // Get Supabase environment variables
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

        // Parse request body
        const { user_id, check_all_users = false } = await req.json()

        const engine = new InterventionEngine(supabaseUrl, supabaseServiceKey)

        if (check_all_users) {
            // Process interventions for all active users (for scheduled runs)
            const { data: activeUsers, error } = await engine.getSupabaseClient()
                .from('daily_engagement_scores')
                .select('user_id')
                .gte('score_date', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0])
                .group('user_id')

            if (error) {
                throw new Error(`Failed to get active users: ${error.message}`)
            }

            const results: ProcessingResult[] = []
            for (const user of activeUsers || []) {
                const interventions = await engine.checkInterventionsNeeded(user.user_id)
                if (interventions.length > 0) {
                    await engine.processInterventions(user.user_id, interventions)
                    results.push({ user_id: user.user_id, interventions_count: interventions.length })
                }
            }

            return new Response(
                JSON.stringify({
                    success: true,
                    message: `Processed interventions for ${results.length} users`,
                    results
                }),
                { headers: { 'Content-Type': 'application/json' } }
            )
        } else if (user_id) {
            // Process interventions for specific user
            const interventions = await engine.checkInterventionsNeeded(user_id)

            if (interventions.length > 0) {
                await engine.processInterventions(user_id, interventions)
            }

            return new Response(
                JSON.stringify({
                    success: true,
                    user_id,
                    interventions_triggered: interventions.length,
                    interventions
                }),
                { headers: { 'Content-Type': 'application/json' } }
            )
        } else {
            return new Response(
                JSON.stringify({ error: 'user_id is required' }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            )
        }

    } catch (error) {
        console.error('Intervention engine error:', error)
        return new Response(
            JSON.stringify({
                error: 'Internal server error',
                message: error.message
            }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
    }
}) 