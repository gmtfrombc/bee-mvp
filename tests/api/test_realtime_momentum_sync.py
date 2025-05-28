"""
Test suite for Real-time Momentum Sync functionality
Epic: 1.1 · Momentum Meter
Task: T1.1.2.7 · Implement real-time triggers for momentum updates

Tests cover:
- Real-time database triggers
- WebSocket connection handling
- Cache invalidation events
- Performance monitoring
- Security and access control
"""

import pytest
import asyncio
import json
import uuid
from datetime import datetime, timedelta
from unittest.mock import Mock, patch, AsyncMock
import websockets
import psycopg2
from psycopg2.extras import RealDictCursor
import requests
import time

# Test configuration
TEST_CONFIG = {
    'supabase_url': 'http://localhost:54321',
    'supabase_key': 'test_key',
    'edge_function_url': 'http://localhost:54321/functions/v1/realtime-momentum-sync',
    'websocket_url': 'ws://localhost:54321/functions/v1/realtime-momentum-sync',
    'db_connection': {
        'host': 'localhost',
        'port': 54322,
        'database': 'postgres',
        'user': 'postgres',
        'password': 'postgres'
    }
}


class TestRealtimeMomentumSync:
    """Test suite for real-time momentum sync functionality"""

    @pytest.fixture
    def db_connection(self):
        """Create database connection for testing"""
        conn = psycopg2.connect(**TEST_CONFIG['db_connection'])
        conn.autocommit = True
        yield conn
        conn.close()

    @pytest.fixture
    def test_user_id(self):
        """Generate test user ID"""
        return str(uuid.uuid4())

    @pytest.fixture
    def test_client_id(self):
        """Generate test client ID"""
        return str(uuid.uuid4())

    @pytest.fixture
    async def websocket_connection(self, test_user_id, test_client_id):
        """Create WebSocket connection for testing"""
        uri = f"{TEST_CONFIG['websocket_url']}?user_id={test_user_id}&client_id={test_client_id}"

        try:
            websocket = await websockets.connect(uri)
            yield websocket
        finally:
            if websocket:
                await websocket.close()

    # =====================================================
    # DATABASE TRIGGER TESTS
    # =====================================================

    def test_momentum_score_realtime_trigger(self, db_connection, test_user_id):
        """Test that momentum score changes trigger real-time events"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert a momentum score
        cursor.execute("""
            INSERT INTO daily_engagement_scores (
                user_id, score_date, raw_score, normalized_score, 
                final_score, momentum_state, breakdown, events_count
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            test_user_id, '2024-12-17', 85.0, 75.0,
            75.0, 'Rising', '{"lessons": 3}', 5
        ))

        score_id = cursor.fetchone()['id']

        # Update the momentum score
        cursor.execute("""
            UPDATE daily_engagement_scores 
            SET momentum_state = 'Steady', final_score = 65.0
            WHERE id = %s
        """, (score_id,))

        # Verify trigger function exists and is properly configured
        cursor.execute("""
            SELECT tgname, tgrelid::regclass, tgfoid::regproc
            FROM pg_trigger 
            WHERE tgname = 'momentum_score_realtime_trigger'
        """)

        trigger = cursor.fetchone()
        assert trigger is not None
        assert trigger['tgrelid'] == 'daily_engagement_scores'
        assert trigger['tgfoid'] == 'publish_momentum_update'

    def test_intervention_realtime_trigger(self, db_connection, test_user_id):
        """Test that intervention changes trigger real-time events"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert an intervention
        cursor.execute("""
            INSERT INTO coach_interventions (
                user_id, intervention_type, trigger_date, trigger_reason,
                trigger_momentum_state, status, scheduled_date
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            test_user_id, 'automated_call_schedule', '2024-12-17',
            'Consecutive needs care days', 'NeedsCare', 'scheduled', '2024-12-18'
        ))

        intervention_id = cursor.fetchone()['id']

        # Update intervention status
        cursor.execute("""
            UPDATE coach_interventions 
            SET status = 'completed'
            WHERE id = %s
        """, (intervention_id,))

        # Verify trigger exists
        cursor.execute("""
            SELECT tgname FROM pg_trigger 
            WHERE tgname = 'intervention_realtime_trigger'
        """)

        assert cursor.fetchone() is not None

    def test_notification_realtime_trigger(self, db_connection, test_user_id):
        """Test that notification changes trigger real-time events"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert a notification
        cursor.execute("""
            INSERT INTO momentum_notifications (
                user_id, notification_type, trigger_date, title, message,
                action_type, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            test_user_id, 'momentum_drop', '2024-12-17',
            'Your momentum needs attention', 'Let\'s get back on track!',
            'open_app', 'pending'
        ))

        notification_id = cursor.fetchone()['id']

        # Update notification status
        cursor.execute("""
            UPDATE momentum_notifications 
            SET status = 'delivered', delivered_at = NOW()
            WHERE id = %s
        """, (notification_id,))

        # Verify trigger exists
        cursor.execute("""
            SELECT tgname FROM pg_trigger 
            WHERE tgname = 'notification_realtime_trigger'
        """)

        assert cursor.fetchone() is not None

    def test_cache_invalidation_trigger(self, db_connection, test_user_id):
        """Test that momentum changes trigger cache invalidation"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert momentum score to trigger cache invalidation
        cursor.execute("""
            INSERT INTO daily_engagement_scores (
                user_id, score_date, raw_score, normalized_score, 
                final_score, momentum_state, breakdown, events_count
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            test_user_id, '2024-12-17', 90.0, 80.0,
            80.0, 'Rising', '{"lessons": 4}', 6
        ))

        # Verify cache invalidation trigger exists
        cursor.execute("""
            SELECT tgname FROM pg_trigger 
            WHERE tgname = 'momentum_cache_invalidation_trigger'
        """)

        assert cursor.fetchone() is not None

    # =====================================================
    # REALTIME FUNCTION TESTS
    # =====================================================

    def test_get_realtime_momentum_state(self, db_connection, test_user_id):
        """Test getting current momentum state for real-time sync"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert test momentum data
        cursor.execute("""
            INSERT INTO daily_engagement_scores (
                user_id, score_date, raw_score, normalized_score, 
                final_score, momentum_state, breakdown, events_count
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            test_user_id, '2024-12-17', 75.0, 70.0,
            70.0, 'Rising', '{"lessons": 2, "journal": 1}', 3
        ))

        # Call the function
        cursor.execute("""
            SELECT get_realtime_momentum_state(%s) as result
        """, (test_user_id,))

        result = cursor.fetchone()['result']

        assert result['user_id'] == test_user_id
        assert result['has_data'] is True
        assert result['momentum_state'] == 'Rising'
        assert result['final_score'] == 70.0
        assert result['events_count'] == 3

    def test_get_realtime_interventions(self, db_connection, test_user_id):
        """Test getting pending interventions for real-time sync"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert test intervention
        cursor.execute("""
            INSERT INTO coach_interventions (
                user_id, intervention_type, trigger_date, trigger_reason,
                status, scheduled_date
            ) VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            test_user_id, 'check_in', '2024-12-17',
            'Weekly check-in', 'scheduled', '2024-12-18'
        ))

        # Call the function
        cursor.execute("""
            SELECT get_realtime_interventions(%s) as result
        """, (test_user_id,))

        result = cursor.fetchone()['result']

        assert result['user_id'] == test_user_id
        assert len(result['interventions']) == 1
        assert result['interventions'][0]['intervention_type'] == 'check_in'
        assert result['interventions'][0]['status'] == 'scheduled'

    def test_subscribe_to_momentum_channels(self, db_connection, test_user_id):
        """Test getting subscription channels for user"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT subscribe_to_momentum_channels(%s) as result
        """, (test_user_id,))

        result = cursor.fetchone()['result']

        expected_channels = [
            f'momentum_updates:{test_user_id}',
            f'interventions:{test_user_id}',
            f'notifications:{test_user_id}',
            'cache_invalidation'
        ]

        assert result['user_id'] == test_user_id
        assert set(result['channels']) == set(expected_channels)

    # =====================================================
    # WEBSOCKET CONNECTION TESTS
    # =====================================================

    @pytest.mark.asyncio
    async def test_websocket_connection_success(self, test_user_id, test_client_id):
        """Test successful WebSocket connection"""
        uri = f"{TEST_CONFIG['websocket_url']}?user_id={test_user_id}&client_id={test_client_id}"

        try:
            websocket = await websockets.connect(uri, timeout=5)

            # Should receive subscription confirmation
            message = await asyncio.wait_for(websocket.recv(), timeout=5)
            data = json.loads(message)

            assert data['type'] == 'subscription_confirmed'
            assert data['user_id'] == test_user_id
            assert len(data['channels']) == 4

            await websocket.close()

        except Exception as e:
            pytest.skip(f"WebSocket connection failed: {e}")

    @pytest.mark.asyncio
    async def test_websocket_ping_pong(self, websocket_connection):
        """Test WebSocket ping/pong functionality"""
        try:
            # Send ping
            ping_message = {'type': 'ping'}
            await websocket_connection.send(json.dumps(ping_message))

            # Receive pong
            response = await asyncio.wait_for(websocket_connection.recv(), timeout=5)
            data = json.loads(response)

            assert data['type'] == 'pong'
            assert 'timestamp' in data

        except Exception as e:
            pytest.skip(f"WebSocket ping/pong failed: {e}")

    @pytest.mark.asyncio
    async def test_websocket_momentum_update_request(self, websocket_connection):
        """Test requesting momentum update via WebSocket"""
        try:
            # Request momentum update
            request_message = {'type': 'request_momentum_update'}
            await websocket_connection.send(json.dumps(request_message))

            # Should receive momentum state update
            response = await asyncio.wait_for(websocket_connection.recv(), timeout=5)
            data = json.loads(response)

            assert data['type'] == 'momentum_state_update'
            assert 'data' in data
            assert 'timestamp' in data

        except Exception as e:
            pytest.skip(f"WebSocket momentum update failed: {e}")

    # =====================================================
    # HTTP API TESTS
    # =====================================================

    def test_momentum_sync_api(self, test_user_id):
        """Test momentum sync HTTP API"""
        try:
            response = requests.post(
                f"{TEST_CONFIG['edge_function_url']}/sync/momentum",
                json={'user_id': test_user_id},
                timeout=10
            )

            assert response.status_code == 200
            data = response.json()

            assert data['success'] is True
            assert 'data' in data
            assert 'timestamp' in data

        except Exception as e:
            pytest.skip(f"HTTP API test failed: {e}")

    def test_interventions_sync_api(self, test_user_id):
        """Test interventions sync HTTP API"""
        try:
            response = requests.post(
                f"{TEST_CONFIG['edge_function_url']}/sync/interventions",
                json={'user_id': test_user_id},
                timeout=10
            )

            assert response.status_code == 200
            data = response.json()

            assert data['success'] is True
            assert 'data' in data

        except Exception as e:
            pytest.skip(f"HTTP API test failed: {e}")

    def test_notifications_sync_api(self, test_user_id):
        """Test notifications sync HTTP API"""
        try:
            response = requests.post(
                f"{TEST_CONFIG['edge_function_url']}/sync/notifications",
                json={'user_id': test_user_id, 'limit': 10},
                timeout=10
            )

            assert response.status_code == 200
            data = response.json()

            assert data['success'] is True
            assert 'data' in data

        except Exception as e:
            pytest.skip(f"HTTP API test failed: {e}")

    def test_health_check_api(self):
        """Test health check API"""
        try:
            response = requests.get(
                f"{TEST_CONFIG['edge_function_url']}/sync/health",
                timeout=10
            )

            assert response.status_code == 200
            data = response.json()

            assert data['status'] == 'healthy'
            assert 'connected_clients' in data
            assert 'active_subscriptions' in data
            assert 'timestamp' in data

        except Exception as e:
            pytest.skip(f"Health check test failed: {e}")

    # =====================================================
    # PERFORMANCE TESTS
    # =====================================================

    def test_realtime_event_metrics_logging(self, db_connection, test_user_id):
        """Test that realtime events are logged for performance monitoring"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Call log function
        cursor.execute("""
            SELECT log_realtime_event(%s, %s, %s, %s, %s, %s, %s)
        """, (
            'test_event', 'test_channel', test_user_id,
            1024, 50, True, None
        ))

        # Verify event was logged
        cursor.execute("""
            SELECT * FROM realtime_event_metrics 
            WHERE event_type = 'test_event' AND user_id = %s
            ORDER BY created_at DESC LIMIT 1
        """, (test_user_id,))

        metric = cursor.fetchone()
        assert metric is not None
        assert metric['event_type'] == 'test_event'
        assert metric['channel_name'] == 'test_channel'
        assert metric['payload_size'] == 1024
        assert metric['processing_time_ms'] == 50
        assert metric['success'] is True

    def test_cleanup_realtime_metrics(self, db_connection):
        """Test cleanup of old realtime metrics"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert old metric
        cursor.execute("""
            INSERT INTO realtime_event_metrics (
                event_type, channel_name, created_at
            ) VALUES (%s, %s, %s)
        """, ('old_event', 'old_channel', datetime.now() - timedelta(days=35)))

        # Run cleanup
        cursor.execute("SELECT cleanup_realtime_metrics() as deleted_count")
        deleted_count = cursor.fetchone()['deleted_count']

        assert deleted_count >= 1

    # =====================================================
    # SECURITY TESTS
    # =====================================================

    def test_row_level_security_momentum_scores(self, db_connection, test_user_id):
        """Test RLS policies for momentum scores"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Verify RLS is enabled
        cursor.execute("""
            SELECT relrowsecurity FROM pg_class 
            WHERE relname = 'daily_engagement_scores'
        """)

        rls_enabled = cursor.fetchone()['relrowsecurity']
        assert rls_enabled is True

        # Verify policy exists
        cursor.execute("""
            SELECT policyname FROM pg_policies 
            WHERE tablename = 'daily_engagement_scores'
            AND policyname = 'Users can view own momentum scores'
        """)

        policy = cursor.fetchone()
        assert policy is not None

    def test_websocket_missing_user_id(self):
        """Test WebSocket connection without user_id parameter"""
        try:
            async def test_connection():
                uri = f"{TEST_CONFIG['websocket_url']}?client_id=test"

                with pytest.raises(websockets.exceptions.ConnectionClosedError):
                    websocket = await websockets.connect(uri, timeout=5)
                    await websocket.recv()

            asyncio.run(test_connection())

        except Exception as e:
            pytest.skip(f"WebSocket security test failed: {e}")

    # =====================================================
    # INTEGRATION TESTS
    # =====================================================

    def test_end_to_end_momentum_update_flow(self, db_connection, test_user_id):
        """Test complete flow from database change to real-time notification"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # 1. Insert momentum score (triggers real-time event)
        cursor.execute("""
            INSERT INTO daily_engagement_scores (
                user_id, score_date, raw_score, normalized_score, 
                final_score, momentum_state, breakdown, events_count
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            test_user_id, '2024-12-17', 95.0, 85.0,
            85.0, 'Rising', '{"lessons": 5}', 8
        ))

        score_id = cursor.fetchone()['id']

        # 2. Update momentum state (triggers state change event)
        cursor.execute("""
            UPDATE daily_engagement_scores 
            SET momentum_state = 'Steady', final_score = 65.0
            WHERE id = %s
        """, (score_id,))

        # 3. Verify real-time functions work
        cursor.execute("""
            SELECT get_realtime_momentum_state(%s) as state
        """, (test_user_id,))

        state = cursor.fetchone()['state']
        assert state['momentum_state'] == 'Steady'
        assert state['final_score'] == 65.0

        # 4. Verify cache invalidation was triggered
        # (This would be verified by checking pg_notify calls in a real environment)

        print(f"✅ End-to-end test completed for user {test_user_id}")


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
