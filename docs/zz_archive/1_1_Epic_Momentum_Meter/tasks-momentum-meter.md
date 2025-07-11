# Tasks - Momentum Meter (Epic 1.1)

**Epic:** 1.1 · Momentum Meter  
**Module:** Core Mobile Experience  
**Status:** ✅ COMPLETE  
**Dependencies:** Epic 2.1 (Engagement Events Logging) ✅ Complete

---

## 📋 **Epic Overview**

**Goal:** Create a patient-facing motivation gauge that replaces traditional "engagement scores" with a friendly, three-state system designed to encourage rather than demotivate users.

**Success Criteria:**
- Users can view real-time momentum state with encouraging feedback
- Momentum meter loads within 2 seconds and updates automatically
- 90%+ of users understand momentum states in usability testing
- Integration with notification system triggers timely interventions
- Accessibility compliance (WCAG AA) achieved

**Key Innovation:** Three positive states (Rising 🚀, Steady 🙂, Needs Care 🌱) replace numerical scores to provide encouraging feedback and trigger coach interventions.

---

## 🏁 **Milestone Breakdown**

### **M1.1.1: UI Design & Mockups** ✅ Complete
*Design the user interface and user experience for the momentum meter*

| Task | Description | Estimated Hours | Status |
|------|-------------|----------------|--------|
| **T1.1.1.1** | Create design system foundation (colors, typography, spacing) | 6h | ✅ Complete |
| **T1.1.1.2** | Design high-fidelity mockups for all three momentum states | 8h | ✅ Complete |
| **T1.1.1.3** | Create circular gauge component specifications | 4h | ✅ Complete |
| **T1.1.1.4** | Design momentum card layout and responsive behavior | 6h | ✅ Complete |
| **T1.1.1.5** | Create weekly trend chart design with emoji markers | 4h | ✅ Complete |
| **T1.1.1.6** | Design detail modal breakdown interface | 4h | ✅ Complete |
| **T1.1.1.7** | Specify animation sequences and micro-interactions | 4h | ✅ Complete |
| **T1.1.1.8** | Create accessibility specifications and screen reader flow | 3h | ✅ Complete |
| **T1.1.1.9** | Design quick stats cards and action button layouts | 3h | ✅ Complete |
| **T1.1.1.10** | Conduct internal design review and iterate | 4h | ✅ Complete |

**Milestone Deliverables:**
- ✅ Complete design system with momentum state theming
- ✅ High-fidelity Figma mockups for all three states
- ✅ Component specifications and responsive design guidelines
- ✅ Animation and interaction specifications
- ✅ Accessibility compliance documentation
- ✅ Weekly trend chart with emoji markers
- ✅ Detail modal breakdown interface
- ✅ Quick stats cards and action button layouts
- ✅ Momentum card layout with responsive behavior

**Acceptance Criteria:**
- [x] All momentum states have distinct, accessible visual designs
- [x] Design follows Material Design 3 principles with BEE theming
- [x] Accessibility considerations documented (WCAG AA compliance)
- [x] Responsive design works across 375px-428px width range
- [x] Stakeholder approval on final designs (internal review complete)

---

### **M1.1.2: Scoring Algorithm & Backend** ✅ Complete
*Implement backend logic for calculating momentum scores and managing interventions*

| Task | Description | Estimated Hours | Status |
|------|-------------|----------------|--------|
| **T1.1.2.1** | Design momentum calculation algorithm with exponential decay | 8h | ✅ Complete |
| **T1.1.2.2** | Create database schema for momentum scores and notifications | 6h | ✅ Complete |
| **T1.1.2.3** | Implement zone classification logic (Rising/Steady/Needs Care) | 4h | ✅ Complete |
| **T1.1.2.4** | Create API endpoints for momentum data retrieval | 8h | ✅ Complete |
| **T1.1.2.5** | Implement intervention rule engine for notifications | 6h | ✅ Complete |
| **T1.1.2.6** | Create Supabase Edge Functions for score calculation | 8h | ✅ Complete |
| **T1.1.2.7** | Implement real-time triggers for momentum updates | 4h | ✅ Complete |
| **T1.1.2.8** | Add data validation and error handling | 4h | ✅ Complete |
| **T1.1.2.9** | Create database indexes and performance optimization | 3h | ✅ Complete |
| **T1.1.2.10** | Write unit tests for calculation logic and API endpoints | 6h | ✅ Complete |

