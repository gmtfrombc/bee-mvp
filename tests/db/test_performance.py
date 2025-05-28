#!/usr/bin/env python3
"""
Performance Tests for Engagement Events
Purpose: Measure Realtime latency and database performance under load
Module: Core Engagement
Milestone: 1 · Data Backbone

This script tests the performance characteristics of the engagement_events table
including Realtime notification latency and concurrent insert performance.

Usage:
    python test_performance.py

Requirements:
    pip install psycopg2-binary asyncio websockets python-dotenv

Created: 2024-12-01
Author: BEE Development Team
"""

import os
import sys
import psycopg2
import time
import json
import uuid
import statistics
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from concurrent.futures import ThreadPoolExecutor, as_completed

# Add project root to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class PerformanceTester:
    """Test class for performance verification"""

    def __init__(self):
        self.db_config = self._get_db_config()
        self.test_user_id = "11111111-1111-1111-1111-111111111111"
        self.test_results = []

    def _get_db_config(self) -> Dict[str, str]:
        """Get database configuration from environment or defaults"""
        return {
            "host": os.getenv("DB_HOST", "localhost"),
            # Default Supabase local port
            "port": os.getenv("DB_PORT", "54322"),
            "database": os.getenv("DB_NAME", "postgres"),
            "user": os.getenv("DB_USER", "postgres"),
            "password": os.getenv("DB_PASSWORD", "postgres"),
        }

    def _get_connection(
        self, user_id: Optional[str] = None
    ) -> psycopg2.extensions.connection:
        """Get database connection with optional user context"""
        conn = psycopg2.connect(**self.db_config)
        conn.autocommit = True

        if user_id:
            # Set the auth.uid() context for RLS
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT set_config('request.jwt.claims', %s, true)",
                    (json.dumps({"sub": user_id}),),
                )

        return conn

    def _log_test_result(
        self, test_name: str, passed: bool, details: str = "", metrics: Dict = None
    ):
        """Log test result with performance metrics"""
        result = {
            "test": test_name,
            "passed": passed,
            "details": details,
            "metrics": metrics or {},
            "timestamp": datetime.now().isoformat(),
        }
        self.test_results.append(result)
        status = "PASS" if passed else "FAIL"
        print(f"[{status}] {test_name}: {details}")
        if metrics:
            for key, value in metrics.items():
                print(f"  📊 {key}: {value}")

    def test_single_insert_performance(self) -> bool:
        """Test 1: Measure single insert performance"""
        try:
            conn = self._get_connection(self.test_user_id)

            # Warm up
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO engagement_events (user_id, event_type, value) 
                    VALUES (%s, %s, %s)
                """,
                    (self.test_user_id, "warmup", "{}"),
                )

            # Measure single inserts
            insert_times = []
            num_tests = 10

            for i in range(num_tests):
                start_time = time.perf_counter()

                with conn.cursor() as cur:
                    cur.execute(
                        """
                        INSERT INTO engagement_events (user_id, event_type, value) 
                        VALUES (%s, %s, %s)
                    """,
                        (
                            self.test_user_id,
                            f"perf_test_single_{i}",
                            json.dumps({"test_id": str(uuid.uuid4()), "iteration": i}),
                        ),
                    )

                end_time = time.perf_counter()
                insert_times.append((end_time - start_time) * 1000)  # Convert to ms

            conn.close()

            # Calculate statistics
            avg_time = statistics.mean(insert_times)
            median_time = statistics.median(insert_times)
            max_time = max(insert_times)
            min_time = min(insert_times)

            # Performance criteria: single insert should be < 50ms on average
            performance_passed = avg_time < 50.0

            metrics = {
                "average_insert_time_ms": f"{avg_time:.2f}",
                "median_insert_time_ms": f"{median_time:.2f}",
                "max_insert_time_ms": f"{max_time:.2f}",
                "min_insert_time_ms": f"{min_time:.2f}",
                "total_inserts": num_tests,
            }

            details = f"Average insert time: {avg_time:.2f}ms (target: <50ms)"

            self._log_test_result(
                "Single Insert Performance", performance_passed, details, metrics
            )
            return performance_passed

        except Exception as e:
            self._log_test_result(
                "Single Insert Performance", False, f"Error: {str(e)}"
            )
            return False

    def test_concurrent_insert_performance(self) -> bool:
        """Test 2: Measure performance with 100+ concurrent inserts"""
        try:
            num_threads = 20
            inserts_per_thread = 10

            def insert_events(thread_id: int) -> List[float]:
                """Insert events in a single thread and return timing data"""
                times = []
                try:
                    conn = self._get_connection(self.test_user_id)

                    for i in range(inserts_per_thread):
                        start_time = time.perf_counter()

                        with conn.cursor() as cur:
                            cur.execute(
                                """
                                INSERT INTO engagement_events (user_id, event_type, value) 
                                VALUES (%s, %s, %s)
                            """,
                                (
                                    self.test_user_id,
                                    f"perf_test_concurrent_{thread_id}_{i}",
                                    json.dumps(
                                        {
                                            "test_id": str(uuid.uuid4()),
                                            "thread_id": thread_id,
                                            "iteration": i,
                                            "timestamp": datetime.now().isoformat(),
                                        }
                                    ),
                                ),
                            )

                        end_time = time.perf_counter()
                        times.append((end_time - start_time) * 1000)

                    conn.close()
                    return times

                except Exception as e:
                    print(f"Thread {thread_id} error: {str(e)}")
                    return []

            # Execute concurrent inserts
            start_time = time.perf_counter()

            with ThreadPoolExecutor(max_workers=num_threads) as executor:
                futures = [
                    executor.submit(insert_events, i) for i in range(num_threads)
                ]
                all_times = []

                for future in as_completed(futures):
                    thread_times = future.result()
                    all_times.extend(thread_times)

            end_time = time.perf_counter()
            total_duration = (end_time - start_time) * 1000  # Convert to ms

            # Calculate statistics
            if all_times:
                avg_time = statistics.mean(all_times)
                median_time = statistics.median(all_times)
                max_time = max(all_times)
                min_time = min(all_times)
                throughput = len(all_times) / (
                    total_duration / 1000
                )  # inserts per second

                # Performance criteria:
                # - Average insert time should still be reasonable under load (<100ms)
                # - Should achieve >50 inserts per second
                performance_passed = avg_time < 100.0 and throughput > 50.0

                metrics = {
                    "total_inserts": len(all_times),
                    "total_duration_ms": f"{total_duration:.2f}",
                    "average_insert_time_ms": f"{avg_time:.2f}",
                    "median_insert_time_ms": f"{median_time:.2f}",
                    "max_insert_time_ms": f"{max_time:.2f}",
                    "min_insert_time_ms": f"{min_time:.2f}",
                    "throughput_inserts_per_sec": f"{throughput:.2f}",
                    "concurrent_threads": num_threads,
                }

                details = (
                    f"Concurrent inserts: {len(all_times)}, "
                    f"Avg time: {avg_time:.2f}ms, Throughput: {throughput:.2f}/sec"
                )

                self._log_test_result(
                    "Concurrent Insert Performance",
                    performance_passed,
                    details,
                    metrics,
                )
                return performance_passed
            else:
                self._log_test_result(
                    "Concurrent Insert Performance", False, "No successful inserts"
                )
                return False

        except Exception as e:
            self._log_test_result(
                "Concurrent Insert Performance", False, f"Error: {str(e)}"
            )
            return False

    def test_query_performance_with_indexes(self) -> bool:
        """Test 3: Verify index effectiveness with EXPLAIN ANALYZE"""
        try:
            conn = self._get_connection(self.test_user_id)

            # Test 1: User timeline query (should use user_timestamp index)
            with conn.cursor() as cur:
                cur.execute(
                    """
                    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) 
                    SELECT * FROM engagement_events 
                    WHERE user_id = %s 
                    ORDER BY timestamp DESC 
                    LIMIT 50
                """,
                    (self.test_user_id,),
                )

                timeline_plan = cur.fetchone()[0][0]

            # Test 2: Event type filtering (should use event_type index)
            with conn.cursor() as cur:
                cur.execute(
                    """
                    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) 
                    SELECT COUNT(*) FROM engagement_events 
                    WHERE event_type = 'app_open'
                """,
                    (self.test_user_id,),
                )

                event_type_plan = cur.fetchone()[0][0]

            # Test 3: JSONB search (should use GIN index)
            with conn.cursor() as cur:
                cur.execute(
                    """
                    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) 
                    SELECT * FROM engagement_events 
                    WHERE value @> '{"goal_type": "steps"}'
                """
                )

                jsonb_plan = cur.fetchone()[0][0]

            conn.close()

            # Analyze execution plans
            timeline_time = timeline_plan["Execution Time"]
            event_type_time = event_type_plan["Execution Time"]
            jsonb_time = jsonb_plan["Execution Time"]

            # Check if indexes are being used (look for Index Scan in plan)
            timeline_uses_index = "Index Scan" in str(timeline_plan)
            event_type_uses_index = "Index Scan" in str(event_type_plan)
            jsonb_uses_index = "Bitmap" in str(jsonb_plan) or "Index Scan" in str(
                jsonb_plan
            )

            # Performance criteria: queries should be fast and use indexes
            performance_passed = (
                timeline_time < 50.0  # Timeline query < 50ms
                and event_type_time < 100.0  # Event type query < 100ms
                and jsonb_time < 200.0  # JSONB query < 200ms
                and timeline_uses_index
                and event_type_uses_index
            )

            metrics = {
                "timeline_query_time_ms": f"{timeline_time:.2f}",
                "event_type_query_time_ms": f"{event_type_time:.2f}",
                "jsonb_query_time_ms": f"{jsonb_time:.2f}",
                "timeline_uses_index": timeline_uses_index,
                "event_type_uses_index": event_type_uses_index,
                "jsonb_uses_index": jsonb_uses_index,
            }

            details = (
                f"Timeline: {timeline_time:.2f}ms, Event type: {event_type_time:.2f}ms, "
                f"JSONB: {jsonb_time:.2f}ms"
            )

            self._log_test_result(
                "Query Performance & Indexes", performance_passed, details, metrics
            )
            return performance_passed

        except Exception as e:
            self._log_test_result(
                "Query Performance & Indexes", False, f"Error: {str(e)}"
            )
            return False

    def test_large_dataset_performance(self) -> bool:
        """Test 4: Benchmark query performance with large datasets"""
        try:
            conn = self._get_connection(self.test_user_id)

            # First, check how many events we have
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                    (self.test_user_id,),
                )
                current_count = cur.fetchone()[0]

            # If we don't have enough data, create more for testing
            target_count = 1000
            if current_count < target_count:
                events_to_create = target_count - current_count
                print(
                    f"Creating {events_to_create} additional events for large dataset test..."
                )

                # Batch insert events
                batch_size = 100
                for batch_start in range(0, events_to_create, batch_size):
                    batch_end = min(batch_start + batch_size, events_to_create)

                    with conn.cursor() as cur:
                        values = []
                        for i in range(batch_start, batch_end):
                            values.append(
                                cur.mogrify(
                                    "(%s, %s, %s, %s)",
                                    (
                                        self.test_user_id,
                                        f"large_dataset_test_{i}",
                                        json.dumps(
                                            {
                                                "batch": batch_start // batch_size,
                                                "index": i,
                                            }
                                        ),
                                        datetime.now() - timedelta(minutes=i),
                                    ),
                                ).decode("utf-8")
                            )

                        cur.execute(
                            f"""
                            INSERT INTO engagement_events (user_id, event_type, value, timestamp) 
                            VALUES {','.join(values)}
                        """
                        )

            # Test various query patterns on large dataset
            queries = [
                (
                    "Recent events",
                    "SELECT * FROM engagement_events WHERE user_id = %s ORDER BY timestamp DESC LIMIT 100",
                ),
                (
                    "Date range",
                    "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s AND timestamp >= %s",
                ),
                (
                    "Event type filter",
                    "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s AND event_type LIKE 'app_%'",
                ),
                (
                    "JSONB aggregation",
                    "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s AND value ? 'batch'",
                ),
            ]

            query_times = {}

            for query_name, query_sql in queries:
                start_time = time.perf_counter()

                with conn.cursor() as cur:
                    if query_name == "Date range":
                        cur.execute(
                            query_sql,
                            (self.test_user_id, datetime.now() - timedelta(days=7)),
                        )
                    else:
                        cur.execute(query_sql, (self.test_user_id,))

                cur.fetchall()

                end_time = time.perf_counter()
                query_times[query_name] = (end_time - start_time) * 1000

            conn.close()

            # Performance criteria: all queries should complete in reasonable time
            max_acceptable_time = 500.0  # 500ms
            performance_passed = all(
                time < max_acceptable_time for time in query_times.values()
            )

            metrics = {
                f"{name.lower().replace(' ', '_')}_time_ms": f"{time:.2f}"
                for name, time in query_times.items()
            }
            metrics["dataset_size"] = target_count
            metrics["max_acceptable_time_ms"] = max_acceptable_time

            details = (
                f"Largest query time: {max(query_times.values()):.2f}ms "
                f"(target: <{max_acceptable_time}ms)"
            )

            self._log_test_result(
                "Large Dataset Performance", performance_passed, details, metrics
            )
            return performance_passed

        except Exception as e:
            self._log_test_result(
                "Large Dataset Performance", False, f"Error: {str(e)}"
            )
            return False

    def test_realtime_latency_simulation(self) -> bool:
        """Test 5: Simulate Realtime notification latency (mock test)"""
        try:
            # Note: This is a simulation since we don't have actual Realtime WebSocket setup
            # In a real test, this would measure the time from INSERT to WebSocket notification

            conn = self._get_connection(self.test_user_id)

            # Simulate the latency by measuring insert + immediate query time
            latencies = []
            num_tests = 10

            for i in range(num_tests):
                # Insert event
                insert_start = time.perf_counter()
                event_id = str(uuid.uuid4())

                with conn.cursor() as cur:
                    cur.execute(
                        """
                        INSERT INTO engagement_events (user_id, event_type, value) 
                        VALUES (%s, %s, %s) RETURNING id
                    """,
                        (
                            self.test_user_id,
                            "realtime_test",
                            json.dumps({"test_id": event_id, "iteration": i}),
                        ),
                    )

                    inserted_id = cur.fetchone()[0]

                # Immediately query for the event (simulating notification trigger)
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        SELECT id, timestamp FROM engagement_events 
                        WHERE id = %s
                    """,
                        (inserted_id,),
                    )

                    result = cur.fetchone()

                insert_end = time.perf_counter()

                if result:
                    latency = (insert_end - insert_start) * 1000  # Convert to ms
                    latencies.append(latency)

            conn.close()

            if latencies:
                avg_latency = statistics.mean(latencies)
                max_latency = max(latencies)
                min_latency = min(latencies)

                # Performance criteria: simulated latency should be < 500ms (target from PRD)
                # Note: Real Realtime latency would include WebSocket transmission time
                performance_passed = avg_latency < 500.0

                metrics = {
                    "average_latency_ms": f"{avg_latency:.2f}",
                    "max_latency_ms": f"{max_latency:.2f}",
                    "min_latency_ms": f"{min_latency:.2f}",
                    "target_latency_ms": "500.00",
                    "test_type": "simulated_insert_query",
                }

                details = f"Simulated avg latency: {avg_latency:.2f}ms (target: <500ms)"

                self._log_test_result(
                    "Realtime Latency (Simulated)", performance_passed, details, metrics
                )
                return performance_passed
            else:
                self._log_test_result(
                    "Realtime Latency (Simulated)", False, "No latency measurements"
                )
                return False

        except Exception as e:
            self._log_test_result(
                "Realtime Latency (Simulated)", False, f"Error: {str(e)}"
            )
            return False

    def run_all_tests(self) -> bool:
        """Run all performance tests and return overall pass/fail"""
        print("=" * 60)
        print("BEE Engagement Events - Performance Test Suite")
        print("=" * 60)
        print(f"Database: {self.db_config['host']}:{self.db_config['port']}")
        print(f"Test User: {self.test_user_id}")
        print("-" * 60)

        tests = [
            self.test_single_insert_performance,
            self.test_concurrent_insert_performance,
            self.test_query_performance_with_indexes,
            self.test_large_dataset_performance,
            self.test_realtime_latency_simulation,
        ]

        passed_tests = 0
        total_tests = len(tests)

        for test in tests:
            try:
                if test():
                    passed_tests += 1
                print()  # Add spacing between tests
            except Exception as e:
                print(f"[ERROR] {test.__name__}: {str(e)}")

        print("-" * 60)
        print(f"Performance Test Results: {passed_tests}/{total_tests} passed")

        # Generate detailed report
        self._generate_performance_report()

        return passed_tests == total_tests

    def _generate_performance_report(self):
        """Generate detailed performance report"""
        report_file = (
            f"performance_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )

        report = {
            "test_suite": "BEE Engagement Events Performance Tests",
            "timestamp": datetime.now().isoformat(),
            "database_config": {
                k: v for k, v in self.db_config.items() if k != "password"
            },
            "test_user": self.test_user_id,
            "results": self.test_results,
            "summary": {
                "total_tests": len(self.test_results),
                "passed_tests": sum(1 for r in self.test_results if r["passed"]),
                "failed_tests": sum(1 for r in self.test_results if not r["passed"]),
                "success_rate": f"{sum(1 for r in self.test_results if r['passed']) / len(self.test_results) * 100:.1f}%",
            },
        }

        with open(f"tests/db/{report_file}", "w") as f:
            json.dump(report, f, indent=2)

        print(f"Detailed performance report saved to: tests/db/{report_file}")


def main():
    """Main test execution"""
    tester = PerformanceTester()
    success = tester.run_all_tests()

    if success:
        print("\n✅ All performance tests PASSED - System meets performance targets")
        sys.exit(0)
    else:
        print("\n❌ Some performance tests FAILED - Review system performance")
        sys.exit(1)


if __name__ == "__main__":
    main()
