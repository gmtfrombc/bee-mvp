#!/usr/bin/env python3
"""
Minimal RLS Test Script for Engagement Events

This script tests basic Row-Level Security functionality for the engagement_events table.
It connects to a local PostgreSQL database and verifies that users can only access their own data.

Requirements:
- PostgreSQL running locally (host=localhost, user=postgres, db=test)
- engagement_events table with RLS policies enabled
- Python dependencies installed: pip install -r tests/requirements-minimal.txt

Usage:
    # Install dependencies first (recommended: use virtual environment)
    python3 -m venv venv
    source venv/bin/activate
    pip install -r tests/requirements-minimal.txt

    # Run tests
    python test_rls.py
    pytest test_rls.py
"""

import psycopg2
import pytest


class TestEngagementEventsRLS:
    """Test Row-Level Security for engagement_events table"""

    @classmethod
    def setup_class(cls):
        """Set up test database connection"""
        cls.conn = psycopg2.connect(
            host="localhost",
            user="postgres",
            database="test",
            password="postgres",  # Default for CI environment
        )
        cls.conn.autocommit = True

        # Test user IDs
        cls.user_a_id = "11111111-1111-1111-1111-111111111111"
        cls.user_b_id = "22222222-2222-2222-2222-222222222222"

    @classmethod
    def teardown_class(cls):
        """Clean up database connection"""
        cls.conn.close()

    def test_rls_user_isolation(self):
        """Test that user A cannot see user B's events"""
        cursor = self.conn.cursor()

        try:
            # Clean up any existing test data first
            cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

            # Step 1: Insert events for BOTH users (without RLS context)
            # Use service role context to bypass RLS for test setup
            cursor.execute("RESET request.jwt.claims")

            cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_event_user_a', '{"test": "user_a_data"}')
            """,
                (self.user_a_id,),
            )

            cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_event_user_b', '{"test": "user_b_data"}')
            """,
                (self.user_b_id,),
            )

            # Verify both events were inserted (should see 2 total without RLS context)
            cursor.execute("SELECT COUNT(*) FROM engagement_events WHERE user_id IN (%s, %s)",
                           (self.user_a_id, self.user_b_id))
            total_events = cursor.fetchone()[0]
            assert total_events == 2, f"Expected 2 events inserted, got {total_events}"

            # Step 2: Test User A isolation
            cursor.execute(
                """
                SET LOCAL request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_a_id}"}}',),
            )

            # User A should see only their own event (1 event)
            cursor.execute("SELECT COUNT(*) FROM engagement_events")
            user_a_total_visible = cursor.fetchone()[0]
            assert user_a_total_visible == 1, f"User A should see only 1 event, saw {user_a_total_visible}"

            # User A should see their specific event
            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_a_id,),
            )
            user_a_own_count = cursor.fetchone()[0]
            assert user_a_own_count == 1, "User A should see their own event"

            # User A should NOT see user B's events (critical security test)
            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_b_id,),
            )
            user_b_from_a_count = cursor.fetchone()[0]
            assert user_b_from_a_count == 0, "User A should not see user B's events"

            # Step 3: Test User B isolation
            cursor.execute(
                """
                SET LOCAL request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_b_id}"}}',),
            )

            # User B should see only their own event (1 event)
            cursor.execute("SELECT COUNT(*) FROM engagement_events")
            user_b_total_visible = cursor.fetchone()[0]
            assert user_b_total_visible == 1, f"User B should see only 1 event, saw {user_b_total_visible}"

            # User B should see their specific event
            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_b_id,),
            )
            user_b_own_count = cursor.fetchone()[0]
            assert user_b_own_count == 1, "User B should see their own event"

            # User B should NOT see user A's events (critical security test)
            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_a_id,),
            )
            user_a_from_b_count = cursor.fetchone()[0]
            assert user_a_from_b_count == 0, "User B should not see user A's events"

        finally:
            # Clean up test data
            # Remove RLS context for cleanup
            cursor.execute("RESET request.jwt.claims")
            cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

    def test_rls_insert_policy(self):
        """Test that users can only insert events for themselves"""
        cursor = self.conn.cursor()

        try:
            # Clean up any existing test data first
            cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

            # Step 1: Test authorized insert (User A inserting for themselves)
            cursor.execute(
                """
                SET LOCAL request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_a_id}"}}',),
            )

            # User A should be able to insert for themselves
            cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_authorized_insert', '{"test": "authorized"}')
            """,
                (self.user_a_id,),
            )

            # Verify the authorized insert worked
            cursor.execute(
                """
                SELECT COUNT(*) FROM engagement_events 
                WHERE user_id = %s AND event_type = 'test_authorized_insert'
            """,
                (self.user_a_id,),
            )
            authorized_count = cursor.fetchone()[0]
            assert authorized_count == 1, "User should be able to insert their own events"

            # Step 2: Test unauthorized insert (User A trying to insert for User B)
            # This should fail with a database error due to RLS policy violation
            insert_failed = False
            error_message = ""

            try:
                cursor.execute(
                    """
                    INSERT INTO engagement_events (user_id, event_type, value)
                    VALUES (%s, 'test_unauthorized_insert', '{"test": "should_fail"}')
                """,
                    (self.user_b_id,),
                )
                # If we reach here, the unauthorized insert succeeded (SECURITY BUG!)
                insert_failed = False
            except psycopg2.Error as e:
                # This is expected - unauthorized insert should fail
                insert_failed = True
                error_message = str(e)

            assert insert_failed, f"Unauthorized insert should have failed but succeeded. This is a CRITICAL SECURITY BUG!"

            # Step 3: Verify no unauthorized data was inserted
            # Reset to admin context to check all data
            cursor.execute("RESET request.jwt.claims")

            cursor.execute(
                """
                SELECT COUNT(*) FROM engagement_events 
                WHERE user_id = %s AND event_type = 'test_unauthorized_insert'
            """,
                (self.user_b_id,),
            )
            unauthorized_count = cursor.fetchone()[0]
            assert unauthorized_count == 0, "No unauthorized events should exist in database"

            # Step 4: Test that User B can insert for themselves
            cursor.execute(
                """
                SET LOCAL request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_b_id}"}}',),
            )

            cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_user_b_insert', '{"test": "user_b_authorized"}')
            """,
                (self.user_b_id,),
            )

            # Verify User B's insert worked
            cursor.execute(
                """
                SELECT COUNT(*) FROM engagement_events 
                WHERE user_id = %s AND event_type = 'test_user_b_insert'
            """,
                (self.user_b_id,),
            )
            user_b_count = cursor.fetchone()[0]
            assert user_b_count == 1, "User B should be able to insert their own events"

            # Step 5: Verify cross-user isolation of inserts
            # User B should not see User A's event, and vice versa
            cursor.execute("SELECT COUNT(*) FROM engagement_events")
            user_b_visible_total = cursor.fetchone()[0]
            assert user_b_visible_total == 1, f"User B should only see 1 event (their own), saw {user_b_visible_total}"

        finally:
            # Clean up test data (use admin context)
            cursor.execute("RESET request.jwt.claims")
            cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

    def test_anonymous_access_denied(self):
        """Test that anonymous users cannot access any events"""
        cursor = self.conn.cursor()

        try:
            # Clean up any existing test data first
            cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

            # Step 1: Insert test events for both users (using admin context)
            # Ensure no user context
            cursor.execute("RESET request.jwt.claims")

            cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_anon_data_a', '{"test": "should_be_hidden"}')
            """,
                (self.user_a_id,),
            )

            cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_anon_data_b', '{"test": "should_be_hidden"}')
            """,
                (self.user_b_id,),
            )

            # Verify test data was inserted (should see 2 events as admin)
            cursor.execute("SELECT COUNT(*) FROM engagement_events WHERE user_id IN (%s, %s)",
                           (self.user_a_id, self.user_b_id))
            admin_count = cursor.fetchone()[0]
            assert admin_count == 2, f"Expected 2 test events, got {admin_count}"

            # Step 2: Test anonymous SELECT access (should see nothing)
            # Empty claims = anonymous
            cursor.execute("SET LOCAL request.jwt.claims = '{}'")

            # Anonymous user should see 0 events (critical security test)
            cursor.execute("SELECT COUNT(*) FROM engagement_events")
            anon_count = cursor.fetchone()[0]
            assert anon_count == 0, f"Anonymous users should not see any events, saw {anon_count} events. CRITICAL SECURITY BUG!"

            # Test specific queries that anonymous users should not access
            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s", (self.user_a_id,))
            anon_user_a_count = cursor.fetchone()[0]
            assert anon_user_a_count == 0, "Anonymous users should not see User A's events"

            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s", (self.user_b_id,))
            anon_user_b_count = cursor.fetchone()[0]
            assert anon_user_b_count == 0, "Anonymous users should not see User B's events"

            # Step 3: Test anonymous INSERT access (should fail)
            insert_failed = False
            try:
                cursor.execute(
                    """
                    INSERT INTO engagement_events (user_id, event_type, value)
                    VALUES (%s, 'test_anon_insert', '{"test": "should_fail"}')
                """,
                    (self.user_a_id,),
                )
                # If we reach here, anonymous insert succeeded (SECURITY BUG!)
                insert_failed = False
            except psycopg2.Error:
                # This is expected - anonymous insert should fail
                insert_failed = True

            assert insert_failed, "Anonymous users should not be able to insert events. CRITICAL SECURITY BUG!"

            # Step 4: Verify no anonymous data was inserted
            cursor.execute("RESET request.jwt.claims")  # Admin context
            cursor.execute(
                """
                SELECT COUNT(*) FROM engagement_events 
                WHERE event_type = 'test_anon_insert'
            """
            )
            anon_insert_count = cursor.fetchone()[0]
            assert anon_insert_count == 0, "No anonymous events should exist in database"

            # Step 5: Verify data still exists and users can still access their own data
            # Test that User A can still see their event
            cursor.execute(
                """
                SET LOCAL request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_a_id}"}}',),
            )

            cursor.execute("SELECT COUNT(*) FROM engagement_events")
            user_a_count = cursor.fetchone()[0]
            assert user_a_count == 1, "User A should still be able to see their own event after anonymous test"

        finally:
            # Clean up test data (use admin context)
            cursor.execute("RESET request.jwt.claims")
            cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )


def main():
    """Run tests when script is executed directly"""
    print("Running minimal RLS tests for engagement_events...")

    try:
        # Create test instance and run tests
        test_instance = TestEngagementEventsRLS()
        test_instance.setup_class()

        print("✓ Testing user isolation...")
        test_instance.test_rls_user_isolation()

        print("✓ Testing insert policy...")
        test_instance.test_rls_insert_policy()

        print("✓ Testing anonymous access...")
        test_instance.test_anonymous_access_denied()

        test_instance.teardown_class()

        print("\n🎉 All RLS tests passed!")

    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        raise


if __name__ == "__main__":
    main()