**Milestone Deliverables:**
- ✅ Momentum calculation algorithm with 10-day half-life decay
- ✅ Database tables: `daily_engagement_scores`, `momentum_notifications`, `coach_interventions`
- ✅ Zone classification logic with hysteresis and trend analysis
- ✅ REST API endpoints: `/v1/momentum/current`, `/v1/momentum/history`, `/v1/momentum/interaction`
- ✅ Intervention rule engine with automated triggers
- ✅ Supabase Edge Functions for automated score calculation
- ✅ Real-time update mechanisms with WebSocket connections and cache invalidation
- ✅ Comprehensive data validation and error handling system
- ✅ Database performance optimization with indexes and materialized views

**Acceptance Criteria:**
- [x] Algorithm produces consistent, meaningful momentum classifications
- [x] API endpoints return data within 500ms for typical user
- [x] Intervention rules trigger correctly based on momentum patterns
- [x] Edge Functions handle batch processing and scheduled calculations
- [x] Real-time updates work reliably with Supabase subscriptions
- [x] Comprehensive error handling and validation implemented
- [x] Database performance optimized with comprehensive indexing strategy
- [x] 90%+ test coverage on calculation logic

---

### **M1.1.3: Flutter Widget Implementation** ✅ Complete
*Build the Flutter UI components and integrate with backend APIs*
**Progress:** 100% Complete (14/14 tasks, 87h/87h)

| Task | Description | Estimated Hours | Status |
|------|-------------|----------------|--------|
| **T1.1.3.1** | Set up Flutter project structure and dependencies | 3h | ✅ Complete |
| **T1.1.3.2** | Implement circular momentum gauge with custom painter | 8h | ✅ Complete |
| **T1.1.3.3** | Create momentum card component with state management | 8h | ✅ Complete |
| **T1.1.3.4** | Build weekly trend chart using fl_chart with emoji markers | 8h | ✅ Complete |
| **T1.1.3.5** | Implement quick stats cards (lessons, streak, today) | 6h | ✅ Complete |
| **T1.1.3.6** | Create action buttons with state-appropriate suggestions | 4h | ✅ Complete |
| **T1.1.3.7** | Implement detail modal breakdown interface | 6h | ✅ Complete |
| **T1.1.3.8** | Add Riverpod state management integration | 6h | ✅ Complete |
| **T1.1.3.9** | Integrate Supabase API calls and real-time subscriptions | 8h | ✅ Complete |
| **T1.1.3.10** | Implement loading states and skeleton screens | 4h | ✅ Complete |
| **T1.1.3.11** | Add error handling and offline support | 6h | ✅ Complete |
| **T1.1.3.12** | Implement responsive design for different screen sizes | 6h | ✅ Complete |
| **T1.1.3.13** | Add accessibility features (VoiceOver/TalkBack support) | 6h | ✅ Complete |
| **T1.1.3.14** | Implement smooth animations and state transitions | 8h | ✅ Complete |

**Milestone Deliverables:**
- ✅ Complete Flutter momentum meter widget library
- ✅ Integration with backend APIs and real-time updates
- ✅ Responsive design for all target devices
- ✅ Accessibility compliance (VoiceOver/TalkBack)
- ✅ Smooth animations and state transitions

**Acceptance Criteria:**
- [x] Momentum meter renders correctly on all target devices (375px-428px)
- [x] All API integrations working with proper error handling
- [x] Real-time updates work reliably in foreground and background
- [x] Accessibility features tested with screen readers
- [x] Performance meets requirements (2s load time, 60 FPS animations)

---

### **M1.1.4: Notification System Integration** ✅ Complete
*Implement push notifications and automated coach interventions*
**Progress:** 12/12 tasks complete (100% complete, 57h/57h)

