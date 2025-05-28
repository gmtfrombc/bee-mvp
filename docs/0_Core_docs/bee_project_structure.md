# BEE Project Structure - Unified Development Plan

> **Definitive source of truth** for BEE project organization, terminology, and development sequence.

---

## 📋 **Project Hierarchy & Terminology**

### **Software Development Naming Conventions**

```
🚀 PROJECT: Behavioral Engagement Engine (BEE)
├── 📦 MODULES: Functional areas (5 total)
│   ├── 🧩 FEATURES: Individual capabilities (20 total)
│   │   ├── 📄 PRD: Product Requirements Document
│   │   ├── 🎯 EPICS: Major development efforts
│   │   │   ├── 🏁 MILESTONES: Deliverable checkpoints
│   │   │   │   ├── 📝 TASKS: Implementation work items
│   │   │   │   └── 🔧 SUBTASKS: Granular development steps
```

### **Terminology Mapping**
| Old Terms | New Standard | Definition |
|-----------|--------------|------------|
| ~~Phases~~ | **MODULES** | Functional areas of the product |
| ~~Milestones~~ | **EPICS** | Major development efforts spanning weeks |
| ~~Tasks~~ | **MILESTONES** | Specific deliverable checkpoints |
| ~~Subtasks~~ | **TASKS** | Implementation work items |

---

## 🏗️ **Module Structure**

### **Module 1: Core Mobile Experience** 
*User-facing mobile features that drive daily behavioral connection*

| Feature | PRD | Epic | Status |
|---------|-----|------|--------|
| **Momentum Meter** | `prd-momentum-meter.md` | Epic 1.1 | ⚪ Planned |
| **On-Demand Lesson Library** | `prd-on-demand-lesson-library.md` | Epic 1.2 | ⚪ Planned |
| **Today Feed (AI Daily Brief)** | `prd-today-feed.md` | Epic 1.3 | ⚪ Planned |
| **In-App Messaging** | `prd-in-app-messaging.md` | Epic 1.4 | ⚪ Planned |
| **Adaptive AI Coach** | `prd-adaptive-ai-coach.md` | Epic 1.5 | ⚪ Planned |
| **Habit Architect** | `prd-habit-architect.md` | Epic 1.6 | ⚪ Planned |
| **Active-Minutes Insights** | `prd-active-minutes-insights.md` | Epic 1.7 | ⚪ Planned |

### **Module 2: Data Integration & Events**
*Captures and processes behavioral and health data*

| Feature | PRD | Epic | Status |
|---------|-----|------|--------|
| **Engagement Events Logging** | `prd-engagement-events-logging.md` | Epic 2.1 | ✅ **COMPLETE** |
| **Wearable Integration Layer** | `prd-wearable-integration-layer.md` | Epic 2.2 | ⚪ Planned |
| **Coaching Interaction Log** | `prd-coaching-interaction-log.md` | Epic 2.3 | ⚪ Planned |

### **Module 3: AI & Personalization**
*Intelligence layer for personalized behavior change*

| Feature | PRD | Epic | Status |
|---------|-----|------|--------|
| **Personalized Motivation Profile** | `prd-personalized-motivation-profile.md` | Epic 3.1 | ⚪ Planned |
| **AI Nudge Optimizer** | `prd-ai-nudge-optimizer.md` | Epic 3.2 | ⚪ Planned |
| **Context-Aware Recommendations** | `prd-context-aware-recommendations.md` | Epic 3.3 | ⚪ Planned |

### **Module 4: Coaching & Support**
*Tools for health coaches and care teams*

| Feature | PRD | Epic | Status |
|---------|-----|------|--------|
| **Health Coach Dashboard** | `prd-health-coach-dashboard.md` | Epic 4.1 | ⚪ Planned |
| **Patient Messaging System** | `prd-patient-messaging-system.md` | Epic 4.2 | ⚪ Planned |
| **Care Team Escalation System** | `prd-care-team-escalation-system.md` | Epic 4.3 | ⚪ Planned |

### **Module 5: Analytics & Administration**
*Program management and operational tools*

