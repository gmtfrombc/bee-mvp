// embedding.ts – lightweight client to generate text embeddings via OpenAI or Vertex AI
// deno-lint-ignore-file no-explicit-any no-unused-vars

import { getSupabaseClient } from './_shared/supabase_client.ts'

const EMBEDDING_API_URL = Deno.env.get('EMBEDDING_API_URL')
const EMBEDDING_API_KEY = Deno.env.get('EMBEDDING_API_KEY')
const EMBEDDING_MODEL = Deno.env.get('EMBEDDING_MODEL') ?? 'text-embedding-3-small'

export async function generateEmbedding(text: string): Promise<number[] | null> {
  if (!EMBEDDING_API_URL || !EMBEDDING_API_KEY) return null

  try {
    const res = await fetch(EMBEDDING_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${EMBEDDING_API_KEY}`,
      },
      body: JSON.stringify({ model: EMBEDDING_MODEL, input: text }),
    })

    if (!res.ok) {
      console.error('[embedding] API error', res.status, await res.text())
      return null
    }

    const data = await res.json() as any
    const vec = data?.data?.[0]?.embedding as number[] | undefined
    return Array.isArray(vec) ? vec : null
  } catch (err) {
    console.error('[embedding] fetch failed', err)
    return null
  }
}

export async function storeEmbedding(
  conversationLogId: string,
  embedding: number[],
): Promise<void> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY')!
  const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
  const supabase = createClient(supabaseUrl, supabaseKey)

  await supabase.from('conversation_embeddings').upsert({
    conversation_id: conversationLogId,
    embedding,
  })
}