| Task | Description | Estimated Hours | Status |
|------|-------------|----------------|--------|
| **T1.1.4.1** | Set up Firebase Cloud Messaging (FCM) configuration | 4h | ✅ Complete |
| **T1.1.4.2** | Implement FCM token management and storage | 4h | ✅ Complete |
| **T1.1.4.3** | Create notification content templates for each momentum state | 3h | ✅ Complete |
| **T1.1.4.4** | Implement push notification triggers based on momentum rules | 8h | ✅ Complete |
| **T1.1.4.5** | Add background notification handling for iOS/Android | 6h | ✅ Complete |
| **T1.1.4.6** | Implement deep linking from notifications to momentum meter | 4h | ✅ Complete |
| **T1.1.4.7** | Create user notification preferences and settings | 4h | ✅ Complete |
| **T1.1.4.8** | Implement automated coach call scheduling system | 6h | ✅ Complete |
| **T1.1.4.9** | Add notification frequency management and rate limiting | 4h | ✅ Complete |
| **T1.1.4.10** | Create coach dashboard integration for intervention tracking | 6h | ✅ Complete |
| **T1.1.4.11** | Implement A/B testing framework for notification effectiveness | 4h | ✅ Complete |
| **T1.1.4.12** | Test notification delivery across different scenarios | 4h | ✅ Complete |

**Milestone Deliverables:**
- ✅ FCM integration for momentum-based notifications
- ✅ FCM token management and refresh system
- ✅ Notification content templates for all momentum states
- ✅ Push notification triggers based on momentum rules (665-line Supabase Edge Function)
- ✅ Background notification handling with comprehensive isolate processing
- ✅ Deep linking service with action routing and UI integration
- ✅ Automated coach call scheduling system
- ✅ User notification preferences with comprehensive settings UI
- ✅ Notification frequency management and rate limiting
- ✅ Coach dashboard integration for intervention tracking
- ✅ A/B testing framework for notification effectiveness
- ✅ Comprehensive notification testing across different scenarios

**Acceptance Criteria:**
- [x] Push notifications sent correctly for all momentum triggers
- [x] Coach interventions scheduled automatically for "Needs Care" patterns
- [x] Users can configure notification preferences
- [x] Deep linking works reliably from notifications
- [x] Notification frequency respects user preferences and rate limits
- [x] Coach dashboard provides comprehensive intervention tracking
- [x] A/B testing framework enables notification optimization
- [x] Notification delivery tested across multiple scenarios

---

### **M1.1.5: Testing & Polish** | 13/13 complete | 86h/86h | ✅ Complete | Week 6 |
*Comprehensive testing, performance optimization, and production readiness*

**Current Test Baseline**: 250+ tests passing (Unit: 40+ tests, Integration: 43 tests, Background Notification: 12 tests, Widget: 90 tests, Accessibility: 23 tests, Performance: 15 tests, Device Compatibility: 14 tests, Other: 27+ tests)

**Performance Optimizations Completed**: 
- ✅ Reduced animation controllers (single controller vs. multiple)
- ✅ Optimized shimmer animations for memory efficiency
- ✅ Improved chart rendering with data pre-calculation
- ✅ Eliminated hardcoded values for full responsive design
- ✅ Memory usage <50MB maintained, 60 FPS animations preserved

| Task | Description | Estimated Hours | Status |
|------|-------------|----------------|--------|
| **T1.1.5.1** | Write comprehensive unit tests for momentum calculation | 8h | ✅ Complete |
| **T1.1.5.2** | Create widget tests for all momentum meter components | 8h | ✅ Complete |
| **T1.1.5.3** | Implement integration tests for API interactions | 8h | ✅ Complete |
| **T1.1.5.4** | Create performance tests for load times and animations | 6h | ✅ Complete |
| **T1.1.5.5** | Conduct accessibility testing with screen readers | 6h | ✅ Complete |
| **T1.1.5.6** | Perform cross-device compatibility testing | 6h | ✅ Complete |
| **T1.1.5.7** | Optimize widget performance and memory usage | 6h | ✅ Complete |
| **T1.1.5.8** | Implement caching strategy for offline support | 4h | ✅ Complete |
| **T1.1.5.9** | User acceptance testing with internal stakeholders | 6h | ✅ Complete |
| **T1.1.5.10** | Polish animations, transitions, and micro-interactions | 6h | ✅ Complete |
| **T1.1.5.11** | Create developer documentation and deployment guides | 6h | ✅ Complete |
| **T1.1.5.12** | Final bug fixes and edge case handling | 8h | ✅ Complete |
| **T1.1.5.13** | Set up production monitoring and deployment automation | 8h | ✅ Complete |

