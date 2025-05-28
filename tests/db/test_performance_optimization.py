"""
Performance Tests for Database Optimization
Epic: 1.1 · Momentum Meter
Task: T1.1.2.9 · Create database indexes and performance optimization

Tests cover:
- Index performance and usage
- Query execution time improvements
- Materialized view functionality
- Performance monitoring functions
- Maintenance procedures
- Memory and resource usage
"""

import pytest
import time
import uuid
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, timedelta
import json
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed

# Test configuration
TEST_CONFIG = {
    'db_connection': {
        'host': 'localhost',
        'port': 54322,
        'database': 'postgres',
        'user': 'postgres',
        'password': 'postgres'
    },
    'performance_thresholds': {
        'single_user_query_ms': 100,  # Single user momentum query
        'batch_query_ms': 500,        # Batch queries
        'complex_analytics_ms': 1000,  # Complex analytics queries
        'materialized_view_refresh_ms': 5000,  # View refresh time
        'maintenance_operation_ms': 10000  # Maintenance operations
    }
}


class TestPerformanceOptimization:
    """Test suite for database performance optimization"""

    @pytest.fixture
    def db_connection(self):
        """Create database connection for testing"""
        conn = psycopg2.connect(**TEST_CONFIG['db_connection'])
        conn.autocommit = True
        yield conn
        conn.close()

    @pytest.fixture
    def test_data_setup(self, db_connection):
        """Set up test data for performance testing"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Create test users
        test_users = [str(uuid.uuid4()) for _ in range(100)]

        # Insert test engagement scores (30 days of data per user)
        test_scores = []
        for user_id in test_users:
            for days_back in range(30):
                score_date = (datetime.now() -
                              timedelta(days=days_back)).date()
                test_scores.append({
                    'user_id': user_id,
                    'score_date': score_date,
                    'raw_score': 50 + (days_back % 50),  # Varying scores
                    'normalized_score': 45 + (days_back % 45),
                    'final_score': 40 + (days_back % 40),
                    'momentum_state': ['Rising', 'Steady', 'NeedsCare'][days_back % 3],
                    'events_count': days_back % 10,
                    'breakdown': json.dumps({'lessons': days_back % 5})
                })

        # Batch insert test data
        cursor.executemany("""
            INSERT INTO daily_engagement_scores (
                user_id, score_date, raw_score, normalized_score, 
                final_score, momentum_state, events_count, breakdown
            ) VALUES (
                %(user_id)s, %(score_date)s, %(raw_score)s, %(normalized_score)s,
                %(final_score)s, %(momentum_state)s, %(events_count)s, %(breakdown)s
            ) ON CONFLICT (user_id, score_date) DO NOTHING
        """, test_scores)

        # Insert test notifications
        test_notifications = []
        for user_id in test_users[:50]:  # Half the users get notifications
            for days_back in range(0, 10, 2):  # Every other day
                trigger_date = (datetime.now() -
                                timedelta(days=days_back)).date()
                test_notifications.append({
                    'user_id': user_id,
                    'notification_type': 'momentum_drop',
                    'trigger_date': trigger_date,
                    'title': f'Test notification {days_back}',
                    'message': f'Test message for day {days_back}',
                    'status': 'sent' if days_back > 5 else 'pending'
                })

        cursor.executemany("""
            INSERT INTO momentum_notifications (
                user_id, notification_type, trigger_date, title, message, status
            ) VALUES (
                %(user_id)s, %(notification_type)s, %(trigger_date)s, 
                %(title)s, %(message)s, %(status)s
            ) ON CONFLICT DO NOTHING
        """, test_notifications)

        # Insert test interventions
        test_interventions = []
        for user_id in test_users[:25]:  # Quarter of users get interventions
            for days_back in range(0, 15, 5):  # Every 5 days
                trigger_date = (datetime.now() -
                                timedelta(days=days_back)).date()
                test_interventions.append({
                    'user_id': user_id,
                    'intervention_type': 'automated_call_schedule',
                    'trigger_date': trigger_date,
                    'trigger_reason': f'Test intervention {days_back}',
                    'status': 'completed' if days_back > 10 else 'scheduled'
                })

        cursor.executemany("""
            INSERT INTO coach_interventions (
                user_id, intervention_type, trigger_date, trigger_reason, status
            ) VALUES (
                %(user_id)s, %(intervention_type)s, %(trigger_date)s, 
                %(trigger_reason)s, %(status)s
            ) ON CONFLICT DO NOTHING
        """, test_interventions)

        return {
            'test_users': test_users,
            'total_scores': len(test_scores),
            'total_notifications': len(test_notifications),
            'total_interventions': len(test_interventions)
        }

    def measure_query_time(self, cursor, query, params=None):
        """Measure query execution time in milliseconds"""
        start_time = time.time()
        cursor.execute(query, params)
        cursor.fetchall()  # Ensure all data is retrieved
        end_time = time.time()
        return (end_time - start_time) * 1000  # Convert to milliseconds

    # =====================================================
    # INDEX PERFORMANCE TESTS
    # =====================================================

    def test_user_date_index_performance(self, db_connection, test_data_setup):
        """Test performance of user_id + date index"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)
        test_user = test_data_setup['test_users'][0]

        # Test single user recent scores query
        query_time = self.measure_query_time(cursor, """
            SELECT * FROM daily_engagement_scores 
            WHERE user_id = %s 
            AND score_date >= %s 
            ORDER BY score_date DESC
        """, (test_user, (datetime.now() - timedelta(days=7)).date()))

        assert query_time < TEST_CONFIG['performance_thresholds']['single_user_query_ms']

        # Verify index is being used
        cursor.execute("""
            EXPLAIN (ANALYZE, BUFFERS) 
            SELECT * FROM daily_engagement_scores 
            WHERE user_id = %s 
            AND score_date >= %s 
            ORDER BY score_date DESC
        """, (test_user, (datetime.now() - timedelta(days=7)).date()))

        explain_result = cursor.fetchall()
        explain_text = '\n'.join([row[0] for row in explain_result])
        assert 'idx_daily_scores_user_date' in explain_text or 'Index Scan' in explain_text

    def test_momentum_state_index_performance(self, db_connection, test_data_setup):
        """Test performance of momentum state filtering"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test momentum state filtering query
        query_time = self.measure_query_time(cursor, """
            SELECT user_id, score_date, final_score 
            FROM daily_engagement_scores 
            WHERE momentum_state = %s 
            AND score_date >= %s 
            ORDER BY score_date DESC
            LIMIT 100
        """, ('NeedsCare', (datetime.now() - timedelta(days=7)).date()))

        assert query_time < TEST_CONFIG['performance_thresholds']['batch_query_ms']

    def test_recent_scores_partial_index_performance(self, db_connection, test_data_setup):
        """Test performance of partial index for recent scores"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test recent scores query (should use partial index)
        query_time = self.measure_query_time(cursor, """
            SELECT user_id, score_date, final_score, momentum_state
            FROM daily_engagement_scores 
            WHERE score_date >= CURRENT_DATE - INTERVAL '30 days'
            ORDER BY user_id, score_date DESC
        """)

        assert query_time < TEST_CONFIG['performance_thresholds']['batch_query_ms']

    def test_notification_indexes_performance(self, db_connection, test_data_setup):
        """Test performance of notification table indexes"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)
        test_user = test_data_setup['test_users'][0]

        # Test user notifications query
        query_time = self.measure_query_time(cursor, """
            SELECT * FROM momentum_notifications 
            WHERE user_id = %s 
            ORDER BY trigger_date DESC
            LIMIT 10
        """, (test_user,))

        assert query_time < TEST_CONFIG['performance_thresholds']['single_user_query_ms']

        # Test unread notifications query
        query_time = self.measure_query_time(cursor, """
            SELECT * FROM momentum_notifications 
            WHERE status = 'pending' OR (status = 'sent' AND read_at IS NULL)
            ORDER BY created_at DESC
            LIMIT 50
        """)

        assert query_time < TEST_CONFIG['performance_thresholds']['batch_query_ms']

    # =====================================================
    # MATERIALIZED VIEW TESTS
    # =====================================================

    def test_user_momentum_summary_performance(self, db_connection, test_data_setup):
        """Test performance of user momentum summary materialized view"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test querying the materialized view
        query_time = self.measure_query_time(cursor, """
            SELECT * FROM user_momentum_summary 
            WHERE activity_status = 'active'
            ORDER BY avg_score DESC
            LIMIT 50
        """)

        assert query_time < TEST_CONFIG['performance_thresholds']['single_user_query_ms']

        # Verify data exists in the view
        cursor.execute("SELECT COUNT(*) as count FROM user_momentum_summary")
        result = cursor.fetchone()
        assert result['count'] > 0

    def test_daily_system_metrics_performance(self, db_connection, test_data_setup):
        """Test performance of daily system metrics materialized view"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test querying the materialized view
        query_time = self.measure_query_time(cursor, """
            SELECT * FROM daily_system_metrics 
            WHERE score_date >= CURRENT_DATE - INTERVAL '7 days'
            ORDER BY score_date DESC
        """)

        assert query_time < TEST_CONFIG['performance_thresholds']['single_user_query_ms']

    def test_materialized_view_refresh_performance(self, db_connection, test_data_setup):
        """Test performance of materialized view refresh"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Measure refresh time
        start_time = time.time()
        cursor.execute("SELECT refresh_momentum_materialized_views()")
        end_time = time.time()

        refresh_time_ms = (end_time - start_time) * 1000
        assert refresh_time_ms < TEST_CONFIG['performance_thresholds']['materialized_view_refresh_ms']

    # =====================================================
    # OPTIMIZED VIEW TESTS
    # =====================================================

    def test_recent_user_momentum_view_performance(self, db_connection, test_data_setup):
        """Test performance of recent user momentum view"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)
        test_user = test_data_setup['test_users'][0]

        # Test single user query
        query_time = self.measure_query_time(cursor, """
            SELECT * FROM recent_user_momentum 
            WHERE user_id = %s 
            ORDER BY score_date DESC
            LIMIT 10
        """, (test_user,))

        assert query_time < TEST_CONFIG['performance_thresholds']['single_user_query_ms']

    def test_intervention_candidates_view_performance(self, db_connection, test_data_setup):
        """Test performance of intervention candidates view"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test intervention candidates query
        query_time = self.measure_query_time(cursor, """
            SELECT * FROM intervention_candidates 
            WHERE consecutive_needs_care_days >= 3
            AND has_pending_intervention = false
            ORDER BY consecutive_needs_care_days DESC
            LIMIT 20
        """)

        assert query_time < TEST_CONFIG['performance_thresholds']['batch_query_ms']

    # =====================================================
    # PERFORMANCE MONITORING TESTS
    # =====================================================

    def test_analyze_momentum_tables_performance(self, db_connection, test_data_setup):
        """Test performance of table analysis function"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Measure analysis time
        start_time = time.time()
        cursor.execute("SELECT analyze_momentum_tables()")
        result = cursor.fetchone()
        end_time = time.time()

        analysis_time_ms = (end_time - start_time) * 1000
        assert analysis_time_ms < TEST_CONFIG['performance_thresholds']['maintenance_operation_ms']

        # Verify statistics are returned
        stats = result[0]  # First column contains the JSONB result
        assert 'daily_scores_count' in stats
        assert 'analyzed_at' in stats
        assert stats['daily_scores_count'] > 0

    def test_performance_monitoring_function(self, db_connection, test_data_setup):
        """Test performance monitoring function"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test monitoring function
        query_time = self.measure_query_time(cursor, """
            SELECT monitor_momentum_performance()
        """)

        assert query_time < TEST_CONFIG['performance_thresholds']['batch_query_ms']

        # Verify monitoring data is returned
        cursor.execute("SELECT monitor_momentum_performance()")
        result = cursor.fetchone()
        performance_stats = result[0]

        assert 'table_sizes' in performance_stats
        assert 'monitored_at' in performance_stats

    def test_performance_recommendations_function(self, db_connection, test_data_setup):
        """Test performance recommendations function"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test recommendations function
        query_time = self.measure_query_time(cursor, """
            SELECT get_performance_recommendations()
        """)

        assert query_time < TEST_CONFIG['performance_thresholds']['batch_query_ms']

        # Verify recommendations are returned
        cursor.execute("SELECT get_performance_recommendations()")
        result = cursor.fetchone()
        recommendations = result[0]

        assert 'recommendations' in recommendations
        assert 'generated_at' in recommendations
        assert 'total_recommendations' in recommendations

    # =====================================================
    # MAINTENANCE OPERATION TESTS
    # =====================================================

    def test_maintenance_operation_performance(self, db_connection, test_data_setup):
        """Test performance of maintenance operations"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test full maintenance operation
        start_time = time.time()
        cursor.execute("SELECT perform_momentum_maintenance()")
        result = cursor.fetchone()
        end_time = time.time()

        maintenance_time_ms = (end_time - start_time) * 1000
        assert maintenance_time_ms < TEST_CONFIG['performance_thresholds']['maintenance_operation_ms']

        # Verify maintenance log is returned
        maintenance_log = result[0]
        assert 'maintenance_started_at' in maintenance_log
        assert 'maintenance_completed_at' in maintenance_log
        assert 'duration_seconds' in maintenance_log

    # =====================================================
    # CONCURRENT ACCESS TESTS
    # =====================================================

    def test_concurrent_user_queries_performance(self, db_connection, test_data_setup):
        """Test performance under concurrent user queries"""
        test_users = test_data_setup['test_users'][:
                                                   20]  # Use 20 users for concurrent testing

        def query_user_momentum(user_id):
            """Query momentum for a single user"""
            conn = psycopg2.connect(**TEST_CONFIG['db_connection'])
            conn.autocommit = True
            cursor = conn.cursor(cursor_factory=RealDictCursor)

            start_time = time.time()
            cursor.execute("""
                SELECT * FROM recent_user_momentum 
                WHERE user_id = %s 
                ORDER BY score_date DESC
                LIMIT 10
            """, (user_id,))
            cursor.fetchall()
            end_time = time.time()

            conn.close()
            return (end_time - start_time) * 1000

        # Execute concurrent queries
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(query_user_momentum, user_id)
                       for user_id in test_users]
            query_times = [future.result() for future in as_completed(futures)]

        # Verify performance under concurrent load
        avg_query_time = statistics.mean(query_times)
        max_query_time = max(query_times)

        # Allow 2x under load
        assert avg_query_time < TEST_CONFIG['performance_thresholds']['single_user_query_ms'] * 2
        # Allow 3x for worst case
        assert max_query_time < TEST_CONFIG['performance_thresholds']['single_user_query_ms'] * 3

    def test_concurrent_analytics_queries_performance(self, db_connection, test_data_setup):
        """Test performance of concurrent analytics queries"""

        def run_analytics_query():
            """Run a complex analytics query"""
            conn = psycopg2.connect(**TEST_CONFIG['db_connection'])
            conn.autocommit = True
            cursor = conn.cursor(cursor_factory=RealDictCursor)

            start_time = time.time()
            cursor.execute("""
                SELECT 
                    momentum_state,
                    COUNT(*) as count,
                    AVG(final_score) as avg_score,
                    MIN(final_score) as min_score,
                    MAX(final_score) as max_score
                FROM daily_engagement_scores 
                WHERE score_date >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY momentum_state
                ORDER BY momentum_state
            """)
            cursor.fetchall()
            end_time = time.time()

            conn.close()
            return (end_time - start_time) * 1000

        # Execute concurrent analytics queries
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(run_analytics_query) for _ in range(10)]
            query_times = [future.result() for future in as_completed(futures)]

        # Verify performance under concurrent analytics load
        avg_query_time = statistics.mean(query_times)
        max_query_time = max(query_times)

        assert avg_query_time < TEST_CONFIG['performance_thresholds']['complex_analytics_ms']
        assert max_query_time < TEST_CONFIG['performance_thresholds']['complex_analytics_ms'] * 2

    # =====================================================
    # MEMORY AND RESOURCE USAGE TESTS
    # =====================================================

    def test_memory_usage_optimization(self, db_connection, test_data_setup):
        """Test memory usage of optimized queries"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Test large result set with LIMIT to ensure memory efficiency
        cursor.execute("""
            SELECT * FROM daily_engagement_scores 
            WHERE score_date >= CURRENT_DATE - INTERVAL '30 days'
            ORDER BY score_date DESC, user_id
            LIMIT 1000
        """)

        results = cursor.fetchall()
        assert len(results) <= 1000  # Verify LIMIT is working

        # Test streaming large datasets (using server-side cursor)
        cursor.execute("""
            DECLARE momentum_cursor CURSOR FOR 
            SELECT user_id, score_date, final_score 
            FROM daily_engagement_scores 
            WHERE score_date >= CURRENT_DATE - INTERVAL '90 days'
            ORDER BY user_id, score_date DESC
        """)

        # Fetch in batches to test memory efficiency
        cursor.execute("FETCH 100 FROM momentum_cursor")
        batch = cursor.fetchall()
        assert len(batch) <= 100

        cursor.execute("CLOSE momentum_cursor")

    # =====================================================
    # INDEX USAGE VERIFICATION TESTS
    # =====================================================

    def test_index_usage_statistics(self, db_connection, test_data_setup):
        """Test that indexes are being used effectively"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Run some queries to generate index usage
        test_user = test_data_setup['test_users'][0]

        # Query that should use user_date index
        cursor.execute("""
            SELECT * FROM daily_engagement_scores 
            WHERE user_id = %s 
            AND score_date >= %s
        """, (test_user, (datetime.now() - timedelta(days=7)).date()))
        cursor.fetchall()

        # Query that should use momentum state index
        cursor.execute("""
            SELECT * FROM daily_engagement_scores 
            WHERE momentum_state = 'NeedsCare'
            AND score_date >= %s
        """, ((datetime.now() - timedelta(days=7)).date(),))
        cursor.fetchall()

        # Check index usage statistics
        cursor.execute("""
            SELECT 
                indexrelname,
                idx_scan,
                idx_tup_read,
                idx_tup_fetch
            FROM pg_stat_user_indexes 
            WHERE schemaname = 'public'
            AND indexrelname LIKE 'idx_daily_scores%'
            ORDER BY idx_scan DESC
        """)

        index_stats = cursor.fetchall()

        # Verify that at least some indexes are being used
        total_scans = sum(stat['idx_scan'] or 0 for stat in index_stats)
        assert total_scans > 0, "Indexes should be used for queries"

    # =====================================================
    # PERFORMANCE REGRESSION TESTS
    # =====================================================

    def test_performance_baseline_establishment(self, db_connection, test_data_setup):
        """Establish performance baselines for future regression testing"""
        cursor = db_connection.cursor(cursor_factory=RealDictCursor)

        # Define baseline queries and their expected performance
        baseline_queries = [
            {
                'name': 'single_user_recent_scores',
                'query': """
                    SELECT * FROM daily_engagement_scores 
                    WHERE user_id = %s 
                    AND score_date >= %s 
                    ORDER BY score_date DESC
                """,
                'params': (test_data_setup['test_users'][0], (datetime.now() - timedelta(days=7)).date()),
                'threshold_ms': 50
            },
            {
                'name': 'momentum_state_analytics',
                'query': """
                    SELECT momentum_state, COUNT(*), AVG(final_score) 
                    FROM daily_engagement_scores 
                    WHERE score_date >= %s 
                    GROUP BY momentum_state
                """,
                'params': ((datetime.now() - timedelta(days=30)).date(),),
                'threshold_ms': 200
            },
            {
                'name': 'user_momentum_summary_query',
                'query': """
                    SELECT * FROM user_momentum_summary 
                    WHERE activity_status = 'active'
                    ORDER BY avg_score DESC
                    LIMIT 20
                """,
                'params': None,
                'threshold_ms': 30
            }
        ]

        # Test each baseline query
        performance_results = {}
        for query_test in baseline_queries:
            query_time = self.measure_query_time(
                cursor,
                query_test['query'],
                query_test['params']
            )

            performance_results[query_test['name']] = {
                'execution_time_ms': query_time,
                'threshold_ms': query_test['threshold_ms'],
                'passed': query_time < query_test['threshold_ms']
            }

            # Assert performance meets baseline
            assert query_time < query_test['threshold_ms'], \
                f"Query {query_test['name']} took {query_time}ms, expected < {query_test['threshold_ms']}ms"

        # Log performance baselines for future reference
        cursor.execute("""
            INSERT INTO momentum_error_logs (
                error_type, error_code, error_message, error_details, severity
            ) VALUES (
                'system_error', 'PERFORMANCE_BASELINE', 
                'Performance baseline established',
                %s,
                'low'
            )
        """, (json.dumps(performance_results),))


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
