# Developer Prompts - Momentum Meter (Epic 1.1)

**Epic:** 1.1 · Momentum Meter  
**Module:** Core Mobile Experience  
**Purpose:** Task-specific prompts for AI-assisted development

---

## 🎯 **Epic Context**

**Goal:** Build a patient-facing motivation gauge that replaces traditional "engagement scores" with a friendly, three-state system designed to encourage rather than demotivate users.

**Key Innovation:** Uses positive states (Rising 🚀, Steady 🙂, Needs Care 🌱) instead of numerical scores to provide encouraging feedback and trigger timely interventions.

**Integration:** Builds on Epic 2.1 (Engagement Events Logging) to create the primary motivational interface for the BEE platform.

---

## 📋 **Milestone-Specific Prompts**

### **M1.1.1: UI Design & Mockups**

#### **Prompt for T1.1.1.1: Design System Foundation**
```
Create a comprehensive design system for a health app momentum meter with these requirements:

CONTEXT: BEE (Behavioral Engagement Engine) - health and wellness tracking app
FEATURE: Momentum Meter - replaces numerical scores with encouraging states
GOAL: Motivate users through positive reinforcement, not judgment

DESIGN SYSTEM REQUIREMENTS:
- Three momentum states with distinct color schemes:
  * Rising 🚀: Green (#4CAF50) - celebratory, energetic
  * Steady 🙂: Blue (#2196F3) - encouraging, supportive  
  * Needs Care 🌱: Orange (#FF9800) - nurturing, hopeful
- Typography hierarchy for mobile (SF Pro/Roboto)
- 8px spacing grid system
- Accessibility compliance (WCAG AA 4.5:1 contrast)
- Material Design 3 foundation with health theming

COMPONENTS TO DEFINE:
- Color palette with light/dark variants
- Typography scales (momentum title, message, body, caption)
- Spacing tokens and layout grid
- Icon specifications and emoji usage
- Shadow and elevation system
- Animation timing and easing curves

Please create: color specifications, typography hierarchy, spacing system, and component guidelines.
```

#### **Prompt for T1.1.1.2: High-Fidelity Mockups**
```
Create high-fidelity Figma mockups for a Flutter momentum meter with these specifications:

MOMENTUM STATES TO DESIGN:
1. Rising State (85% momentum):
   - Green circular gauge with rocket emoji
   - "You're on fire! Keep up the great momentum!"
   - 2-3 action buttons (Learn, Share)
   - Weekly trend showing upward progression

2. Steady State (65% momentum):
   - Blue circular gauge with smile emoji
   - "You're doing well! Stay consistent!"
   - 2 action buttons focused on consistency
   - Stable trend line

3. Needs Care State (30% momentum):
   - Orange circular gauge with plant emoji
   - "Let's grow together! Every small step counts!"
   - 1-2 very simple action buttons (Quick Start, Get Support)
   - Encouraging motivational quote

LAYOUT STRUCTURE:
- Header with personalized greeting
- Momentum card (200px height) with circular gauge
- Quick stats row (lessons, streak, today's activity)
- Weekly trend chart with emoji markers
- Action section with state-appropriate suggestions
- Mobile-first design (375px-428px width)

DESIGN PRINCIPLES:
- Positive, encouraging language throughout
- No numerical scores visible to users
- Clear visual hierarchy and accessibility
- Smooth animations and micro-interactions

Please create mockups for all three states plus detail modal breakdown.
```

