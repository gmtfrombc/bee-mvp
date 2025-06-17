import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getEmbedding } from './embedding.service.ts'

interface LogParams {
  userId: string
  sender: 'user' | 'ai' | 'human_coach'
  message: string
  metadata?: Record<string, unknown>
}

/**
 * Insert a row into public.coach_interactions.
 * In DENO_TESTING mode this is a no-op to keep unit tests isolated.
 */
export async function logCoachInteraction({ userId, sender, message, metadata = {} }: LogParams) {
  const isTest = Deno.env.get('DENO_TESTING') === 'true'
  if (isTest) return

  const url = Deno.env.get('SUPABASE_URL')
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SERVICE_ROLE_KEY')
  if (!url || !key) {
    console.warn('logCoachInteraction skipped – missing env vars')
    return
  }

  const client = createClient(url, key)
  const embedding = await getEmbedding(message)
  await client.from('coach_interactions').insert({
    user_id: userId,
    sender,
    message,
    metadata,
    embedding,
  })
}
