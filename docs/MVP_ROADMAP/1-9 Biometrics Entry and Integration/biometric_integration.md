
# BEE App – Biometric Data Trigger System for Coaching (MVP)

---

## 🧠 Overview

This module defines how biometric data (e.g., steps, sleep, active energy) should be used within the BEE app.

- ✅ Used for **coaching triggers and personalized check-ins**
- 🚫 NOT used for direct changes to the **Momentum (Engagement) Score** unless **user confirms context**
- 🎯 Goal: preserve data trust, reduce false positives, and support behaviorally intelligent AI coaching

---

## 🎯 Biometric Signals Collected

| Metric | Notes |
|--------|-------|
| **Steps** | From Apple Health / Health Connect |
| **Active Energy** | Preferred over steps if available |
| **Sleep Duration** | Nightly hours |
| **HRV** | Read but not used for scoring |
| **Resting Heart Rate** | Read but not scored |

---

## 🚧 Why Biometric Data is NOT Scored Directly

- Data is **incomplete**, **inconsistent**, and **modality-biased**
- Users may walk less but swim/bike more
- A “bad” biometric trend may reflect **life context** (e.g., vacation, illness, broken device)
- False scoring would erode **user trust**

---

## ✅ How Biometrics Are Used

### 1. **Trigger Coaching Conversations**
When a significant pattern is detected, the AI Coach initiates a check-in:
- Drop in sleep ≥2 nights
- Drop in active energy or steps for ≥2 days
- Sudden complete loss of data

#### Example:
> “Hey, I noticed your sleep’s been down the past couple nights—anything going on?”

---

### 2. **If User Confirms a Slump → Score Modifier Applied**

- If the patient reports disengagement, the AI calls:
```ts
updateMomentumScore(user_id, -10, "Confirmed disengagement via chat")
```

- If the patient reports neutral/positive context (e.g., vacation), no score is updated

#### Alternate Outcome:
> “Got it—just a change of routine. No worries, I’ll keep checking in.”

---

## 🧠 Backend Logic Flow

```mermaid
graph TD
    A[Biometric Drop Detected] --> B{Pattern Persisted > 2 days?}
    B -- Yes --> C[Trigger AI Coaching Prompt]
    C --> D{User indicates disengagement?}
    D -- Yes --> E[Call updateMomentumScore()]
    D -- No --> F[No change to score]
    B -- No --> G[No action]
```

---

## 📂 Backend Requirements

### 1. Biometric Flag Detection
- Create logic that checks for:
  - Steps down ≥40% from 7-day avg for 2+ days
  - Sleep <6 hrs for 2+ nights
  - No data from steps, sleep, and energy for 48+ hrs

→ Insert flag into `biometric_flags` table:
```json
{
  "user_id": "uuid",
  "flag_type": "low_sleep_2days",
  "timestamp": "2025-06-28T08:00:00Z"
}
```

### 2. AI Coach Integration
- When biometric flag exists, AI chat opens with a relevant message
- Response from user analyzed:
  - If disengaged: score adjusted
  - If not: flag marked “resolved_no_action”

### 3. Logging Score Updates
- Log score changes via `updateMomentumScore()` function
- Track reason and timestamp

---

## ✅ Summary

- Biometrics are **informational**, not determinative
- Momentum score should reflect **confirmed engagement**, not inferred data
- AI Coach is the **interpreter and mediator** of noisy inputs

---

**Last updated:** June 2025
