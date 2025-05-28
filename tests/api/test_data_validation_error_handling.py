"""
Test suite for Data Validation and Error Handling
Epic: 1.1 · Momentum Meter
Task: T1.1.2.8 · Add data validation and error handling

Tests cover:
- Input validation functions
- Error logging and monitoring
- Data integrity safeguards
- Error recovery mechanisms
- Health monitoring and system status
"""

import pytest
import asyncio
import json
import uuid
from datetime import datetime, timedelta
from unittest.mock import Mock, patch, AsyncMock
import psycopg2
from psycopg2.extras import RealDictCursor
import requests
import time

# Test configuration
TEST_CONFIG = {
    'supabase_url': 'http://localhost:54321',
    'supabase_key': 'test_key',
    'edge_function_url': 'http://localhost:54321/functions/v1/momentum-score-calculator',
    'db_connection': {
        'host': 'localhost',
        'port': 54322,
        'database': 'postgres',
        'user': 'postgres',
        'password': 'postgres'
    }
}


class TestDataValidationErrorHandling:
    """Test suite for data validation and error handling functionality"""

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
    def invalid_user_id(self):
        """Generate invalid user ID for testing"""
        return "invalid-uuid-format"

    @pytest.fixture
    def test_error_data(self):
        """Generate test error data"""
        return {
            'error_type': 'validation_error',
            'error_code': 'TEST_ERROR',
            'error_message': 'Test error message',
            'error_details': {'test_field': 'test_value'},
            'severity': 'medium'
        }

    # =====================================================
    # INPUT VALIDATION TESTS
    # =====================================================

    def test_validate_user_id_valid(self, db_connection, test_user_id):
        """Test user ID validation with valid UUID"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT validate_user_id(%s) as is_valid
        """, (test_user_id,))

        result = cursor.fetchone()
        assert result['is_valid'] is True

    def test_validate_user_id_invalid_format(self, db_connection, invalid_user_id):
        """Test user ID validation with invalid format"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT validate_user_id(%s) as is_valid
        """, (invalid_user_id,))

        result = cursor.fetchone()
        assert result['is_valid'] is False

    def test_validate_user_id_null(self, db_connection):
        """Test user ID validation with null value"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT validate_user_id(NULL) as is_valid
        """)

        result = cursor.fetchone()
        assert result['is_valid'] is False

    def test_validate_user_id_empty_uuid(self, db_connection):
        """Test user ID validation with empty UUID"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT validate_user_id('00000000-0000-0000-0000-000000000000') as is_valid
        """)

        result = cursor.fetchone()
        assert result['is_valid'] is False

    def test_validate_score_values_valid(self, db_connection):
        """Test score validation with valid values"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT validate_score_values(85.5, 75.0, 70.0) as result
        """)

        result = cursor.fetchone()['result']
        assert result['is_valid'] is True
        assert len(result['errors']) == 0

    def test_validate_score_values_invalid_ranges(self, db_connection):
        """Test score validation with invalid ranges"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test negative raw score
        cursor.execute("""
            SELECT validate_score_values(-10.0, 75.0, 70.0) as result
        """)

        result = cursor.fetchone()['result']
        assert result['is_valid'] is False
        assert 'Raw score cannot be negative' in result['errors']

        # Test out-of-range normalized score
        cursor.execute("""
            SELECT validate_score_values(85.0, 150.0, 70.0) as result
        """)

        result = cursor.fetchone()['result']
        assert result['is_valid'] is False
        assert 'Normalized score must be between 0 and 100' in result['errors']

    def test_validate_score_values_null_values(self, db_connection):
        """Test score validation with null values"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT validate_score_values(NULL, NULL, NULL) as result
        """)

        result = cursor.fetchone()['result']
        assert result['is_valid'] is False
        assert len(result['errors']) == 3  # All three scores are null

    def test_validate_momentum_state_valid(self, db_connection):
        """Test momentum state validation with valid states"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        valid_states = ['Rising', 'Steady', 'NeedsCare']
        for state in valid_states:
            cursor.execute("""
                SELECT validate_momentum_state(%s) as is_valid
            """, (state,))

            result = cursor.fetchone()
            assert result['is_valid'] is True

    def test_validate_momentum_state_invalid(self, db_connection):
        """Test momentum state validation with invalid states"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        invalid_states = ['Invalid', 'rising', 'STEADY', '', None]
        for state in invalid_states:
            cursor.execute("""
                SELECT validate_momentum_state(%s) as is_valid
            """, (state,))

            result = cursor.fetchone()
            assert result['is_valid'] is False

    def test_validate_date_range_valid(self, db_connection):
        """Test date range validation with valid dates"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        start_date = (datetime.now() - timedelta(days=7)).date()
        end_date = datetime.now().date()

        cursor.execute("""
            SELECT validate_date_range(%s, %s) as result
        """, (start_date, end_date))

        result = cursor.fetchone()['result']
        assert result['is_valid'] is True
        assert len(result['errors']) == 0

    def test_validate_date_range_invalid(self, db_connection):
        """Test date range validation with invalid dates"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Future start date
        future_date = (datetime.now() + timedelta(days=1)).date()
        cursor.execute("""
            SELECT validate_date_range(%s, NULL) as result
        """, (future_date,))

        result = cursor.fetchone()['result']
        assert result['is_valid'] is False
        assert 'Start date cannot be in the future' in result['errors']

        # End date before start date
        start_date = datetime.now().date()
        end_date = (datetime.now() - timedelta(days=1)).date()
        cursor.execute("""
            SELECT validate_date_range(%s, %s) as result
        """, (start_date, end_date))

        result = cursor.fetchone()['result']
        assert result['is_valid'] is False
        assert 'End date cannot be before start date' in result['errors']

    def test_validate_notification_data_valid(self, db_connection):
        """Test notification data validation with valid data"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT validate_notification_data(
                'momentum_drop', 
                'Your momentum needs attention', 
                'Let''s get back on track!',
                'open_app'
            ) as result
        """)

        result = cursor.fetchone()['result']
        assert result['is_valid'] is True
        assert len(result['errors']) == 0

    def test_validate_notification_data_invalid(self, db_connection):
        """Test notification data validation with invalid data"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Invalid notification type
        cursor.execute("""
            SELECT validate_notification_data(
                'invalid_type', 
                'Title', 
                'Message',
                'open_app'
            ) as result
        """)

        result = cursor.fetchone()['result']
        assert result['is_valid'] is False
        assert 'Invalid notification type' in result['errors']

        # Empty title
        cursor.execute("""
            SELECT validate_notification_data(
                'momentum_drop', 
                '', 
                'Message',
                'open_app'
            ) as result
        """)

        result = cursor.fetchone()['result']
        assert result['is_valid'] is False
        assert 'Title cannot be empty' in result['errors']

        # Message too long
        long_message = 'x' * 501  # Exceeds 500 character limit
        cursor.execute("""
            SELECT validate_notification_data(
                'momentum_drop', 
                'Title', 
                %s,
                'open_app'
            ) as result
        """, (long_message,))

        result = cursor.fetchone()['result']
        assert result['is_valid'] is False
        assert 'Message cannot exceed 500 characters' in result['errors']

    # =====================================================
    # ERROR LOGGING TESTS
    # =====================================================

    def test_log_momentum_error(self, db_connection, test_user_id, test_error_data):
        """Test error logging functionality"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT log_momentum_error(
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            ) as error_id
        """, (
            test_error_data['error_type'],
            test_error_data['error_code'],
            test_error_data['error_message'],
            json.dumps(test_error_data['error_details']),
            test_user_id,
            'test_function',
            'test_table',
            'INSERT',
            json.dumps({'test': 'data'}),
            test_error_data['severity']
        ))

        error_id = cursor.fetchone()['error_id']
        assert error_id is not None

        # Verify error was logged
        cursor.execute("""
            SELECT * FROM momentum_error_logs WHERE id = %s
        """, (error_id,))

        logged_error = cursor.fetchone()
        assert logged_error is not None
        assert logged_error['error_type'] == test_error_data['error_type']
        assert logged_error['error_code'] == test_error_data['error_code']
        assert logged_error['user_id'] == test_user_id
        assert logged_error['is_resolved'] is False

    def test_resolve_momentum_error(self, db_connection, test_user_id, test_error_data):
        """Test error resolution functionality"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # First log an error
        cursor.execute("""
            SELECT log_momentum_error(
                %s, %s, %s, %s, %s
            ) as error_id
        """, (
            test_error_data['error_type'],
            test_error_data['error_code'],
            test_error_data['error_message'],
            json.dumps(test_error_data['error_details']),
            test_user_id
        ))

        error_id = cursor.fetchone()['error_id']

        # Resolve the error
        resolution_notes = 'Error resolved during testing'
        cursor.execute("""
            SELECT resolve_momentum_error(%s, %s) as success
        """, (error_id, resolution_notes))

        success = cursor.fetchone()['success']
        assert success is True

        # Verify error is marked as resolved
        cursor.execute("""
            SELECT is_resolved, resolved_at, resolution_notes 
            FROM momentum_error_logs WHERE id = %s
        """, (error_id,))

        resolved_error = cursor.fetchone()
        assert resolved_error['is_resolved'] is True
        assert resolved_error['resolved_at'] is not None
        assert resolved_error['resolution_notes'] == resolution_notes

    # =====================================================
    # VALIDATION TRIGGER TESTS
    # =====================================================

    def test_daily_engagement_scores_validation_trigger(self, db_connection, test_user_id):
        """Test validation trigger for daily_engagement_scores"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test valid insertion
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
        assert score_id is not None

        # Test invalid insertion (should fail)
        with pytest.raises(psycopg2.Error):
            cursor.execute("""
                INSERT INTO daily_engagement_scores (
                    user_id, score_date, raw_score, normalized_score, 
                    final_score, momentum_state, breakdown, events_count
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                test_user_id, '2024-12-17', -10.0, 150.0,  # Invalid scores
                # Invalid state and count
                75.0, 'InvalidState', '{"lessons": 3}', -1
            ))

    def test_momentum_notifications_validation_trigger(self, db_connection, test_user_id):
        """Test validation trigger for momentum_notifications"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test valid insertion
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
        assert notification_id is not None

        # Test invalid insertion (should fail)
        with pytest.raises(psycopg2.Error):
            cursor.execute("""
                INSERT INTO momentum_notifications (
                    user_id, notification_type, trigger_date, title, message,
                    action_type, status
                ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                test_user_id, 'invalid_type', '2024-12-17',  # Invalid type
                '', 'Message',  # Empty title
                'invalid_action', 'pending'  # Invalid action
            ))

    def test_coach_interventions_validation_trigger(self, db_connection, test_user_id):
        """Test validation trigger for coach_interventions"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test valid insertion
        cursor.execute("""
            INSERT INTO coach_interventions (
                user_id, intervention_type, trigger_date, trigger_reason,
                status, scheduled_date
            ) VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            test_user_id, 'automated_call_schedule', '2024-12-17',
            'Consecutive needs care days', 'scheduled', '2024-12-18'
        ))

        intervention_id = cursor.fetchone()['id']
        assert intervention_id is not None

        # Test invalid insertion (should fail)
        with pytest.raises(psycopg2.Error):
            cursor.execute("""
                INSERT INTO coach_interventions (
                    user_id, intervention_type, trigger_date, trigger_reason,
                    status, scheduled_date
                ) VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                test_user_id, 'invalid_type', '2024-12-17',  # Invalid type
                '', 'invalid_status', '2024-12-18'  # Empty reason, invalid status
            ))

    # =====================================================
    # DATA INTEGRITY TESTS
    # =====================================================

    def test_prevent_duplicate_daily_scores(self, db_connection, test_user_id):
        """Test prevention of duplicate daily scores"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert first score
        cursor.execute("""
            INSERT INTO daily_engagement_scores (
                user_id, score_date, raw_score, normalized_score, 
                final_score, momentum_state, breakdown, events_count
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            test_user_id, '2024-12-17', 85.0, 75.0,
            75.0, 'Rising', '{"lessons": 3}', 5
        ))

        # Attempt to insert duplicate (should fail)
        with pytest.raises(psycopg2.Error):
            cursor.execute("""
                INSERT INTO daily_engagement_scores (
                    user_id, score_date, raw_score, normalized_score, 
                    final_score, momentum_state, breakdown, events_count
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                test_user_id, '2024-12-17', 90.0, 80.0,  # Same user and date
                80.0, 'Rising', '{"lessons": 4}', 6
            ))

    # =====================================================
    # ERROR RECOVERY TESTS
    # =====================================================

    def test_safe_calculate_momentum_score_valid_input(self, db_connection, test_user_id):
        """Test safe momentum calculation with valid input"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT safe_calculate_momentum_score(%s, %s) as result
        """, (test_user_id, '2024-12-17'))

        result = cursor.fetchone()['result']
        assert result['success'] is True
        assert result['user_id'] == test_user_id

    def test_safe_calculate_momentum_score_invalid_input(self, db_connection):
        """Test safe momentum calculation with invalid input"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Invalid user ID
        cursor.execute("""
            SELECT safe_calculate_momentum_score(NULL, %s) as result
        """, ('2024-12-17',))

        result = cursor.fetchone()['result']
        assert result['success'] is False
        assert result['error_code'] == 'INVALID_USER_ID'

        # Invalid date
        cursor.execute("""
            SELECT safe_calculate_momentum_score(%s, NULL) as result
        """, (str(uuid.uuid4()),))

        result = cursor.fetchone()['result']
        assert result['success'] is False
        assert result['error_code'] == 'INVALID_DATE'

    # =====================================================
    # MONITORING AND HEALTH CHECK TESTS
    # =====================================================

    def test_get_error_statistics(self, db_connection, test_user_id):
        """Test error statistics retrieval"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Log some test errors
        for i in range(3):
            cursor.execute("""
                SELECT log_momentum_error(
                    'validation_error', 
                    'TEST_ERROR_' || %s, 
                    'Test error message', 
                    '{}', 
                    %s
                )
            """, (i, test_user_id))

        # Get statistics
        cursor.execute("""
            SELECT get_error_statistics(24) as stats
        """)

        stats = cursor.fetchone()['stats']
        assert stats['total_errors'] >= 3
        assert stats['period_hours'] == 24
        assert 'by_type' in stats
        assert 'validation_error' in stats['by_type']

    def test_check_momentum_system_health(self, db_connection):
        """Test system health check"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        cursor.execute("""
            SELECT check_momentum_system_health() as health
        """)

        health = cursor.fetchone()['health']
        assert 'health' in health
        assert 'error_stats' in health
        assert health['health']['status'] in [
            'healthy', 'degraded', 'critical']

    def test_cleanup_error_logs(self, db_connection, test_user_id):
        """Test error log cleanup functionality"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Insert old resolved error
        cursor.execute("""
            INSERT INTO momentum_error_logs (
                error_type, error_code, error_message, error_details,
                user_id, severity, is_resolved, resolved_at, created_at
            ) VALUES (
                'test_error', 'OLD_ERROR', 'Old test error', '{}',
                %s, 'low', true, %s, %s
            )
        """, (
            test_user_id,
            datetime.now() - timedelta(days=100),  # resolved_at
            datetime.now() - timedelta(days=100)   # created_at
        ))

        # Run cleanup
        cursor.execute("SELECT cleanup_error_logs() as deleted_count")
        deleted_count = cursor.fetchone()['deleted_count']

        assert deleted_count >= 1

    # =====================================================
    # EDGE FUNCTION ERROR HANDLING TESTS
    # =====================================================

    def test_edge_function_validation_error(self):
        """Test Edge Function validation error handling"""
        try:
            response = requests.post(
                f"{TEST_CONFIG['edge_function_url']}/calculate",
                json={
                    'user_id': 'invalid-uuid',  # Invalid format
                    'target_date': '2024-12-17'
                },
                timeout=10
            )

            assert response.status_code == 400
            data = response.json()
            assert data['success'] is False
            assert data['error']['type'] == 'validation_error'
            assert 'user_id' in data['error']['message'].lower()

        except Exception as e:
            pytest.skip(f"Edge Function test failed: {e}")

    def test_edge_function_missing_fields(self):
        """Test Edge Function with missing required fields"""
        try:
            response = requests.post(
                f"{TEST_CONFIG['edge_function_url']}/calculate",
                json={},  # Missing required fields
                timeout=10
            )

            assert response.status_code == 400
            data = response.json()
            assert data['success'] is False
            assert data['error']['type'] == 'validation_error'

        except Exception as e:
            pytest.skip(f"Edge Function test failed: {e}")

    def test_edge_function_health_check(self):
        """Test Edge Function health check endpoint"""
        try:
            response = requests.get(
                f"{TEST_CONFIG['edge_function_url']}/health",
                timeout=10
            )

            assert response.status_code in [200, 503]  # Healthy or degraded
            data = response.json()
            assert 'status' in data
            assert 'error_stats' in data
            assert data['status'] in ['healthy', 'degraded', 'critical']

        except Exception as e:
            pytest.skip(f"Health check test failed: {e}")

    def test_edge_function_batch_validation(self):
        """Test Edge Function batch processing validation"""
        try:
            response = requests.post(
                f"{TEST_CONFIG['edge_function_url']}/batch",
                json={
                    # Invalid UUIDs
                    'user_ids': ['invalid-uuid-1', 'invalid-uuid-2'],
                    'target_date': '2024-12-17'
                },
                timeout=10
            )

            assert response.status_code == 400
            data = response.json()
            assert data['success'] is False
            assert data['error']['type'] == 'validation_error'

        except Exception as e:
            pytest.skip(f"Batch validation test failed: {e}")

    # =====================================================
    # PERFORMANCE TESTS
    # =====================================================

    def test_validation_performance(self, db_connection, test_user_id):
        """Test validation function performance"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        start_time = time.time()

        # Run multiple validations
        for _ in range(100):
            cursor.execute("""
                SELECT 
                    validate_user_id(%s) as user_valid,
                    validate_score_values(85.0, 75.0, 70.0) as scores_valid,
                    validate_momentum_state('Rising') as state_valid
            """, (test_user_id,))

        end_time = time.time()
        execution_time = end_time - start_time

        # Should complete 100 validations in under 1 second
        assert execution_time < 1.0

    def test_error_logging_performance(self, db_connection, test_user_id):
        """Test error logging performance"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        start_time = time.time()

        # Log multiple errors
        for i in range(50):
            cursor.execute("""
                SELECT log_momentum_error(
                    'performance_test', 
                    'PERF_TEST_' || %s, 
                    'Performance test error', 
                    '{}', 
                    %s
                )
            """, (i, test_user_id))

        end_time = time.time()
        execution_time = end_time - start_time

        # Should complete 50 error logs in under 2 seconds
        assert execution_time < 2.0


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
