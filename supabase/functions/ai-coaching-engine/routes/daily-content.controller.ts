// routes/daily-content.controller.ts
// Controller for POST /generate-daily-content endpoint.
// Expects DailyContentRequest and returns JSON<GeneratedContent>

import { getSupabaseClient } from '../_shared/supabase_client.ts'
import { DailyContentRequest } from '../types.ts'
import { generateDailyHealthContent } from '../services/daily-content.service.ts'

interface ControllerOptions {
  cors: Record<string, string>
  isTestingEnv: boolean
  supabaseUrl?: string | null
  serviceRoleKey?: string | null
}

type SupabaseClient = any

export async function dailyContentController(
  req: Request,
  { cors, isTestingEnv, supabaseUrl, serviceRoleKey }: ControllerOptions,
): Promise<Response> {
  const start = Date.now()

  try {
    const body: DailyContentRequest = await req.json()
    const { content_date, topic_category, force_regenerate = false } = body

    if (!content_date) {
      return json({ error: 'Missing required field: content_date' }, 400, cors)
    }

    const authToken = req.headers.get('Authorization')?.replace('Bearer ', '')
    if (authToken !== serviceRoleKey) {
      return json(
        { error: 'Unauthorized: Service role key required for content generation' },
        401,
        cors,
      )
    }

    if (isTestingEnv) throw new Error('Daily content generation not supported in test environment')
    if (!supabaseUrl || !serviceRoleKey) throw new Error('Missing Supabase configuration')

    const supabase: SupabaseClient = await getSupabaseClient({ overrideKey: serviceRoleKey })

    if (!force_regenerate) {
      const { data: existing } = await supabase
        .from('daily_feed_content')
        .select('*')
        .eq('content_date', content_date)
        .single()

      if (existing && existing.full_content !== null && existing.full_content !== undefined) {
        return json(
          {
            success: true,
            message: 'Content already exists for this date',
            content: existing,
            generated: false,
            response_time_ms: Date.now() - start,
          },
          200,
          cors,
        )
      }
    }

    const generated = await generateDailyHealthContent(content_date, topic_category)
    if (!generated) throw new Error('Failed to generate content')

    // ------------------------------------------------------------------
    // Guarantee rich full_content structure for client consumption
    // ------------------------------------------------------------------
    generated.full_content = ensureRichFullContent(generated)

    const { data: saved, error: saveErr } = await supabase
      .from('daily_feed_content')
      .upsert({
        content_date,
        title: generated.title,
        summary: generated.summary,
        topic_category: generated.topic_category,
        ai_confidence_score: generated.confidence_score,
        content_url: generated.content_url,
        external_link: generated.external_link,
        full_content: generated.full_content,
      }, { onConflict: 'content_date' })
      .select()
      .single()

    if (saveErr) throw new Error(`Failed to save content: ${saveErr.message}`)

    return json(
      {
        success: true,
        message: 'Daily content generated successfully',
        content: saved,
        generated: true,
        response_time_ms: Date.now() - start,
      },
      200,
      cors,
    )
  } catch (err) {
    console.error('Error generating daily content:', err)
    return json(
      {
        error: 'Failed to generate daily content',
        message: err instanceof Error ? err.message : 'Unknown error',
        response_time_ms: Date.now() - start,
      },
      500,
      cors,
    )
  }
}

function json(payload: unknown, status: number, headers: Record<string, string>): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  })
}

function ensureRichFullContent(content: {
  summary: string
  topic_category?: string
  full_content?: unknown
}): unknown {
  // deno-lint-ignore no-explicit-any
  const fc: any = content.full_content
  if (fc && Array.isArray(fc.elements) && fc.elements.length >= 3) {
    // quick sanity—ensure first two paragraphs + bullet_list
    const [a, b, c] = fc.elements
    if (
      a?.type === 'paragraph' &&
      b?.type === 'paragraph' &&
      c?.type === 'bullet_list' &&
      Array.isArray(c.list_items) && c.list_items.length >= 3
    ) {
      return fc
    }
  }
  // Fallback: construct minimal rich structure from summary
  const para = { type: 'paragraph', text: content.summary }
  const topicSecond: Record<string, string> = {
    nutrition: 'Consistently choosing balanced meals lays the foundation for long-term health.',
    exercise: 'Consistent, moderate movement adds up and supports strength, mobility, and mood.',
    sleep: 'Aim for a calm wind-down routine to help your body recognise it is time to rest.',
    stress: 'Small mindful pauses throughout the day can lower stress and build resilience.',
    prevention: 'Every positive choice today is an investment in your future wellbeing.',
    lifestyle: 'Small daily habits compound, creating sustainable lifestyle change over time.',
  }
  const finalSecondParagraph = topicSecond[content.topic_category ?? 'lifestyle'] ??
    'Small healthy actions completed regularly can make a big difference over time.'
  return {
    elements: [
      para,
      { type: 'paragraph', text: finalSecondParagraph },
      {
        type: 'bullet_list',
        list_items: [
          "Apply today's insight in a small way",
          'Share it with a friend for accountability',
          'Consult a professional for personalised advice',
        ],
        text: '',
      },
    ],
  }
}
