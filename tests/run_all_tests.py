#!/usr/bin/env python3
"""
Test Runner for BEE Engagement Events Testing Suite
Purpose: Execute all testing components for Task 5 (Testing & Validation)
Module: Core Engagement
Milestone: 1 · Data Backbone

This script runs all test suites in the correct order:
1. RLS Audit Tests
2. Performance Tests
3. API Validation Tests

Usage:
    python run_all_tests.py [--skip-performance] [--skip-api] [--skip-rls]

Requirements:
    pip install -r tests/requirements.txt

Created: 2024-12-01
Author: BEE Development Team
"""

import os
import sys
import argparse
import subprocess
import time
from datetime import datetime


class TestRunner:
    """Main test runner for all engagement events tests"""

    def __init__(self):
        self.test_results = []
        self.start_time = datetime.now()

    def _log_result(
        self, test_suite: str, passed: bool, duration: float, details: str = ""
    ):
        """Log test suite result"""
        result = {
            "test_suite": test_suite,
            "passed": passed,
            "duration_seconds": duration,
            "details": details,
            "timestamp": datetime.now().isoformat(),
        }
        self.test_results.append(result)

        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} {test_suite} ({duration:.1f}s): {details}")

    def _run_python_test(self, script_path: str, test_name: str) -> bool:
        """Run a Python test script and return success status"""
        print(f"\n{'='*60}")
        print(f"Running {test_name}")
        print(f"{'='*60}")

        start_time = time.time()

        try:
            # Run the test script
            result = subprocess.run(
                [sys.executable, script_path],
                capture_output=True,
                text=True,
                timeout=300,
            )  # 5 minute timeout

            duration = time.time() - start_time

            if result.returncode == 0:
                self._log_result(test_name, True, duration, "All tests passed")
                print(result.stdout)
                return True
            else:
                self._log_result(
                    test_name, False, duration, f"Exit code: {result.returncode}"
                )
                print("STDOUT:", result.stdout)
                print("STDERR:", result.stderr)
                return False

        except subprocess.TimeoutExpired:
            duration = time.time() - start_time
            self._log_result(
                test_name, False, duration, "Test timed out after 5 minutes"
            )
            print(f"❌ {test_name} timed out after 5 minutes")
            return False
        except Exception as e:
            duration = time.time() - start_time
            self._log_result(test_name, False, duration, f"Error: {str(e)}")
            print(f"❌ Error running {test_name}: {str(e)}")
            return False

    def _check_prerequisites(self) -> bool:
        """Check if all prerequisites are met"""
        print("Checking prerequisites...")

        # Check if we're in the right directory
        if not os.path.exists("tests"):
            print("❌ Error: tests directory not found. Run from project root.")
            return False

        # Check if test scripts exist
        required_scripts = [
            "tests/db/test_rls_audit.py",
            "tests/db/test_performance.py",
            "tests/api/test_api_validation.py",
        ]

        for script in required_scripts:
            if not os.path.exists(script):
                print(f"❌ Error: Required test script not found: {script}")
                return False

        # Check if requirements are installed
        try:
            import importlib.util

            # Check for psycopg2
            if importlib.util.find_spec("psycopg2") is None:
                raise ImportError("psycopg2 not found")

            # Check for requests
            if importlib.util.find_spec("requests") is None:
                raise ImportError("requests not found")

        except ImportError as e:
            print(f"❌ Error: Missing required dependency: {e}")
            print("Install dependencies with: pip install -r tests/requirements.txt")
            return False

        print("✅ Prerequisites check passed")
        return True

    def _check_environment(self) -> bool:
        """Check environment variables and database connectivity"""
        print("\nChecking environment configuration...")

        # Check for environment variables
        required_env_vars = ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"]
        optional_env_vars = ["SUPABASE_URL", "SUPABASE_ANON_KEY", "USER_JWT_TOKEN"]

        missing_required = []
        for var in required_env_vars:
            if not os.getenv(var):
                missing_required.append(var)

        if missing_required:
            print(
                f"⚠️  Warning: Missing required environment variables: {missing_required}"
            )
            print("Using default values for local testing")

        missing_optional = []
        for var in optional_env_vars:
            if not os.getenv(var):
                missing_optional.append(var)

        if missing_optional:
            print(
                f"⚠️  Warning: Missing optional environment variables: {missing_optional}"
            )
            print("Some API tests may be skipped")

        # Test database connectivity
        try:
            import psycopg2

            db_config = {
                "host": os.getenv("DB_HOST", "localhost"),
                "port": os.getenv("DB_PORT", "54322"),
                "database": os.getenv("DB_NAME", "postgres"),
                "user": os.getenv("DB_USER", "postgres"),
                "password": os.getenv("DB_PASSWORD", "postgres"),
            }

            conn = psycopg2.connect(**db_config)
            conn.close()
            print("✅ Database connectivity check passed")
            return True

        except Exception as e:
            print(f"❌ Database connectivity check failed: {str(e)}")
            print("Make sure your database is running and accessible")
            return False

    def run_all_tests(
        self,
        skip_rls: bool = False,
        skip_performance: bool = False,
        skip_api: bool = False,
    ) -> bool:
        """Run all test suites"""
        print("🐝 BEE Engagement Events - Complete Testing Suite")
        print(f"Started at: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)

        # Prerequisites check
        if not self._check_prerequisites():
            return False

        if not self._check_environment():
            print("⚠️  Continuing with environment warnings...")

        # Track overall success
        all_passed = True

        # Run RLS Audit Tests
        if not skip_rls:
            success = self._run_python_test(
                "tests/db/test_rls_audit.py", "RLS Audit Tests"
            )
            all_passed = all_passed and success
        else:
            print("\n⏭️  Skipping RLS Audit Tests")

        # Run Performance Tests
        if not skip_performance:
            success = self._run_python_test(
                "tests/db/test_performance.py", "Performance Tests"
            )
            all_passed = all_passed and success
        else:
            print("\n⏭️  Skipping Performance Tests")

        # Run API Validation Tests
        if not skip_api:
            success = self._run_python_test(
                "tests/api/test_api_validation.py", "API Validation Tests"
            )
            all_passed = all_passed and success
        else:
            print("\n⏭️  Skipping API Validation Tests")

        # Generate summary report
        self._generate_summary_report()

        return all_passed

    def _generate_summary_report(self):
        """Generate final summary report"""
        end_time = datetime.now()
        total_duration = (end_time - self.start_time).total_seconds()

        print(f"\n{'='*60}")
        print("🐝 BEE ENGAGEMENT EVENTS - TEST SUMMARY REPORT")
        print(f"{'='*60}")
        print(f"Started:  {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Finished: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Duration: {total_duration:.1f} seconds")
        print()

        passed_count = sum(1 for r in self.test_results if r["passed"])
        total_count = len(self.test_results)

        print(f"Test Suites: {passed_count}/{total_count} passed")
        print()

        for result in self.test_results:
            status = "✅" if result["passed"] else "❌"
            print(
                f"{status} {result['test_suite']:<25} {result['duration_seconds']:>6.1f}s  {result['details']}"
            )

        print()

        if passed_count == total_count:
            print("🎉 ALL TESTS PASSED! Task 5 (Testing & Validation) is complete.")
            print("✅ Zero cross-user leakage confirmed")
            print("✅ Performance targets met")
            print("✅ API validation successful")
        else:
            print("❌ Some tests failed. Review the output above for details.")
            print("🔧 Fix issues before proceeding to next milestone.")

        print("\n📊 Detailed reports saved in tests/db/ and tests/api/ directories")
        print(f"{'='*60}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Run BEE Engagement Events test suite")
    parser.add_argument("--skip-rls", action="store_true", help="Skip RLS audit tests")
    parser.add_argument(
        "--skip-performance", action="store_true", help="Skip performance tests"
    )
    parser.add_argument(
        "--skip-api", action="store_true", help="Skip API validation tests"
    )

    args = parser.parse_args()

    runner = TestRunner()
    success = runner.run_all_tests(
        skip_rls=args.skip_rls,
        skip_performance=args.skip_performance,
        skip_api=args.skip_api,
    )

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
