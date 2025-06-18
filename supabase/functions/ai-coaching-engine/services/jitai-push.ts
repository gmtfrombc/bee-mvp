import { getSupabaseClient } from '../_shared/supabase_client.ts'
import { JITAITrigger } from '../types.ts'

// Introduce minimal client interface
interface SupabaseLike {
  from: (
    table: string,
  ) => {
    insert: (row: Record<string, unknown>[]) => Promise<{ error: { message?: string } | null }>
  }
}

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

  const client = await getSupabaseClient({ overrideKey: serviceRoleKey }) as unknown as SupabaseLike
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
