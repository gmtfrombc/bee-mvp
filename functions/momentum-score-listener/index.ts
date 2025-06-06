import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const aiCoachingEngineUrl = Deno.env.get('AI_COACHING_ENGINE_URL') || 'http://localhost:54321/functions/v1/ai-coaching-engine'

interface MomentumChangeEvent {
    user_id: string
    previous_state?: string
    current_state: string
    score_date: string
    final_score: number
}

/**
 * Edge Function that listens to momentum score changes and triggers AI coaching
 * Implements M1.3.6 - Momentum Integration & Proactive Nudge
 */
export default async function handler(req: Request): Promise<Response> {
    // Only handle POST requests (webhook calls from Supabase)
    if (req.method !== 'POST') {
        return new Response('Method not allowed', { status: 405 })
    }

    try {
        const payload = await req.json()

        // Extract the new record from Supabase webhook payload
        const record = payload.record
        if (!record) {
            console.log('No record in payload, skipping...')
            return new Response('OK', { status: 200 })
        }

        const { user_id, score_date, momentum_state, final_score } = record

        // Get previous day's momentum state to detect changes
        const supabase = createClient(supabaseUrl, supabaseServiceKey)
        const previousDate = new Date(score_date)
        previousDate.setDate(previousDate.getDate() - 1)
        const previousDateStr = previousDate.toISOString().split('T')[0]

        const { data: previousRecord } = await supabase
            .from('daily_engagement_scores')
            .select('momentum_state')
            .eq('user_id', user_id)
            .eq('score_date', previousDateStr)
            .single()

        const previousState = previousRecord?.momentum_state

        // Only trigger if state actually changed
        if (previousState && previousState !== momentum_state) {
            console.log(`Momentum state change detected for user ${user_id}: ${previousState} → ${momentum_state}`)

            // Get user's auth token from service account
            const { data: userResponse } = await supabase.auth.admin.getUserById(user_id)
            if (!userResponse.user) {
                console.error(`User ${user_id} not found`)
                return new Response('User not found', { status: 404 })
            }

            // For coaching system events, we'll use the service role key directly
            // since this is a system-initiated action, not a user action
            const serviceToken = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

            if (!serviceToken) {
                console.error('Service role key not available')
                return new Response('Service configuration error', { status: 500 })
            }

            // Call AI coaching engine with momentum change event using service role
            const coachingResponse = await fetch(aiCoachingEngineUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${serviceToken}`,
                    'X-System-Event': 'true' // Flag this as a system event
                },
                body: JSON.stringify({
                    user_id,
                    message: `momentum_change:${previousState}:${momentum_state}`,
                    momentum_state,
                    system_event: 'momentum_change',
                    previous_state: previousState,
                    current_score: final_score
                })
            })

            if (coachingResponse.ok) {
                const coachingResult = await coachingResponse.json()
                console.log(`AI coaching response generated for user ${user_id}:`, coachingResult.assistant_message)

                // Send push notification via NotificationService
                await sendCoachNudge(user_id, momentum_state, previousState, coachingResult.assistant_message)
            } else {
                console.error(`AI coaching request failed:`, await coachingResponse.text())
            }
        }

        return new Response('OK', { status: 200 })
    } catch (error) {
        console.error('Error in momentum-score-listener:', error)
        return new Response('Internal server error', { status: 500 })
    }
}

/**
 * Send push notification for coaching nudge
 */
async function sendCoachNudge(
    userId: string,
    currentState: string,
    previousState: string,
    message: string
): Promise<void> {
    try {
        const supabase = createClient(supabaseUrl, supabaseServiceKey)

        // Get user's FCM token from their profile or notification preferences
        const { data: userProfile } = await supabase
            .from('user_profiles')
            .select('fcm_token, notification_preferences')
            .eq('id', userId)
            .single()

        if (!userProfile?.fcm_token) {
            console.log(`No FCM token found for user ${userId}`)
            return
        }

        // Check if user has coaching notifications enabled
        const notificationPrefs = userProfile.notification_preferences || {}
        if (notificationPrefs.coaching_enabled === false) {
            console.log(`Coaching notifications disabled for user ${userId}`)
            return
        }

        // Generate notification title based on momentum change
        let title = 'Your Coach Has a Message'
        if (currentState === 'Rising' && previousState !== 'Rising') {
            title = '🚀 Momentum Rising!'
        } else if (currentState === 'NeedsCare' && previousState !== 'NeedsCare') {
            title = '💪 Let\'s Get Back on Track'
        } else if (currentState === 'Steady') {
            title = '⚖️ Staying Steady'
        }

        // Send FCM notification using Supabase Edge Function or service
        const notificationPayload = {
            to: userProfile.fcm_token,
            notification: {
                title,
                body: message.length > 100 ? message.substring(0, 97) + '...' : message,
                icon: 'ic_notification',
                sound: 'default'
            },
            data: {
                type: 'coach_nudge',
                user_id: userId,
                momentum_state: currentState,
                previous_state: previousState,
                message,
                timestamp: new Date().toISOString()
            }
        }

        // Store notification in database for Today Feed integration
        await supabase
            .from('momentum_notifications')
            .insert({
                user_id: userId,
                notification_type: 'coach_nudge',
                title,
                message,
                metadata: {
                    momentum_change: {
                        from: previousState,
                        to: currentState
                    },
                    coaching_triggered: true
                }
            })

        console.log(`Coach nudge notification queued for user ${userId}`)
    } catch (error) {
        console.error('Error sending coach nudge:', error)
    }
} 