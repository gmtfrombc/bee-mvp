# User Journey Mapping - Momentum Meter

**Epic:** 1.1 · Momentum Meter  
**Task:** T1.1.1.1 · User Journey Mapping  
**Status:** 🟡 IN PROGRESS  
**Created:** $(date)

---

## 📋 Overview

This document maps the complete user journey for the Momentum Meter, identifying key touchpoints, user emotions, pain points, and opportunities for motivation optimization. The Momentum Meter replaces traditional "engagement scores" with a friendly, three-state motivation gauge designed to encourage rather than demotivate users.

## 🎯 User Personas

### Primary Persona: Health-Conscious Sarah
- **Age:** 32, working professional
- **Goals:** Improve daily wellness habits, track progress
- **Tech Comfort:** High
- **Usage Pattern:** Morning check-in, evening review
- **Motivation Style:** Responds well to positive reinforcement and visual progress

### Secondary Persona: Motivated Mike
- **Age:** 45, busy parent
- **Goals:** Build consistent health routines
- **Tech Comfort:** Medium
- **Usage Pattern:** Quick check-ins throughout day
- **Motivation Style:** Needs gentle encouragement and simple wins

## 🗺️ Core User Journey: Daily Momentum Check-in

### Journey Stage 1: App Launch & Momentum Discovery
**Touchpoint:** App icon tap → Momentum Meter load

| Step | User Action | System Response | User Emotion | Pain Points | Opportunities |
|------|-------------|-----------------|--------------|-------------|---------------|
| 1.1 | Taps BEE app icon | Splash screen appears | Anticipation | Slow load times | Smooth animations |
| 1.2 | Waits for momentum meter | Loading skeleton appears | Patience/Curiosity | Network delays | Offline cache |
| 1.3 | Views momentum state | Momentum meter renders with state | Satisfaction/Concern | Confusing states | Clear, positive messaging |

**Success Criteria:**
- Momentum meter loads within 2 seconds
- Loading states provide clear feedback
- User immediately understands their momentum state

---

### Journey Stage 2: Momentum State Understanding
**Touchpoint:** Primary momentum meter interaction

| Step | User Action | System Response | User Emotion | Pain Points | Opportunities |
|------|-------------|-----------------|--------------|-------------|---------------|
| 2.1 | Views momentum state | Rising 🚀/Steady 🙂/Needs Care 🌱 | Pride/Acceptance/Hope | Unclear meaning | State explanation |
| 2.2 | Taps meter for details | Momentum breakdown modal | Curiosity | Complex metrics | Simple insights |
| 2.3 | Views contributing factors | 4 key areas with positive labels | Understanding | Overwhelming data | Focused feedback |
| 2.4 | Reads encouraging message | Personalized motivational text | Motivation | Generic messaging | Tailored encouragement |

**Success Criteria:**
- 90% of users understand their momentum state
- Messaging feels personal and encouraging
- Breakdown provides actionable insights

---

### Journey Stage 3: Progress Review & Context
**Touchpoint:** Quick stats and trend exploration

| Step | User Action | System Response | User Emotion | Pain Points | Opportunities |
|------|-------------|-----------------|--------------|-------------|---------------|
| 3.1 | Scans quick stats | Lessons, streak, activity displayed | Assessment | Information overload | Key highlights only |
| 3.2 | Taps stats cards | Detailed progress views | Focus | Too much detail | Bite-sized insights |
| 3.3 | Views momentum trend | Weekly emoji-based chart | Pattern recognition | Complex charts | Visual simplicity |
| 3.4 | Identifies patterns | Momentum state progression | Understanding | No guidance | Pattern highlights |

**Success Criteria:**
- Stats are scannable at a glance
- Trends are visually intuitive
- Patterns drive motivation

---

### Journey Stage 4: Momentum Trend Analysis
**Touchpoint:** Weekly momentum chart interaction

| Step | User Action | System Response | User Emotion | Pain Points | Opportunities |
|------|-------------|-----------------|--------------|-------------|---------------|
| 4.1 | Views trend chart | 7-day emoji progression | Analysis | Chart complexity | Emoji simplicity |
| 4.2 | Taps data points | Daily momentum details | Curiosity | Information density | Key insights only |
| 4.3 | Recognizes patterns | Visual momentum journey | Understanding | No context | Encouraging interpretation |
| 4.4 | Compares to goals | Personal progress narrative | Motivation/Reflection | Unrealistic expectations | Adaptive messaging |

**Success Criteria:**
- Trends are immediately understandable
- Emoji states provide clear visual feedback
- Data drives positive action

---

### Journey Stage 5: Motivated Action Planning
**Touchpoint:** Encouraging actions and quick buttons

| Step | User Action | System Response | User Emotion | Pain Points | Opportunities |
|------|-------------|-----------------|--------------|-------------|---------------|
| 5.1 | Reads action suggestions | State-appropriate recommendations | Guidance | Generic advice | Personalized suggestions |
| 5.2 | Taps quick action | Direct feature launch | Efficiency | Too many options | Prioritized actions |
| 5.3 | Completes action | Real-time momentum feedback | Satisfaction | Delayed feedback | Instant encouragement |
| 5.4 | Returns to meter | Updated state/progress shown | Progress | No celebration | Micro-celebrations |

