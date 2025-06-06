# Momentum Score Listener

Edge Function that listens to momentum score changes and triggers AI coaching interventions.

## Purpose

This function implements **M1.3.6 - Momentum Integration & Proactive Nudge** by:

1. Listening to `daily_engagement_scores` table inserts via Supabase webhooks
2. Detecting momentum state changes (Rising, Steady, NeedsCare)
3. Triggering AI coaching responses for state transitions
4. Sending push notifications via FCM
5. Storing coaching notifications for Today Feed integration

## Setup

### Environment Variables

```bash
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
AI_COACHING_ENGINE_URL=http://localhost:54321/functions/v1/ai-coaching-engine
```

### Supabase Webhook Configuration

Configure a webhook in your Supabase project:

1. Go to Database → Webhooks
2. Create new webhook for `daily_engagement_scores` table
3. Set URL to your deployed function endpoint
4. Select `INSERT` events
5. Set HTTP method to `POST`

## Usage

The function is triggered automatically when new momentum scores are inserted. It:

1. Compares current momentum state with previous day
2. Only triggers on actual state changes
3. Calls AI coaching engine with system event context
4. Sends push notification with coaching message
5. Stores notification in database for Today Feed

## Testing

```bash
deno test --allow-all momentum-score-listener.test.ts
```

## Deployment

Deploy using Supabase CLI:

```bash
supabase functions deploy momentum-score-listener
```

## Integration Points

- **AI Coaching Engine**: Calls `/ai-coaching-engine` with momentum change context
- **FCM**: Sends push notifications via user FCM tokens
- **Today Feed**: Stores notifications for in-app coaching cards
- **Momentum Calculator**: Triggered by momentum score updates 