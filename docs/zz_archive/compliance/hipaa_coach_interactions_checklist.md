# HIPAA Compliance Checklist – coach_interactions

| Requirement           | Implementation                                                 | Status     |
| --------------------- | -------------------------------------------------------------- | ---------- |
| ePHI access logged    | Row‐level audit via `coach_interactions` + Supabase logs       | ✅         |
| Minimum necessary     | Message previews truncated in `coach_interactions_public` view | ✅         |
| RLS enforced          | Policies restrict `user_id = auth.uid()`                       | ✅         |
| Encryption at rest    | Supabase defaults (AES-256)                                    | ✅         |
| Encryption in transit | HTTPS enforced                                                 | ✅         |
| Access revocation     | Supabase auth token expiry, RLS                                | ✅         |
| Audit retention       | ≥ 6 years (bucket lifecycle)                                   | ⬜ pending |
| Incident response     | See SECURITY_DOCS/CLAUDE_SECURITY_INSTRUCTIONS.md              | ✅         |
