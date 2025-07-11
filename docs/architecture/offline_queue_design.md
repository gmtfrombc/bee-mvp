# Offline Queue Design for Onboarding Submission

Milestone **M1.11.6** · Action **C2**\
Status: 🟡 Draft – pending review

---

## Why an Offline Queue?

Submitting onboarding data requires network connectivity. To provide a seamless
user experience and ensure data integrity when the device is offline or has
intermittent connectivity, we persist the submission locally and retry when the
network is available.

---

## Storage Technology Choice

| Option            | Pros                                                                            | Cons                                           |
| ----------------- | ------------------------------------------------------------------------------- | ---------------------------------------------- |
| SharedPreferences | Simple key–value                                                                | Not suited for structured lists; no encryption |
| SQLite (Drift)    | Powerful queries; ACID                                                          | Heavier; schema migrations needed              |
| **Hive (chosen)** | Lightweight, fast (binary); supports encrypted boxes; no async-init boilerplate | Cannot run complex queries (OK for FIFO queue) |

**Hive** is preferred because:

1. Adds minimal binary size (<200 KB).
2. Box encryption via AES (password stored in secure storage).
3. No platform-specific code; works on Web (if needed).
4. Simpler model (pure Dart) than SQLite.

---

## Data Model

```dart
@HiveType(typeId: 30)
class OnboardingQueueItem {
  @HiveField(0)
  final String id; // uuid

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final Map<String, dynamic> answers; // raw survey answers

  @HiveField(3)
  final Map<String, dynamic>? tags; // optional AI tags

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  int attemptCount;
}
```

Box name: `onboarding_queue`

---

## Retention & Retry Policy

1. **FIFO Retry:** Attempt earliest item first to preserve order.
2. **Back-off:** Exponential (1 s → 2 s → 4 s … cap 30 s) between retries per
   item.
3. **Max Attempts:** 5 → then mark as _failed_ and surface to Sentry for manual
   inspection.
4. **Time-based TTL:** Purge items older than **7 days** nightly using a
   background task.
5. **Success Cleanup:** Remove item immediately after successful RPC response
   (`status == success`).

---

## Service Responsibilities

- `OnboardingQueueService`
  - `enqueue(OnboardingDraft draft)` – persists item.
  - `processQueue()` – called by connectivity listener.
  - `retryFailed()` – manual trigger (user retry button).
- Uses **Riverpod** `StateNotifier` to expose queue length for UI badges.

---

## Encryption & Security

- AES-256 key stored in **flutter_secure_storage** under
  `offline_queue_hive_key`.
- Only answers and tags are stored; no PII beyond user UUID (already public).
- Queue purged on user logout.

---

## Testing Strategy

1. **Unit:**
   - Serialization round-trip with Hive adapter.
   - Retry policy logic (attempt counts, back-off).
2. **Integration:**
   - Disable network → enqueue → enable network → expect RPC call.
3. **Performance:**
   - Insert 1 000 items; `processQueue()` completes <50 ms on mid-tier device.

---

## Open Questions

- Should we abstract queue for reuse by other offline features? _(future work)_
- Keep queue encrypted on Web? (No secure storage) – may need fallback.

---

_Author: AI Pair-Programmer\
Date: 2025-07-11_