| Feature | PRD | Epic | Status |
|---------|-----|------|--------|
| **User Segmentation & Cohort Analysis** | `prd-user-segmentation-and-cohort-analysis.md` | Epic 5.1 | ⚪ Planned |
| **Analytics Dashboard** | `prd-analytics-dashboard.md` | Epic 5.2 | ⚪ Planned |
| **Feature Flag & Content Config** | `prd-feature-flag-and-content-config.md` | Epic 5.3 | ⚪ Planned |

---

## 🎯 **Development Sequence (MVP Focus)**

### **Epic 2.1: Engagement Events Logging** ✅ **COMPLETE**
*Foundation data layer for all user behavioral events*

| Milestone | Deliverable | Status |
|-----------|-------------|--------|
| **M2.1.1: Database Schema** | `engagement_events` table with RLS | ✅ Complete |
| **M2.1.2: API Configuration** | REST/GraphQL/Realtime APIs | ✅ Complete |
| **M2.1.3: Cloud Function Integration** | Batch import endpoints | ✅ Complete |
| **M2.1.4: Testing & Validation** | Performance and RLS tests | ✅ Complete |
| **M2.1.5: Documentation & Deployment** | Production procedures | ✅ Complete |

### **Epic 1.1: Momentum Meter** 🟡 **NEXT**
*Patient-facing motivation gauge with three states: Rising, Steady, Needs Care*

| Milestone | Deliverable | Status |
|-----------|-------------|--------|
| **M1.1.1: UI Design & Mockups** | Complete design system and high-fidelity mockups | ⚪ Planned |
| **M1.1.2: Scoring Algorithm & Backend** | Database schema, calculation engine, API endpoints | ⚪ Planned |
| **M1.1.3: Flutter Widget Implementation** | Complete momentum meter widget with state management | ⚪ Planned |
| **M1.1.4: Notification System Integration** | FCM integration and automated coach interventions | ⚪ Planned |
| **M1.1.5: Testing & Polish** | Unit tests, performance optimization, deployment | ⚪ Planned |

### **Epic 1.2: On-Demand Lesson Library** 🟡 **NEXT**
*WordPress-integrated educational content with search and completion tracking*

| Milestone | Deliverable | Status |
|-----------|-------------|--------|
| **M1.2.1: WordPress Integration** | REST API connection and content sync | ⚪ Planned |
| **M1.2.2: Content Management** | Lesson cards with images and completion badges | ⚪ Planned |
| **M1.2.3: Search & Filter** | Tag-based filtering and search functionality | ⚪ Planned |
| **M1.2.4: Offline Support** | SQLite caching for offline access | ⚪ Planned |
| **M1.2.5: Completion Tracking** | Progress tracking and momentum integration | ⚪ Planned |

### **Epic 1.3: Today Feed (AI Daily Brief)** 🟡 **NEXT**
*Daily AI-generated health topics to spark curiosity and engagement*

| Milestone | Deliverable | Status |
|-----------|-------------|--------|
| **M1.3.1: Content Pipeline** | GCP backend integration for daily content | ⚪ Planned |
| **M1.3.2: Feed UI Component** | Today feed tile with summary and links | ⚪ Planned |
| **M1.3.3: Caching Strategy** | 24-hour refresh with offline fallback | ⚪ Planned |
| **M1.3.4: Momentum Integration** | +1 momentum on first daily open | ⚪ Planned |
| **M1.3.5: Testing & Analytics** | Usage tracking and content effectiveness | ⚪ Planned |

### **Epic 1.4: In-App Messaging** 🟡 **PLANNED**
*Simple messaging system for patient-coach communication*

| Milestone | Deliverable | Status |
|-----------|-------------|--------|
| **M1.4.1: Message Schema** | Database design for secure messaging | ⚪ Planned |
| **M1.4.2: Chat UI** | Flutter chat interface with message bubbles | ⚪ Planned |
| **M1.4.3: Push Notifications** | Real-time message notifications | ⚪ Planned |
| **M1.4.4: Security & Compliance** | HIPAA-compliant message encryption | ⚪ Planned |
| **M1.4.5: Coach Dashboard Integration** | Message management for care team | ⚪ Planned |

---