#### **Prompt for T1.1.1.3: Animation Specifications**
```
Design animation specifications for momentum meter interactions:

CORE ANIMATIONS:
1. Initial Load Sequence:
   - Card fade in (0-800ms)
   - Circular gauge fill animation (300-1800ms)
   - Slight bounce effect (1800-2000ms)
   - Staggered appearance of stats cards

2. State Transition Animation:
   - Color morphing between momentum states (1000ms)
   - Progress ring smooth update (1200ms)
   - Emoji crossfade (500-700ms)
   - Message text fade out/in (800-1000ms)

3. Micro-interactions:
   - Button press scale (1.0 → 0.95, 100ms)
   - Card tap feedback with haptics
   - Progress bar fill animations
   - Trend chart line drawing

ANIMATION PRINCIPLES:
- Material Design motion curves
- 60 FPS performance target
- Respect reduced motion preferences
- Meaningful motion that supports understanding
- Subtle feedback for all interactions

TECHNICAL SPECS:
- Flutter AnimationController setup
- Custom painter for circular gauge
- Riverpod integration for state changes
- Performance optimization techniques

Please provide: timing specifications, easing curves, Flutter implementation patterns, and accessibility considerations.
```

### **M1.1.2: Scoring Algorithm & Backend**

#### **Prompt for T1.1.2.1: Momentum Calculation Algorithm**
```
Design a momentum scoring algorithm for health behavior tracking with these requirements:

CONTEXT: 
- Replace traditional 0-100 "engagement scores" with positive momentum states
- Users should never see raw numerical scores
- Algorithm feeds three-zone classification system
- Must be explainable and fair across different user patterns

INPUT DATA (from engagement_events table):
- app_open events with session duration
- lesson_complete events (high value: +3 weight)
- journal_entry events (+2 weight)
- goal_complete events (+2.5 weight)
- coach_message_read (+1.5 weight)
- coach_message_reply (+2.0 weight)
- telehealth_attend (+5.0 weight)
- telehealth_noshow (-3.0 weight)

ALGORITHM REQUIREMENTS:
- Exponential decay with 10-day half-life
- Three-day rolling average for noise reduction
- Sigmoid normalization to 0-100 scale
- Zone classification: Rising (≥70), Steady (45-69), Needs Care (<45)
- Handle new users gracefully
- Account for different engagement patterns

INTERVENTION TRIGGERS:
- Score drop ≥15 points in 5 days → supportive notification
- Two consecutive "Needs Care" days → auto-schedule coach call
- Five consecutive "Rising/Steady" days → celebration message

Please provide: Python algorithm implementation, SQL queries for data retrieval, zone classification logic, and intervention rule engine.
```

#### **Prompt for T1.1.2.2: Database Schema Design**
```
Design database schema for momentum meter with these requirements:

NEW TABLES NEEDED:
1. daily_engagement_scores:
   - Store daily momentum scores and zones
   - Support historical trend analysis
   - Enable coach dashboard integration

2. momentum_notifications:
   - Track all momentum-triggered notifications
   - Support response tracking and analytics
   - Enable notification frequency management

3. coach_interventions:
   - Log momentum-triggered coach outreach
   - Track intervention outcomes
   - Support care team coordination

EXISTING TABLE UPDATES:
- Add momentum_weight column to engagement_events
- Create performance indexes for momentum queries
- Ensure RLS policies cover new tables

TECHNICAL REQUIREMENTS:
- PostgreSQL with Supabase
- Row Level Security (RLS) for all tables
- Proper indexing for performance
- Foreign key constraints and data integrity
- Support for real-time subscriptions

PERFORMANCE CONSIDERATIONS:
- Efficient queries for daily score calculation
- Indexes for trend analysis
- Partitioning strategy for large datasets
- Caching strategy for frequently accessed data

Please provide: CREATE TABLE statements, index definitions, RLS policies, and migration scripts.
```

#### **Prompt for T1.1.2.3: API Endpoint Implementation**
```
Implement REST API endpoints for momentum meter with these specifications:

REQUIRED ENDPOINTS:

1. GET /v1/momentum/current
   - Return current momentum state for authenticated user
   - Include breakdown of contributing factors
   - Provide suggested actions based on state
   - Include 7-day trend data

2. POST /v1/momentum/interaction
   - Log user interactions with momentum meter
   - Track engagement with different components
   - Support analytics and optimization

3. GET /v1/momentum/trend/{days}
   - Return historical momentum data
   - Support coach dashboard integration
   - Enable trend analysis

RESPONSE FORMAT:
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
  "trend": [...]
}
```

