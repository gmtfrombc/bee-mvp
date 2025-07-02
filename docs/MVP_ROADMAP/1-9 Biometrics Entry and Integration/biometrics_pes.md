
# BEE App – Energy Level and Manual Biometrics Input (MVP)

---

## 📦 Milestones
### 1. **Perceived Energy Score System**
### 2. **Manual Biometrics Input & Metabolic Health Score Calculation**

---

## 🔹 Milestone 1: Perceived Energy Score System

### 🎯 Goal
Capture users’ **perceived daily energy level** as a proxy for readiness, mood, and motivation.

### ✅ Features
- Prompted daily on the Momentum Screen:  
  > “How’s your energy today?”
- 1–5 emoji scale (or stars/smiley UI) mapped to numeric value:
  | Emoji | Value |
  |-------|--------|
  | 😴 Very low | 1 |
  | 😕 Low | 2 |
  | 🙂 Neutral | 3 |
  | 😄 High | 4 |
  | 🚀 Excellent | 5 |

### 🧠 UX Logic
- Defaults to daily prompt (user can change frequency to every 2, 3, or 7 days)
- Tap-to-log interaction (no text required)
- Entry saved to `energy_levels` table

```json
{
  "user_id": "uuid",
  "value": 4,
  "timestamp": "2025-06-30T08:00:00Z"
}
```

### 🧾 Backend Tasks
- Create `energy_levels` table in Supabase
- Daily reminder toggle (default daily)
- Rolling average and trendline to display in future dashboard

---

## 🔹 Milestone 2: Manual Biometrics Input + Metabolic Score

### 🎯 Goal
Allow patients to manually input key biometrics for metabolic health scoring (until EHR/cloud integration is live).

### ✅ Data Inputs (via onboarding and update screen)
- **Weight (lbs or kg)** ✅
- **Height (ft/in or cm)** ✅ (from onboarding)
- **Systolic BP**
- **Diastolic BP**
- **Fasting Blood Glucose**
- **Triglycerides**
- **HDL Cholesterol**
- **Optionally: Enter Metabolic Health Score manually**

### 🧠 UI Recommendations
- Access from user profile/settings or Metabolic Score tile
- Include unit validation and support for US/metric toggle
- Include brief context (e.g., “Enter your most recent lab values”)

### 🧾 Data Table: `biometric_manual_inputs`
```json
{
  "user_id": "uuid",
  "weight": 178,
  "height_cm": 177,
  "systolic_bp": 118,
  "diastolic_bp": 75,
  "triglycerides": 140,
  "hdl": 52,
  "fasting_glucose": 92,
  "entered_mhs": null,
  "calculated_mhs": 72,
  "timestamp": "2025-06-30T08:00:00Z"
}
```

---

## ⚙️ Metabolic Health Score (MHS) Logic

- Use validated z-score → percentile algorithm based on **metscalc.com**
- Convert percentile to “Vitality Score”
- If patient enters MHS manually, override calculated score
- Label as:
  > “Your Vitality Score is 72 (out of 100). Lower score = higher metabolic risk.”

---

## 🔁 Future Integration Path

- Replace manual input once EHR/Cloud integration active
- Migrate `biometric_manual_inputs` into primary biometrics stream
- Flag for validation discrepancies between manual and sourced data

---

## ✅ Summary

| Feature | Purpose |
|--------|---------|
| Energy Score | Captures day-to-day engagement and subjective wellbeing |
| Manual Biometrics | Enables metabolic scoring and trend tracking |
| MHS Support | Patients can either calculate from inputs or enter a lab-provided score |
| UI Simplicity | Emoji sliders, toggle frequency, unit validation ensure high usability |

---

**Last updated:** June 2025
