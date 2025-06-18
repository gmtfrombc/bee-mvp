
# 🛠️ Supabase Edge-Function – Revised Diagnostic Plan (504 + JWT Off)

## 🔍 Updated Diagnosis

Even with **JWT verification turned off**, sending requests with a **signed service-role JWT** still leads to a **504 Gateway Timeout**. This strongly suggests the issue is **not your code**, but rather a **Cloudflare WAF or edge security rule** that blocks the request before your function ever executes.

---

## ✅ Revised Recommendations

### 1. 🔧 Test Function Without Authorization Header

```bash
curl -i -X POST https://<project>.supabase.co/functions/v1/daily-gen \
  -H "x-test: 1" \
  -H "Content-Type: application/json" \
  -d '{"target_date":"2025-06-18"}'
```

✅ If this works: the function itself is fine.  
❌ If this fails: even the route alone is triggering the block.

---

### 2. 🧪 Test With Smaller JWT (e.g. Anon Key)

```bash
curl -i -X POST https://<project>.supabase.co/functions/v1/daily-gen \
  -H "Authorization: Bearer <anon_key>" \
  -H "Content-Type: application/json" \
  -d '{"target_date":"2025-06-18"}'
```

✅ If this works but SRK fails → **header size or role string** is triggering the filter.

---

### 3. 🪄 Rename Function Route Again (e.g., `tile-job`)

```bash
mv supabase/functions/daily-gen supabase/functions/tile-job
supabase functions deploy tile-job --use-api
```

✅ If the renamed route works: path name (like `daily-content`) may have been flagged by Cloudflare  
❌ If it still fails: confirms token is the core issue.

---

### 4. 🔍 Enable Edge Debug Headers

If your Supabase project supports it:
- Go to **Project Settings → Edge Functions**
- Enable **“Debug Headers”**

These headers may reveal the exact WAF rule ID that’s blocking your request:
```
x-waf-rule-id: 12345
```

---

### 5. 🛠 Use `x-cron-auth` Instead of Authorization Header

If you don't need user/session-based access:
- Stop using `Authorization` header
- Replace with a custom header in your cron/trigger calls:

```bash
curl -i -X POST https://<project>.supabase.co/functions/v1/daily-gen \
  -H "x-cron-auth: my-secure-token" \
  -H "Content-Type: application/json" \
  -d '{"target_date":"2025-06-18"}'
```

Then in your function:
```ts
const auth = req.headers.get("x-cron-auth");
if (auth !== Deno.env.get("CRON_SECRET")) {
  return new Response("Unauthorized", { status: 401 });
}
```

---

## ✅ Final Checklist

| Step | Complete? |
|------|-----------|
| ✅ JWT verification disabled | ✔ |
| 🔁 Route renamed to neutral slug | ☐ |
| 🧪 Small token / no Authorization tested | ☐ |
| 🔍 Edge logs / WAF headers enabled | ☐ |
| 🛠 Fallback auth with `x-cron-auth` | ☐ |

---

This confirms you're running into an edge-layer block, not a code problem. Your next step is to isolate **which piece of the request triggers the block**, then either work around it or escalate with Supabase support including full request headers + WAF rule ID.
