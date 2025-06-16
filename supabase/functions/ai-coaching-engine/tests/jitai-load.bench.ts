import { jitaiController } from '../routes/jitai.controller.ts'

Deno.bench('evaluate-jitai 100 reqs', async () => {
  Deno.env.set('DENO_TESTING', 'true')
  const body = { user_id: 'bench' }
  const reqInit = {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }
  for (let i = 0; i < 100; i++) {
    const res = await jitaiController(new Request('http://localhost/evaluate-jitai', reqInit), {
      cors: {},
    })
    if (res.status !== 200) throw new Error('non-200')
  }
})
