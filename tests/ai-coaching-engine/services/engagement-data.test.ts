import { assertEquals, assertExists } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { EngagementDataService } from "../../../functions/ai-coaching-engine/services/engagement-data.ts";

// Mock environment variables for testing
Deno.env.set('SUPABASE_URL', 'https://test-project.supabase.co');
Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key');

Deno.test("EngagementDataService - instantiation", () => {
    const service = new EngagementDataService();
    assertExists(service);
});

Deno.test("EngagementDataService - transformEventFormat", () => {
    const service = new EngagementDataService();

    // Access private method through any cast for testing
    const transformEventFormat = (service as any).transformEventFormat.bind(service);

    const dbEvent = {
        event_type: 'app_open',
        timestamp: '2025-01-06T10:00:00.000Z',
        value: { session_duration: 300, screen: 'dashboard' }
    };

    const result = transformEventFormat(dbEvent);

    assertEquals(result.event_type, 'app_session');
    assertEquals(result.timestamp, '2025-01-06T10:00:00.000Z');
    assertEquals(result.metadata.session_duration, 300);
    assertEquals(result.metadata.screen, 'dashboard');
});

Deno.test("EngagementDataService - mapEventType", () => {
    const service = new EngagementDataService();

    // Access private method through any cast for testing
    const mapEventType = (service as any).mapEventType.bind(service);

    // Test app session mappings
    assertEquals(mapEventType('app_open'), 'app_session');
    assertEquals(mapEventType('mood_log'), 'app_session');
    assertEquals(mapEventType('sleep_log'), 'app_session');
    assertEquals(mapEventType('steps_import'), 'app_session');

    // Test goal completion mappings
    assertEquals(mapEventType('goal_complete'), 'goal_completion');
    assertEquals(mapEventType('goal_completion'), 'goal_completion');

    // Test momentum change mapping
    assertEquals(mapEventType('momentum_change'), 'momentum_change');

    // Test unknown event type defaults to app_session
    assertEquals(mapEventType('unknown_event'), 'app_session');
});

Deno.test("EngagementDataService - isValidEventType", () => {
    const service = new EngagementDataService();

    // Access private method through any cast for testing
    const isValidEventType = (service as any).isValidEventType.bind(service);

    assertEquals(isValidEventType('app_session'), true);
    assertEquals(isValidEventType('goal_completion'), true);
    assertEquals(isValidEventType('momentum_change'), true);
    assertEquals(isValidEventType('invalid_type'), false);
});

Deno.test("EngagementDataService - getFallbackEvents", () => {
    const service = new EngagementDataService();

    // Access private method through any cast for testing
    const getFallbackEvents = (service as any).getFallbackEvents.bind(service);

    const fallbackEvents = getFallbackEvents();

    assertEquals(fallbackEvents.length, 1);
    assertEquals(fallbackEvents[0].event_type, 'app_session');
    assertEquals(fallbackEvents[0].metadata.source, 'fallback');
    assertEquals(fallbackEvents[0].metadata.reason, 'no_real_data_available');
    assertExists(fallbackEvents[0].timestamp);
});

// Integration test with mock Supabase client would require more complex setup
// For now, focusing on unit tests for transformation logic
Deno.test("EngagementDataService - getUserEngagementEvents fallback on error", async () => {
    // This test would require mocking the Supabase client
    // For now, we'll test that the method exists and returns fallback data
    const service = new EngagementDataService();

    // With invalid credentials, this should return fallback events
    const events = await service.getUserEngagementEvents('test-user-id');

    // Should return fallback events when database is unavailable
    assertEquals(events.length, 1);
    assertEquals(events[0].event_type, 'app_session');
    assertEquals(events[0].metadata.source, 'fallback');
}); 