**Milestone Deliverables:**
- 🟡 Complete test suite with 80%+ coverage (Integration tests: ✅ Complete)
- ✅ Performance testing framework and benchmarks (✅ Complete: Load time, memory, animation, stress tests)
- ✅ Accessibility testing with screen readers (✅ Complete: 23 comprehensive accessibility tests)
- ✅ Enhanced offline caching strategy (✅ Complete: Comprehensive offline support with advanced features)
- ✅ Developer and user documentation (✅ Complete: Comprehensive developer documentation created)
- ⚪ Production-ready deployment
- ⚪ Accessibility compliance verification
- ✅ 250+ comprehensive tests passing (Unit: 40+, Integration: 43, Widget: 90, Performance: 15+)
- ✅ Performance optimizations (memory <50MB, 60 FPS animations, <2s load time)
- ✅ Accessibility compliance (WCAG AA, screen reader support, semantic labels)
- ✅ Device compatibility testing (iPhone SE to iPhone 15 Pro Max)
- ✅ Production deployment pipeline with automated testing and quality gates
- ✅ Comprehensive monitoring setup with Sentry integration and health checks
- ✅ Automated deployment scripts with environment validation and rollback procedures
- ✅ Production alerting system with Slack integration and escalation policies
- ✅ GitHub Actions workflow for CI/CD with security scanning and artifact management

**Acceptance Criteria:**
- [x] All tests pass with 90%+ coverage maintained
- [x] Performance benchmarks met (2s load time, 60 FPS animations)
- [x] Accessibility compliance verified (WCAG AA)
- [x] Production deployment pipeline functional with automated quality gates
- [x] Monitoring and alerting system operational with real-time health checks
- [x] Error tracking integrated with Sentry for production debugging
- [x] Automated deployment scripts tested and documented
- [x] GitHub Actions workflow validates all builds and deployments

---

## 📊 **Epic Progress Tracking**

### **Overall Status**
- **Total Tasks**: 59 tasks across 5 milestones
- **Estimated Hours**: 246 hours (~6 weeks for 1 developer)
- **Completed**: 56/59 tasks (94.9%)
- **In Progress**: 0/59 tasks (0%)
- **Planned**: 3/59 tasks (5.1%)

**Current Test Baseline**: 250+ tests passing (Unit: 40+ tests, Integration: 43 tests, Background Notification: 12 tests, Widget: 90 tests, Accessibility: 23 tests, Performance: 15 tests, Device Compatibility: 14 tests, Other: 27+ tests)

### **Milestone Progress**
| Milestone | Tasks | Hours | Status | Target Completion |
|-----------|-------|-------|--------|------------------|
| **M1.1.1: UI Design** | 10/10 complete | 46h/46h | ✅ Complete | Week 1 |
| **M1.1.2: Backend** | 10/10 complete | 57h/57h | ✅ Complete | Week 2 |
| **M1.1.3: Flutter Implementation** | 14/14 complete | 87h/87h | ✅ Complete | Week 3-4 |
| **M1.1.4: Notifications** | 12/12 complete | 57h/57h | ✅ Complete | Week 5 |
| **M1.1.5: Testing & Polish** | 13/13 complete | 86h/86h | ✅ Complete | Week 6 |

### **Dependencies Status**
- ✅ **Epic 2.1**: Engagement Events Logging (Complete - provides data source)
- 🟡 **Design System**: BEE Flutter UI components (In Progress - M1.1.1 core complete)
- ⚪ **Firebase Setup**: FCM configuration (Parallel development)
- ⚪ **Coach Dashboard**: Integration points (Future epic dependency)

---

## 🔧 **Technical Implementation Details**

### **Key Technologies**
- **Frontend**: Flutter with Material Design 3
- **State Management**: Riverpod for reactive updates
- **Backend**: Supabase with PostgreSQL
- **Real-time**: Supabase realtime subscriptions
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Charts**: fl_chart package for trend visualization
- **Testing**: Flutter test framework with Mockito

### **Performance Requirements**
- **Load Time**: Momentum meter must render within 2 seconds
- **Animation**: 60 FPS target for all animations
- **Memory**: <50MB RAM usage for momentum components
- **API Response**: <500ms for momentum data retrieval
- **Battery**: Minimal impact from background processing

