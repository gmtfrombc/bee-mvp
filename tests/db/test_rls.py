#!/usr/bin/env python3
"""
Minimal RLS Test Script for Engagement Events

This script tests basic Row-Level Security functionality for the engagement_events table.
It connects to a local PostgreSQL database and verifies that users can only access their own data.

Requirements:
- PostgreSQL running locally (auto-detects local vs CI environment)
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
import os
import getpass


class TestEngagementEventsRLS:
    """Test Row-Level Security for engagement_events table"""

    @classmethod
    def setup_class(cls):
        """Set up test database connection with environment detection"""

        # Environment detection: CI vs Local
        is_ci = os.getenv("CI") or os.getenv("GITHUB_ACTIONS")
        current_user = getpass.getuser()

        if is_ci:
            # CI environment (GitHub Actions) - use postgres user directly
            db_user = "postgres"
            db_password = "postgres"
            db_name = "test"
            print("🤖 CI Environment detected - using postgres user")

            # In CI, test with the postgres user directly
            cls.admin_conn = None  # Not needed in CI
            cls.test_user = db_user

        else:
            # Local development environment - use admin + non-superuser approach
            admin_user = current_user  # Use current system user (e.g., gmtfr)
            db_name = "test"
            print(
                f"💻 Local Environment detected - using admin '{admin_user}' + test user 'rls_test_user'"
            )

            # First, connect as admin to ensure non-superuser role exists
            try:
                cls.admin_conn = psycopg2.connect(
                    host="localhost",
                    user=admin_user,
                    database=db_name,
                )
                cls.admin_conn.autocommit = True

                # Create/verify the non-superuser role for testing
                admin_cursor = cls.admin_conn.cursor()
                admin_cursor.execute(
                    """
                    DO $$
                    BEGIN
                        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rls_test_user') THEN
                            CREATE ROLE rls_test_user WITH LOGIN NOSUPERUSER;
                        END IF;
                        
                        -- Grant necessary permissions
                        GRANT USAGE ON SCHEMA auth TO rls_test_user;
                        GRANT USAGE ON SCHEMA public TO rls_test_user;
                        GRANT SELECT, INSERT, UPDATE, DELETE ON auth.users TO rls_test_user;
                        GRANT SELECT, INSERT, UPDATE, DELETE ON engagement_events TO rls_test_user;
                        GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rls_test_user;
                        GRANT USAGE ON ALL SEQUENCES IN SCHEMA auth TO rls_test_user;
                    END $$;
                """
                )
                print("✅ Created/verified non-superuser role 'rls_test_user'")

            except psycopg2.Error as e:
                print(f"❌ Admin connection failed: {e}")
                raise

            # Use the non-superuser for actual testing
            db_user = "rls_test_user"
            db_password = None
            cls.test_user = db_user

        # Connect as the test user (postgres in CI, rls_test_user locally)
        try:
            connection_params = {
                "host": "localhost",
                "user": db_user,
                "database": db_name,
            }

            # Only add password if it's set (CI needs it, local doesn't)
            if db_password:
                connection_params["password"] = db_password

            cls.conn = psycopg2.connect(**connection_params)
            cls.conn.autocommit = True
            print(f"✅ Connected to PostgreSQL as '{db_user}' on database '{db_name}'")

            # Test auth.uid() function to ensure it works
            cursor = cls.conn.cursor()
            cursor.execute("SELECT auth.uid() IS NULL as no_auth_context")
            no_auth = cursor.fetchone()[0]

            if no_auth:
                print("✅ auth.uid() returns NULL without context (expected)")
            else:
                print("⚠️  WARNING: auth.uid() returns value without context")

        except psycopg2.OperationalError as e:
            print(f"❌ Test user connection failed: {e}")
            print("🔧 Troubleshooting:")
            print("   - Ensure PostgreSQL is running locally")
            print("   - For local testing: Create test database with: createdb test")
            print("   - Run database setup: ./scripts/test_database_only.sh")
            if not is_ci:
                print("   - Run: psql -d test -f setup_ci_exact.sql")
            raise

        # Test user IDs
        cls.user_a_id = "11111111-1111-1111-1111-111111111111"
        cls.user_b_id = "22222222-2222-2222-2222-222222222222"

    @classmethod
    def teardown_class(cls):
        """Clean up database connections"""
        cls.conn.close()
        if hasattr(cls, "admin_conn") and cls.admin_conn:
            cls.admin_conn.close()

    def test_rls_user_isolation(self):
        """Test that user A cannot see user B's events"""

        # For local testing, use admin connection for setup; for CI, use main connection
        if hasattr(self, "admin_conn") and self.admin_conn:
            # Local environment: use admin for setup, test user for RLS verification
            setup_cursor = self.admin_conn.cursor()
            test_cursor = self.conn.cursor()
            print("🔧 Using admin connection for setup, test user for RLS verification")
        else:
            # CI environment: use same connection for both
            setup_cursor = self.conn.cursor()
            test_cursor = self.conn.cursor()
            print("🤖 Using postgres user for both setup and testing (CI environment)")

        try:
            # Clean up any existing test data first (use admin/setup connection)
            setup_cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

            # Step 1: Insert events for BOTH users using admin/setup connection
            # This bypasses RLS for test data setup
            setup_cursor.execute("RESET request.jwt.claims")

            setup_cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_event_user_a', '{"test": "user_a_data"}')
            """,
                (self.user_a_id,),
            )

            setup_cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_event_user_b', '{"test": "user_b_data"}')
            """,
                (self.user_b_id,),
            )

            # Verify both events were inserted (check with admin/setup connection)
            setup_cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )
            total_events = setup_cursor.fetchone()[0]
            assert total_events == 2, f"Expected 2 events inserted, got {total_events}"
            print(f"✅ Test data setup: {total_events} events inserted")

            # Step 2: Test User A isolation using test connection (enforces RLS)
            # Clear any previous auth state
            test_cursor.execute("RESET request.jwt.claims")
            test_cursor.execute(
                """
                SET request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_a_id}"}}',),
            )

            # User A should see only their own event (1 event)
            test_cursor.execute("SELECT COUNT(*) FROM engagement_events")
            user_a_total_visible = test_cursor.fetchone()[0]
            print(f"🔍 User A sees {user_a_total_visible} events (should be 1)")
            assert (
                user_a_total_visible == 1
            ), f"User A should see only 1 event, saw {user_a_total_visible}"

            # User A should see their specific event
            test_cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_a_id,),
            )
            user_a_own_count = test_cursor.fetchone()[0]
            assert user_a_own_count == 1, "User A should see their own event"

            # User A should NOT see user B's events (critical security test)
            test_cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_b_id,),
            )
            user_b_from_a_count = test_cursor.fetchone()[0]
            assert user_b_from_a_count == 0, "User A should not see user B's events"

            # Step 3: Test User B isolation
            # Clear User A context
            test_cursor.execute("RESET request.jwt.claims")
            test_cursor.execute(
                """
                SET request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_b_id}"}}',),
            )

            # User B should see only their own event (1 event)
            test_cursor.execute("SELECT COUNT(*) FROM engagement_events")
            user_b_total_visible = test_cursor.fetchone()[0]
            print(f"🔍 User B sees {user_b_total_visible} events (should be 1)")
            assert (
                user_b_total_visible == 1
            ), f"User B should see only 1 event, saw {user_b_total_visible}"

            # User B should see their specific event
            test_cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_b_id,),
            )
            user_b_own_count = test_cursor.fetchone()[0]
            assert user_b_own_count == 1, "User B should see their own event"

            # User B should NOT see user A's events (critical security test)
            test_cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_a_id,),
            )
            user_a_from_b_count = test_cursor.fetchone()[0]
            assert user_a_from_b_count == 0, "User B should not see user A's events"

            print("✅ RLS user isolation test PASSED!")

        finally:
            # Clean up test data using admin/setup connection
            setup_cursor.execute("RESET request.jwt.claims")
            setup_cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

    def test_rls_insert_policy(self):
        """Test that users can only insert events for themselves"""

        # For local testing, use admin connection for setup; for CI, use main connection
        if hasattr(self, "admin_conn") and self.admin_conn:
            # Local environment: use admin for setup, test user for RLS verification
            setup_cursor = self.admin_conn.cursor()
            test_cursor = self.conn.cursor()
            print("🔧 Using admin connection for setup, test user for RLS verification")
        else:
            # CI environment: use same connection for both
            setup_cursor = self.conn.cursor()
            test_cursor = self.conn.cursor()
            print("🤖 Using postgres user for both setup and testing (CI environment)")

        try:
            # Clean up any existing test data first (use admin/setup connection)
            setup_cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

            # Step 1: Test authorized insert (User A inserting for themselves)
            test_cursor.execute("RESET request.jwt.claims")
            test_cursor.execute(
                """
                SET request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_a_id}"}}',),
            )

            # User A should be able to insert for themselves
            test_cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_authorized_insert', '{"test": "authorized"}')
            """,
                (self.user_a_id,),
            )

            # Verify the authorized insert worked
            test_cursor.execute(
                """
                SELECT COUNT(*) FROM engagement_events 
                WHERE user_id = %s AND event_type = 'test_authorized_insert'
            """,
                (self.user_a_id,),
            )
            authorized_count = test_cursor.fetchone()[0]
            assert (
                authorized_count == 1
            ), "User should be able to insert their own events"
            print("✅ User A successfully inserted their own event")

            # Step 2: Test unauthorized insert (User A trying to insert for User B)
            # This should fail with a database error due to RLS policy violation
            insert_failed = False

            try:
                test_cursor.execute(
                    """
                    INSERT INTO engagement_events (user_id, event_type, value)
                    VALUES (%s, 'test_unauthorized_insert', '{"test": "should_fail"}')
                """,
                    (self.user_b_id,),
                )
                # If we reach here, the unauthorized insert succeeded (SECURITY BUG!)
                insert_failed = False
            except psycopg2.Error:
                # This is expected - unauthorized insert should fail
                insert_failed = True

            assert (
                insert_failed
            ), "Unauthorized insert should have failed but succeeded. This is a CRITICAL SECURITY BUG!"
            print("✅ Unauthorized insert correctly failed")

            # Step 3: Verify no unauthorized data was inserted (use admin context)
            setup_cursor.execute("RESET request.jwt.claims")
            setup_cursor.execute(
                """
                SELECT COUNT(*) FROM engagement_events 
                WHERE user_id = %s AND event_type = 'test_unauthorized_insert'
            """,
                (self.user_b_id,),
            )
            unauthorized_count = setup_cursor.fetchone()[0]
            assert (
                unauthorized_count == 0
            ), "No unauthorized events should exist in database"

            # Step 4: Test that User B can insert for themselves
            test_cursor.execute("RESET request.jwt.claims")
            test_cursor.execute(
                """
                SET request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_b_id}"}}',),
            )

            test_cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_user_b_insert', '{"test": "user_b_authorized"}')
            """,
                (self.user_b_id,),
            )

            # Verify User B's insert worked
            test_cursor.execute(
                """
                SELECT COUNT(*) FROM engagement_events 
                WHERE user_id = %s AND event_type = 'test_user_b_insert'
            """,
                (self.user_b_id,),
            )
            user_b_count = test_cursor.fetchone()[0]
            assert user_b_count == 1, "User B should be able to insert their own events"

            # Step 5: Verify cross-user isolation of inserts
            # User B should not see User A's event, and vice versa
            test_cursor.execute("SELECT COUNT(*) FROM engagement_events")
            user_b_visible_total = test_cursor.fetchone()[0]
            assert (
                user_b_visible_total == 1
            ), f"User B should only see 1 event (their own), saw {user_b_visible_total}"

            print("✅ RLS insert policy test PASSED!")

        finally:
            # Clean up test data (use admin/setup connection)
            setup_cursor.execute("RESET request.jwt.claims")
            setup_cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

    def test_anonymous_access_denied(self):
        """Test that anonymous users cannot access any events"""

        # For local testing, use admin connection for setup; for CI, use main connection
        if hasattr(self, "admin_conn") and self.admin_conn:
            # Local environment: use admin for setup, test user for RLS verification
            setup_cursor = self.admin_conn.cursor()
            test_cursor = self.conn.cursor()
            print("🔧 Using admin connection for setup, test user for RLS verification")
        else:
            # CI environment: use same connection for both
            setup_cursor = self.conn.cursor()
            test_cursor = self.conn.cursor()
            print("🤖 Using postgres user for both setup and testing (CI environment)")

        try:
            # Clean up any existing test data first (use admin/setup connection)
            setup_cursor.execute(
                "DELETE FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )

            # Step 1: Insert test events for both users using admin connection
            setup_cursor.execute("RESET request.jwt.claims")

            setup_cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_anon_data_a', '{"test": "should_be_hidden"}')
            """,
                (self.user_a_id,),
            )

            setup_cursor.execute(
                """
                INSERT INTO engagement_events (user_id, event_type, value)
                VALUES (%s, 'test_anon_data_b', '{"test": "should_be_hidden"}')
            """,
                (self.user_b_id,),
            )

            # Verify test data was inserted (should see 2 events as admin)
            setup_cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id IN (%s, %s)",
                (self.user_a_id, self.user_b_id),
            )
            admin_count = setup_cursor.fetchone()[0]
            assert admin_count == 2, f"Expected 2 test events, got {admin_count}"
            print(f"✅ Test data setup: {admin_count} events inserted")

            # Step 2: Test anonymous SELECT access (should see nothing)
            # Empty claims = anonymous
            test_cursor.execute("RESET request.jwt.claims")
            test_cursor.execute("SET request.jwt.claims = '{}'")

            # Anonymous user should see 0 events (critical security test)
            test_cursor.execute("SELECT COUNT(*) FROM engagement_events")
            anon_count = test_cursor.fetchone()[0]
            print(f"🔍 Anonymous user sees {anon_count} events (should be 0)")
            assert (
                anon_count == 0
            ), f"Anonymous users should not see any events, saw {anon_count} events. CRITICAL SECURITY BUG!"

            # Test specific queries that anonymous users should not access
            test_cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_a_id,),
            )
            anon_user_a_count = test_cursor.fetchone()[0]
            assert (
                anon_user_a_count == 0
            ), "Anonymous users should not see User A's events"

            test_cursor.execute(
                "SELECT COUNT(*) FROM engagement_events WHERE user_id = %s",
                (self.user_b_id,),
            )
            anon_user_b_count = test_cursor.fetchone()[0]
            assert (
                anon_user_b_count == 0
            ), "Anonymous users should not see User B's events"

            # Step 3: Test anonymous INSERT access (should fail)
            insert_failed = False
            try:
                test_cursor.execute(
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

            assert (
                insert_failed
            ), "Anonymous users should not be able to insert events. CRITICAL SECURITY BUG!"
            print("✅ Anonymous insert correctly failed")

            # Step 4: Verify no anonymous data was inserted (use admin context)
            setup_cursor.execute("RESET request.jwt.claims")
            setup_cursor.execute(
                """
                SELECT COUNT(*) FROM engagement_events 
                WHERE event_type = 'test_anon_insert'
            """
            )
            anon_insert_count = setup_cursor.fetchone()[0]
            assert (
                anon_insert_count == 0
            ), "No anonymous events should exist in database"

            # Step 5: Verify data still exists and users can still access their own data
            # Test that User A can still see their event
            test_cursor.execute("RESET request.jwt.claims")
            test_cursor.execute(
                """
                SET request.jwt.claims = %s
            """,
                (f'{{"sub": "{self.user_a_id}"}}',),
            )

            test_cursor.execute("SELECT COUNT(*) FROM engagement_events")
            user_a_count = test_cursor.fetchone()[0]
            assert (
                user_a_count == 1
            ), "User A should still be able to see their own event after anonymous test"

            print("✅ RLS anonymous access test PASSED!")

        finally:
            # Clean up test data (use admin/setup connection)
            setup_cursor.execute("RESET request.jwt.claims")
            setup_cursor.execute(
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
