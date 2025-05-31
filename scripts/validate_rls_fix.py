#!/usr/bin/env python3
"""
RLS Fix Validation Script

This script validates that the RLS test fix properly detects superuser vs non-superuser
connections and uses the correct roles in different environments.
"""

import psycopg2
import os
import getpass


def test_connection_logic():
    """Test the connection logic used in RLS tests"""

    # Simulate CI environment detection
    is_ci = os.getenv("CI") or os.getenv("GITHUB_ACTIONS")
    current_user = getpass.getuser()

    print("🔍 Environment Detection:")
    print(f"   - is_ci: {is_ci}")
    print(f"   - current_user: {current_user}")
    print()

    if is_ci:
        print("🤖 CI Environment - Testing rls_test_user connection...")
        db_user = "rls_test_user"
        db_password = "postgres"
    else:
        print("💻 Local Environment - Testing rls_test_user connection...")
        db_user = "rls_test_user"
        db_password = None

    # Test connection
    try:
        connection_params = {
            "host": "localhost",
            "user": db_user,
            "database": "test",
        }

        if db_password:
            connection_params["password"] = db_password

        conn = psycopg2.connect(**connection_params)
        conn.autocommit = True

        cursor = conn.cursor()

        # Check superuser status
        cursor.execute("SELECT current_setting('is_superuser')")
        is_superuser = cursor.fetchone()[0] == "on"

        # Check role name
        cursor.execute("SELECT current_user")
        current_role = cursor.fetchone()[0]

        # Check if RLS is enabled on engagement_events
        cursor.execute(
            """
            SELECT relrowsecurity 
            FROM pg_class 
            WHERE relname = 'engagement_events'
        """
        )
        result = cursor.fetchone()
        rls_enabled = result[0] if result else False

        print("✅ Connection successful!")
        print(f"   - Connected as: {current_role}")
        print(f"   - Is superuser: {is_superuser}")
        print(f"   - RLS enabled on engagement_events: {rls_enabled}")

        if is_superuser:
            print("🚨 WARNING: Connected as superuser - RLS will be bypassed!")
            return False
        else:
            print("✅ Connected as regular user - RLS will be enforced")
            return True

        conn.close()

    except psycopg2.Error as e:
        print(f"❌ Connection failed: {e}")
        return False


if __name__ == "__main__":
    print("🧪 RLS Fix Validation")
    print("=" * 50)

    success = test_connection_logic()

    if success:
        print("\n✅ RLS fix validation PASSED - Non-superuser connection working!")
    else:
        print("\n❌ RLS fix validation FAILED - Superuser bypass detected!")
        exit(1)