### **Accessibility Requirements**
- **Screen Readers**: Full VoiceOver/TalkBack support
- **Color Contrast**: WCAG AA compliance (4.5:1 minimum)
- **Touch Targets**: 44px minimum for all interactive elements
- **Dynamic Type**: Support for iOS/Android text scaling
- **Reduced Motion**: Respect system motion preferences

---

## 🎯 **Quality Assurance Strategy**

### **Testing Approach**
1. **Unit Testing**: Algorithm logic, API functions, data validation
2. **Widget Testing**: UI components, animations, user interactions
3. **Integration Testing**: API integration, real-time updates, notifications
4. **Performance Testing**: Load times, memory usage, animation smoothness
5. **Accessibility Testing**: Screen reader compatibility, contrast ratios
6. **User Testing**: Comprehension of momentum states, overall usability

### **Test Coverage Goals**
- **Unit Tests**: 90%+ coverage for business logic
- **Widget Tests**: 80%+ coverage for UI components
- **Integration Tests**: 70%+ coverage for API interactions
- **Overall**: 80%+ combined test coverage

### **Quality Gates**
- [ ] All tests passing with required coverage
- [ ] Performance benchmarks met
- [ ] Accessibility compliance verified
- [ ] Code review approval from senior developers
- [ ] Stakeholder acceptance testing passed

---

## 🚨 **Risks & Mitigation Strategies**

### **High Priority Risks**
1. **Algorithm Complexity**: Momentum calculation may be too complex
   - *Mitigation*: Start with simple rules, iterate based on user feedback
   
2. **User Comprehension**: Users may not understand three-state system
   - *Mitigation*: Extensive user testing and clear messaging

3. **Performance Issues**: Complex animations may impact performance
   - *Mitigation*: Implement performance monitoring and optimization

### **Medium Priority Risks**
1. **Notification Fatigue**: Too many notifications may annoy users
   - *Mitigation*: Careful frequency tuning and user preference controls

2. **Real-time Reliability**: Supabase subscriptions may be unreliable
   - *Mitigation*: Implement fallback polling and error recovery

3. **Cross-platform Consistency**: Different behavior on iOS vs Android
   - *Mitigation*: Extensive testing on both platforms

### **Low Priority Risks**
1. **Design Iteration**: Multiple design changes may delay development
   - *Mitigation*: Lock design early with stakeholder approval

2. **API Changes**: Backend API changes may break frontend
   - *Mitigation*: Versioned APIs and proper error handling

---

## 📋 **Definition of Done**

**Epic 1.1 is complete when:**
- [ ] All 59 tasks completed and verified
- [ ] Momentum meter loads within 2 seconds on average devices
- [ ] All three momentum states display correctly with appropriate messaging
- [ ] Real-time updates work reliably across all scenarios
- [ ] Push notifications trigger correctly based on momentum rules
- [ ] 80%+ test coverage achieved across all test types
- [ ] Performance requirements met (memory, CPU, network)
- [ ] Accessibility compliance verified (WCAG AA)
- [ ] Cross-device compatibility confirmed
- [ ] Documentation complete and approved
- [ ] Stakeholder acceptance testing passed
- [ ] Production deployment successful
- [ ] Monitoring and alerting configured

---

## 🚀 **Next Steps**

### **Immediate Actions**
1. **Stakeholder Review**: Get approval on Epic scope and timeline
2. **Design Kickoff**: Begin M1.1.1 with design system foundation
3. **Environment Setup**: Prepare development tools and access
4. **Team Coordination**: Align with design and backend teams

### **Week 1 Focus**
- Complete design system foundation (T1.1.1.1)
- Create high-fidelity mockups for all momentum states (T1.1.1.2)
- Begin component specifications (T1.1.1.3-T1.1.1.4)

### **Success Metrics**
- Design approval by end of Week 1
- Backend implementation complete by end of Week 2
- Flutter widgets functional by end of Week 4
- Full integration testing by end of Week 5
- Production deployment by end of Week 6

---

**Last Updated**: December 2024  
**Next Milestone**: M1.1.1 (UI Design & Mockups)  
**Estimated Completion**: 6 weeks from start  
**Epic Owner**: Development Team  
**Stakeholders**: Design Team, Product Team, Clinical Team 