## 📅 **MVP Timeline (Next 12 Weeks)**

### **Sprint Planning**
| Week | Epic | Milestone | Focus |
|------|------|-----------|-------|
| **Week 1-3** | Epic 1.1 | M1.1.1-M1.1.5 | Momentum Meter complete implementation |
| **Week 4-5** | Epic 1.2 | M1.2.1-M1.2.3 | Lesson Library core features |
| **Week 6-7** | Epic 1.3 | M1.3.1-M1.3.3 | Today Feed implementation |
| **Week 8-9** | Epic 1.4 | M1.4.1-M1.4.3 | In-App Messaging basics |
| **Week 10-11** | Integration | All MVP epics | Testing, polish, TestFlight |
| **Week 12** | Epic 1.5 | M1.5.1 | AI Coach foundation (if time permits) |

### **Definition of Done (MVP)**
- ✅ Users can view momentum meter with real-time updates
- ✅ Users can access and complete educational lessons
- ✅ Users receive daily AI-generated health content
- ✅ Users can send/receive messages with care team
- ✅ All features integrate with engagement events logging
- ✅ 80%+ test coverage on core functionality
- ✅ Production deployment procedures documented
- ✅ TestFlight build ready for beta testing

### **Post-MVP Features (Weeks 13+)**
- **Epic 1.5:** Adaptive AI Coach (chat & voice)
- **Epic 1.6:** Habit Architect (mini-loop builder)
- **Epic 1.7:** Active-Minutes Insights (wearable integration)

---

## 📁 **File Organization**

### **Current Structure**
```
docs/
├── 0_Initial_docs/
│   ├── bee_project_structure.md        # This file (NEW)
│   ├── bee_mvp_architecture.md         # Technical architecture
│   └── [other foundation docs]
├── 1_milestone_1/                      # Epic 2.1 (COMPLETE)
│   ├── prd-engagement-events-logging.md
│   ├── tasks-prd-engagement-events-logging.md
│   └── [implementation docs]
└── 3_epic_1_1/                         # Epic 1.1 (IN PROGRESS)
    ├── README.md                        # Epic navigation hub
    ├── prd-daily-engagement-dashboard.md
    ├── tasks-prd-daily-engagement-dashboard.md
    ├── prompts-daily-engagement-dashboard.md
    ├── implementation/                  # Developer documentation
    └── docs/                            # Operational documentation
```

### **Naming Conventions**
- **Epic Directories**: `{epic_number}_{module}_{epic}/` (e.g., `2_epic_1_1/`)
- **PRD Files**: `prd-{feature-name}.md`
- **Task Files**: `tasks-prd-{feature-name}.md`
- **Prompt Files**: `prompts-{feature-name}.md`

---

## 🔄 **Status Tracking**

### **Epic Status Definitions**
- ✅ **COMPLETE**: All milestones delivered and deployed
- 🟡 **IN PROGRESS**: Active development underway
- 🟠 **NEXT**: Ready to start, dependencies met
- ⚪ **PLANNED**: Defined but not yet started
- 🔴 **BLOCKED**: Cannot proceed due to dependencies

### **Current Status Summary**
- **Module 1 (Core Mobile Experience)**: 0/7 epics complete (0 in progress)
- **Module 2 (Data Integration)**: 1/3 epics complete ✅
- **Module 3 (AI & Personalization)**: 0/3 epics complete
- **Module 4 (Coaching & Support)**: 0/3 epics complete
- **Module 5 (Analytics & Admin)**: 0/3 epics complete

**Overall Progress**: 1/19 epics complete (5%), 0 in progress

---

## 🚀 **Next Actions**

1. **Create Epic 1.1 directory structure** for Momentum Meter
2. **Write PRD for Momentum Meter** based on updated mobile app features
3. **Generate task breakdown** for Epic 1.1 milestones
4. **Set up development environment** for Flutter momentum meter work
5. **Begin Milestone M1.1.1** (UI Design & Mockups for circular gauge)

---

**Last Updated**: December 2024  
**Current Epic**: Epic 1.1 ⚪ Planned (Epic 2.1 ✅ Complete)  
**MVP Target**: 12 weeks (4 core epics) 