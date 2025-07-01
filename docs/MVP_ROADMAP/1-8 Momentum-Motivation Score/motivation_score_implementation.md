# 🧠 Motivation Score System – Technical Specification

## 🎯 Overview

This system introduces a **Motivation Score** and optional **Internalization Index** to assess and support the transition from **external** to **internal** motivation in lifestyle change. It supports long-term behavioral resilience and integrates with coach conversations, biometric patterns, journaling, and in-app prompts.

---

## 🔑 Core Concepts

### 1. Motivation Continuum (Based on SDT)
| Type                   | Example                              |
|------------------------|--------------------------------------|
| External Regulation    | "Doctor told me to"                  |
| Introjected            | "I’ll feel guilty if I don’t"        |
| Identified             | "I value this"                       |
| Integrated / Intrinsic | "This is who I am"                   |

- The goal is to move users progressively **rightward** toward intrinsic motivation.

---

### 2. Two Axes of Sustainability

|                       | Effortful        | Automated            |
|-----------------------|------------------|----------------------|
| External Motivation   | Fragile Compliance | Rigid, brittle habit |
| Internal Motivation   | Growth Phase      | 🔥 Resilient Behavior 🔥 |

---

## 🧪 Measurement Strategies

### A. AI-Inferred Motivational State (via Transcripts)

- **Source**: Audio/text transcripts from coaching sessions
- **Classifier Tags**:
  - `"external: reward-seeking"`
  - `"internal: value-driven"`
- **Implementation**:
  - Add transcript classifier step in ingestion pipeline
  - Output motivational state per session
  - Store in `session_metadata` or `motivational_tags`

---

### B. Micro-Check-ins (Conversational AI Prompts)

- **Prompt cadence**: 1x/week via AI Coach
- **Sample Prompts**:
  - “What makes this goal meaningful to you today?”
  - “If this habit vanished, what would you miss?”
- **Analysis**:
  - Use LLMs to detect motivational tone from responses
  - Track movement along internalization continuum

**Schema (motivation_journal):**
```sql
CREATE TABLE motivation_journal (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users,
  date DATE NOT NULL,
  prompt TEXT,
  response TEXT,
  motivation_type TEXT, -- inferred by LLM
  created_at TIMESTAMP DEFAULT now()
);
```

---

### C. Habit Strength Score (via Biometric Signals)

- **Inputs**:
  - Sleep timing consistency
  - Step patterns
  - Activity timing regularity
- **Logic**: High regularity → higher habit score

**Example Metric:**
- “Sleep within ±30 min for 10+ consecutive days = Strong Habit”

Store in: `habit_index` table or as derived analytics layer.

---

### D. Skill-Building Indicators

- Tracked behaviors:
  - Logging new strategies
  - Modifying plans
  - Completing skill modules

**Implementation**:
- Tag LMS content as “skill-building”
- Track completion logs + free-text journaling

---

### E. Narrative-Based Reflection

- User prompt: “How would you describe your health journey so far?”
- Analyze text for:
  - Agency
  - Value-alignment
  - Internal motivation language

---

## 🔗 Integration with Roadmap

| Epic | Feature                            |
|------|------------------------------------|
| 1.1  | Add `Internalization Index` to Momentum Score system |
| 1.4  | Tag journal entries with motivation/volition metadata |
| 1.5  | Habit Index from biometric patterns |
| 2.2  | AI Coach Micro-prompts              |
| 2.3  | Coach Session Transcript Analysis   |
| 1.7+ | Optional screener for BREQ/TSRQ     |

---

## 🚀 Future Enhancements

- ML model to predict:
  - Dropout risk
  - Motivation regression
  - Internalization growth curve
- Adaptive coaching: users with declining motivation get value-reflective prompts

---

## 🧰 Implementation Notes

- Use LLM (GPT-4o or local model) for motivation tagging
- Secure storage of motivational tags & narrative content
- Integrate tags into AI Coach prompt generator
- Support batch reprocessing of transcripts as classifier improves

---

## 📌 Summary

This feature enables the app to:
- Track motivation quality over time
- Support long-term sustainability through personalized nudges
- Generate a *Motivation Score* and optional *Internalization Index*
- Differentiate this platform from other wellness apps with intelligent motivational scaffolding
