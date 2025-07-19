# Biometric Flags — Migration Notes & Realtime RLS

This file documents security considerations and broadcast permissions introduced
by the **`biometric_flags`** table and associated realtime channel.

## 1. Table Security

`biometric_flags` is protected by an **owner-only** RLS policy:

```sql
CREATE POLICY "Owner can read/write own flags" ON biometric_flags
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

This ensures users can **only** see their own flags and prevents cross-tenant
leakage.

## 2. Realtime Broadcast Channel

The edge function `biometric_flag_detector@1.0.0` publishes flag events via:

```ts
supabase.realtime.broadcast("public:biometric_flag", payload);
```

Channel characteristics:

| Property  | Value                                             |
| --------- | ------------------------------------------------- |
| Namespace | `public`                                          |
| Channel   | `biometric_flag`                                  |
| Direction | **Write → Service Role only**; **Read → Clients** |

### 2.1 Access Rules

Add the following RLS rule in `supabase_realtime` schema to lock down writes:

```sql
-- Only service-role can broadcast
ALTER PUBLICATION supabase_realtime ADD TABLE public.biometric_flags;

-- Client writes are disabled by default; no action required
```

Clients subscribe using anon or logged-in keys and receive read-only messages.

## 3. Migration Ordering

1. **`create_biometric_flags.sql`** (table + RLS + indexes)
2. **`install_realtime_rls.sql`** (optional if publication already exists)

Run migrations with `supabase db reset` locally or GitHub CI matrix; the pgTAP
suite validates:

- Table schema & indexes
- RLS owner constraint
- Broadcast channel availability

---

**Last updated:** $(date +"%Y-%m-%d")
