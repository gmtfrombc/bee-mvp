# Product Requirements Document: Momentum Meter

**Epic:** 1.1 · Core Mobile Experience  
**Feature:** Momentum Meter  
**Version:** 1.0  
**Status:** 📝 Draft  
**Created:** December 2024  
**Owner:** Product Team  

---

## 📋 Executive Summary

The Momentum Meter is a patient-facing motivation gauge that replaces traditional "engagement scores" with a friendly, three-state system designed to encourage rather than demotivate users. It provides real-time feedback on user engagement through positive states—Rising 🚀, Steady 🙂, Needs Care 🌱—and serves as the foundation for AI-driven nudges and coach interventions.

### **Key Benefits**
- **Patient-Friendly:** Eliminates demotivating numerical scores
- **Actionable:** Triggers timely interventions and support
- **Motivational:** Uses positive language and growth metaphors
- **Intelligent:** Enables AI and coach-driven personalization

---

## 🎯 Problem Statement

Current engagement tracking systems often use numerical scores (0-100) that can be demotivating when low, creating anxiety and potential app abandonment. Users need encouraging feedback that motivates continued engagement without judgment.

### **User Pain Points**
- Numerical scores feel clinical and judgmental
- Low scores create shame and avoidance behaviors
- No clear guidance on how to improve
- Lack of positive reinforcement for small wins

---

## 🎯 Product Goals

### **Primary Goals**
1. **Increase User Retention:** Reduce app abandonment due to demotivating feedback
2. **Enable Timely Interventions:** Trigger coach outreach when users need support
3. **Improve User Experience:** Provide encouraging, actionable feedback
4. **Support Behavior Change:** Motivate consistent engagement through positive reinforcement

### **Success Metrics**
| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| User comprehension of momentum states | 90% | User testing surveys |
| Daily momentum meter interaction rate | 70% | App analytics |
| User retention (7-day) | 85% | Cohort analysis |
| Time to load momentum meter | <2 seconds | Performance monitoring |
| Coach intervention effectiveness | 60% response rate | Clinical metrics |

---

## 👥 User Stories

### **Epic User Story**
> As a health program participant, I want to see encouraging feedback about my progress so that I stay motivated to continue my health journey without feeling judged or demotivated.

### **Detailed User Stories**

#### **US1.1: View Momentum State**
**As a** program participant  
**I want to** see my current momentum state when I open the app  
**So that** I understand how I'm doing in a positive, encouraging way  

**Acceptance Criteria:**
- [ ] Momentum meter displays within 2 seconds of app launch
- [ ] State is clearly visible with emoji and descriptive text
- [ ] Color coding is intuitive and non-judgmental
- [ ] Tapping meter shows breakdown of contributing factors

#### **US1.2: Understand Momentum Factors**
**As a** program participant  
**I want to** understand what contributes to my momentum  
**So that** I know how to maintain or improve my progress  

**Acceptance Criteria:**
- [ ] Breakdown shows 4 key contributing areas
- [ ] Each area uses positive language (e.g., "Great" vs "80%")
- [ ] Visual progress bars are easy to understand
- [ ] No overwhelming technical details

#### **US1.3: Receive Encouraging Guidance**
**As a** program participant  
**I want to** receive personalized suggestions based on my momentum state  
**So that** I know what actions to take next  

**Acceptance Criteria:**
- [ ] Suggestions are state-appropriate (1-2 for Needs Care, more for Rising)
- [ ] Language is encouraging and supportive
- [ ] Actions are specific and achievable
- [ ] Quick action buttons launch relevant features

#### **US1.4: Get Timely Support**
**As a** program participant  
**I want to** receive support when my momentum drops  
**So that** I don't feel abandoned and can get back on track  

**Acceptance Criteria:**
- [ ] Automatic coach outreach after 2 consecutive "Needs Care" days
- [ ] Supportive push notifications for momentum drops
- [ ] Celebratory messages for sustained positive momentum
- [ ] Option to decline auto-scheduled calls

---

## 🏗️ Technical Requirements

### **System Architecture**