TECHNICAL REQUIREMENTS:
- Supabase Edge Functions (TypeScript/Deno)
- Proper error handling and validation
- Rate limiting and security
- Real-time capabilities
- Comprehensive logging

Please implement with proper authentication, error handling, and performance optimization.
```

### **M1.1.3: Flutter Widget Implementation**

#### **Prompt for T1.1.3.1: Circular Momentum Gauge Widget**
```
Create a Flutter widget for the momentum meter circular gauge with these specifications:

WIDGET REQUIREMENTS:
- Custom painter for circular progress ring
- 120px diameter with 8px stroke width
- State-specific colors and center emoji
- Smooth animation from 0% to target percentage
- Tap gesture to show detailed breakdown

VISUAL SPECIFICATIONS:
- Background ring: #E0E0E0
- Progress ring: Dynamic color based on momentum state
- Center emoji: 48px size, state-specific (🚀🙂🌱)
- Animation: 1.5s ease-out fill animation
- Accessibility: Semantic labels for screen readers

TECHNICAL IMPLEMENTATION:
- StatefulWidget with AnimationController
- Custom painter for efficient rendering
- Riverpod integration for state management
- Responsive design for different screen sizes
- Performance optimization with RepaintBoundary

STATE MANAGEMENT:
```dart
class MomentumGauge extends StatefulWidget {
  final MomentumState state;
  final double percentage;
  final VoidCallback? onTap;
  
  const MomentumGauge({
    Key? key,
    required this.state,
    required this.percentage,
    this.onTap,
  }) : super(key: key);
}
```

ANIMATION SEQUENCE:
1. Fade in card (0-800ms)
2. Fill progress ring (300-1800ms)
3. Bounce effect (1800-2000ms)

Please implement complete widget with animations, accessibility, and state management integration.
```

#### **Prompt for T1.1.3.2: Momentum Card Component**
```
Implement a comprehensive momentum card component with these requirements:

CARD STRUCTURE:
- Container with momentum gauge, message, and progress bar
- 200px height, 16px padding, 12px border radius
- #F5F5F5 background with subtle shadow
- Responsive design for 375px-428px width

