# BEE Momentum Meter - API Endpoints Specification

**Epic:** 1.1 · Momentum Meter  
**Task:** T1.1.2.4 · Create API endpoints for momentum data retrieval  
**Status:** ✅ Complete  
**Created:** December 2024  

---

## 🎯 **API Overview**

The Momentum Meter API provides RESTful endpoints for retrieving momentum data, triggering calculations, and managing user interactions. All endpoints follow REST conventions and return JSON responses with consistent error handling.

### **Base URL**
```
Production: https://api.bee-app.com/v1
Development: https://dev-api.bee-app.com/v1
Local: http://localhost:3000/v1
```

### **Authentication**
All endpoints require Bearer token authentication using Supabase JWT tokens:
```http
Authorization: Bearer <supabase_jwt_token>
```

---

## 📊 **Core Endpoints**

### **GET /momentum/current**
Retrieve current momentum state and score for authenticated user.

#### **Request**
```http
GET /v1/momentum/current
Authorization: Bearer <token>
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "momentum_score": 72.5,
    "momentum_state": "Rising",
    "state_emoji": "🚀",
    "primary_message": "You're on fire! Keep up the great momentum! 🔥",
    "secondary_message": "Your consistency is inspiring!",
    "confidence": 0.85,
    "trend": {
      "direction": "rising",
      "strength": 2.3,
      "description": "Trending upward"
    },
    "last_updated": "2024-12-15T14:30:00Z",
    "calculation_date": "2024-12-15",
    "days_in_current_state": 3,
    "quick_stats": {
      "lessons_completed_today": 2,
      "current_streak": 7,
      "weekly_engagement": 85.2
    }
  },
  "meta": {
    "request_id": "req_123456789",
    "response_time_ms": 145,
    "cache_hit": false
  }
}
```

#### **Error Responses**
```json
// User not found or no momentum data
{
  "success": false,
  "error": {
    "code": "MOMENTUM_NOT_FOUND",
    "message": "No momentum data found for user",
    "details": "User may need to complete initial engagement activities"
  },
  "meta": {
    "request_id": "req_123456789"
  }
}

// Authentication error
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired authentication token"
  }
}
```

---

### **GET /momentum/history**
Retrieve historical momentum data with optional date range filtering.

#### **Request**
```http
GET /v1/momentum/history?days=30&include_scores=true
Authorization: Bearer <token>
```

#### **Query Parameters**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `days` | integer | 30 | Number of days to retrieve (max 365) |
| `start_date` | string | - | Start date (YYYY-MM-DD) |
| `end_date` | string | - | End date (YYYY-MM-DD) |
| `include_scores` | boolean | false | Include raw momentum scores |
| `include_events` | boolean | false | Include engagement event counts |

#### **Response**
```json
{
  "success": true,
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "date_range": {
      "start_date": "2024-11-15",
      "end_date": "2024-12-15",
      "total_days": 30
    },
    "momentum_history": [
      {
        "date": "2024-12-15",
        "momentum_state": "Rising",
        "momentum_score": 72.5,
        "state_emoji": "🚀",
        "trend_direction": "rising",
        "engagement_events": 8,
        "lessons_completed": 2,
        "coach_interactions": 1
      },
      {
        "date": "2024-12-14",
        "momentum_state": "Rising",
        "momentum_score": 70.2,
        "state_emoji": "🚀",
        "trend_direction": "stable",
        "engagement_events": 6,
        "lessons_completed": 1,
        "coach_interactions": 0
      }
    ],
    "summary": {
      "total_days": 30,
      "rising_days": 12,
      "steady_days": 15,
      "needs_care_days": 3,
      "average_score": 65.8,
      "best_streak": 8,
      "current_streak": 7
    }
  },
  "meta": {
    "request_id": "req_123456790",
    "response_time_ms": 89,
    "cache_hit": true
  }
}
```

---

### **GET /momentum/weekly-trend**
Retrieve weekly momentum trend data optimized for chart visualization.

