# User Acceptance Testing – Wearable Integration (M2.2.6.10)

## Scope

End-to-end validation of wearable onboarding, real-time vitals, and dashboard
tiles on both iOS & Android.

## Test Personas

1. **Alice (iOS)** – Apple Watch Ultra user, high steps, night shift sleeper.
2. **Bob (Android)** – Garmin beta user on Pixel 8.
3. **Clara (Samsung)** – Galaxy Watch user; limited HRV support.

## Happy Path

1. Install app → open onboarding.
2. Select wearable platform (chooser widget).
3. Grant all permissions.
4. Observe first data in <30 s.
5. Close app 30 min → reopen → tiles refresh.
6. Trigger walking test 1000 steps → HR rise → Live Vitals updates ≤5 s.

## Edge Cases

- Deny permissions twice → Android Settings guidance appears.
- Revoke HealthKit permission in iOS Settings → app shows missing-permission
  state.
- Switch platform from Apple Health → Health Connect; ensure old tokens revoked.

## Acceptance Criteria

✓ All happy-path steps pass for 3 personas.<br/>✓ App handles each edge case
gracefully (no crashes, clear UI).<br/>✓ Grafana dashboard shows live metrics
for each test user.<br/>✓ JITAI trigger arrives when sleep score <60 (simulate
by editing supabase record).

## Sign-off

Stakeholders: Mobile lead, QA lead, AI coaching PM.<br/>Signed off on
2025-06-16.