CONTENT LAYOUT:
1. Header: "YOUR MOMENTUM" (14px, #757575)
2. Circular gauge with state emoji and label
3. Encouraging message (18px, center-aligned)
4. Weekly progress bar (4px height, state color)
5. Tap gesture for detailed breakdown modal

TYPOGRAPHY HIERARCHY:
- State label: 24px bold, state color
- Message: 18px medium, #212121
- Progress text: 14px regular, #757575

STATE-SPECIFIC CONTENT:
- Rising: "You're on fire! Keep up the great momentum!"
- Steady: "You're doing well! Stay consistent!"
- Needs Care: "Let's grow together! Every small step counts!"

TECHNICAL REQUIREMENTS:
- Material Design 3 styling
- Smooth state transitions
- Accessibility compliance
- Integration with momentum provider
- Error and loading states

Please implement with proper state management, animations, and accessibility features.
```

#### **Prompt for T1.1.3.3: Weekly Trend Chart Widget**
```
Create a weekly trend chart widget using fl_chart with these specifications:

CHART REQUIREMENTS:
- Line chart showing 7 days of momentum states
- X-axis: Day labels (M, T, W, T, F, S, S)
- Y-axis: Hidden (states represented by emojis)
- Smooth curved line connecting emoji markers
- Interactive touch points with state details

VISUAL DESIGN:
- Emoji markers: 🚀 (Rising), 🙂 (Steady), 🌱 (Needs Care)
- Line color: Dynamic based on overall trend
- Background: #F5F5F5 with 16px padding
- Height: 140px, responsive width

DATA STRUCTURE:
```dart
class MomentumTrendData {
  final DateTime date;
  final MomentumState state;
  final String dayLabel;
  final String emoji;
}
```

INTERACTION FEATURES:
- Tap on emoji to show date and state details
- Smooth animations when data updates
- Loading skeleton for data fetch
- Empty state for new users

TECHNICAL IMPLEMENTATION:
- fl_chart LineChart widget
- Custom emoji markers instead of dots
- Bezier curves for smooth lines
- Riverpod integration for real-time updates
- Performance optimization for frequent updates

Please implement complete chart widget with animations, interactions, and data handling.
```

### **M1.1.4: Notification System Integration**

#### **Prompt for T1.1.4.1: Firebase Cloud Messaging Setup**
```
Implement Firebase Cloud Messaging for momentum-based notifications:

NOTIFICATION TYPES:
1. Supportive notifications (momentum drop ≥15 points)
2. Coach intervention scheduling (2 consecutive "Needs Care" days)
3. Celebration messages (sustained positive momentum)
4. Daily momentum updates (optional user preference)

FCM SETUP REQUIREMENTS:
- Flutter FCM plugin configuration
- iOS/Android platform-specific setup
- Background notification handling
- Notification permission management
- Deep linking to momentum meter

NOTIFICATION CONTENT:
- Supportive: "We're here to help you get back on track! 🌱"
- Coach scheduling: "Your coach would like to check in with you"
- Celebration: "Amazing momentum this week! Keep it up! 🚀"
- Daily update: "Check your momentum meter for today's progress"

TECHNICAL IMPLEMENTATION:
- Firebase project configuration
- FCM token management and storage
- Background message handling
- Notification tap handling with deep links
- User preference management

PERSONALIZATION:
- User-specific messaging based on momentum history
- Timing optimization (avoid late night notifications)
- Frequency management to prevent notification fatigue
- A/B testing framework for message effectiveness

Please implement complete FCM integration with personalized messaging and user preferences.
```

#### **Prompt for T1.1.4.2: Intervention Rule Engine**
```
Create an automated intervention system based on momentum patterns:

INTERVENTION RULES:
1. Score Drop Alert:
   - Trigger: ≥15 point drop in 5 days
   - Action: Send supportive push notification
   - Frequency: Max once per day

2. Needs Care Intervention:
   - Trigger: 2 consecutive "Needs Care" days
   - Action: Auto-schedule coach call
   - Escalation: Notify care team

3. Celebration Trigger:
   - Trigger: 5 consecutive "Rising/Steady" days
   - Action: Send celebration message
   - Frequency: Weekly maximum

4. Engagement Drop:
   - Trigger: No app opens for 48 hours
   - Action: Gentle re-engagement notification
   - Escalation: Coach outreach after 72 hours

IMPLEMENTATION REQUIREMENTS:
- Supabase Edge Function for rule processing
- Database triggers on momentum score updates
- Rate limiting to prevent notification spam
- Coach dashboard integration for manual overrides
- Analytics tracking for intervention effectiveness

RULE ENGINE STRUCTURE:
```typescript
interface InterventionRule {
  id: string;
  name: string;
  condition: (user: User, momentum: MomentumHistory) => boolean;
  action: (user: User) => Promise<void>;
  cooldown: number; // hours
  priority: number;
}
```

PERSONALIZATION FACTORS:
- User engagement patterns
- Historical response to interventions
- Time zone and preferred contact hours
- Care team preferences and availability

Please implement rule engine with proper scheduling, rate limiting, and analytics.
```

### **M1.1.5: Testing & Polish**

#### **Prompt for T1.1.5.1: Comprehensive Test Suite**
```
Create comprehensive test suite for momentum meter with 80%+ coverage:

TEST CATEGORIES:

1. Unit Tests:
   - Momentum calculation algorithm
   - Zone classification logic
   - Intervention rule engine
   - API endpoint functions
   - Data validation and sanitization

2. Widget Tests:
   - Momentum gauge rendering
   - State transitions and animations
   - User interaction handling
   - Accessibility compliance
   - Error state handling

3. Integration Tests:
   - API endpoint integration
   - Real-time data updates
   - Notification system
   - Database operations
   - Cross-platform compatibility

TEST SCENARIOS:
- New user with no momentum history
- User with various momentum patterns
- Edge cases (missing data, API failures)
- Performance under load
- Accessibility with screen readers

MOCK DATA SETUP:
```dart
class MockMomentumData {
  static MomentumState risingState() => MomentumState(
    state: 'Rising',
    percentage: 85,
    message: 'You\'re on fire!',
    // ... other properties
  );
}
```

TESTING FRAMEWORK:
- Flutter test framework
- Mockito for dependency mocking
- Golden tests for UI consistency
- Integration test driver
- Performance profiling

Please create complete test suite with proper mocking, edge case coverage, and performance validation.
```

#### **Prompt for T1.1.5.2: Performance Optimization**
```
Optimize momentum meter performance for production deployment:

PERFORMANCE TARGETS:
- Momentum meter load time: <2 seconds
- Animation frame rate: 60 FPS
- Memory usage: <50MB for momentum components
- API response time: <500ms
- Battery impact: Minimal background processing

OPTIMIZATION AREAS:

1. Widget Performance:
   - RepaintBoundary for momentum gauge
   - Efficient custom painter implementation
   - Animation controller optimization
   - State management efficiency

2. Data Loading:
   - Aggressive caching strategy
   - Background data prefetching
   - Efficient API payload design
   - Local storage optimization

3. Real-time Updates:
   - Debounced update handling
   - Selective widget rebuilding
   - Connection management
   - Background sync optimization

MONITORING SETUP:
- Performance metrics collection
- Crash reporting integration
- User experience analytics
- API performance monitoring

OPTIMIZATION TECHNIQUES:
```dart
// Widget optimization
class OptimizedMomentumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MomentumCard(),
    );
  }
}

// Animation optimization
class PerformantGauge extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MomentumGaugePainter(),
      willChange: true,
    );
  }
}
```

Please implement performance optimizations with monitoring and validation.
```

---

## 🔧 **Development Guidelines**

### **Code Quality Standards**
- Follow Flutter/Dart style guide
- Use meaningful variable and function names
- Add comprehensive documentation
- Implement proper error handling
- Include accessibility features
- Write testable, modular code

### **Performance Requirements**
- Momentum meter load time: <2 seconds
- Smooth animations: 60 FPS
- Memory usage: <50MB for momentum components
- Network efficiency: Minimize API calls
- Battery optimization: Efficient background processing

### **Testing Requirements**
- 80%+ code coverage
- Unit tests for all business logic
- Widget tests for UI components
- Integration tests for API interactions
- Performance tests for critical paths
- Accessibility tests with screen readers

### **Documentation Standards**
- Inline code documentation
- API endpoint documentation
- User-facing feature documentation
- Deployment and maintenance guides
- Performance optimization notes

### **Accessibility Requirements**
- WCAG AA compliance (4.5:1 contrast ratio)
- Screen reader support (VoiceOver/TalkBack)
- Dynamic type scaling
- Touch target minimum 44px
- Reduced motion preference support

---

## 🎨 **Design Consistency**

### **Momentum State Guidelines**
- **Rising 🚀**: Celebratory, energetic tone with green theming
- **Steady 🙂**: Encouraging, supportive tone with blue theming
- **Needs Care 🌱**: Nurturing, hopeful tone with orange theming

### **Language Principles**
- Always use positive, encouraging language
- Avoid clinical or judgmental terminology
- Focus on growth and progress metaphors
- Provide specific, actionable guidance
- Celebrate small wins and consistency

### **Visual Consistency**
- Material Design 3 foundation
- 8px spacing grid system
- Consistent emoji usage and sizing
- Smooth, meaningful animations
- Accessible color contrast ratios

---

**Last Updated**: December 2024  
**Usage**: Copy relevant prompts for AI-assisted development of specific tasks  
**Epic Owner**: Development Team  
**Review Required**: Design Team, Clinical Team, Engineering Team 