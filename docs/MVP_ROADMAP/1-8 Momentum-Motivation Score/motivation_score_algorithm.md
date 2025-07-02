# 🧠 Motivation Internalization Score (MIS) – Scoring Rubric & Algorithm

## 🎯 Overview

This document defines a **Motivation Internalization Score (MIS)** — a composite metric (0–100 scale) designed to quantify the depth of internal motivation using multi-dimensional data. This score can be tracked over time, visualized in the app, and used by AI Coaches to tailor interventions.

---

## 📊 Scoring Rubric – Subcomponent Breakdown

| Component                    | Source                               | Weight | Scoring Notes |
|-----------------------------|--------------------------------------|--------|----------------|
| 1. Linguistic Internalization | NLP on coach messages, journaling, AI prompts | 25 pts | Based on first-person agency, values-based language, etc. |
| 2. Behavioral Consistency     | Biometric trends (steps, sleep, app use)       | 25 pts | High consistency over time reflects automation & habit strength |
| 3. Skill Engagement           | Completion of skill modules, user-defined goals| 25 pts | Tracks goal ownership, coping strategies, and skill mastery |
| 4. Micro-survey Responses     | 1–3 SDT-based questions/month (optional)       | 25 pts | Derived using weighted RAI or LLM analysis of short reflections |

---

## ⚙️ Algorithm – Calculation Steps

### Step 1: 🧠 Linguistic Internalization (0–25 pts)
- Use LLM to analyze user-generated content for motivational tone:
  - +5 pts for each detection of intrinsic/self-driven phrasing
  - −5 pts for external/compliance-based phrasing
- Normalize across past 7–14 days.

**Example Tags:**
- “I enjoy doing this” → +5 pts
- “Because I have to” → −5 pts

**Max:** 25 pts

---

### Step 2: 📈 Behavioral Consistency (0–25 pts)
- Daily sleep/wake time variation ≤ ±30min (for 5+ days): +10 pts
- Steps logged at same time of day for 4+ days/week: +10 pts
- App opened ≥4 days/week without prompt: +5 pts

**Max:** 25 pts

---

### Step 3: 🛠 Skill Engagement (0–25 pts)
- Completed skill module: +5 pts each (up to 3)
- Logged coping strategy or adjusted plan: +5 pts
- Set or modified a personal goal: +5 pts

**Max:** 25 pts

---

### Step 4: 📝 Micro-Survey / Reflection (0–25 pts)
- User response to “Why is this goal meaningful to you?” is classified as:
  - Intrinsic/Integrated: +20–25 pts
  - Identified/Value-driven: +10–15 pts
  - Introjected/Obligation: +5–10 pts
  - External/Reward-Seeking: 0–5 pts

**Optional:** Adapt RAI (Relative Autonomy Index) to short survey:
\[
RAI = (2 × 	ext{Intrinsic}) + (1 × 	ext{Identified}) − (1 × 	ext{Introjected}) − (2 × 	ext{External})
\]

Normalize to 25-pt scale.

**Max:** 25 pts

---

## 🧮 Final Score

\[
\text{{MIS}} = \text{{Linguistic}} + \text{{Behavior}} + \text{{Skill}} + \text{{Reflection}}
\]

- **Scale:** 0–100
- **Interpretation:**
  - **80–100:** Highly Internalized
  - **60–79:** Moderately Internalized
  - **40–59:** Mixed Motivation
  - **<40:** Primarily External Motivation

---

## 🔁 Usage in App

- Display in Momentum Feed as “Motivation Score”
- Trend chart to visualize weekly progress
- Used by AI Coach to guide nudges and identify users needing support

---

## 📌 Notes

- Weights can be adjusted in future iterations based on data performance
- Additional signals (e.g. dropout risk, affect tone, coaching alignment) can be integrated
