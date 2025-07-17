# Action Steps Analytics Event Schema

This document standardizes the analytics payloads emitted by the Action Steps
feature so that mobile, backend, and data-warehouse teams remain in sync.

---

## 1. Events

| Event Name              | Trigger                             | Description                             |
| ----------------------- | ----------------------------------- | --------------------------------------- |
| `action_step_set`       | When a user saves a new Action Step | Captures details of the goal being set. |
| `action_step_completed` | When a daily completion is logged   | Indicates success or skip outcome.      |

---

## 2. Common Properties

| Property         | Type            | Required | Notes                              |
| ---------------- | --------------- | -------- | ---------------------------------- |
| `user_id`        | UUID            | Yes      | Supabase `auth.uid()`.             |
| `action_step_id` | UUID            | Yes      | Primary key of `action_steps` row. |
| `timestamp`      | ISO-8601 string | Yes      | Client-side event time in UTC.     |
| `device_id`      | String          | Yes      | Amplitude device ID.               |

---

## 3. Event-Specific Properties

### 3.1 `action_step_set`

| Property      | Type              | Required | Notes                                          |
| ------------- | ----------------- | -------- | ---------------------------------------------- |
| `category`    | String            | Yes      | e.g. `physical_activity`, `nutrition`.         |
| `description` | String            | Yes      | Goal text shown to user.                       |
| `frequency`   | Int               | Yes      | Expected completions per week (3-7).           |
| `week_start`  | Date (YYYY-MM-DD) | Yes      | ISO date of the Monday starting the goal week. |
| `source`      | String            | Yes      | `manual` or `coach_suggested`.                 |

### 3.2 `action_step_completed`

| Property         | Type   | Required | Notes                             |
| ---------------- | ------ | -------- | --------------------------------- |
| `status`         | String | Yes      | `success` or `skipped`.           |
| `momentum_delta` | Float  | No       | Change applied to Momentum Score. |

---

## 4. Versioning

Any breaking change requires bumping the event name suffix (e.g.
`action_step_set_v2`) and updating downstream ETL jobs.

---

## 5. Validation Checklist

- [ ] Payload conforms to property tables above.
- [ ] Events appear in Amplitude staging project.
- [ ] ETL integration tests pass.

---

_Last updated: <!-- ADD DATE -->_
