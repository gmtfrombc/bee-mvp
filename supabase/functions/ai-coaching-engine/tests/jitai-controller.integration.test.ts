import { jitaiController } from '../routes/jitai.controller.ts'

Deno.test('jitaiController enqueues push notification', async () => {
  // Set testing env to prevent Supabase calls
  Deno.env.set('DENO_TESTING', 'true')

  const body = { user_id: 'user-int' /* any wearable data comes from stub */
  }
  const req = new Request('http://localhost/evaluate-jitai', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  })

  const res = await jitaiController(req, { cors: {} })
  if (res.status !== 200) {
    throw new Error(`Expected 200 OK, got ${res.status}`)
  }
})
