
# Wearable Integration Milestones (Revised)

## ### M2.2.1 Device Integration Architecture (REVISED)

| Task | Description | Est. hrs | Owner | Status |
|------|-------------|----------|-------|--------|
| **T2.2.1.1** | **Select & spike Flutter packages** – confirm `health_kit_reporter` (iOS) + `health_connect` (Android) meet data‑type & background‑sync needs; document any gaps. | 8 | Mobile | ⬜ |
| **T2.2.1.2** | Prototype **cross‑platform abstraction** `WearableDataRepository` (Dart) that hides platform specifics and emits unified `HealthSample` models. | 10 | Mobile | ⬜ |
| **T2.2.1.3** | Add **iOS HealthKit entitlement** & configure Apple Health capabilities in Xcode; create Info.plist `NSHealthShareUsageDescription`. | 4 | Mobile | ⬜ |
| **T2.2.1.4** | Implement iOS **permission flow UI** (modal + settings deep‑link) for all required types (steps, HR, HRV, sleep, active energy, VO₂ max). | 6 | UX | ⬜ |
| **T2.2.1.5** | Implement Android **Health Connect permission & OAuth flow** (Google sign‑in + `HealthPermissions` API). | 6 | Mobile | ⬜ |
| **T2.2.1.6** | Build **token / scope manager** service to cache granted permissions, request deltas, and surface “missing‑permission” toast. | 6 | Mobile | ⬜ |
| **T2.2.1.7** | Create **Garmin→Apple Health enablement wizard** (one‑time checklist instructing tester to toggle Garmin Connect write‑permissions). | 4 | UX | ⬜ |
| **T2.2.1.8** | **Feature‑flag Android Garmin beta** – detect Health Connect data origin and warn if Garmin support not yet enabled on tester’s device. | 4 | Mobile | ⬜ |
| **T2.2.1.9** | Add **background fetch / observers**: `HKObserverQuery` (iOS) and `HealthDataService.subscribe()` (Android) to push deltas into the app even when closed. | 8 | Mobile | ⬜ |
| **T2.2.1.10** | Push samples to **Supabase Edge function** via batched HTTPS; return 201/400 diagnostics for retry logic. | 6 | Backend | ⬜ |
| **T2.2.1.11** | **HIPAA checklist** – encryption at rest, access‑token rotation schedule, audit‑log of every sample write. | 4 | Compliance | ⬜ |
| **T2.2.1.12** | **Telemetry & logging** – attach Sentry breadcrumbs to every sync attempt; Grafana dashboard for sync latency & failure codes. | 6 | DevOps | ⬜ |

**Deliverables**

* Unified `WearableDataRepository` service (Dart) + platform channels  
* iOS & Android permission screens wired to native stores  
* Background observer → Supabase pipeline skeleton  
* Tester wizard for Garmin Connect ↔ Apple Health toggles  
* Grafana panel “Health Sync Latency” and log schema

**Acceptance**

- Repository returns ≥ 5 sample types on both OSs within 30 s of app launch  
- Permission denial handled gracefully (UI + retry)  
- HealthKit & Health Connect unit tests (mocked) pass in CI

---

## ### M2.2.1.5 Real Data Integration & Validation (REVISED)

| Task | Description | Est. hrs | Owner | Status |
|------|-------------|----------|-------|--------|
| **T2.2.1.5‑1** | Enrol **principal tester** (you) with TestFlight + Garmin Connect; capture baseline screenshots of Apple Health dashboard. | 2 | QA | ⬜ |
| **T2.2.1.5‑2** | Run **guided data‑pull script** in Debug build: fetch last 24 h of steps, HR, sleep; write to local SQLite cache & send to Supabase `wearable_raw`. | 6 | Mobile | ⬜ |
| **T2.2.1.5‑3** | Build **Data Quality harness**: compare pulled values vs. Apple Health Summary using runtime asserts (±3 % tolerance). | 6 | QA | ⬜ |
| **T2.2.1.5‑4** | Create **“Live Vitals” developer screen** (in‑app) showing last 5 seconds of heart‑rate & step deltas for ad‑hoc validation. | 4 | Mobile | ⬜ |
| **T2.2.1.5‑5** | Log **edge cases**: permission revocation, airplane‑mode, timestamp drift; document mitigation tickets. | 4 | QA | ⬜ |
| **T2.2.1.5‑6** | Export day‑level CSV from Supabase and attach to Confluence validation report. | 2 | Backend | ⬜ |
| **T2.2.1.5‑7** | **Green‑light Android parity** checklist: once Garmin → Health Connect public beta detected, repeat steps 1‑6 on Pixel test device. | 4 | QA | ⬜ |

**Deliverables**

* Confluence “Garmin Real‑Data Validation Report” with screenshots & CSV  
* Live Vitals dev screen (hidden behind debug flag)  
* Pass/fail quality script in CI (`flutter drive --target=test/health_validation.dart`)

**Acceptance**