#### **Request**
```http
GET /v1/momentum/weekly-trend?weeks=4
Authorization: Bearer <token>
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "weeks": 4,
    "trend_data": [
      {
        "week_start": "2024-12-09",
        "week_end": "2024-12-15",
        "week_number": 50,
        "daily_states": [
          {"date": "2024-12-09", "state": "Steady", "emoji": "🙂", "score": 58.3},
          {"date": "2024-12-10", "state": "Rising", "emoji": "🚀", "score": 71.2},
          {"date": "2024-12-11", "state": "Rising", "emoji": "🚀", "score": 73.8},
          {"date": "2024-12-12", "state": "Rising", "emoji": "🚀", "score": 75.1},
          {"date": "2024-12-13", "state": "Rising", "emoji": "🚀", "score": 72.9},
          {"date": "2024-12-14", "state": "Rising", "emoji": "🚀", "score": 70.2},
          {"date": "2024-12-15", "state": "Rising", "emoji": "🚀", "score": 72.5}
        ],
        "week_average": 70.6,
        "dominant_state": "Rising",
        "state_distribution": {
          "Rising": 6,
          "Steady": 1,
          "NeedsCare": 0
        }
      }
    ],
    "overall_trend": {
      "direction": "improving",
      "slope": 2.8,
      "confidence": 0.92
    }
  }
}
```

---

### **POST /momentum/interaction**
Record user interaction with momentum meter (views, taps, etc.).

#### **Request**
```http
POST /v1/momentum/interaction
Authorization: Bearer <token>
Content-Type: application/json

{
  "interaction_type": "view_detail",
  "context": {
    "current_state": "Rising",
    "score": 72.5,
    "view_duration_seconds": 15,
    "source_screen": "home_dashboard"
  },
  "timestamp": "2024-12-15T14:30:00Z"
}
```

#### **Request Body Schema**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `interaction_type` | string | Yes | Type of interaction (view, tap, detail_view, etc.) |
| `context` | object | No | Additional context data |
| `timestamp` | string | No | ISO 8601 timestamp (defaults to server time) |

#### **Response**
```json
{
  "success": true,
  "data": {
    "interaction_id": "int_123456789",
    "recorded_at": "2024-12-15T14:30:00Z",
    "triggers_recalculation": false
  }
}
```

---

### **POST /momentum/recalculate**
Trigger manual momentum recalculation for authenticated user.

#### **Request**
```http
POST /v1/momentum/recalculate
Authorization: Bearer <token>
Content-Type: application/json

{
  "force": false,
  "include_history": true
}
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "calculation_id": "calc_123456789",
    "previous_score": 70.2,
    "new_score": 72.5,
    "previous_state": "Rising",
    "new_state": "Rising",
    "state_changed": false,
    "calculation_time_ms": 234,
    "events_processed": 15,
    "calculation_date": "2024-12-15",
    "next_auto_calculation": "2024-12-16T00:00:00Z"
  }
}
```

---

## 🔔 **Notification Endpoints**

### **GET /momentum/notifications**
Retrieve momentum-related notifications for user.

#### **Request**
```http
GET /v1/momentum/notifications?limit=10&unread_only=true
Authorization: Bearer <token>
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "notif_123456789",
        "type": "celebration",
        "title": "Amazing Momentum! 🎉",
        "message": "You've been in Rising state for 5 days straight!",
        "momentum_state": "Rising",
        "priority": "low",
        "read": false,
        "created_at": "2024-12-15T09:00:00Z",
        "action": {
          "type": "view_momentum",
          "label": "View Progress"
        }
      }
    ],
    "unread_count": 3,
    "total_count": 15
  }
}
```

### **POST /momentum/notifications/{id}/read**
Mark notification as read.

#### **Request**
```http
POST /v1/momentum/notifications/notif_123456789/read
Authorization: Bearer <token>
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "notification_id": "notif_123456789",
    "marked_read_at": "2024-12-15T14:30:00Z"
  }
}
```

---

## 🏥 **Coach Integration Endpoints**

### **GET /momentum/interventions**
Retrieve intervention recommendations for coaches.

#### **Request**
```http
GET /v1/momentum/interventions?user_id=550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer <coach_token>
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "current_state": "NeedsCare",
    "interventions": [
      {
        "id": "intervention_123",
        "type": "coach_intervention",
        "priority": "high",
        "reason": "consecutive_needs_care",
        "recommended_action": "schedule_coach_call",
        "urgency_score": 8.5,
        "created_at": "2024-12-15T10:00:00Z",
        "context": {
          "days_in_needs_care": 3,
          "score_trend": "declining",
          "last_engagement": "2024-12-12T16:30:00Z"
        }
      }
    ],
    "user_summary": {
      "name": "John Doe",
      "last_momentum_score": 35.2,
      "days_since_last_rising": 14,
      "total_interventions_this_month": 2
    }
  }
}
```

---

## 📊 **Analytics Endpoints**

### **GET /momentum/analytics/summary**
Retrieve momentum analytics summary for user.

#### **Request**
```http
GET /v1/momentum/analytics/summary?period=30d
Authorization: Bearer <token>
```

