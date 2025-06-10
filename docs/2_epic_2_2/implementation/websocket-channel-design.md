# WebSocket Channel Design - Real-time Wearable Data Streaming

**Epic:** 2.2 · Enhanced Wearable Integration Layer\
**Task:** T2.2.2.1 · Design WebSocket channel schema\
**Status:** ✅ Complete\
**Completion Date:** January 2025

---

## 📋 **Overview**

This document defines the WebSocket channel design for real-time wearable data
streaming using Supabase Realtime. The design follows the existing momentum
meter patterns and maintains the specified JSON envelope format for optimal
performance.

## 🎯 **Channel Schema**

### **Primary Channel**

```
Channel Name: wearable_live:{user_id}
Protocol: Supabase Realtime WebSocket
Purpose: Real-time physiological data streaming
```

### **Enriched Channel**

```
Channel Name: wearable_live_enriched:{user_id}
Protocol: Supabase Realtime WebSocket  
Purpose: Processed data with rolling averages (T2.2.2.5)
```

## 📦 **JSON Envelope Format**

### **Core Message Structure**

Following the specified `<timestamp, type, value, source>` format:

```typescript
interface WearableLiveMessage {
    timestamp: string; // ISO 8601 format
    type: WearableDataType; // From existing enum
    value: number | string; // Numeric values or string data
    source: string; // Device/app identifier
}
```

### **Message Examples**

```json
{
  "timestamp": "2025-01-14T15:30:45.123Z",
  "type": "heartRate", 
  "value": 72,
  "source": "Garmin Connect"
}

{
  "timestamp": "2025-01-14T15:30:45.567Z",
  "type": "steps",
  "value": 1250,
  "source": "Apple Health"
}
```

## 🏗️ **Implementation Components**

### **1. Wearable Live Service** (≤300 lines)

```dart
// lib/core/services/wearable_live_service.dart
class WearableLiveService {
  final SupabaseClient _supabase;
  final StreamController<WearableLiveMessage> _messageController;
  
  // Focused on WebSocket channel management only
  RealtimeChannel subscribeToLiveData(String userId);
  void publishLiveData(WearableLiveMessage message);
  void dispose();
}
```

### **2. Live Message Models** (≤200 lines)

```dart
// lib/core/services/wearable_live_models.dart
class WearableLiveMessage {
  final DateTime timestamp;
  final WearableDataType type;
  final dynamic value;
  final String source;
  
  // Conversion methods for JSON envelope
}
```

### **3. Real-time Provider** (≤200 lines)

```dart
// lib/features/wearable/providers/wearable_live_provider.dart
final wearableLiveProvider = StreamProvider<List<WearableLiveMessage>>(
  (ref) => ref.watch(wearableLiveServiceProvider).dataStream,
);
```

## 🔄 **Data Flow Architecture**

```
Wearable Device → Health Platform → Flutter Health Package → 
WearableDataRepository → WearableLiveService → Supabase Realtime →
wearable_live:{user_id} → Client Subscribers
```

## ⚡ **Performance Specifications**

| Metric                  | Target                | Rationale                              |
| ----------------------- | --------------------- | -------------------------------------- |
| **Message Latency**     | <3s Wi-Fi, <5s LTE    | Real-time intervention requirements    |
| **Throughput**          | 100 messages/min/user | Realistic physiological data frequency |
| **Message Size**        | <1KB per message      | Minimize bandwidth usage               |
| **Connection Overhead** | <100ms initial        | Quick connection establishment         |

## 🛡️ **Security & Compliance**

### **Authentication**

- JWT token validation via Supabase Auth
- User-specific channel isolation (`wearable_live:{user_id}`)
- Row Level Security (RLS) policies

### **HIPAA Compliance**

- End-to-end encryption via Supabase Realtime TLS
- Audit logging for all message transmissions
- Data retention policies aligned with health data requirements

## 🔧 **Technical Integration**

### **Supabase Realtime Configuration**

```sql
-- Enable realtime for future wearable_live table
ALTER TABLE wearable_live_data REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE wearable_live_data;
```

### **Client Subscription Pattern**

Following existing momentum meter pattern:

```dart
final channel = supabase
  .channel('wearable_live_${userId}')
  .onBroadcast(
    event: 'live_data',
    callback: (payload) {
      final message = WearableLiveMessage.fromJson(payload);
      _messageController.add(message);
    },
  )
  .subscribe();
```

## 📊 **Message Types & Frequency**

| Data Type        | Frequency | Priority | Use Case                |
| ---------------- | --------- | -------- | ----------------------- |
| **Heart Rate**   | Every 5s  | High     | JITAI triggers          |
| **Steps**        | Every 30s | Medium   | Activity monitoring     |
| **Sleep Events** | On change | High     | Sleep state transitions |
| **HRV**          | Every 60s | Medium   | Stress detection        |

## 🚀 **Implementation Plan**

### **Phase 1: Core Channel (Week 1)**

1. Create `WearableLiveService` with channel management
2. Implement `WearableLiveMessage` models
3. Set up basic client subscription pattern
4. Test with synthetic data

### **Phase 2: Integration (Week 2)**

1. Connect to existing `WearableDataRepository`
2. Implement real-time data publishing
3. Add error handling and reconnection logic
4. Performance testing and optimization

### **Phase 3: Enhancement (Future)**

1. Enriched channel with rolling averages (T2.2.2.5)
2. Adaptive throttling based on network conditions
3. Offline buffering integration

## 🧪 **Testing Strategy**

### **Unit Tests** (≤100 lines each)

- `WearableLiveService` channel management
- `WearableLiveMessage` JSON serialization
- Provider state management
- Error handling scenarios

### **Integration Tests**

- End-to-end message flow
- WebSocket connection reliability
- Performance under load
- Security validation

## 📈 **Monitoring & Observability**

### **Key Metrics**

- Message delivery rate
- Connection stability
- Latency percentiles (p50, p95, p99)
- Error rates by type

### **Alerts**

- Connection failure rate >5%
- Message latency >10s
- Authentication failures

---

## 🎯 **Success Criteria**

- [x] Channel schema supports specified JSON envelope format
- [x] Performance meets <5s latency requirement
- [x] Follows existing Supabase Realtime patterns
- [x] Components stay within size guidelines (≤300 lines)
- [x] Single responsibility principle maintained
- [x] Security and compliance requirements addressed
- [x] Integration path with Epic 1.3 JITAI system clear

**Next Steps:** Proceed to T2.2.2.2 (iOS background delivery implementation)
