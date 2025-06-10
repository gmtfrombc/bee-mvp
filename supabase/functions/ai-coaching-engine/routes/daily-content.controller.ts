// routes/daily-content.controller.ts
// Controller for POST /generate-daily-content endpoint.
// Expects DailyContentRequest and returns JSON<GeneratedContent>

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { DailyContentRequest } from '../types.ts'
import { generateDailyHealthContent } from '../services/daily-content.service.ts'

interface ControllerOptions {
  cors: Record<string, string>
  isTestingEnv: boolean
  supabaseUrl?: string | null
  serviceRoleKey?: string | null
}

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

    const supabase = createClient(supabaseUrl, serviceRoleKey)

    if (!force_regenerate) {
      const { data: existing } = await supabase
        .from('daily_feed_content')
        .select('*')
        .eq('content_date', content_date)
        .single()
      if (existing) {
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