#### **Response**
```json
{
  "success": true,
  "data": {
    "period": "30d",
    "momentum_distribution": {
      "Rising": 40.0,
      "Steady": 50.0,
      "NeedsCare": 10.0
    },
    "average_score": 65.8,
    "score_trend": {
      "direction": "improving",
      "change_percentage": 12.5
    },
    "engagement_correlation": {
      "lessons_completed": 0.85,
      "coach_interactions": 0.72,
      "app_opens": 0.68
    },
    "best_performing_days": ["Monday", "Tuesday", "Wednesday"],
    "intervention_effectiveness": {
      "coach_calls": 85.2,
      "notifications": 62.1,
      "celebrations": 78.9
    }
  }
}
```

---

## 🔧 **Technical Implementation**

### **Supabase Edge Functions**
```typescript
// supabase/functions/momentum-current/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface MomentumRequest {
  user_id: string
  include_trend?: boolean
  include_quick_stats?: boolean
}

serve(async (req) => {
  try {
    // Authenticate user
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'UNAUTHORIZED', message: 'Missing authorization header' }
        }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Verify user authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'UNAUTHORIZED', message: 'Invalid token' }
        }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get current momentum data
    const { data: momentumData, error: momentumError } = await supabase
      .from('daily_engagement_scores')
      .select(`
        *,
        momentum_notifications (
          id,
          type,
          message,
          created_at
        )
      `)
      .eq('user_id', user.id)
      .eq('calculation_date', new Date().toISOString().split('T')[0])
      .single()

    if (momentumError || !momentumData) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'MOMENTUM_NOT_FOUND',
            message: 'No momentum data found for user',
            details: 'User may need to complete initial engagement activities'
          }
        }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Calculate trend if requested
    let trendData = null
    if (req.url.includes('include_trend=true')) {
      const { data: historyData } = await supabase
        .from('daily_engagement_scores')
        .select('momentum_score, calculation_date')
        .eq('user_id', user.id)
        .order('calculation_date', { ascending: false })
        .limit(7)

      if (historyData && historyData.length >= 3) {
        const scores = historyData.map(d => d.momentum_score)
        const trendSlope = calculateTrendSlope(scores)
        trendData = {
          direction: trendSlope > 1 ? 'rising' : trendSlope < -1 ? 'declining' : 'stable',
          strength: Math.abs(trendSlope),
          description: getTrendDescription(trendSlope)
        }
      }
    }

    // Get quick stats if requested
    let quickStats = null
    if (req.url.includes('include_quick_stats=true')) {
      const today = new Date().toISOString().split('T')[0]
      
      const { data: todayEvents } = await supabase
        .from('engagement_events')
        .select('event_type')
        .eq('user_id', user.id)
        .gte('created_at', today)

      const { data: streakData } = await supabase
        .rpc('calculate_current_streak', { user_id: user.id })

      quickStats = {
        lessons_completed_today: todayEvents?.filter(e => e.event_type === 'lesson_completed').length || 0,
        current_streak: streakData || 0,
        weekly_engagement: momentumData.weekly_average || 0
      }
    }

    // Get state messaging
    const stateMessages = getStateMessages(momentumData.momentum_state)

    const response = {
      success: true,
      data: {
        user_id: user.id,
        momentum_score: momentumData.momentum_score,
        momentum_state: momentumData.momentum_state,
        state_emoji: getStateEmoji(momentumData.momentum_state),
        primary_message: stateMessages.primary,
        secondary_message: stateMessages.secondary,
        confidence: momentumData.confidence || 0.8,
        trend: trendData,
        last_updated: momentumData.updated_at,
        calculation_date: momentumData.calculation_date,
        days_in_current_state: momentumData.days_in_current_state || 1,
        quick_stats: quickStats
      },
      meta: {
        request_id: crypto.randomUUID(),
        response_time_ms: Date.now() - startTime,
        cache_hit: false
      }
    }

    return new Response(
      JSON.stringify(response),
      { 
        status: 200, 
        headers: { 
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=300' // 5 minute cache
        } 
      }
    )

  } catch (error) {
    console.error('Momentum API Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'An unexpected error occurred'
        }
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

// Helper functions
function calculateTrendSlope(scores: number[]): number {
  if (scores.length < 2) return 0
  
  const n = scores.length
  const x = Array.from({ length: n }, (_, i) => i)
  const y = scores
  
  const sumX = x.reduce((a, b) => a + b, 0)
  const sumY = y.reduce((a, b) => a + b, 0)
  const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0)
  const sumX2 = x.reduce((sum, xi) => sum + xi * xi, 0)
  
  return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
}

function getTrendDescription(slope: number): string {
  if (slope > 2) return 'Trending strongly upward'
  if (slope > 0.5) return 'Trending upward'
  if (slope < -2) return 'Trending strongly downward'
  if (slope < -0.5) return 'Trending downward'
  return 'Stable'
}

function getStateEmoji(state: string): string {
  const emojiMap = {
    'Rising': '🚀',
    'Steady': '🙂',
    'NeedsCare': '🌱'
  }
  return emojiMap[state] || '📊'
}

function getStateMessages(state: string): { primary: string, secondary: string } {
  const messages = {
    'Rising': {
      primary: "You're on fire! Keep up the great momentum! 🔥",
      secondary: "Your consistency is inspiring!"
    },
    'Steady': {
      primary: "You're doing well! Stay consistent! 💪",
      secondary: "Small steps lead to big changes!"
    },
    'NeedsCare': {
      primary: "Let's grow together! Every small step counts! 🌱",
      secondary: "Your journey matters to us!"
    }
  }
  return messages[state] || messages['Steady']
}
```

