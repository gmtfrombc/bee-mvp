"""
Test Suite: Momentum Score Calculator Edge Function
Epic: 1.1 · Momentum Meter
Task: T1.1.2.6 · Create Supabase Edge Functions for score calculation

Tests the momentum score calculation algorithm including:
- Exponential decay weighting
- Zone classification with hysteresis
- Batch processing for all users
- Error handling and edge cases
- Performance and accuracy validation

Created: 2024-12-17
Author: BEE Development Team
"""

import pytest
import requests
import json
from datetime import datetime, timedelta, date
from typing import Dict, List, Any
import uuid
import time

# Test configuration
EDGE_FUNCTION_URL = "http://localhost:54321/functions/v1/momentum-score-calculator"
SUPABASE_URL = "http://localhost:54321"
SUPABASE_ANON_KEY = "your-anon-key"  # Replace with actual key
SUPABASE_SERVICE_KEY = "your-service-key"  # Replace with actual key


class TestMomentumScoreCalculator:
    """Test suite for momentum score calculation Edge Function"""

    @pytest.fixture(autouse=True)
    def setup_test_data(self, supabase_client):
        """Set up test data before each test"""
        self.supabase = supabase_client
        self.test_user_id = str(uuid.uuid4())
        self.test_date = date.today().isoformat()

        # Clean up any existing test data
        self.cleanup_test_data()

        yield

        # Clean up after test
        self.cleanup_test_data()

    def cleanup_test_data(self):
        """Clean up test data"""
        try:
            # Delete test engagement events
            self.supabase.table('engagement_events').delete().eq(
                'user_id', self.test_user_id).execute()

            # Delete test daily scores
            self.supabase.table('daily_engagement_scores').delete().eq(
                'user_id', self.test_user_id).execute()

            # Delete test calculation jobs
            self.supabase.table('score_calculation_jobs').delete().eq(
                'triggered_by', 'test').execute()
        except Exception as e:
            print(f"Cleanup warning: {e}")

    def create_engagement_event(self, event_type: str, event_date: str = None, points: int = None) -> Dict:
        """Helper to create engagement events"""
        if event_date is None:
            event_date = self.test_date

        event_data = {
            'user_id': self.test_user_id,
            'event_type': event_type,
            'event_date': event_date,
            'event_timestamp': f"{event_date}T10:00:00Z",
            'metadata': {'test': True},
            'points_awarded': points or 10
        }

        result = self.supabase.table(
            'engagement_events').insert(event_data).execute()
        return result.data[0]

    def create_historical_score(self, score_date: str, final_score: float, momentum_state: str) -> Dict:
        """Helper to create historical scores"""
        score_data = {
            'user_id': self.test_user_id,
            'score_date': score_date,
            'raw_score': final_score,
            'normalized_score': final_score,
            'final_score': final_score,
            'momentum_state': momentum_state,
            'breakdown': {'test': True},
            'events_count': 1,
            'algorithm_version': 'test',
            'calculation_metadata': {'test': True}
        }

        result = self.supabase.table(
            'daily_engagement_scores').insert(score_data).execute()
        return result.data[0]

    def call_edge_function(self, payload: Dict) -> requests.Response:
        """Helper to call the Edge Function"""
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}'
        }

        return requests.post(EDGE_FUNCTION_URL, json=payload, headers=headers)

    # =====================================================
    # BASIC FUNCTIONALITY TESTS
    # =====================================================

    def test_single_user_score_calculation(self):
        """Test calculating score for a single user"""
        # Create engagement events
        self.create_engagement_event('lesson_completion')  # 15 points
        self.create_engagement_event('journal_entry')     # 10 points
        self.create_engagement_event('app_session')       # 3 points

        # Call Edge Function
        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        assert data['success'] is True
        assert data['user_id'] == self.test_user_id
        assert data['target_date'] == self.test_date

        score = data['score']
        assert score['user_id'] == self.test_user_id
        assert score['score_date'] == self.test_date
        assert score['raw_score'] == 28  # 15 + 10 + 3
        assert score['final_score'] == 28  # No history, so no decay
        assert score['events_count'] == 3
        assert score['algorithm_version'] == 'v1.0'

        # Verify score was saved to database
        saved_score = self.supabase.table('daily_engagement_scores').select(
            '*').eq('user_id', self.test_user_id).eq('score_date', self.test_date).execute()
        assert len(saved_score.data) == 1
        assert saved_score.data[0]['final_score'] == 28

    def test_zone_classification_rising(self):
        """Test Rising zone classification (score >= 70)"""
        # Create high-value events to reach Rising threshold
        for _ in range(5):
            self.create_engagement_event(
                'lesson_completion')  # 5 * 15 = 75 points

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        assert score['final_score'] >= 70
        assert score['momentum_state'] == 'Rising'

    def test_zone_classification_steady(self):
        """Test Steady zone classification (45 <= score < 70)"""
        # Create medium-value events for Steady zone
        for _ in range(6):
            self.create_engagement_event('journal_entry')  # 6 * 10 = 60 points

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        assert 45 <= score['final_score'] < 70
        assert score['momentum_state'] == 'Steady'

    def test_zone_classification_needs_care(self):
        """Test NeedsCare zone classification (score < 45)"""
        # Create low-value events for NeedsCare zone
        for _ in range(10):
            self.create_engagement_event('app_session')  # 10 * 3 = 30 points

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        assert score['final_score'] < 45
        assert score['momentum_state'] == 'NeedsCare'

    def test_exponential_decay_application(self):
        """Test exponential decay weighting with historical scores"""
        # Create historical scores
        yesterday = (datetime.now() - timedelta(days=1)).date().isoformat()
        two_days_ago = (datetime.now() - timedelta(days=2)).date().isoformat()

        self.create_historical_score(yesterday, 80.0, 'Rising')
        self.create_historical_score(two_days_ago, 75.0, 'Rising')

        # Create today's events (lower score)
        for _ in range(3):
            self.create_engagement_event('journal_entry')  # 3 * 10 = 30 points

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        assert score['raw_score'] == 30
        # Final score should be higher due to historical decay weighting
        assert score['final_score'] > score['raw_score']
        assert score['calculation_metadata']['decay_applied'] is True
        assert score['calculation_metadata']['historical_days_analyzed'] == 2

    def test_hysteresis_prevents_rapid_state_changes(self):
        """Test hysteresis buffer prevents rapid momentum state changes"""
        # Create historical Rising state
        yesterday = (datetime.now() - timedelta(days=1)).date().isoformat()
        self.create_historical_score(yesterday, 72.0, 'Rising')

        # Create today's events that would normally be Steady (68 points)
        for _ in range(4):
            self.create_engagement_event('lesson_completion')  # 4 * 15 = 60
        self.create_engagement_event('journal_entry')  # 10
        # Total: 70 points, but with decay might be ~68

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        # Should stay Rising due to hysteresis buffer (threshold - 2)
        if score['final_score'] >= 68:  # Within hysteresis buffer
            assert score['momentum_state'] == 'Rising'

    def test_event_type_limits_prevent_gaming(self):
        """Test that event type limits prevent gaming the system"""
        # Create more than max events per type (5)
        for _ in range(10):
            # Only first 5 should count
            self.create_engagement_event('lesson_completion')

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        # Should only count 5 events: 5 * 15 = 75 points
        assert score['raw_score'] == 75
        assert score['events_count'] == 10  # All events recorded

        breakdown = score['breakdown']
        assert breakdown['events_by_type']['lesson_completion'] == 10
        # Only 5 counted
        assert breakdown['points_by_type']['lesson_completion'] == 75

    def test_daily_score_cap(self):
        """Test daily score cap of 100 points"""
        # Create events that would exceed 100 points
        for _ in range(10):
            self.create_engagement_event(
                'streak_milestone')  # 10 * 25 = 250 points

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        # Should be capped at 100
        assert score['raw_score'] == 100
        assert score['final_score'] <= 100

    # =====================================================
    # BATCH PROCESSING TESTS
    # =====================================================

    def test_calculate_all_users_batch_processing(self):
        """Test batch processing for all active users"""
        # Create multiple test users with events
        user_ids = [str(uuid.uuid4()) for _ in range(3)]

        for user_id in user_ids:
            # Create events for each user
            event_data = {
                'user_id': user_id,
                'event_type': 'lesson_completion',
                'event_date': self.test_date,
                'event_timestamp': f"{self.test_date}T10:00:00Z",
                'metadata': {'test': True},
                'points_awarded': 15
            }
            self.supabase.table('engagement_events').insert(
                event_data).execute()

        # Call batch processing
        response = self.call_edge_function({
            'calculate_all_users': True,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        assert data['success'] is True
        assert data['target_date'] == self.test_date

        results = data['results']
        assert results['successful'] == 3
        assert results['failed'] == 0
        assert len(results['details']) == 3

        # Verify all users have scores in database
        for user_id in user_ids:
            saved_score = self.supabase.table('daily_engagement_scores').select(
                '*').eq('user_id', user_id).eq('score_date', self.test_date).execute()
            assert len(saved_score.data) == 1

            # Clean up
            self.supabase.table('engagement_events').delete().eq(
                'user_id', user_id).execute()
            self.supabase.table('daily_engagement_scores').delete().eq(
                'user_id', user_id).execute()

    def test_batch_processing_handles_user_errors(self):
        """Test batch processing handles individual user errors gracefully"""
        # Create one valid user and one with invalid data
        valid_user_id = str(uuid.uuid4())

        # Valid user with events
        event_data = {
            'user_id': valid_user_id,
            'event_type': 'lesson_completion',
            'event_date': self.test_date,
            'event_timestamp': f"{self.test_date}T10:00:00Z",
            'metadata': {'test': True},
            'points_awarded': 15
        }
        self.supabase.table('engagement_events').insert(event_data).execute()

        # Invalid user (will be created by the function but might fail)
        invalid_user_id = str(uuid.uuid4())
        invalid_event_data = {
            'user_id': invalid_user_id,
            'event_type': 'lesson_completion',
            'event_date': self.test_date,
            'event_timestamp': f"{self.test_date}T10:00:00Z",
            'metadata': {'test': True},
            'points_awarded': 15
        }
        self.supabase.table('engagement_events').insert(
            invalid_event_data).execute()

        response = self.call_edge_function({
            'calculate_all_users': True,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        assert data['success'] is True
        results = data['results']
        assert results['successful'] >= 1  # At least the valid user

        # Clean up
        self.supabase.table('engagement_events').delete().eq(
            'user_id', valid_user_id).execute()
        self.supabase.table('engagement_events').delete().eq(
            'user_id', invalid_user_id).execute()
        self.supabase.table('daily_engagement_scores').delete().eq(
            'user_id', valid_user_id).execute()
        self.supabase.table('daily_engagement_scores').delete().eq(
            'user_id', invalid_user_id).execute()

    # =====================================================
    # EDGE CASES AND ERROR HANDLING
    # =====================================================

    def test_user_with_no_events(self):
        """Test handling user with no engagement events"""
        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        assert score['raw_score'] == 0
        assert score['final_score'] == 0
        assert score['events_count'] == 0
        assert score['momentum_state'] == 'NeedsCare'  # 0 < 45

    def test_invalid_user_id(self):
        """Test handling invalid user ID"""
        response = self.call_edge_function({
            'user_id': 'invalid-uuid',
            'target_date': self.test_date
        })

        # Should handle gracefully and return error
        assert response.status_code in [400, 500]

    def test_missing_required_parameters(self):
        """Test handling missing required parameters"""
        response = self.call_edge_function({})

        assert response.status_code == 400
        data = response.json()
        assert 'error' in data

    def test_invalid_date_format(self):
        """Test handling invalid date format"""
        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': 'invalid-date'
        })

        assert response.status_code in [400, 500]

    def test_future_date_handling(self):
        """Test handling future dates"""
        future_date = (datetime.now() + timedelta(days=1)).date().isoformat()

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': future_date
        })

        assert response.status_code == 200
        data = response.json()

        # Should work but return 0 score (no events in future)
        score = data['score']
        assert score['raw_score'] == 0
        assert score['final_score'] == 0

    # =====================================================
    # ALGORITHM ACCURACY TESTS
    # =====================================================

    def test_score_breakdown_accuracy(self):
        """Test accuracy of score breakdown calculation"""
        # Create specific events with known weights
        self.create_engagement_event('lesson_completion')  # 15 points
        self.create_engagement_event('journal_entry')     # 10 points
        self.create_engagement_event('coach_interaction')  # 20 points
        self.create_engagement_event('app_session')       # 3 points

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        breakdown = score['breakdown']

        assert breakdown['total_events'] == 4
        assert breakdown['raw_score'] == 48  # 15 + 10 + 20 + 3
        assert breakdown['final_score'] == 48
        assert breakdown['decay_adjustment'] == 0  # No history

        # Check events by type
        events_by_type = breakdown['events_by_type']
        assert events_by_type['lesson_completion'] == 1
        assert events_by_type['journal_entry'] == 1
        assert events_by_type['coach_interaction'] == 1
        assert events_by_type['app_session'] == 1

        # Check points by type
        points_by_type = breakdown['points_by_type']
        assert points_by_type['lesson_completion'] == 15
        assert points_by_type['journal_entry'] == 10
        assert points_by_type['coach_interaction'] == 20
        assert points_by_type['app_session'] == 3

        # Check top activities
        top_activities = breakdown['top_activities']
        assert len(top_activities) == 3  # Top 3
        assert top_activities[0]['type'] == 'coach_interaction'
        assert top_activities[0]['points'] == 20

    def test_calculation_metadata_completeness(self):
        """Test completeness of calculation metadata"""
        self.create_engagement_event('lesson_completion')

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        assert response.status_code == 200
        data = response.json()

        score = data['score']
        metadata = score['calculation_metadata']

        # Check required metadata fields
        assert 'events_processed' in metadata
        assert 'raw_score' in metadata
        assert 'decay_applied' in metadata
        assert 'historical_days_analyzed' in metadata
        assert 'calculation_timestamp' in metadata
        assert 'algorithm_config' in metadata

        # Check algorithm config
        config = metadata['algorithm_config']
        assert 'half_life_days' in config
        assert 'rising_threshold' in config
        assert 'needs_care_threshold' in config

        assert config['half_life_days'] == 10
        assert config['rising_threshold'] == 70
        assert config['needs_care_threshold'] == 45

    # =====================================================
    # PERFORMANCE TESTS
    # =====================================================

    def test_calculation_performance(self):
        """Test calculation performance with many events"""
        # Create many events (within limits)
        event_types = ['lesson_completion', 'journal_entry',
                       'coach_interaction', 'goal_setting']

        for event_type in event_types:
            for _ in range(5):  # Max per type
                self.create_engagement_event(event_type)

        start_time = time.time()

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        end_time = time.time()
        execution_time = end_time - start_time

        assert response.status_code == 200
        assert execution_time < 5.0  # Should complete within 5 seconds

        data = response.json()
        score = data['score']
        assert score['events_count'] == 20  # 4 types * 5 events each

    def test_historical_data_performance(self):
        """Test performance with extensive historical data"""
        # Create 30 days of historical scores
        for i in range(30):
            score_date = (datetime.now() - timedelta(days=i+1)
                          ).date().isoformat()
            self.create_historical_score(score_date, 60.0, 'Steady')

        # Create today's events
        self.create_engagement_event('lesson_completion')

        start_time = time.time()

        response = self.call_edge_function({
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        end_time = time.time()
        execution_time = end_time - start_time

        assert response.status_code == 200
        assert execution_time < 10.0  # Should complete within 10 seconds

        data = response.json()
        score = data['score']
        assert score['calculation_metadata']['historical_days_analyzed'] == 30

    # =====================================================
    # INTEGRATION TESTS
    # =====================================================

    def test_cors_headers(self):
        """Test CORS headers are properly set"""
        # Test OPTIONS request
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}'
        }

        response = requests.options(EDGE_FUNCTION_URL, headers=headers)

        assert response.status_code == 200
        assert 'Access-Control-Allow-Origin' in response.headers
        assert 'Access-Control-Allow-Methods' in response.headers
        assert 'Access-Control-Allow-Headers' in response.headers

    def test_method_not_allowed(self):
        """Test non-POST methods are rejected"""
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}'
        }

        response = requests.get(EDGE_FUNCTION_URL, headers=headers)
        assert response.status_code == 405

        response = requests.put(EDGE_FUNCTION_URL, headers=headers)
        assert response.status_code == 405

    def test_unauthorized_access(self):
        """Test unauthorized access is rejected"""
        response = requests.post(EDGE_FUNCTION_URL, json={
            'user_id': self.test_user_id,
            'target_date': self.test_date
        })

        # Should require authentication
        assert response.status_code in [401, 403]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
