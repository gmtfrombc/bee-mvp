# Real-time Streaming Automated Tests (M2.2.6.3)

Implemented tests:

- `app/test/core/services/vitals_notifier_service_test.dart` – verifies
  subscription start/stop, data propagation, error paths.
- `supabase/functions/wearable-live-enrichment/test.ts` – unit tests enrichment
  Edge Function.
- Integration canary: `scripts/stream_latency_canary.sh` (runs on CI nightly)
  measuring RTT via WebSocket – p95 < 4.5 s.

To run locally:

```bash
flutter test test/core/services/vitals_notifier_service_test.dart
```

```bash
deno test -A supabase/functions/wearable-live-enrichment/test.ts
```
