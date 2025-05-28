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
import uuid
from datetime import datetime


class TestEngagementEventsRLS:
    """Test Row-Level Security for engagement_events table"""

    @classmethod
    def setup_class(cls):
        """Set up test database connection"""
        cls.conn = psycopg2.connect(
            host="localhost",
            user="postgres",
            database="test",
            password="postgres"  # Default for CI environment
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
            # Insert event for user A
            cursor.execute("""
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_event', '{"test": true}')
            """, (self.user_a_id,))

            # Set session to user A context
            cursor.execute("""
                SET LOCAL request.jwt.claims = %s
            """, (f'{{"sub": "{self.user_a_id}"}}',))

            # User A should see their own event
            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s", (self.user_a_id,))
            user_a_count = cursor.fetchone()[0]
            assert user_a_count >= 1, "User A should see their own events"

            # User A should NOT see user B's events (if any exist)
            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s", (self.user_b_id,))
            user_b_count = cursor.fetchone()[0]
            assert user_b_count == 0, "User A should not see user B's events"

            # Switch to user B context
            cursor.execute("""
                SET LOCAL request.jwt.claims = %s
            """, (f'{{"sub": "{self.user_b_id}"}}',))

            # User B should NOT see user A's events
            cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s", (self.user_a_id,))
            user_a_from_b_count = cursor.fetchone()[0]
            assert user_a_from_b_count == 0, "User B should not see user A's events"

        finally:
            # Clean up test data
            cursor.execute("DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                           (self.user_a_id, self.user_b_id))

    def test_rls_insert_policy(self):
        """Test that users can only insert events for themselves"""
        cursor = self.conn.cursor()

        try:
            # Set session to user A context
            cursor.execute("""
                SET LOCAL request.jwt.claims = %s
            """, (f'{{"sub": "{self.user_a_id}"}}',))

            # User A should be able to insert for themselves
            cursor.execute("""
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_insert', '{"test": "insert"}')
            """, (self.user_a_id,))

            # Verify the insert worked
            cursor.execute("""
                SELECT COUNT(*) FROM engagement_events 
                WHERE user_id = %s AND event_type = 'test_insert'
            """, (self.user_a_id,))
            count = cursor.fetchone()[0]
            assert count >= 1, "User should be able to insert their own events"

            # User A should NOT be able to insert for user B
            with pytest.raises(psycopg2.Error):
                cursor.execute("""
                    INSERT INTO engagement_events (user_id, event_type, value)
                    VALUES (%s, 'test_insert_forbidden', '{"test": "forbidden"}')
                """, (self.user_b_id,))

        finally:
            # Clean up test data
            cursor.execute("DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                           (self.user_a_id, self.user_b_id))

    def test_anonymous_access_denied(self):
        """Test that anonymous users cannot access any events"""
        cursor = self.conn.cursor()

        try:
            # Insert test event
            cursor.execute("""
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_anon', '{"test": "anonymous"}')
            """, (self.user_a_id,))

            # Clear user context (simulate anonymous access)
            cursor.execute("SET LOCAL request.jwt.claims = '{}'")

            # Anonymous user should see 0 events
            cursor.execute("SELECT COUNT(*) FROM engagement_events")
            count = cursor.fetchone()[0]
            assert count == 0, "Anonymous users should not see any events"

        finally:
            # Clean up test data
            cursor.execute(
                "DELETE FROM engagement_events WHERE user_id = %s", (self.user_a_id,))


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
