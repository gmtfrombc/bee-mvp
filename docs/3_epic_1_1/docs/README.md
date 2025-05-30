# Epic 1.1: Momentum Meter

**Module:** Core Mobile Experience  
**Status:** ⚪ Planned  
**Priority:** High (MVP Core Feature)  
**Estimated Duration:** 2 weeks  

---

## 📋 Overview

The Momentum Meter is a patient-facing motivation gauge that provides friendly, real-time feedback on user engagement without using potentially demotivating "scores." It displays three positive states—Rising 🚀, Steady 🙂, Needs Care 🌱—and serves as the foundation for AI-driven nudges and coach interventions.

## 🎯 Epic Goals

### Primary Objectives
- **Patient-Friendly Feedback:** Replace technical "engagement scores" with encouraging momentum states
- **Timely Interventions:** Enable AI and coach interventions based on momentum trends
- **Positive Reinforcement:** Use uplifting language and visual design to motivate users
- **Real-Time Updates:** Provide daily momentum updates based on user behavior

### Success Metrics
- 90% user comprehension of momentum states in testing
- <2 second load time for momentum meter widget
- 70% user interaction rate with momentum meter
- Successful integration with notification system

## 🏗️ Technical Architecture

### Core Components
1. **Momentum Calculation Engine** - Backend scoring algorithm with 3-zone classification
2. **Flutter Momentum Widget** - Circular gauge with custom painter and animations
3. **Notification System** - Push notifications for momentum drops and achievements
4. **Data Pipeline** - Nightly batch job processing engagement events

### Key Integrations
- **Engagement Events Logging** (Epic 2.1) - Data source for momentum calculation
- **Push Notification Service** - FCM integration for timely interventions
- **Coach Dashboard** - Momentum trends visible to care team

## 📊 Feature Specifications

### Momentum States
- **Rising 🚀** (Score ≥70): "You're on fire! Keep up the great momentum!"
- **Steady 🙂** (Score 45-69): "You're doing well! Stay consistent!"
- **Needs Care 🌱** (Score <45): "Let's get back on track together!"

### Scoring Algorithm
```python
score = sigmoid(Σ weight_i * feature_i_decay) * 100
zone = (
    "Rising" if score >= 70 else
    "Steady" if score >= 45 else
    "NeedsCare"
)
```

### Intervention Rules
- Drop ≥15 pts in 5 days → supportive push notification
- Two consecutive "Needs Care" days → auto-schedule coach call
- Five "Steady" or "Rising" days → celebratory message

## 📅 Milestone Breakdown

| Milestone | Deliverable | Duration | Dependencies |
|-----------|-------------|----------|--------------|
| **M1.1.1** | UI Design & Mockups | 3 days | Design team availability |
| **M1.1.2** | Scoring Algorithm & Backend | 4 days | Epic 2.1 complete |
| **M1.1.3** | Flutter Widget Implementation | 5 days | M1.1.1, M1.1.2 |
| **M1.1.4** | Notification System Integration | 3 days | M1.1.2, Firebase setup |
| **M1.1.5** | Testing & Polish | 3 days | All previous milestones |

**Total Duration:** 18 days (3.5 weeks)

### **Detailed Milestone Breakdown**

#### **M1.1.1: UI Design & Mockups (3 days)**
- **Day 1:** Design system foundation (colors, typography, spacing)
- **Day 2:** High-fidelity mockups for all three momentum states
- **Day 3:** Component specifications and animation details
- **Deliverables:**
  - Complete UI design specifications document ✅
  - Figma mockups for Rising, Steady, Needs Care states
  - Component library with momentum meter widgets
  - Animation specifications and micro-interactions

#### **M1.1.2: Scoring Algorithm & Backend (4 days)**
- **Day 1:** Database schema design and migration scripts
- **Day 2:** Momentum calculation algorithm implementation
- **Day 3:** API endpoints for momentum data retrieval
- **Day 4:** Intervention rules and notification triggers
- **Deliverables:**
  - Database tables: `daily_engagement_scores`, `momentum_notifications`, `coach_interventions`
  - Momentum calculation engine with exponential decay
  - REST API endpoints: `/v1/momentum/current`, `/v1/momentum/interaction`
  - Intervention trigger system for coach outreach

