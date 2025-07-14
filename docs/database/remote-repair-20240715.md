# Remote migration repair – 2024-07-15

Two experimental migrations (`20240715211000`, `20240715211500`) were deleted
during hot-fix work. They still existed in the Supabase project’s
`schema_migrations` table, which blocked `supabase db push` on deploy.

On 2025-07-14 we ran:

```bash
supabase migration repair --status reverted 20240715211000 20240715211500
```

This marked both versions as **reverted** without changing the schema. Repo and
remote migration histories are now in sync.