#### **Backend Components**
1. **Momentum Calculation Engine**
   - Nightly batch job processing engagement events
   - Sigmoid function with exponential decay (10-day half-life)
   - Three-day rolling average for noise reduction
   - Zone classification (Rising/Steady/Needs Care)

2. **Notification Service**
   - Firebase Cloud Messaging integration
   - Rule-based trigger system
   - Coach scheduling automation
   - Message personalization

3. **Data Pipeline**
   - Real-time event ingestion
   - Batch processing for momentum scores
   - Historical trend storage
   - Coach dashboard integration

#### **Frontend Components**
1. **Flutter Momentum Widget**
   - Custom painter for circular gauge
   - Smooth state transition animations
   - Responsive design (375px-428px width)
   - Accessibility compliance

2. **State Management**
   - Riverpod for reactive updates
   - Local caching for offline support
   - Real-time subscription to score changes
   - Error handling and retry logic

### **Database Schema**

#### **New Tables**
```sql
-- Daily momentum scores
CREATE TABLE daily_engagement_scores (
    user_id UUID NOT NULL,
    score_date DATE NOT NULL,
    raw_score NUMERIC(5,2) NOT NULL,
    zone TEXT NOT NULL CHECK (zone IN ('Rising', 'Steady', 'NeedsCare')),
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, score_date)
);

-- Momentum notifications
CREATE TABLE momentum_notifications (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    notification_type TEXT NOT NULL,
    trigger_condition TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT NOW(),
    response_action TEXT,
    response_at TIMESTAMP
);

-- Coach interventions
CREATE TABLE coach_interventions (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    trigger_momentum_drop BOOLEAN DEFAULT FALSE,
    scheduled_at TIMESTAMP,
    completed_at TIMESTAMP,
    outcome TEXT,
    notes TEXT
);
```

#### **Existing Table Updates**
```sql
-- Add momentum-related events
ALTER TABLE engagement_events 
ADD COLUMN momentum_weight NUMERIC(3,2) DEFAULT 1.0;

-- Index for performance
CREATE INDEX idx_engagement_events_momentum 
ON engagement_events (user_id, recorded_at, momentum_weight);
```

### **API Specifications**

#### **GET /v1/momentum/current**
Returns current momentum state for authenticated user.

**Response:**
```json
{
  "user_id": "uuid",
  "current_state": "Rising",
  "score_date": "2024-12-15",
  "message": "You're on fire! Keep up the great momentum!",
  "breakdown": {
    "app_engagement": {"label": "Excellent", "percentage": 95},
    "learning_progress": {"label": "Good", "percentage": 75},
    "daily_checkins": {"label": "Great", "percentage": 85},
    "consistency": {"label": "Excellent", "percentage": 90}
  },
  "suggested_actions": [
    {"text": "Complete today's lesson", "action": "open_lessons"},
    {"text": "Log your evening reflection", "action": "open_journal"}
  ],
  "trend": [
    {"date": "2024-12-09", "state": "Steady"},
    {"date": "2024-12-10", "state": "Steady"},
    {"date": "2024-12-11", "state": "Rising"},
    {"date": "2024-12-12", "state": "Rising"},
    {"date": "2024-12-13", "state": "Rising"},
    {"date": "2024-12-14", "state": "Rising"},
    {"date": "2024-12-15", "state": "Rising"}
  ]
}
```

#### **POST /v1/momentum/interaction**
Logs user interaction with momentum meter.

**Request:**
```json
{
  "interaction_type": "view_breakdown",
  "timestamp": "2024-12-15T10:30:00Z"
}
```

---

## 🎨 User Experience Requirements

### **Momentum States Design**

