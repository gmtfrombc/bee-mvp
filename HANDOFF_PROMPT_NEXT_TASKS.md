# Handoff Prompt: BEE Momentum Meter - Continue Notification System

## Project Context
**BEE Momentum Meter** - Flutter app with Supabase backend for patient motivation tracking. Currently at **61% completion** of Epic 1.1.

## Current Status
✅ **COMPLETED**: T1.1.4.1-T1.1.4.5 (Background Notification Handling & Deep Linking)
- Firebase Cloud Messaging fully integrated
- FCM token management working
- Notification content templates created
- Push notification triggers implemented (665-line Supabase Edge Function)
- Background notification handler with isolate processing
- Deep linking service with action routing
- Comprehensive test suite (92 tests passing)
- All linting issues resolved

## Next Tasks (T1.1.4.6-T1.1.4.12)
**PRIORITY**: Complete remaining notification system integration tasks:

1. **T1.1.4.6**: Implement deep linking from notifications to momentum meter (4h)
2. **T1.1.4.7**: Create user notification preferences and settings (4h)  
3. **T1.1.4.8**: Implement automated coach call scheduling system (6h)
4. **T1.1.4.9**: Add notification frequency management and rate limiting (4h)
5. **T1.1.4.10**: Create coach dashboard integration for intervention tracking (6h)
6. **T1.1.4.11**: Implement A/B testing framework for notification effectiveness (4h)
7. **T1.1.4.12**: Test notification delivery across different scenarios (4h)

## Key Files to Work With
- `app/lib/core/services/notification_deep_link_service.dart` - Deep linking logic
- `app/lib/core/services/notification_action_dispatcher.dart` - Action coordination
- `app/lib/core/services/push_notification_trigger_service.dart` - Trigger logic
- `functions/push-notification-triggers/index.ts` - Supabase Edge Function
- `docs/3_epic_1_1/tasks-momentum-meter.md` - Task tracking

## Technical Context
- **Flutter**: Material Design 3 with Riverpod state management
- **Backend**: Supabase with PostgreSQL, Edge Functions
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Testing**: 92 tests currently passing, maintain coverage

## Success Criteria
- Complete M1.1.4 milestone (notification system integration)
- Maintain test coverage and code quality
- Update `docs/3_epic_1_1/tasks-momentum-meter.md` when tasks completed
- All notification scenarios working end-to-end

## Important Notes
- Deep linking foundation already exists, extend for full navigation
- FCM payload format supports: notification_id, intervention_type, action_type, action_data
- Background processing handles: momentum_drop, celebration, consecutive_needs_care, score_drop
- Test environment properly configured, all tests should pass

**REMEMBER**: Update the tasks file (`docs/3_epic_1_1/tasks-momentum-meter.md`) when you complete tasks to track progress. 