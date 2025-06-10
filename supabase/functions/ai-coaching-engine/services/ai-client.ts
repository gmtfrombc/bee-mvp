// services/ai-client.ts
// Thin wrapper around OpenAI / Anthropic chat completion endpoints.
// Selects provider based on the AI_MODEL env var.

import { AIMessage } from '../types.ts'

const aiApiKey = Deno.env.get('AI_API_KEY') ?? ''
const aiModel = Deno.env.get('AI_MODEL') || 'gpt-4o'

export async function callAIAPI(prompt: AIMessage[]): Promise<string> {
  const apiUrl = aiModel.startsWith('gpt')
    ? 'https://api.openai.com/v1/chat/completions'
    : 'https://api.anthropic.com/v1/messages'

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }

  let body: unknown

  if (aiModel.startsWith('gpt')) {
    headers['Authorization'] = `Bearer ${aiApiKey}`
    body = {
      model: aiModel,
      messages: prompt,
      max_tokens: 200,
      temperature: 0.7,
    }
  } else {
    headers['x-api-key'] = aiApiKey
    headers['anthropic-version'] = '2023-06-01'

    const systemMsg = prompt.find((m) => m.role === 'system')?.content ?? ''
    body = {
      model: aiModel,
      messages: prompt.filter((m) => m.role !== 'system'),
      system: systemMsg,
      max_tokens: 200,
    }
  }

  // Offline stub – avoid external calls when OFFLINE_AI=true or no key
  const offline = Deno.env.get('OFFLINE_AI') === 'true' || !aiApiKey
  if (offline) {
    const lastUserMsg = [...prompt].reverse().find((m) => m.role === 'user')?.content ??
      'your goals'
    return `I hear that ${lastUserMsg}. Let's take one small step today to build momentum! What is one action you can commit to right now?`
  }

  const res = await fetch(apiUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  })

  if (!res.ok) {
    console.error(`AI API error: ${res.status} ${res.statusText}`)
    if (res.status === 401 || res.status === 403) {
      return "I'm having trouble connecting to my knowledge base right now. Let's focus on one small, doable action: what is a tiny habit you can start today?"
    }

    throw new Error(`AI API error: ${res.status} ${res.statusText}`)
  }

  const data = await res.json()

  if (aiModel.startsWith('gpt')) {
    // OpenAI shape
    // deno-lint-ignore no-explicit-any
    return (data as any).choices[0]?.message?.content ??
      'I apologize, but I cannot respond right now.'
  }

  // Anthropic shape
  // deno-lint-ignore no-explicit-any
  return (data as any).content[0]?.text ?? 'I apologize, but I cannot respond right now.'
}
