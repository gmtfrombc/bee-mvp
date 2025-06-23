// services/ai-client.ts
// Thin wrapper around OpenAI / Anthropic chat completion endpoints.
// Selects provider based on the AI_MODEL env var.

import { AIMessage } from '../types.ts'

const aiApiKey = Deno.env.get('AI_API_KEY') ?? ''
const aiModel = Deno.env.get('AI_MODEL') || 'gpt-4o'

// Default temperature; allow override via AI_TEMPERATURE env var (e.g. 0.4)
const defaultTemp = parseFloat(Deno.env.get('AI_TEMPERATURE') ?? '0.4')

export interface AIResponse {
  text: string
  usage?: {
    prompt_tokens: number
    completion_tokens: number
    total_tokens: number
    cost_usd: number
  }
}

// ---------------------------------------------------------------------------
// Response shapes for supported providers
// ---------------------------------------------------------------------------

interface OpenAIUsage {
  prompt_tokens: number
  completion_tokens: number
  total_tokens: number
}

interface OpenAIChoice {
  message: {
    content: string
  }
}

interface OpenAIResponse {
  choices: OpenAIChoice[]
  usage?: OpenAIUsage
}

interface AnthropicContentBlock {
  text: string
}

interface AnthropicResponse {
  content?: AnthropicContentBlock[]
}

export async function callAIAPI(prompt: AIMessage[]): Promise<AIResponse> {
  // --- Fail-over & timeout configuration ----------------------------------
  // Hard latency budget (ms) before falling back to local stub to guarantee
  // sub-second p95 end-to-end response times.
  const timeoutMs = parseInt(Deno.env.get('AI_API_TIMEOUT_MS') ?? '900')

  // Optional secondary model – if provided we will attempt a best-effort
  // retry using this model before falling back to the local stub.
  const fallbackModel = Deno.env.get('AI_FALLBACK_MODEL')?.trim()

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
      temperature: defaultTemp,
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
    return {
      text:
        `I hear that ${lastUserMsg}. Let's take one small step today to build momentum! What is one action you can commit to right now?`,
    }
  }

  // ----------------------- Primary provider call ---------------------------

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), timeoutMs)

  let res: Response | null = null

  try {
    res = await fetch(apiUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
      signal: controller.signal,
    })
  } catch (err) {
    console.warn('⏱️ Primary AI provider timed-out or failed –', err)
  } finally {
    clearTimeout(timeout)
  }

  // If the primary request was aborted or returned error status, attempt
  // secondary provider (if configured) **within the remaining latency budget**.
  if (!res || !res.ok) {
    if (fallbackModel && fallbackModel !== aiModel) {
      try {
        const fbApiUrl = fallbackModel.startsWith('gpt')
          ? 'https://api.openai.com/v1/chat/completions'
          : 'https://api.anthropic.com/v1/messages'

        const fbHeaders: Record<string, string> = { 'Content-Type': 'application/json' }
        if (fallbackModel.startsWith('gpt')) {
          fbHeaders['Authorization'] = `Bearer ${aiApiKey}`
        } else {
          fbHeaders['x-api-key'] = aiApiKey
          fbHeaders['anthropic-version'] = '2023-06-01'
        }

        let fbBody: unknown
        if (fallbackModel.startsWith('gpt')) {
          fbBody = {
            model: fallbackModel,
            messages: prompt,
            max_tokens: 200,
            temperature: defaultTemp,
          }
        } else {
          const system = prompt.find((m) => m.role === 'system')?.content ?? ''
          fbBody = {
            model: fallbackModel,
            messages: prompt.filter((m) => m.role !== 'system'),
            system,
            max_tokens: 200,
          }
        }

        // Give the fallback at most (timeoutMs / 2) to finish.
        const fbController = new AbortController()
        const fbTimeout = setTimeout(() => fbController.abort(), Math.floor(timeoutMs / 2))
        try {
          res = await fetch(fbApiUrl, {
            method: 'POST',
            headers: fbHeaders,
            body: JSON.stringify(fbBody),
            signal: fbController.signal,
          })
        } catch (err) {
          console.warn('⚠️ Fallback AI provider also failed –', err)
          res = null
        } finally {
          clearTimeout(fbTimeout)
        }
      } catch (err) {
        console.error('Fallback provider setup error:', err)
        res = null
      }
    }
  }

  // If still no valid response, return quick local stub to maintain latency.
  if (!res || !res.ok) {
    const lastUserMsg = [...prompt].reverse().find((m) => m.role === 'user')?.content ??
      'your goals'
    return {
      text:
        `I hear that ${lastUserMsg}. Let's take one small step today to build momentum! What is one action you can commit to right now?`,
    }
  }

  const data: unknown = await res.json()

  // ----------------------------- Parse ------------------------------------

  // NARROW: OpenAI format has a choices array with a message.content string
  const looksLikeOpenAI = typeof data === 'object' &&
    data !== null &&
    Array.isArray((data as Partial<OpenAIResponse>).choices) &&
    ((data as Partial<OpenAIResponse>).choices?.[0]?.message?.content ?? false)

  if (looksLikeOpenAI) {
    const oa = data as OpenAIResponse
    const text = oa.choices[0].message.content
    const usage = oa.usage
    let cost = 0
    if (usage) {
      const pricing: Record<string, { prompt: number; completion: number }> = {
        'gpt-4o': { prompt: 0.005, completion: 0.015 },
        'gpt-4o-mini': { prompt: 0.003, completion: 0.009 },
        'gpt-3.5-turbo': { prompt: 0.0005, completion: 0.0015 },
      }
      const price = pricing[aiModel] ?? { prompt: 0.0, completion: 0.0 }
      cost = ((usage.prompt_tokens || 0) * price.prompt +
        (usage.completion_tokens || 0) * price.completion) / 1000
    }

    return {
      text: text || 'I apologize, but I cannot respond right now.',
      usage: usage
        ? {
          prompt_tokens: usage.prompt_tokens,
          completion_tokens: usage.completion_tokens,
          total_tokens: usage.total_tokens,
          cost_usd: parseFloat(cost.toFixed(6)),
        }
        : undefined,
    }
  }

  // Anthropic Claude shape (or any provider with similar structure)
  const anthropic = data as AnthropicResponse
  const text = anthropic.content?.[0]?.text ??
    'I apologize, but I cannot respond right now.'
  return { text }
}
