import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JITAITrigger } from '../types.ts'

/**
 * Lightweight service to enqueue push notifications for JITAI triggers.
 * Currently inserts rows into `push_notification_queue` which is consumed by
 * the existing `push-notification-triggers` Edge Function.
 */
export async function enqueueJITAITriggers(
  userId: string,
  triggers: JITAITrigger[],
): Promise<void> {
  if (triggers.length === 0) return

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SERVICE_ROLE_KEY')
  const isTesting = Deno.env.get('DENO_TESTING') === 'true'

  if (!supabaseUrl || !serviceRoleKey || isTesting) {
    console.log(`[JITAI-Push] Would enqueue push for ${userId}:`, triggers)
    return
  }

  const client = createClient(supabaseUrl, serviceRoleKey)
  // Map each trigger to a push record. Assume queue table exists with payload JSON.
  const rows = triggers.map((t) => ({
    user_id: userId,
    title: 'Coach Tip',
    body: t.message,
    channel: 'coach_push',
    payload: { trigger_id: t.id, type: t.type },
    created_at: new Date().toISOString(),
  }))
  const { error } = await client.from('push_notification_queue').insert(rows)
  if (error) {
    console.error('[JITAI-Push] Failed to enqueue push:', error.message)
  }
}
