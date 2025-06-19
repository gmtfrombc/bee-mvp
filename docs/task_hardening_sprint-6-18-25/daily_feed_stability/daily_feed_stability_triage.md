# Daily Feed & Momentum Screen – H1.2 Stability Triage

**Sprint:** Stability & Observability Hardening (Pre-Epic 1.4)

**Scope lock date:** {{DATE}}

---

## 1. Components in Scope

1. **Daily Feed (Today Tile)** – AI-generated article, topic chip, "Read More"
   link.
2. **Momentum Meter (gauge) & "This Week's Journey" bar** – shows momentum score
   per day.
3. **Home-Screen Layout** – placement/scroll interaction for tiles + hidden
   cards.
4. **Legacy/Placeholder Widgets** – Transition State Demo,
   Lesson/Streak/Today/Badges cards, Learn/Share buttons.

---

## 2. Observed Defects & Symptoms

| ID    | Component      | Symptom                                                                  | Frequency | Notes                                                                |
| ----- | -------------- | ------------------------------------------------------------------------ | --------- | -------------------------------------------------------------------- |
| DF-01 | Daily Feed     | Article never rotates (same content > 7 days).                           | 100 %     | Edge function scheduled at 03:00 appears not to run / write new row. |
| DF-02 | Daily Feed     | Article topic chip (e.g. "exercise") does not match article body.        | ~70 %     | Likely stale metadata fetch; chip not linked to article row.         |
| DF-03 | Daily Feed     | "Read More" link is present but taps do nothing.                         | 100 %     | URL null or WebView not invoked.                                     |
| DF-04 | Daily Feed     | Writing quality uneven; needs prompt tuning.                             | Always    | To be addressed in separate content workstream.                      |
| DF-05 | Layout         | Tile sits mid-screen; user scroll attempts scroll the tile not the page. | High      | Poor UX; tile intercepts drag gesture.                               |
| MM-01 | Momentum Meter | "This Week's Journey" shows blank line, no day labels.                   | 100 %     | Data binding missing.                                                |
| MM-02 | Momentum Meter | Icons not wired to momentum score (plant / smile / rocket).              | 100 %     | Needs mapping to 7-day rolling average.                              |
| HS-01 | Home cards     | Lesson / Streak / Today / Badges cards visible but empty.                | Always    | Should be hidden until implemented.                                  |
| HS-02 | Buttons        | "Learn" and "Share" buttons not wired.                                   | Always    | Should be hidden or feature-flagged.                                 |
| LG-01 | Legacy         | "Transition State Demo" widget still present.                            | Always    | Safe to delete.                                                      |

---

## 3. Current Implementation Facts / Unknowns

| Area               | Known                                                        | Unknown / To-Do                                                   |
| ------------------ | ------------------------------------------------------------ | ----------------------------------------------------------------- |
| **Rotation job**   | Edge function scheduled daily 03:00 _local device_           | Exact runtime environment & timezone handling; verify cron entry. |
| **Content source** | Articles stored in Supabase Postgres; old articles retained. | Upstream prompt chain (Vertex?), retention policy (keep 20).      |
| **Topic chip**     | Field exists in table.                                       | Canonical list not yet defined; mapping rules TBD.                |
| **Momentum data**  | Supabase computes momentum score daily.                      | API contract for 7-day slice; thresholds for icons & colours.     |

---

## 4. Suspected Root Causes / Hypotheses

1. **Cron mis-time-zone** – Edge function runs UTC 03:00 → outside local day
   boundary; fails to insert.
2. **Edge function 500** – content generation hitting rate-limit or missing env
   var; job exits early.
3. **Chip mismatch** – mobile fetches latest chip from RemoteConfig not Postgres
   row.
4. **Read More null URL** – column empty; or WebView handler not registered.
5. **Momentum widget unimplemented** – placeholder JSON; no API call.
6. **Gesture conflict** – Nested `SingleChildScrollView` on Today tile captures
   vertical drag.

---

## 5. Logging & Observability Gaps

- No metric for "daily_feed_rotation_success" (Edge) → Grafana panel.
- Mobile lacks log for `today_tile_tap_read_more` event.
- Momentum API calls not timed or traced.

---

## 6. Recommended Fixes & Owners (feed into H2-B tasks)

| #    | Area          | Fix                                                                                   | Est. hrs | Owner            |
| ---- | ------------- | ------------------------------------------------------------------------------------- | -------- | ---------------- |
| F-01 | Rotation job  | Verify cron timezone; log success/fail; emit metric.                                  | 2        | Backend          |
| F-02 | Rotation job  | Add retry & alert via Grafana if 2 failures / 24 h.                                   | 1        | DevOps           |
| F-03 | Chip          | Define canonical topic list (yaml); store with article row; bind tile chip to row.    | 3        | Product + Mobile |
| F-04 | Read More     | Add `url` column; open external link via in-app WebView.                              | 3        | Mobile           |
| F-05 | Retention     | DB job to delete articles > 20 old.                                                   | 1        | Backend          |
| F-06 | Layout        | Move Today tile near top; wrap in `IgnorePointer` for vertical drag pass-through.     | 2        | Mobile           |
| F-07 | Momentum      | Fetch 7 calendar-day momentum scores; map to icons; display day initials.             | 4        | Mobile           |
| F-08 | Hide cards    | Gate Lesson/Streak/Today/Badges + Learn/Share buttons behind `home_extras_beta` flag. | 2        | Mobile           |
| F-09 | Delete legacy | Remove "Transition State Demo" widget.                                                | 0.5      | Mobile           |

---

## 7. Open Questions

1. Should we keep "Read More" if external link requires GDPR/analytics consent?
2. Which colours/icons for missing vs future days in "This Week's Journey"?
3. Keep Today tile scrollable (for long articles) or truncate + expand?

---

## 8. Acceptance Criteria

- New article appears before 04:00 local each day (> 95 % 7-day).
- Topic chip text matches article topic column (QA script).
- "Read More" opens WebView with valid URL (no console errors).
- Page scrolls regardless of finger position on Today tile.
- "This Week's Journey" shows 7 labelled days with correct icon mapping.
- Hidden cards & buttons not visible in production build.
- Grafana panel `daily_feed_rotation_success_rate` > 95 % rolling 7 d.

---

_Prepared by:_ Mobile, Backend & DevOps
