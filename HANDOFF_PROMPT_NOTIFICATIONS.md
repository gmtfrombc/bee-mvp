# Handoff Prompt: M1.1.4 Notification System Integration

**Epic:** 1.1 · Momentum Meter  
**Milestone:** M1.1.4 - Notification System Integration  
**Status:** Ready to Begin  
**Estimated Duration:** 57 hours (12 tasks over 5-7 days)  
**Priority:** High (Critical for MVP)  

---

## 🎯 **Milestone Overview**

You are beginning work on **M1.1.4: Notification System Integration** for the BEE Momentum Meter. This milestone integrates Firebase Cloud Messaging (FCM) to enable momentum-based push notifications and automated coach interventions.

### **Key Goals**
- Implement FCM for momentum-triggered notifications
- Create automated coach call scheduling system  
- Build personalized notification messaging
- Add user notification preferences
- Integrate with coach dashboard for intervention tracking

### **Context: What's Complete**
**M1.1.1 ✅ UI Design & Mockups** - Complete design system with 3 momentum states (Rising 🚀, Steady 🙂, Needs Care 🌱)

**M1.1.2 ✅ Scoring Algorithm & Backend** - Momentum calculation engine with:
- Exponential decay scoring algorithm (10-day half-life)
- Zone classification (Rising ≥70, Steady 45-69, Needs Care <45)
- Database tables: `daily_engagement_scores`, `momentum_notifications`, `coach_interventions`
- API endpoints: `/v1/momentum/current`, `/v1/momentum/history`
- Intervention rule engine foundation

**M1.1.3 ✅ Flutter Widget Implementation** - Complete Flutter momentum meter:
- Circular momentum gauge with custom painter
- Momentum card component with state management
- Weekly trend chart and quick stats cards
- Action buttons and detail modal
- Riverpod state management integration
- Supabase API integration with real-time updates
- Loading states, error handling, and offline support
- Responsive design for all target devices (375px-428px+)
- Accessibility compliance (VoiceOver/TalkBack)
- Smooth animations and state transitions

---

## 📋 **Task Breakdown for M1.1.4**

### **T1.1.4.1: Firebase Cloud Messaging Setup** (4h)
Set up FCM configuration for iOS and Android platforms
- Configure Firebase project and add app configurations
- Install and configure FCM Flutter plugin
- Set up iOS/Android platform-specific configurations
- Implement permission management for notifications

### **T1.1.4.2: FCM Token Management** (4h)
Implement token lifecycle management and storage
- Token generation and refresh handling
- Store tokens in Supabase user profiles
- Handle token invalidation and updates
- Cross-device token management

### **T1.1.4.3: Notification Content Templates** (3h)
Create personalized notification templates for each momentum state
- Supportive notifications (momentum drops)
- Coach intervention scheduling messages
- Celebration messages (sustained momentum)
- Daily momentum updates (optional)

### **T1.1.4.4: Push Notification Triggers** (8h)
Implement momentum-based notification triggers
- Score drop alert (≥15 points in 5 days)
- Needs Care intervention (2 consecutive days)
- Celebration trigger (5 consecutive Rising/Steady days)
- Engagement drop alerts (no app opens 48h+)

### **T1.1.4.5: Background Notification Handling** (6h)
Add background processing for iOS/Android
- Background notification processing
- Silent notification handling
- Badge count management
- Notification history tracking

### **T1.1.4.6: Deep Linking Implementation** (4h)
Implement navigation from notifications to momentum meter
- Deep link routing setup
- Notification tap handling
- App state management for deep links
- Analytics tracking for notification interactions

### **T1.1.4.7: User Notification Preferences** (4h)
Create user settings for notification control
- Notification type preferences (supportive, celebrations, etc.)
- Timing preferences (quiet hours, frequency)
- Notification channel management
- Opt-out functionality

