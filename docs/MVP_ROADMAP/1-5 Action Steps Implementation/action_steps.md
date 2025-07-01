
# BEE Action Step System – AI Coach Integration (June 2025)

This document defines the structure, logic, and content for weekly action steps (process goals) set by patients in collaboration with the AI Coach.

---

## 🎯 Goal of the System

Help patients develop identity-based, consistent behaviors through weekly mini-goals that:
- Are proactive (approach-oriented)
- Are consistent (5–7 days per week)
- Support internal motivation and confidence
- Allow tracking and reflection
- Opportunity for AI Coach to support behavior change
- Completion/non-completion of action steps is a significant contributor to Momentum Score

---

## 🤖 UX Flow Recommendation: Hybrid (Chat-Led with Structured Options)

1. **Coach initiates goal-setting** via chat:
   > “Time to set your weekly action step. Want to keep the same one, bump it up, or try something new?”

2. **User types in a preference or request.**
   - If vague, AI provides a list of 3–5 curated suggestions.

3. **User taps a suggestion or provides own idea.**
   - AI reformats into structured goal:
     ```json
     {
       "category": "Sleep",
       "description": "Go to bed before 11 PM",
       "frequency": 6,
       "source": "AI-Coach"
     }
     ```

4. **Coach confirms and logs.**
   > “Great! this is what I've got': ‘Go to bed before 11 PM, 6 days this week.’ I’ll check in with you daily! Is that okay?” 
   > User confirms or rejects. If rejects then loops through the process or quits

---

## ✅ Action Step Constraints

- **Positive framing only** (no “I will not...”)
- **Minimum frequency:** 3 days/week
- **Maximum frequency:** 7 days/week
- **Goal type:** Process behavior only (not outcomes like weight loss)
- **Can include:**
  - Free text + AI validation
  - List selection
  - Paired activity (“walk while listening to a podcast”)

---

## 📚 Example Action Step Categories & Prompts

### 🥦 Nutrition
- Eat a regular breakfast each day
- Pack a healthy lunch for work/school
- Add a vegetable to one meal
- Prepare your own dinner 5 nights

### 🏃 Movement
- Walk 5000+ steps per day
- Stretch for 3 minutes after waking
- Take a 10-min walk after dinner
- Exercise 6 days this week

### 😴 Sleep
- Go to bed before 11 PM
- Turn off screens 30 minutes before sleep
- Wake up by 7:30 AM

### 🧘 Stress / Mental Health
- Do a 2-minute breathing practice daily
- Practice mindfulness once per day
- Take 3 pauses during your day to check in

### 💬 Social / Connection
- Call or text a friend
- Eat one meal with someone else
- Do something kind for someone

---

## 🧠 AI Coach Messaging Guardrails

- If user enters avoidance-based goal:
  > “That’s a great insight. Let’s turn it into something *you’ll do*. For example: ‘Put phone away 30 minutes before bed.’ Want to go with that?”

- If user enters vague goal:
  > “That’s a strong direction. Want to pick one of these to make it trackable?”

---

## 🧾 Backend Logging Schema

```json
{
  "user_id": "uuid",
  "category": "Movement",
  "description": "Walk 5000+ steps",
  "frequency": 5,
  "week_start": "2025-06-30",
  "source": "AI-Coach",
  "created_at": "2025-06-30T08:00:00Z"
}
```
## AI Coach - User Interactions

- User completing action step => AI Coach response with encouragement (based on user's AI coaching style preference) as well as 'variable reward' approach to avoid a contrived or generic interaction.
- User can 'turn off' feedback for the coach or reduce the frequency
---

## 🏁 Reward Logic

- If patient completes ≥ frequency goal, show confetti animation + send celebratory AI message
- If goal missed, prompt reflection with empathy (e.g., “Want to adjust next week?”)

## Momentum Score Update

- Completion (or non-completion) of Action steps updates Momentum score as described in @momentum_score_calculation.md

---

**Last Updated:** June 2025