**Success Criteria:**
- Actions feel personally relevant
- Quick buttons reduce friction
- Completion provides immediate positive feedback

---

## 🔄 Alternative User Journeys

### Journey A: Needs Care State Recovery
**Scenario:** User with "Needs Care 🌱" state needs gentle support

1. **Recognition:** Orange meter with "Let's grow together!" messaging
2. **Guidance:** 1-2 very simple action suggestions
3. **Support:** Extra encouraging tone, growth metaphors
4. **Celebration:** Immediate positive feedback for any small action

### Journey B: Rising State Maintenance
**Scenario:** User with "Rising 🚀" state maintaining momentum

1. **Validation:** Green meter with "You're on fire!" recognition
2. **Challenge:** Slightly more ambitious suggestions
3. **Insights:** Deeper progress analytics and patterns
4. **Sharing:** Optional celebration or milestone recognition

### Journey C: Steady State Consistency
**Scenario:** User with "Steady 🙂" state building habits

1. **Acknowledgment:** Blue meter with "You're doing well!" message
2. **Encouragement:** Consistency-focused suggestions
3. **Progress:** Small step recommendations
4. **Momentum:** Gentle nudges toward "Rising" state

---

## 📱 Device-Specific Considerations

### Mobile Phone (Primary)
- **Portrait Mode:** Vertical momentum meter, thumb-friendly interactions
- **Landscape Mode:** Horizontal layout with meter emphasis
- **One-Hand Use:** Bottom actions, reachable quick buttons

### Tablet
- **Split Layout:** Momentum meter + detail view side-by-side
- **Enhanced Visuals:** Larger meter with more detailed animations
- **Multi-touch:** Gesture-based meter interactions

---

## ⏰ Temporal User Patterns

### Morning Check-in (7-9 AM)
- **Goal:** Quick momentum review and day planning
- **Priority:** Current state, encouraging start to day
- **Mood:** Optimistic, planning-focused
- **Actions:** Quick lesson, positive affirmation

### Midday Progress (12-2 PM)
- **Goal:** Quick momentum check and encouragement
- **Priority:** Current progress, staying on track
- **Mood:** Busy, efficiency-focused
- **Actions:** Quick check-in, micro-action

### Evening Review (7-9 PM)
- **Goal:** Day reflection and momentum assessment
- **Priority:** Final state, achievements, tomorrow prep
- **Mood:** Reflective, planning next day
- **Actions:** Final logging, reflection, planning

---

## 🎭 Emotional Journey Mapping

### Positive Emotional Arc
```
Curiosity → Discovery → Pride → Motivation → Satisfaction → Planning
     ↑           ↑         ↑         ↑            ↑           ↑
App Launch  State View   Progress   Trends      Actions    Tomorrow
```

### Recovery Emotional Arc (Needs Care State)
```
Concern → Acceptance → Hope → Encouragement → Small Win → Growth
   ↓          ↓         ↓         ↓             ↓          ↓
Support   Understanding Guidance  Action      Success   Momentum
```

---

## 🚀 Optimization Opportunities

### Immediate Wins
1. **Faster Load Times:** Skeleton screens and progressive loading
2. **Clear States:** Intuitive emoji-based momentum states
3. **Positive Messaging:** Encouraging language for all states
4. **Micro-interactions:** Delightful feedback for all actions

### Advanced Features
1. **Adaptive Messaging:** AI-powered personalized encouragement
2. **Smart Suggestions:** Context-aware action recommendations
3. **Celebration Moments:** Milestone recognition and achievements
4. **Progressive Disclosure:** Advanced insights for engaged users

---

## 📊 Success Metrics by Journey Stage

| Stage | Metric | Target | Measurement |
|-------|--------|--------|-------------|
| **Load** | Time to interactive | <2 seconds | Performance monitoring |
| **Discovery** | State comprehension | 90% understand | User testing |
| **Progress** | Stats interaction rate | 60% tap stats | Analytics |
| **Trends** | Chart engagement | 40% view trends | Analytics |
| **Actions** | Quick action usage | 70% use buttons | Analytics |

---

## 🔄 Iteration Plan

### Phase 1: Core Momentum Meter (Week 1-2)
- Implement basic three-state system
- Focus on load time and state display
- Simple encouraging messaging

### Phase 2: Enhanced Interactions (Week 3-4)
- Add trend chart with emoji states
- Implement quick actions
- Real-time momentum updates

### Phase 3: Optimization (Week 5+)
- Personalized messaging
- Advanced momentum analytics
- Performance optimization

---

## 📝 Next Steps

1. **Validate Journey:** User interviews to confirm momentum state understanding
2. **Create Wireframes:** Visual representation of each journey stage
3. **Define Interactions:** Detailed interaction specifications for momentum meter
4. **Prototype Testing:** Rapid prototyping for key touchpoints

---

**Status:** ✅ COMPLETE  
**Next Task:** T1.1.1.2 - Design wireframes for mobile momentum meter layout 