### **T1.1.4.8: Automated Coach Scheduling** (6h)
Implement coach call scheduling system
- Integration with momentum rule engine
- Coach availability management
- Automated scheduling API
- User confirmation and rescheduling

### **T1.1.4.9: Notification Frequency Management** (4h)
Implement rate limiting and spam prevention
- Cooldown periods between notifications
- Daily/weekly frequency limits
- User fatigue detection
- A/B testing framework for message effectiveness

### **T1.1.4.10: Coach Dashboard Integration** (6h)
Create intervention tracking for care team
- Real-time intervention alerts
- Intervention outcome tracking
- Manual intervention override capabilities
- Care team notification preferences

### **T1.1.4.11: A/B Testing Framework** (4h)
Implement testing for notification effectiveness
- Message variant testing
- Timing optimization experiments
- Response rate analytics
- Personalization effectiveness metrics

### **T1.1.4.12: Notification Testing** (4h)
Test notification delivery across scenarios
- Platform-specific testing (iOS/Android)
- Background/foreground testing
- Edge case handling
- Integration testing with momentum system

---

## 📁 **Essential Files & Documentation**

### **Primary References**
- **📋 `docs/3_epic_1_1/tasks-momentum-meter.md`** - Complete task breakdown and progress tracking
- **📖 `docs/3_epic_1_1/README.md`** - Epic overview and technical architecture
- **📝 `docs/3_epic_1_1/prd-momentum-meter.md`** - Product requirements and user stories
- **🤖 `docs/3_epic_1_1/prompts-momentum-meter.md`** - Task-specific AI prompts for each implementation

### **Technical Implementation**
- **🔧 `app/lib/core/services/`** - Core service implementations (responsive, error handling, etc.)
- **📱 `app/lib/features/momentum/`** - Complete momentum meter implementation
- **🗄️ `supabase/migrations/`** - Database schema with momentum tables
- **⚙️ `functions/`** - Supabase Edge Functions for momentum calculation

### **Configuration Files**
- **📱 `app/pubspec.yaml`** - Flutter dependencies (ready for FCM additions)
- **🔥 `app/android/app/build.gradle`** - Android configuration (needs FCM setup)
- **🍎 `app/ios/Runner/Info.plist`** - iOS configuration (needs FCM setup)
- **📊 `pyproject.toml`** - Python dependencies for backend functions

---

## 🏗️ **Technical Architecture Context**

### **Current State**
- **Backend**: Supabase with PostgreSQL, Edge Functions for momentum calculation
- **Frontend**: Flutter app with Riverpod state management
- **Real-time**: Supabase realtime subscriptions for momentum updates
- **Database**: Tables for `daily_engagement_scores`, `momentum_notifications`, `coach_interventions`
- **API**: REST endpoints for momentum data with proper error handling

### **Integration Points**
- **Momentum Rule Engine**: Already implemented in Supabase Edge Functions
- **User Profiles**: Stored in Supabase auth with additional profile data
- **Coach Dashboard**: Future integration point (basic structure exists)
- **Analytics**: Event tracking infrastructure in place

---

## 🎯 **Specific Implementation Guidance**

### **Notification Types & Triggers**

#### **Supportive Notifications**
```typescript
// Trigger: Momentum drop ≥15 points in 5 days
{
  type: 'supportive',
  title: 'We\'re here to help! 🌱',
  body: 'Your momentum dipped a bit - that\'s okay! Small steps can get you back on track.',
  data: { action: 'open_momentum_meter', encouragement_level: 'gentle' }
}
```

#### **Coach Intervention**
```typescript
// Trigger: 2 consecutive "Needs Care" days
{
  type: 'coach_intervention',
  title: 'Your coach wants to connect',
  body: 'We\'ve noticed you might benefit from some support. Let\'s chat!',
  data: { action: 'schedule_coach_call', priority: 'high' }
}
```

