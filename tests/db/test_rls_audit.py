#!/usr/bin/env python3
"""
RLS Audit Tests for Engagement Events
Purpose: Verify complete cross-user data isolation and RLS policy enforcement
Module: Core Engagement
Milestone: 1 · Data Backbone

This script tests the Row Level Security (RLS) policies on the engagement_events table
to ensure zero cross-user data leakage as required by HIPAA compliance.

Usage:
    python test_rls_audit.py

Requirements:
    pip install psycopg2-binary pytest python-dotenv

Created: 2024-12-01
Author: BEE Development Team
"""

import os
import sys
import psycopg2
from datetime import datetime
from typing import Dict, Optional
import json
import uuid

# Add project root to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class RLSAuditTester:
    """Test class for RLS audit verification"""

    def __init__(self):
        self.db_config = self._get_db_config()
        self.test_users = {
            "user_a": "11111111-1111-1111-1111-111111111111",
            "user_b": "22222222-2222-2222-2222-222222222222",
            "user_c": "33333333-3333-3333-3333-333333333333",
        }
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
        """Get database connection with optional user context for RLS testing"""
        conn = psycopg2.connect(**self.db_config)
        conn.autocommit = True

        if user_id:
            # Set the auth.uid() context for RLS testing
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT set_config('request.jwt.claims', %s, true)",
                    (json.dumps({"sub": user_id}),),
                )

        return conn

    def _log_test_result(self, test_name: str, passed: bool, details: str = ""):
        """Log test result for final reporting"""
        result = {
            "test": test_name,
            "passed": passed,
            "details": details,
            "timestamp": datetime.now().isoformat(),
        }
        self.test_results.append(result)
        status = "PASS" if passed else "FAIL"
        print(f"[{status}] {test_name}: {details}")

    def test_table_exists_and_rls_enabled(self):
        """Test 1: Verify engagement_events table exists and RLS is enabled"""
        try:
            conn = self._get_connection()
            with conn.cursor() as cur:
                # Check table exists
                cur.execute(
                    """
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_schema = 'public' 
                        AND table_name = 'engagement_events'
                    )
                """
                )
                table_exists = cur.fetchone()[0]

                if not table_exists:
                    self._log_test_result(
                        "Table Existence", False, "engagement_events table not found"
                    )
                    return False

                # Check RLS is enabled
                cur.execute(
                    """
                    SELECT relrowsecurity 
                    FROM pg_class 
                    WHERE relname = 'engagement_events'
                """
                )
                rls_enabled = cur.fetchone()[0]

                self._log_test_result(
                    "RLS Enabled", rls_enabled, f"RLS enabled: {rls_enabled}"
                )
                return rls_enabled

        except Exception as e:
            self._log_test_result("Table/RLS Check", False, f"Error: {str(e)}")
            return False
        finally:
            conn.close()

    def test_user_isolation_select(self):
        """Test 2: Verify users can only SELECT their own events"""
        try:
            # Test User A can see their own events
            conn_a = self._get_connection(self.test_users["user_a"])
            with conn_a.cursor() as cur:
                cur.execute(
                    "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                    (self.test_users["user_a"],),
                )
                user_a_count = cur.fetchone()[0]

            # Test User A cannot see User B's events
            with conn_a.cursor() as cur:
                cur.execute(
                    "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                    (self.test_users["user_b"],),
                )
                user_b_count_from_a = cur.fetchone()[0]

            # Test User A sees total events equal to their own events only
            with conn_a.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM engagement_events")
                total_count_from_a = cur.fetchone()[0]

            conn_a.close()

            # Test User B perspective
            conn_b = self._get_connection(self.test_users["user_b"])
            with conn_b.cursor() as cur:
                cur.execute(
                    "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                    (self.test_users["user_b"],),
                )
                user_b_count = cur.fetchone()[0]

            with conn_b.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM engagement_events")
                total_count_from_b = cur.fetchone()[0]

            conn_b.close()

            # Verify isolation
            isolation_passed = (
                user_b_count_from_a == 0  # User A cannot see User B's events
                and total_count_from_a == user_a_count  # User A only sees their events
                and total_count_from_b == user_b_count  # User B only sees their events
                and user_a_count > 0
                and user_b_count > 0  # Both users have events
            )

            details = (
                f"User A sees {user_a_count} own events, {user_b_count_from_a} of User B's events. "
                f"User B sees {user_b_count} own events. Total counts: A={total_count_from_a}, B={total_count_from_b}"
            )

            self._log_test_result("User Isolation (SELECT)", isolation_passed, details)
            return isolation_passed

        except Exception as e:
            self._log_test_result("User Isolation (SELECT)", False, f"Error: {str(e)}")
            return False

    def test_anonymous_access_denied(self):
        """Test 3: Verify anonymous users have no access"""
        try:
            # Connect without user context (anonymous)
            conn = self._get_connection()
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM engagement_events")
                anon_count = cur.fetchone()[0]

            conn.close()

            access_denied = anon_count == 0
            self._log_test_result(
                "Anonymous Access Denied",
                access_denied,
                f"Anonymous user sees {anon_count} events",
            )
            return access_denied

        except Exception as e:
            self._log_test_result("Anonymous Access Denied", False, f"Error: {str(e)}")
            return False

    def test_insert_isolation(self):
        """Test 4: Verify users can only INSERT events for themselves"""
        try:
            test_event_id = str(uuid.uuid4())

            # User A tries to insert event for User B (should fail)
            conn_a = self._get_connection(self.test_users["user_a"])
            insert_failed = False
            try:
                with conn_a.cursor() as cur:
                    cur.execute(
                        """
                        INSERT INTO engagement_events (user_id, event_type, value) 
                        VALUES (%s, %s, %s)
                    """,
                        (
                            self.test_users["user_b"],
                            "test_unauthorized_insert",
                            json.dumps({"test_id": test_event_id}),
                        ),
                    )
            except psycopg2.Error:
                insert_failed = True

            conn_a.close()

            # User A inserts event for themselves (should succeed)
            conn_a = self._get_connection(self.test_users["user_a"])
            insert_succeeded = False
            try:
                with conn_a.cursor() as cur:
                    cur.execute(
                        """
                        INSERT INTO engagement_events (user_id, event_type, value) 
                        VALUES (%s, %s, %s)
                    """,
                        (
                            self.test_users["user_a"],
                            "test_authorized_insert",
                            json.dumps({"test_id": test_event_id}),
                        ),
                    )
                insert_succeeded = True
            except psycopg2.Error:
                pass

            # Verify the authorized event was inserted
            with conn_a.cursor() as cur:
                cur.execute(
                    """
                    SELECT COUNT(*) FROM engagement_events 
                    WHERE event_type = 'test_authorized_insert' 
                    AND value->>'test_id' = %s
                """,
                    (test_event_id,),
                )
                authorized_count = cur.fetchone()[0]

            conn_a.close()

            # Verify User B cannot see the unauthorized event
            conn_b = self._get_connection(self.test_users["user_b"])
            with conn_b.cursor() as cur:
                cur.execute(
                    """
                    SELECT COUNT(*) FROM engagement_events 
                    WHERE value->>'test_id' = %s
                """,
                    (test_event_id,),
                )
                visible_to_b = cur.fetchone()[0]

            conn_b.close()

            isolation_passed = (
                insert_failed  # Unauthorized insert failed
                and insert_succeeded  # Authorized insert succeeded
                and authorized_count == 1  # Event was created
                and visible_to_b == 0  # User B cannot see User A's event
            )

            details = (
                f"Unauthorized insert failed: {insert_failed}, "
                f"Authorized insert succeeded: {insert_succeeded}, "
                f"Event created: {authorized_count}, Visible to other user: {visible_to_b}"
            )

            self._log_test_result("Insert Isolation", isolation_passed, details)
            return isolation_passed

        except Exception as e:
            self._log_test_result("Insert Isolation", False, f"Error: {str(e)}")
            return False

    def test_service_role_access(self):
        """Test 5: Verify service role can access all data (if configured)"""
        try:
            # This test requires service role configuration
            # For now, we'll test with admin/postgres user as a proxy
            conn = self._get_connection()

            # Count total events across all users
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM engagement_events")
                total_events = cur.fetchone()[0]

            # Count events per user
            user_counts = {}
            for user_name, user_id in self.test_users.items():
                with conn.cursor() as cur:
                    cur.execute(
                        "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                        (user_id,),
                    )
                    user_counts[user_name] = cur.fetchone()[0]

            conn.close()

            # Service role should see all events
            expected_total = sum(user_counts.values())
            service_access_works = total_events >= expected_total

            details = (
                f"Service role sees {total_events} events, "
                f"Expected at least {expected_total} from users: {user_counts}"
            )

            self._log_test_result("Service Role Access", service_access_works, details)
            return service_access_works

        except Exception as e:
            self._log_test_result("Service Role Access", False, f"Error: {str(e)}")
            return False

    def test_concurrent_user_sessions(self):
        """Test 6: Verify RLS holds under concurrent access"""
        try:
            import threading
            import time

            results = {"user_a": [], "user_b": [], "errors": []}

            def query_user_events(user_name: str, user_id: str, iterations: int = 5):
                """Query events for a user multiple times"""
                try:
                    for i in range(iterations):
                        conn = self._get_connection(user_id)
                        with conn.cursor() as cur:
                            cur.execute("SELECT COUNT(*) FROM engagement_events")
                            count = cur.fetchone()[0]
                            results[user_name].append(count)
                        conn.close()
                        time.sleep(0.1)  # Small delay between queries
                except Exception as e:
                    results["errors"].append(f"{user_name}: {str(e)}")

            # Start concurrent threads
            thread_a = threading.Thread(
                target=query_user_events, args=("user_a", self.test_users["user_a"])
            )
            thread_b = threading.Thread(
                target=query_user_events, args=("user_b", self.test_users["user_b"])
            )

            thread_a.start()
            thread_b.start()

            thread_a.join()
            thread_b.join()

            # Verify consistent results and no cross-contamination
            # All counts should be same
            user_a_consistent = len(set(results["user_a"])) <= 1
            user_b_consistent = len(set(results["user_b"])) <= 1
            no_errors = len(results["errors"]) == 0
            different_counts = (
                results["user_a"][0] != results["user_b"][0]
                if results["user_a"] and results["user_b"]
                else True
            )

            concurrent_passed = (
                user_a_consistent
                and user_b_consistent
                and no_errors
                and different_counts
            )

            details = (
                f"User A counts: {results['user_a']}, "
                f"User B counts: {results['user_b']}, "
                f"Errors: {len(results['errors'])}"
            )

            self._log_test_result("Concurrent Sessions", concurrent_passed, details)
            return concurrent_passed

        except Exception as e:
            self._log_test_result("Concurrent Sessions", False, f"Error: {str(e)}")
            return False

    def _ensure_audit_setup(self, conn):
        """Ensure _shared schema, audit_log table, and audit() function exist for tests"""
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE SCHEMA IF NOT EXISTS _shared;

                CREATE TABLE IF NOT EXISTS _shared.audit_log (
                    id BIGSERIAL PRIMARY KEY,
                    table_name TEXT,
                    action TEXT,
                    old_row JSONB,
                    new_row JSONB,
                    changed_at TIMESTAMPTZ DEFAULT NOW()
                );

                CREATE OR REPLACE FUNCTION _shared.audit()
                RETURNS TRIGGER
                LANGUAGE plpgsql
                SECURITY DEFINER
                SET search_path = public, pg_temp
                AS $$
                BEGIN
                  INSERT INTO _shared.audit_log(table_name, action, old_row, new_row)
                  VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW));
                  RETURN COALESCE(NEW, OLD);
                END;
                $$;
                """
            )

    def test_audit_log_trigger(self):
        """Test 7: Verify that audit trigger logs changes"""
        try:
            conn = self._get_connection()
            self._ensure_audit_setup(conn)
            with conn.cursor() as cur:
                # Create a lightweight table for audit testing
                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS audit_test (
                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        owner_id UUID NOT NULL
                    );

                    -- Attach audit trigger if not already present
                    DO $$
                    BEGIN
                      IF NOT EXISTS (
                        SELECT 1 FROM pg_trigger WHERE tgname = 'audit_test_trigger'
                      ) THEN
                        CREATE TRIGGER audit_test_trigger
                          AFTER INSERT OR UPDATE OR DELETE ON audit_test
                          FOR EACH ROW EXECUTE PROCEDURE _shared.audit();
                      END IF;
                    END$$;
                    """
                )

                # Baseline count
                cur.execute("SELECT COUNT(*) FROM _shared.audit_log;")
                before_count = cur.fetchone()[0]

                # Perform insert
                cur.execute(
                    "INSERT INTO audit_test(owner_id) VALUES (%s) RETURNING id;",
                    (self.test_users["user_a"],),
                )
                _ = cur.fetchone()[0]

                # Fetch after count
                cur.execute("SELECT COUNT(*) FROM _shared.audit_log;")
                after_count = cur.fetchone()[0]

                passed = after_count == before_count + 1
                self._log_test_result(
                    "Audit Log Trigger",
                    passed,
                    f"Count before={before_count}, after={after_count}",
                )
                return passed
        except Exception as e:
            self._log_test_result(
                "Audit Log Trigger",
                False,
                f"Error: {str(e)}",
            )
            return False

    def run_all_tests(self) -> bool:
        """Run all RLS audit tests and return overall pass/fail"""
        print("=" * 60)
        print("BEE Engagement Events - RLS Audit Test Suite")
        print("=" * 60)
        print(f"Database: {self.db_config['host']}:{self.db_config['port']}")
        print(f"Test Users: {list(self.test_users.keys())}")
        print("-" * 60)

        tests = [
            self.test_table_exists_and_rls_enabled,
            self.test_user_isolation_select,
            self.test_anonymous_access_denied,
            self.test_insert_isolation,
            self.test_service_role_access,
            self.test_concurrent_user_sessions,
            self.test_audit_log_trigger,
        ]

        passed_tests = 0
        total_tests = len(tests)

        for test in tests:
            try:
                if test():
                    passed_tests += 1
            except Exception as e:
                print(f"[ERROR] {test.__name__}: {str(e)}")

        print("-" * 60)
        print(f"Test Results: {passed_tests}/{total_tests} passed")

        # Generate detailed report
        self._generate_audit_report()

        return passed_tests == total_tests

    def _generate_audit_report(self):
        """Generate detailed audit report"""
        report_file = (
            f"rls_audit_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )

        report = {
            "test_suite": "BEE Engagement Events RLS Audit",
            "timestamp": datetime.now().isoformat(),
            "database_config": {
                k: v for k, v in self.db_config.items() if k != "password"
            },
            "test_users": self.test_users,
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

        print(f"Detailed report saved to: tests/db/{report_file}")


def main():
    """Main test execution"""
    tester = RLSAuditTester()
    success = tester.run_all_tests()

    if success:
        print("\n✅ All RLS audit tests PASSED - Zero cross-user leakage confirmed")
        sys.exit(0)
    else:
        print("\n❌ Some RLS audit tests FAILED - Review security policies")
        sys.exit(1)


if __name__ == "__main__":
    main()
