import { getSupabaseClient } from '../_shared/supabase_client.ts'
import { JITAITrigger, WearableData } from '../types.ts'

type SupabaseClient = any

export async function logJITAIEvent(
  userId: string,
  wearable: WearableData,
  triggers: JITAITrigger[],
  source: 'predictive' | 'rules' | 'hybrid',
): Promise<void> {
  const isTesting = Deno.env.get('DENO_TESTING') === 'true'
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SERVICE_ROLE_KEY')

  if (!supabaseUrl || !serviceRoleKey || isTesting) {
    console.log('JITAI event:', { userId, source, triggersCount: triggers.length })
    return
  }

  const client: SupabaseClient = await getSupabaseClient({ overrideKey: serviceRoleKey })

  await client.from('jitai_training_events').insert({
    user_id: userId,
    wearable_snapshot: wearable,
    triggers,
    source,
    created_at: new Date().toISOString(),
  })
}