#### **Celebration Messages**
```typescript
// Trigger: 5 consecutive Rising/Steady days
{
  type: 'celebration',
  title: 'Amazing momentum! 🚀',
  body: 'You\'ve been consistently engaged this week. Keep up the fantastic work!',
  data: { action: 'view_achievements', celebration_type: 'weekly_streak' }
}
```

### **Technical Requirements**

#### **Firebase Setup Checklist**
- [ ] Firebase project with FCM enabled
- [ ] iOS APNs certificate configuration
- [ ] Android google-services.json added
- [ ] Flutter firebase_messaging plugin configured
- [ ] Background message handling for both platforms

#### **Database Integration**
```sql
-- Update momentum_notifications table for FCM
ALTER TABLE momentum_notifications ADD COLUMN fcm_token TEXT;
ALTER TABLE momentum_notifications ADD COLUMN notification_payload JSONB;
ALTER TABLE momentum_notifications ADD COLUMN delivery_status TEXT DEFAULT 'pending';
```

#### **Deep Linking Routes**
```dart
// App routing for notification taps
'/momentum' -> MomentumScreen()
'/momentum/detail' -> MomentumDetailModal()
'/coach/schedule' -> CoachSchedulingScreen()
'/achievements' -> AchievementsScreen()
```

---

## 🚨 **Critical Success Factors**

### **Must-Have Features**
1. **Reliable Delivery**: Notifications must reach users consistently
2. **Appropriate Timing**: Respect user preferences and quiet hours
3. **Non-Intrusive**: Avoid notification fatigue with proper rate limiting
4. **Actionable**: Each notification should have clear next steps
5. **Personalized**: Messages should feel relevant and encouraging

### **Performance Requirements**
- Notification delivery latency: <30 seconds
- Background processing impact: Minimal battery drain
- Deep link navigation: <2 seconds to target screen
- Token refresh handling: Automatic and seamless

### **User Experience Standards**
- Clear, encouraging language aligned with momentum states
- Consistent visual branding in notification content
- Seamless integration with existing momentum meter UI
- Accessibility compliance for notification content

---

## 🧪 **Testing Strategy**

### **Test Scenarios**
1. **New User Flow**: First-time notification setup and permissions
2. **Momentum Transitions**: Notifications for each state change
3. **Background Scenarios**: App closed, device locked, low power mode
4. **Edge Cases**: Token refresh, network failures, permission revocation
5. **Cross-Platform**: iOS vs Android behavior differences

### **Validation Requirements**
- [ ] All notification types deliver successfully
- [ ] Deep links navigate to correct screens
- [ ] User preferences are respected
- [ ] Rate limiting prevents spam
- [ ] Coach scheduling integrates properly
- [ ] Background processing works reliably

---

## 📊 **Success Metrics**

### **Technical Metrics**
- Notification delivery success rate: >95%
- Deep link navigation success rate: >98%
- Background processing reliability: >99%
- Token refresh success rate: >95%

### **User Experience Metrics**
- Notification tap-through rate: >40%
- User preference opt-out rate: <15%
- Coach call acceptance rate: >60%
- Overall user satisfaction with notifications: >4.0/5.0

---

## 🚀 **Ready to Begin**

You have all the foundation pieces in place:
- ✅ Complete momentum calculation system
- ✅ Full Flutter UI implementation
- ✅ Database schema and API endpoints
- ✅ Real-time data synchronization
- ✅ User state management with Riverpod

Your mission is to add the notification layer that makes the momentum meter truly proactive in supporting user engagement. Focus on creating encouraging, timely, and actionable notifications that enhance the user experience without being intrusive.

**Start with T1.1.4.1 (Firebase Cloud Messaging Setup)** and refer to the detailed prompts in `docs/3_epic_1_1/prompts-momentum-meter.md` for specific implementation guidance.

---

**Last Updated**: December 2024  
**Handoff Completed**: M1.1.3 Flutter Widget Implementation ✅  
**Next Milestone**: M1.1.5 Testing & Polish  
**Epic Progress**: 34/59 tasks complete (57.6%) 