#### **Rising State 🚀**
- **Color:** Green (#4CAF50)
- **Message:** "You're on fire! Keep up the great momentum!"
- **Tone:** Celebratory, energetic
- **Actions:** 2-3 options including challenges or sharing
- **Animation:** Upward motion, sparkles

#### **Steady State 🙂**
- **Color:** Blue (#2196F3)
- **Message:** "You're doing well! Stay consistent!"
- **Tone:** Encouraging, supportive
- **Actions:** 2 options focused on consistency
- **Animation:** Gentle pulse, steady rhythm

#### **Needs Care State 🌱**
- **Color:** Orange (#FF9800)
- **Message:** "Let's grow together!"
- **Tone:** Nurturing, hopeful
- **Actions:** 1-2 very simple, achievable options
- **Animation:** Growing/blooming motion

### **Interaction Patterns**

#### **Primary Interactions**
1. **View State:** Immediate visual feedback on app launch
2. **Tap for Details:** Modal with breakdown and suggestions
3. **Quick Actions:** Direct navigation to relevant features
4. **Trend Review:** Weekly momentum progression

#### **Accessibility Requirements**
- **Screen Reader:** Full VoiceOver/TalkBack support
- **Color Contrast:** WCAG AA compliance (4.5:1 minimum)
- **Touch Targets:** 44px minimum for all interactive elements
- **Dynamic Type:** Support for iOS/Android text scaling
- **Reduced Motion:** Respect system motion preferences

---

## 🔧 Momentum Calculation Algorithm

### **Scoring Logic**
```python
def calculate_momentum_score(user_id, date):
    """
    Calculate momentum score using weighted engagement events
    with exponential decay and noise reduction.
    """
    
    # Data inputs with weights
    events = get_engagement_events(user_id, date, lookback_days=30)
    
    weights = {
        'app_open': 1.0,
        'lesson_complete': 3.0,
        'journal_entry': 2.0,
        'goal_complete': 2.5,
        'coach_message_read': 1.5,
        'coach_message_reply': 2.0,
        'telehealth_attend': 5.0,
        'telehealth_noshow': -3.0
    }
    
    # Apply exponential decay (10-day half-life)
    decay_factor = 0.5 ** (days_ago / 10)
    
    # Calculate weighted score
    total_score = 0
    for event in events:
        weight = weights.get(event.type, 1.0)
        decayed_weight = weight * decay_factor
        total_score += decayed_weight
    
    # Apply sigmoid normalization
    normalized_score = sigmoid(total_score) * 100
    
    # Three-day rolling average for noise reduction
    recent_scores = get_recent_scores(user_id, days=3)
    smoothed_score = np.mean(recent_scores + [normalized_score])
    
    return smoothed_score

def classify_momentum_zone(score):
    """Classify score into momentum zones."""
    if score >= 70:
        return "Rising"
    elif score >= 45:
        return "Steady"
    else:
        return "NeedsCare"
```

### **Intervention Rules**
```python
def check_intervention_triggers(user_id):
    """Check if user needs intervention based on momentum trends."""
    
    recent_scores = get_recent_scores(user_id, days=5)
    current_zone = get_current_zone(user_id)
    
    # Score drop trigger
    if len(recent_scores) >= 2:
        score_drop = recent_scores[0] - recent_scores[-1]
        if score_drop >= 15:
            send_supportive_notification(user_id)
    
    # Consecutive "Needs Care" trigger
    recent_zones = get_recent_zones(user_id, days=2)
    if all(zone == "NeedsCare" for zone in recent_zones):
        schedule_coach_call(user_id)
    
    # Celebration trigger
    recent_zones = get_recent_zones(user_id, days=5)
    if all(zone in ["Rising", "Steady"] for zone in recent_zones):
        send_celebration_message(user_id)
```

---

## 🔗 Integration Requirements

### **Epic 2.1: Engagement Events Logging**
- **Dependency:** Complete ✅
- **Integration:** Momentum calculation reads from `engagement_events` table
- **Data Flow:** Real-time events → Nightly batch processing → Momentum scores

### **Future Epic Integrations**

#### **Epic 1.2: On-Demand Lesson Library**
- **Integration Point:** Lesson completion events boost momentum
- **Weight:** +3 points per lesson completed
- **Feedback:** Immediate momentum update on completion

#### **Epic 1.3: Today Feed**
- **Integration Point:** Daily engagement with feed content
- **Weight:** +1 point for first daily open
- **Feedback:** Momentum boost notification

#### **Epic 1.4: In-App Messaging**
- **Integration Point:** Coach message interactions
- **Weight:** +1.5 for read, +2.0 for reply
- **Trigger:** Momentum-based coach outreach

### **Coach Dashboard Integration**
- **Data Export:** Daily momentum scores and trends
- **Alerts:** Automatic notifications for intervention triggers
- **Analytics:** Momentum effectiveness metrics

---

## 📊 Analytics & Monitoring

### **Key Performance Indicators**

#### **User Engagement Metrics**
- Daily momentum meter interaction rate
- Time spent viewing momentum details
- Quick action button usage
- Trend chart engagement

#### **Clinical Effectiveness Metrics**
- Coach intervention response rates
- Momentum improvement after interventions
- User retention by momentum state
- Correlation between momentum and health outcomes

#### **Technical Performance Metrics**
- Momentum meter load time
- API response times
- Batch job completion time
- Error rates and recovery

### **A/B Testing Framework**
- **Messaging Variations:** Test different encouraging phrases
- **Color Schemes:** Validate color choices for different states
- **Intervention Timing:** Optimize notification timing
- **Action Suggestions:** Test effectiveness of different CTAs

---

## 🚀 Launch Strategy

### **Phase 1: MVP Launch (Week 1-2)**
- Basic three-state momentum meter
- Simple scoring algorithm
- Manual coach notifications
- Core Flutter widget

### **Phase 2: Enhanced Features (Week 3-4)**
- Automated intervention triggers
- Detailed breakdown modal
- Trend visualization
- Push notification integration

### **Phase 3: Optimization (Week 5+)**
- Personalized messaging
- Advanced analytics
- A/B testing implementation
- Performance optimization

---

## ⚠️ Risks & Mitigation

### **Technical Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Scoring algorithm complexity | High | Medium | Start with simple rules, iterate |
| Real-time performance issues | High | Low | Implement caching and optimization |
| Flutter widget compatibility | Medium | Low | Thorough device testing |

### **User Experience Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| State confusion | High | Medium | Extensive user testing |
| Notification fatigue | Medium | Medium | Careful frequency tuning |
| Motivational messaging backfire | High | Low | Clinical team review |

### **Business Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Coach workload increase | Medium | High | Automated triage system |
| User privacy concerns | High | Low | Clear data usage policies |
| Clinical effectiveness questions | High | Medium | Robust analytics and studies |

---

## 📋 Acceptance Criteria

### **Epic-Level Acceptance Criteria**
- [ ] Momentum meter loads within 2 seconds on average devices
- [ ] 90% of users understand momentum states in usability testing
- [ ] All three momentum states display correctly with appropriate messaging
- [ ] Breakdown modal shows contributing factors with positive language
- [ ] Quick action buttons navigate to correct features
- [ ] Weekly trend chart displays momentum progression
- [ ] Push notifications trigger correctly based on momentum rules
- [ ] Coach dashboard shows momentum data for all patients
- [ ] Accessibility requirements met (WCAG AA compliance)
- [ ] Performance targets achieved (load time, API response)

### **Quality Assurance Requirements**
- [ ] Unit tests for momentum calculation algorithm
- [ ] Integration tests for API endpoints
- [ ] UI tests for Flutter widget interactions
- [ ] Performance tests for load times
- [ ] Accessibility tests with screen readers
- [ ] Cross-device compatibility testing
- [ ] Security testing for data protection

---

## 📚 Appendices

### **Appendix A: User Research Findings**
- User interviews highlighting pain points with numerical scores
- Usability testing results for momentum state concepts
- Clinical team feedback on intervention triggers

### **Appendix B: Technical Specifications**
- Detailed API documentation
- Database migration scripts
- Flutter widget implementation guide
- Push notification setup procedures

### **Appendix C: Design Assets**
- Figma mockups for all momentum states
- Icon and emoji specifications
- Color palette and typography guidelines
- Animation specifications

---

**Document Status:** 📝 Draft  
**Next Review:** Design Team Approval  
**Approval Required:** Product Team, Clinical Team, Engineering Team  
**Target Start Date:** Week 1, Epic 1.1  

---

*This PRD serves as the definitive specification for the Momentum Meter feature. All implementation decisions should reference this document, and any changes must be approved through the standard change management process.* 