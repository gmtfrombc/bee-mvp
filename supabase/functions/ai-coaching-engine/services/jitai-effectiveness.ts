import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export async function recordJITAIOutcome(
  userId: string,
  triggerId: string,
  outcome: 'delivered' | 'engaged' | 'ignored',
  interventionType: string,
  context: Record<string, unknown> = {},
): Promise<void> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SERVICE_ROLE_KEY')
  const isTesting = Deno.env.get('DENO_TESTING') === 'true'
  if (!supabaseUrl || !serviceRoleKey || isTesting) {
    console.log('[JITAI-Outcome]', userId, triggerId, outcome)
    return
  }
  const client = createClient(supabaseUrl, serviceRoleKey)
  const { error } = await client.from('jitai_effectiveness').insert({
    user_id: userId,
    trigger_id: triggerId,
    outcome,
    recorded_at: new Date().toISOString(),
  })
  if (error) console.error('[JITAI-Outcome] insert failed', error.message)

  // Map outcome to numeric reward (simple)
  const reward = outcome === 'engaged' ? 1 : 0
  const { error: rewardErr } = await client.from('jitai_reward_log').insert({
    user_id: userId,
    trigger_id: triggerId,
    intervention_type: interventionType,
    context,
    reward,
    recorded_at: new Date().toISOString(),
  })
  if (rewardErr) console.error('[JITAI-Reward] insert failed', rewardErr.message)
}