#### **M1.1.3: Flutter Widget Implementation (5 days)**
- **Day 1:** Momentum meter circular gauge widget
- **Day 2:** Momentum card component with state management
- **Day 3:** Quick stats cards and weekly trend chart
- **Day 4:** Action buttons and modal breakdown view
- **Day 5:** Responsive design and accessibility features
- **Deliverables:**
  - Complete Flutter momentum meter widget library
  - Riverpod state management integration
  - Responsive design for all device sizes
  - Accessibility compliance (VoiceOver/TalkBack)

#### **M1.1.4: Notification System Integration (3 days)**
- **Day 1:** Firebase Cloud Messaging setup and configuration
- **Day 2:** Push notification triggers based on momentum rules
- **Day 3:** Coach scheduling automation and message personalization
- **Deliverables:**
  - FCM integration for momentum-based notifications
  - Automated coach call scheduling system
  - Personalized notification messaging
  - Coach dashboard integration for intervention tracking

#### **M1.1.5: Testing & Polish (3 days)**
- **Day 1:** Unit tests for momentum calculation and API endpoints
- **Day 2:** UI tests for Flutter widgets and user interactions
- **Day 3:** Performance optimization and final polish
- **Deliverables:**
  - 80%+ test coverage for momentum meter functionality
  - Performance optimization (sub-2-second load times)
  - Cross-device compatibility testing
  - Production deployment procedures

## 📁 Documentation Structure

```
docs/3_epic_1_1/
├── README.md                           # This file - Epic overview
├── prd-momentum-meter.md               # Product Requirements Document ✅
├── tasks-prd-momentum-meter.md         # Detailed task breakdown
├── prompts-momentum-meter.md           # AI prompts and copy
├── implementation/                     # Technical documentation
│   ├── momentum-meter-ui-specs.md      # UI Design Specifications ✅
│   ├── momentum-algorithm.md           # Scoring logic specification
│   ├── flutter-widget-spec.md          # Widget implementation details
│   ├── notification-rules.md           # Push notification logic
│   ├── api-integration.md              # Backend API specifications
│   ├── testing-strategy.md             # QA and testing approach
│   ├── mobile-wireframes.md            # Mobile wireframes ✅
│   └── user-journey-mapping.md         # User journey documentation ✅
└── docs/                               # Operational documentation
    ├── user-testing-results.md         # User feedback and iterations
    ├── performance-metrics.md          # Load time and usage analytics
    └── deployment-procedures.md        # Production deployment guide
```

## 🔗 Related Epics

### Dependencies
- **Epic 2.1:** Engagement Events Logging ✅ (Complete - provides data source)

### Future Integrations
- **Epic 1.2:** On-Demand Lesson Library (momentum boost on completion)
- **Epic 1.3:** Today Feed (momentum boost on daily engagement)
- **Epic 1.4:** In-App Messaging (momentum-based coach outreach)
- **Epic 1.5:** Adaptive AI Coach (momentum-driven conversation triggers)

## 🚀 Getting Started

### Prerequisites
1. Epic 2.1 (Engagement Events Logging) must be complete
2. Flutter development environment set up
3. Access to Figma for design mockups
4. Firebase project configured for push notifications

### Next Steps
1. **Review mobile app features specification** in `docs/0_Core_docs/mobile_app_features/`
2. **Create detailed PRD** based on updated requirements
3. **Design momentum meter UI** with three-state visual system
4. **Implement scoring algorithm** with proper data decay and thresholds
5. **Build Flutter widget** with smooth animations and real-time updates

---

**Last Updated:** December 2024  
**Epic Owner:** Development Team  
**Stakeholders:** Design Team, Product Team, Clinical Team 