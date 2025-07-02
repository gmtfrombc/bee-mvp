
# BEE App – AI Coach Conversation Engine

## 📌 Epic Overview
The AI Coach is a cross-cutting behavioral engine designed to interact with users throughout the app—both within specific features (e.g., action steps, biometrics) and in general, freeform conversation.

This epic contains **4 primary milestones**:
1. Feature-Specific Interaction Hooks
2. General AI Conversation Thread
3. Conversational Event Analyzer
4. Backend Routing & Role Enforcement

---

## 📦 Milestone M1.3.12 – Feature-Specific Interaction Hooks

### 🎯 Purpose
Enable feature-level interactions between the AI Coach and the user.

### 🧩 Key Use Cases
- Action Step setting/review
- Biometric check-ins ("Your sleep was low—how are you doing?")
- Energy score prompts
- Goal reflection nudges

### 🧾 Tasks
- Define AI message triggers for each feature Milestone
- Enable API calls or message payloads to AI model
- Handle context-specific data writes (e.g., inserting engagement event)

---

## 📦 Milestone M1.3.13 – General AI Conversation Thread

### 🎯 Purpose
Facilitate a persistent, open-ended conversation channel between user and AI Coach.

### 🧩 Key Features
- 24/7 chat availability
- Emotionally intelligent tone
- Conversation is specific for each user based on AI learning of user characteristics
- AI coach learns over time as more data gathered during interactions.
- User can share thoughts without prompt
- AI may respond with support, questions, or education

### 📄 Data Logging
Create table `coach_chat_log`:
```json
{
  "user_id": "uuid",
  "message": "I've had a hard week staying on track.",
  "sent_by": "user",
  "timestamp": "2025-06-30T10:00:00Z",
  "tags": ["frustration", "potential_disengagement"]
}
```

### 🧾 Tasks
- Create secure general chat UI component
- Log messages with timestamp and intent classification stub
- Persist chat history and render chronologically

---

## 📦 Milestone M1.3.14 – Conversational Event Analyzer

### 🎯 Purpose
Extract behavioral signals from natural language inputs for use in engagement scoring and coaching adaptation.

### 🔍 Features
- Detect internal vs external motivation language
- Detect frustration, disengagement, pride, curiosity
- Apply NLP tagging or rules-based classification

### 🧠 AI Capability
- Use GPT function calling or post-chat processing
- Store classified events with `tag_confidence` rating

### 🧾 Tasks
- Build tagging taxonomy (e.g. ["slump", "pride", "self-reflection"])
- Store event tags to `coach_chat_log` or `nlp_insights`
- Connect relevant tags to engagement scoring modifiers

---

## 📦 Milestone M1.3.15 – Backend Routing & Role Enforcement

### 🎯 Purpose
Ensure secure and reliable communication between the AI coach, Supabase data, and scoring APIs.

### 🧩 Core Functions
- `updateMomentumScore(user_id, delta, reason)`
- `insertEngagementEvent(user_id, event_type)`
- `flagUserForHumanFollowUp(user_id, reason)`

### 🔐 Guardrails
- Only allow score updates via validated conditions (e.g. confirmed disengagement)
- Prevent hallucinated or unauthorized data mutations

### 🧾 Tasks
- Define server functions callable by AI via function calling
- Implement API keys and access rules
- Create audit log for each call made by AI

---

## ✅ Summary Table

| Milestone | Purpose | Key Output |
|---------|---------|-------------|
| M1.3.12 | Feature hooks | Action step/chat integration |
| M1.3.13 | General thread | Long-term engagement, passive signal |
| M1.3.14 | NLP signal extraction | Momentum score & motivation tagging |
| M1.3.15 | Backend routing | Safe, auditable, context-aware updates |

---

**Last updated:** June 2025