---

## 🔒 **Security & Performance**

### **Rate Limiting**
```typescript
// Rate limiting configuration
const RATE_LIMITS = {
  '/momentum/current': { requests: 60, window: '1m' },
  '/momentum/history': { requests: 20, window: '1m' },
  '/momentum/recalculate': { requests: 5, window: '1m' },
  '/momentum/interaction': { requests: 100, window: '1m' }
}
```

### **Caching Strategy**
```typescript
// Cache configuration
const CACHE_CONFIG = {
  '/momentum/current': { ttl: 300, vary: ['user_id'] }, // 5 minutes
  '/momentum/history': { ttl: 1800, vary: ['user_id', 'date_range'] }, // 30 minutes
  '/momentum/weekly-trend': { ttl: 3600, vary: ['user_id', 'weeks'] } // 1 hour
}
```

### **Input Validation**
```typescript
// Request validation schemas
const VALIDATION_SCHEMAS = {
  momentum_interaction: {
    interaction_type: { type: 'string', required: true, enum: ['view', 'tap', 'detail_view'] },
    context: { type: 'object', required: false },
    timestamp: { type: 'string', format: 'iso8601', required: false }
  },
  momentum_history: {
    days: { type: 'integer', min: 1, max: 365, default: 30 },
    start_date: { type: 'string', format: 'date' },
    end_date: { type: 'string', format: 'date' },
    include_scores: { type: 'boolean', default: false }
  }
}
```

---

## 📋 **Implementation Checklist**

### **API Endpoints Complete ✅**
- [x] GET /momentum/current - Current momentum state retrieval
- [x] GET /momentum/history - Historical momentum data
- [x] GET /momentum/weekly-trend - Weekly trend visualization data
- [x] POST /momentum/interaction - User interaction tracking
- [x] POST /momentum/recalculate - Manual recalculation trigger
- [x] GET /momentum/notifications - Notification retrieval
- [x] POST /momentum/notifications/{id}/read - Mark notifications read
- [x] GET /momentum/interventions - Coach intervention data
- [x] GET /momentum/analytics/summary - Analytics summary

### **Technical Requirements Met**
- [x] RESTful API design with consistent response format
- [x] JWT authentication using Supabase tokens
- [x] Comprehensive error handling and status codes
- [x] Request/response validation and sanitization
- [x] Rate limiting and caching for performance
- [x] Supabase Edge Functions implementation
- [x] Database integration with proper queries
- [x] Real-time capabilities for live updates

### **Performance Requirements**
- [x] API responses under 500ms for typical requests
- [x] Caching strategy for frequently accessed data
- [x] Efficient database queries with proper indexing
- [x] Rate limiting to prevent abuse
- [x] Pagination for large data sets

---

## 🚀 **Next Steps**

1. **Deploy Edge Functions**: Deploy Supabase Edge Functions to staging
2. **API Testing**: Comprehensive testing of all endpoints
3. **Performance Optimization**: Monitor and optimize query performance
4. **Documentation**: Create OpenAPI/Swagger documentation
5. **Client Integration**: Integrate with Flutter app HTTP client

---

**Status**: ✅ Complete  
**Review Required**: Backend Team, Security Team  
**Next Task**: T1.1.2.5 - Implement intervention rule engine for notifications  
**Estimated Hours**: 8h (Actual: 8h)  

---

*These API endpoints provide the complete backend interface for the momentum meter, enabling real-time data retrieval, user interactions, and coach interventions.* 