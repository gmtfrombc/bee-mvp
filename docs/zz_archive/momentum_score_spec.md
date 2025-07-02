# ⚡ Momentum Score – Technical Specification

## 🎯 Purpose

The Momentum Score is being redesigned to enhance its predictive value, reduce noise, and support both **user-facing motivation** and **backend analytics**. This document outlines the updated architecture and implementation strategy.

---

## ✅ Overview: What is Working

- **Weighted event system**: Prioritizes high-signal user actions.
- **Exponential decay + hysteresis**: Adds nuance by modeling momentum as non-linear and stateful.
- **Normalization & deduplication**: Prevents inflation from repeat actions.

---

## ❗ Revision Rationale

- Many events are **low-signal or speculative**.
- Score is cluttered with **placeholders**.
- Does not fully utilize **passive biometric or adherence data**.

---

## 📊 Behavioral Signals – Updated Scorecard

| Event Type                  | Signal Strength | Action                           |
|-----------------------------|-----------------|-----------------------------------|
| Coach Interactions          | 🔥🔥🔥 High      | AI assessment of user language, tone using motivational interviewing techniques |
| Action Step Completions     | 🔥🔥🔥 High      | User defined process goals adherence trends                                     |
| Today Tile Interaction      | 🔥 Medium       | User clicks on today tile for extended article; engages in dialogue withn coach |
| Progress to Goal            | 🔥 Medium       | Trend in progress to weight loss or metabolic health goals                      |
| Internal Motivation Score   | 🔥 Medium       | AI assessment of current internal motivation and transition from ext=>int       |
| Biometric Changes           | 🔥 Medium       | steps and sleep/energy changes - need user confirmed                            |
| Perceived Energy Score      | 🔥🔥 Medium-High | check in consistensy plus trend changes                                         |
| Perceived Motivation Score  | 🔥🔥 Medium-High | check in consistensy plus trend changes                                         |

## 💡 Future Metrics (post-MVP)

| Signal Type                     | Signal Strength     | Action|
|---------------------------------|---------------------|---------------------------|
| Coach/Provider Visit Adherence  | 🔥🔥🔥 High          | Number of total visits kept/canceled/rescheduled visits                   |
| Visit Transript AI Analysis     | 🔥🔥 Medium-High     | AI analyzes video (later audio) trancrips using motivational interviewing |
| HRV, CGM, RHR (biometrics)      | 🔥🔥 Medium-High     | Biometric parameters in relation to physiologic state                     |

---

## ✳️ Redesign Strategy

### 1. Multi-Channel Signal Fusion

Break the score into **four pillars**, each with a weighted contribution:

| Pillar                 | Weight | Data Types                                               |
|------------------------|--------|----------------------------------------------------------|
| Cognitive Engagement   | 30%    | Today feed, Lesson completion (future)                   |
| Behavioral Execution   | 30%    | Task Completion--enter perceived energy (20%), motivation score (20%), completes action steps (60%)|
| Relational Engagement  | 20%    | Coach/provider interactions, peer engagement (future)    |
| Biometric Consistency  | 20%    | Steps, sleep, energy, HRV (future)                       |

Each subscore is normalized and blended into a final **Momentum Score (0–100)**.

---

### 2. Dual Purpose Implementation

- **Momentum Meter** (user-visible):
  - Simple UI with trendline and tier labels (e.g., “Building”, “Maintaining”, “Low”)
  - Used to motivate, not diagnose

- **Engagement Risk Index** (backend analytics):
  - Composite model using LLM + biometrics + app logs
  - For predicting drop-off, tailoring interventions

---

## 🧭 Implementation Roadmap

### Step 1: Implement Behavioral Signal Integrations
- Track and score:
  - Coach Interactions
  - Action Step Completion
  - Today Tile Interaction
  - Sleep/Steps syncing
  - Progress to Goal
  - Motivation Score
  - Biometric Changes
  - Internal Motivation Score

### Step 2: Schema Redesign
- Create `momentum_events` table with tags and weights
- Add `momentum_pillars` table to store pillar-specific subscores

### Step 3: Store Raw Data for Validation
- Biometric streams (via device sync)
- Timestamped actions and goal logs
- Coach visit adherence logs

---

## 📌 Final Thoughts

This redesign positions the Momentum Score to be:
- **Meaningful to users**
- **Predictive for the system**
- **Flexible for future ML-based improvements**

Balance simplicity for motivation with smart analytics for intervention.

Last Updated: June 30, 2025