- Baseline correlation ≥ 97 % for steps & HR, ≥ 90 % for sleep minutes  
- Live Vitals updates ≤ 5 s after movement (screen‑on)  
- Known edge cases logged with Jira tickets

---

## ### M2.2.2 Real‑time Data Streaming (REVISED)

| Task | Description | Est. hrs | Owner | Status |
|------|-------------|----------|-------|--------|
| **T2.2.2.1** | Design **WebSocket channel** (`supabase_realtime`) schema `wearable_live:{user_id}`; choose JSON envelope `<timestamp, type, value, source>`. | 6 | Backend | ⬜ |
| **T2.2.2.2** | Implement **iOS background delivery**: use `HKAnchoredObjectQuery` with `deliverImmediately`; throttle to 5 s min‑interval. | 8 | Mobile | ⬜ |
| **T2.2.2.3** | Implement **Android callback flow** via `PassiveListenerService` + coroutine channel; throttle identical to iOS. | 8 | Mobile | ⬜ |
| **T2.2.2.4** | Encode & push **delta packets** to WebSocket; fall back to HTTPS batch if socket unavailable. | 6 | Backend | ⬜ |
| **T2.2.2.5** | Build **Edge Function up‑converter**: enrich deltas with rolling 5‑min average & battery flag; publish to `wearable_live_enriched`. | 6 | Backend | ⬜ |
| **T2.2.2.6** | **Client‑side subscriber** – Provider pattern that updates `VitalsNotifier` for UI widgets & JITAI engine. | 4 | Mobile | ⬜ |
| **T2.2.2.7** | **Offline buffer** (Hive) storing max 2 h of deltas; flush on reconnect. | 4 | Mobile | ⬜ |
| **T2.2.2.8** | Bench **latency & battery**: automate 30‑min walking test; record mean RTT & phone battery drain. | 6 | QA | ⬜ |
| **T2.2.2.9** | Implement **adaptive polling fallback** (user setting) to reduce resource use on older devices. | 4 | Mobile | ⬜ |
| **T2.2.2.10** | Create **Grafana live‑stream dashboard** (messages per minute, median latency, error rate). | 4 | DevOps | ⬜ |

**Deliverables**

* Live WebSocket streaming service in production  
* Edge enrichment function & redundant HTTPS fallback  
* `VitalsNotifier` with unit tests → updates sample UI tile  
* Grafana “Streaming Health” dashboard

**Acceptance**

- Median end‑to‑end latency ≤ 3 s on Wi‑Fi, ≤ 5 s on LTE  
- Stream survives 5‑minute offline test with zero data loss after reconnection  
- 30‑min walking test shows phone battery drain ≤ 4 %  
- Dashboard alert < 2 % error rate over 24 h canary run

---

## ### M2.2.3 User‑Facing Wearable Dashboard & Platform Chooser

| Task | Description | Est. hrs | Owner | Status |
|------|-------------|----------|-------|--------|
| **T2.2.3.1** | Decide on initial metrics to show to user, empty states, and three data tiles (consider Steps, Sleep, Heart Rate). | 6 | UX | ⬜ |
| **T2.2.3.2** | Implement **`PlatformChooserWidget`** (Flutter): shows Apple Health + Health Connect icons, detects availability, deep‑links to native permission flow. | 8 | Mobile | ⬜ |
| **T2.2.3.3** | Wire chooser to **`WearableDataRepository.requestSetup()`**; persist selection in Hive & trigger re‑auth if revoked. | 6 | Mobile | ⬜ |
| **T2.2.3.4** | Build **`StepsTile`, `SleepTile`, `HeartRateTile`** widgets; subscribe to `VitalsNotifier` for real‑time updates. | 10 | Mobile | ⬜ |
| **T2.2.3.5** | Add **empty / error / loading** states with pull‑to‑refresh; include CTA to open permissions if blocked. | 4 | UX | ⬜ |
| **T2.2.3.6** | Implement **accessibility & theming** (contrast, semantics labels, dark‑mode). | 4 | QA | ⬜ |
| **T2.2.3.7** | Emit **analytics events** (`platform_selected`, `tile_viewed`, `tile_error`) to Supabase Edge; update Grafana. | 4 | DevOps | ⬜ |
| **T2.2.3.8** | **Widget tests** (golden + state) using mocked repository; coverage ≥ 80 %. | 6 | QA | ⬜ |

**Deliverables**

* `PlatformChooserWidget` integrated into onboarding & Settings  
* Three live data tiles rendered on Home screen (or Momentum screen)  
* Figma spec + accessibility report  
* Widget test suite and analytics dashboard panel “Tile Activity”

**Acceptance**

- User can pick a platform, grant permissions, and see first data within < 30 s  
- Tiles auto‑refresh when `VitalsNotifier` receives deltas (demo with walk test)  
- Empty/error states render correctly when data unavailable or permissions revoked  
- Golden tests pass in CI; coverage report shows ≥ 80 % for `ui/` folder
