#!/usr/bin/env python3
"""
API Validation Tests for Engagement Events
Purpose: Test all CRUD operations, error responses, and API behavior
Module: Core Engagement
Milestone: 1 · Data Backbone

This script validates the REST and GraphQL APIs for engagement_events,
including authentication, authorization, error handling, and rate limiting.

Usage:
    python test_api_validation.py

Requirements:
    pip install requests python-dotenv

Created: 2024-12-01
Author: BEE Development Team
"""

import os
import sys
import requests
import json
import uuid
from datetime import datetime, timedelta
from typing import Dict, Tuple
from concurrent.futures import ThreadPoolExecutor, as_completed

# Add project root to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class APIValidationTester:
    """Test class for API validation"""

    def __init__(self):
        self.config = self._get_config()
        self.test_results = []
        self.test_user_id = "11111111-1111-1111-1111-111111111111"

    def _get_config(self) -> Dict[str, str]:
        """Get API configuration from environment"""
        return {
            "supabase_url": os.getenv("SUPABASE_URL", "http://localhost:54321"),
            "anon_key": os.getenv("SUPABASE_ANON_KEY", "your_anon_key_here"),
            "service_role_key": os.getenv(
                "SUPABASE_SERVICE_ROLE_KEY", "your_service_role_key_here"
            ),
            "user_jwt": os.getenv("USER_JWT_TOKEN", "your_user_jwt_here"),
        }

    def _log_test_result(
        self,
        test_name: str,
        passed: bool,
        details: str = "",
        response_data: Dict = None,
    ):
        """Log test result for final reporting"""
        result = {
            "test": test_name,
            "passed": passed,
            "details": details,
            "response_data": response_data or {},
            "timestamp": datetime.now().isoformat(),
        }
        self.test_results.append(result)
        status = "PASS" if passed else "FAIL"
        print(f"[{status}] {test_name}: {details}")
        if response_data and not passed:
            print(f"  Response: {json.dumps(response_data, indent=2)[:200]}...")

    def _make_rest_request(
        self,
        method: str,
        endpoint: str,
        auth_type: str = "user",
        data: Dict = None,
        params: Dict = None,
    ) -> Tuple[int, Dict]:
        """Make REST API request with proper authentication"""
        url = f"{self.config['supabase_url']}/rest/v1/{endpoint}"

        headers = {
            "Content-Type": "application/json",
            "apikey": self.config["anon_key"],
        }

        if auth_type == "user":
            headers["Authorization"] = f"Bearer {self.config['user_jwt']}"
        elif auth_type == "service":
            headers["Authorization"] = f"Bearer {self.config['service_role_key']}"
        # 'none' means no authorization header

        try:
            if method.upper() == "GET":
                response = requests.get(url, headers=headers, params=params, timeout=10)
            elif method.upper() == "POST":
                response = requests.post(url, headers=headers, json=data, timeout=10)
            elif method.upper() == "PATCH":
                response = requests.patch(
                    url, headers=headers, json=data, params=params, timeout=10
                )
            elif method.upper() == "DELETE":
                response = requests.delete(
                    url, headers=headers, params=params, timeout=10
                )
            else:
                return 400, {"error": f"Unsupported method: {method}"}

            try:
                response_data = response.json()
            except Exception:
                response_data = {"text": response.text}

            return response.status_code, response_data

        except requests.exceptions.RequestException as e:
            return 500, {"error": str(e)}

    def _make_graphql_request(
        self, query: str, variables: Dict = None, auth_type: str = "user"
    ) -> Tuple[int, Dict]:
        """Make GraphQL API request"""
        url = f"{self.config['supabase_url']}/graphql/v1"

        headers = {
            "Content-Type": "application/json",
            "apikey": self.config["anon_key"],
        }

        if auth_type == "user":
            headers["Authorization"] = f"Bearer {self.config['user_jwt']}"
        elif auth_type == "service":
            headers["Authorization"] = f"Bearer {self.config['service_role_key']}"

        payload = {"query": query}
        if variables:
            payload["variables"] = variables

        try:
            response = requests.post(url, headers=headers, json=payload, timeout=10)
            return response.status_code, response.json()
        except requests.exceptions.RequestException as e:
            return 500, {"error": str(e)}

    def test_rest_api_crud_operations(self) -> bool:
        """Test 1: REST API CRUD operations with proper authentication"""
        try:
            # Test CREATE (POST)
            test_event = {
                "event_type": "api_test_create",
                "value": {
                    "test_id": str(uuid.uuid4()),
                    "timestamp": datetime.now().isoformat(),
                    "source": "api_validation_test",
                },
            }

            status, response = self._make_rest_request(
                "POST", "engagement_events", "user", test_event
            )
            create_success = status == 201
            created_event_id = (
                response[0]["id"] if create_success and response else None
            )

            # Test READ (GET) - all events
            status, response = self._make_rest_request(
                "GET", "engagement_events", "user"
            )
            read_all_success = status == 200 and isinstance(response, list)

            # Test READ (GET) - specific event
            if created_event_id:
                status, response = self._make_rest_request(
                    "GET", f"engagement_events?id=eq.{created_event_id}", "user"
                )
                read_specific_success = status == 200 and len(response) == 1
            else:
                read_specific_success = False

            # Test UPDATE (PATCH) - Note: This might fail due to RLS policies
            if created_event_id:
                update_data = {
                    "value": {
                        "updated": True,
                        "test_id": test_event["value"]["test_id"],
                    }
                }
                status, response = self._make_rest_request(
                    "PATCH",
                    f"engagement_events?id=eq.{created_event_id}",
                    "user",
                    update_data,
                )
                # Update might not be allowed by RLS, so we'll check if it's either successful or properly denied
                # Success or properly denied
                update_handled = status in [200, 204, 403, 405]
            else:
                update_handled = False

            # Test DELETE - Note: This might fail due to RLS policies
            if created_event_id:
                status, response = self._make_rest_request(
                    "DELETE", f"engagement_events?id=eq.{created_event_id}", "user"
                )
                # Delete might not be allowed by RLS, so we'll check if it's either successful or properly denied
                # Success or properly denied
                delete_handled = status in [200, 204, 403, 405]
            else:
                delete_handled = False

            crud_passed = (
                create_success
                and read_all_success
                and read_specific_success
                and update_handled
                and delete_handled
            )

            details = (
                f"CREATE: {create_success}, READ_ALL: {read_all_success}, "
                f"READ_SPECIFIC: {read_specific_success}, UPDATE: {update_handled}, DELETE: {delete_handled}"
            )

            self._log_test_result("REST API CRUD Operations", crud_passed, details)
            return crud_passed

        except Exception as e:
            self._log_test_result("REST API CRUD Operations", False, f"Error: {str(e)}")
            return False

    def test_graphql_api_operations(self) -> bool:
        """Test 2: GraphQL API queries and mutations"""
        try:
            # Test GraphQL Query
            query = """
            query GetEngagementEvents {
                engagement_events(limit: 10, order_by: {timestamp: desc}) {
                    id
                    timestamp
                    event_type
                    value
                }
            }
            """

            status, response = self._make_graphql_request(query, auth_type="user")
            query_success = (
                status == 200
                and "data" in response
                and "engagement_events" in response["data"]
            )

            # Test GraphQL Mutation
            mutation = """
            mutation InsertEngagementEvent($event: engagement_events_insert_input!) {
                insert_engagement_events_one(object: $event) {
                    id
                    timestamp
                    event_type
                    value
                }
            }
            """

            variables = {
                "event": {
                    "event_type": "api_test_graphql",
                    "value": {
                        "test_id": str(uuid.uuid4()),
                        "source": "graphql_validation_test",
                    },
                }
            }

            status, response = self._make_graphql_request(
                mutation, variables, auth_type="user"
            )
            mutation_success = (
                status == 200
                and "data" in response
                and "insert_engagement_events_one" in response["data"]
            )

            graphql_passed = query_success and mutation_success

            details = f"Query: {query_success}, Mutation: {mutation_success}"

            self._log_test_result("GraphQL API Operations", graphql_passed, details)
            return graphql_passed

        except Exception as e:
            self._log_test_result("GraphQL API Operations", False, f"Error: {str(e)}")
            return False

    def test_unauthorized_access_responses(self) -> bool:
        """Test 3: Validate error responses for unauthorized access"""
        try:
            # Test no authentication
            status, response = self._make_rest_request(
                "GET", "engagement_events", "none"
            )
            no_auth_denied = status in [401, 403]

            # Test invalid JWT
            original_jwt = self.config["user_jwt"]
            self.config["user_jwt"] = "invalid.jwt.token"
            status, response = self._make_rest_request(
                "GET", "engagement_events", "user"
            )
            invalid_jwt_denied = status in [401, 403]
            self.config["user_jwt"] = original_jwt  # Restore

            # Test accessing other user's data (should be blocked by RLS)
            other_user_data = {
                "user_id": "99999999-9999-9999-9999-999999999999",  # Different user
                "event_type": "unauthorized_test",
                "value": {"test": "should_fail"},
            }
            status, response = self._make_rest_request(
                "POST", "engagement_events", "user", other_user_data
            )
            # Should fail validation or RLS
            cross_user_denied = status in [400, 403, 422]

            # Test GraphQL unauthorized access
            query = "query { engagement_events { id } }"
            status, response = self._make_graphql_request(query, auth_type="none")
            graphql_auth_denied = status in [401, 403]

            auth_passed = (
                no_auth_denied
                and invalid_jwt_denied
                and cross_user_denied
                and graphql_auth_denied
            )

            details = (
                f"No auth: {no_auth_denied}, Invalid JWT: {invalid_jwt_denied}, "
                f"Cross-user: {cross_user_denied}, GraphQL: {graphql_auth_denied}"
            )

            self._log_test_result("Unauthorized Access Responses", auth_passed, details)
            return auth_passed

        except Exception as e:
            self._log_test_result(
                "Unauthorized Access Responses", False, f"Error: {str(e)}"
            )
            return False

    def test_service_role_access(self) -> bool:
        """Test 4: Verify service role can bypass RLS"""
        try:
            # Test service role can read all events
            status, response = self._make_rest_request(
                "GET", "engagement_events", "service"
            )
            service_read_success = status == 200

            # Test service role can insert for any user
            service_event = {
                "user_id": self.test_user_id,
                "event_type": "service_role_test",
                "value": {
                    "test_id": str(uuid.uuid4()),
                    "source": "service_role_validation",
                },
            }

            status, response = self._make_rest_request(
                "POST", "engagement_events", "service", service_event
            )
            service_insert_success = status == 201

            # Test bulk insert with service role
            bulk_events = [
                {
                    "user_id": self.test_user_id,
                    "event_type": "bulk_test_1",
                    "value": {"batch_id": str(uuid.uuid4())},
                },
                {
                    "user_id": self.test_user_id,
                    "event_type": "bulk_test_2",
                    "value": {"batch_id": str(uuid.uuid4())},
                },
            ]

            status, response = self._make_rest_request(
                "POST", "engagement_events", "service", bulk_events
            )
            bulk_insert_success = status == 201

            service_passed = (
                service_read_success and service_insert_success and bulk_insert_success
            )

            details = (
                f"Read: {service_read_success}, Insert: {service_insert_success}, "
                f"Bulk: {bulk_insert_success}"
            )

            self._log_test_result("Service Role Access", service_passed, details)
            return service_passed

        except Exception as e:
            self._log_test_result("Service Role Access", False, f"Error: {str(e)}")
            return False

    def test_data_validation_and_constraints(self) -> bool:
        """Test 5: Validate data constraints and validation"""
        try:
            # Test empty event_type (should fail)
            invalid_event = {"event_type": "", "value": {"test": "empty_event_type"}}
            status, response = self._make_rest_request(
                "POST", "engagement_events", "user", invalid_event
            )
            empty_type_rejected = status in [400, 422]

            # Test null event_type (should fail)
            invalid_event = {"event_type": None, "value": {"test": "null_event_type"}}
            status, response = self._make_rest_request(
                "POST", "engagement_events", "user", invalid_event
            )
            null_type_rejected = status in [400, 422]

            # Test invalid JSON in value field
            # Note: This is tricky to test via REST API as requests will validate JSON
            # We'll test with a very large JSON payload instead
            large_value = {"data": "x" * 10000}  # Large but valid JSON
            large_event = {"event_type": "large_payload_test", "value": large_value}
            status, response = self._make_rest_request(
                "POST", "engagement_events", "user", large_event
            )
            large_payload_handled = status in [
                200,
                201,
                413,
                422,
            ]  # Success or proper rejection

            # Test future timestamp (should fail due to constraint)
            future_event = {
                "event_type": "future_timestamp_test",
                "value": {"test": "future"},
                "timestamp": (datetime.now() + timedelta(hours=2)).isoformat(),
            }
            status, response = self._make_rest_request(
                "POST", "engagement_events", "user", future_event
            )
            future_timestamp_rejected = status in [400, 422]

            validation_passed = (
                empty_type_rejected
                and null_type_rejected
                and large_payload_handled
                and future_timestamp_rejected
            )

            details = (
                f"Empty type: {empty_type_rejected}, Null type: {null_type_rejected}, "
                f"Large payload: {large_payload_handled}, Future timestamp: {future_timestamp_rejected}"
            )

            self._log_test_result(
                "Data Validation & Constraints", validation_passed, details
            )
            return validation_passed

        except Exception as e:
            self._log_test_result(
                "Data Validation & Constraints", False, f"Error: {str(e)}"
            )
            return False

    def test_api_rate_limiting(self) -> bool:
        """Test 6: Test API rate limiting behavior"""
        try:
            # Test rapid requests to check for rate limiting
            request_count = 50
            success_count = 0
            rate_limited_count = 0
            error_count = 0

            def make_rapid_request(i):
                test_event = {
                    "event_type": f"rate_limit_test_{i}",
                    "value": {"request_id": i, "timestamp": datetime.now().isoformat()},
                }
                status, response = self._make_rest_request(
                    "POST", "engagement_events", "user", test_event
                )
                return status

            # Make requests concurrently
            with ThreadPoolExecutor(max_workers=10) as executor:
                futures = [
                    executor.submit(make_rapid_request, i) for i in range(request_count)
                ]

                for future in as_completed(futures):
                    status = future.result()
                    if status in [200, 201]:
                        success_count += 1
                    elif status == 429:  # Too Many Requests
                        rate_limited_count += 1
                    else:
                        error_count += 1

            # Rate limiting behavior analysis
            # If rate limiting is implemented, we should see some 429 responses
            # If not implemented, all requests should succeed (which is also valid for testing)
            rate_limiting_works = (rate_limited_count > 0) or (
                success_count > request_count * 0.8
            )

            details = (
                f"Success: {success_count}, Rate limited: {rate_limited_count}, "
                f"Errors: {error_count} out of {request_count} requests"
            )

            self._log_test_result("API Rate Limiting", rate_limiting_works, details)
            return rate_limiting_works

        except Exception as e:
            self._log_test_result("API Rate Limiting", False, f"Error: {str(e)}")
            return False

    def test_api_response_formats(self) -> bool:
        """Test 7: Validate API response formats and structure"""
        try:
            # Test REST API response format
            status, response = self._make_rest_request(
                "GET", "engagement_events?limit=1", "user"
            )

            if status == 200 and response:
                event = (
                    response[0] if isinstance(response, list) and response else response
                )

                # Check required fields
                required_fields = ["id", "user_id", "timestamp", "event_type", "value"]
                rest_format_valid = all(field in event for field in required_fields)

                # Check data types
                rest_types_valid = (
                    isinstance(event.get("id"), str)
                    and isinstance(event.get("user_id"), str)
                    and isinstance(event.get("timestamp"), str)
                    and isinstance(event.get("event_type"), str)
                    and isinstance(event.get("value"), dict)
                )
            else:
                rest_format_valid = False
                rest_types_valid = False

            # Test GraphQL response format
            query = """
            query {
                engagement_events(limit: 1) {
                    id
                    user_id
                    timestamp
                    event_type
                    value
                }
            }
            """

            status, response = self._make_graphql_request(query, auth_type="user")

            if (
                status == 200
                and "data" in response
                and response["data"]["engagement_events"]
            ):
                event = response["data"]["engagement_events"][0]

                # Check GraphQL response structure
                graphql_format_valid = all(field in event for field in required_fields)
                graphql_types_valid = (
                    isinstance(event.get("id"), str)
                    and isinstance(event.get("user_id"), str)
                    and isinstance(event.get("timestamp"), str)
                    and isinstance(event.get("event_type"), str)
                    and isinstance(event.get("value"), dict)
                )
            else:
                graphql_format_valid = False
                graphql_types_valid = False

            format_passed = (
                rest_format_valid
                and rest_types_valid
                and graphql_format_valid
                and graphql_types_valid
            )

            details = (
                f"REST format: {rest_format_valid}, REST types: {rest_types_valid}, "
                f"GraphQL format: {graphql_format_valid}, GraphQL types: {graphql_types_valid}"
            )

            self._log_test_result("API Response Formats", format_passed, details)
            return format_passed

        except Exception as e:
            self._log_test_result("API Response Formats", False, f"Error: {str(e)}")
            return False

    def run_all_tests(self) -> bool:
        """Run all API validation tests and return overall pass/fail"""
        print("=" * 60)
        print("BEE Engagement Events - API Validation Test Suite")
        print("=" * 60)
        print(f"Supabase URL: {self.config['supabase_url']}")
        print(f"Test User ID: {self.test_user_id}")
        print("-" * 60)

        tests = [
            self.test_rest_api_crud_operations,
            self.test_graphql_api_operations,
            self.test_unauthorized_access_responses,
            self.test_service_role_access,
            self.test_data_validation_and_constraints,
            self.test_api_rate_limiting,
            self.test_api_response_formats,
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
        print(f"API Validation Results: {passed_tests}/{total_tests} passed")

        # Generate detailed report
        self._generate_api_report()

        return passed_tests == total_tests

    def _generate_api_report(self):
        """Generate detailed API validation report"""
        report_file = (
            f"api_validation_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )

        report = {
            "test_suite": "BEE Engagement Events API Validation",
            "timestamp": datetime.now().isoformat(),
            "config": {
                k: v
                for k, v in self.config.items()
                if "key" not in k and "jwt" not in k
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

        with open(f"tests/api/{report_file}", "w") as f:
            json.dump(report, f, indent=2)

        print(f"Detailed API validation report saved to: tests/api/{report_file}")


def main():
    """Main test execution"""
    tester = APIValidationTester()
    success = tester.run_all_tests()

    if success:
        print("\n✅ All API validation tests PASSED - APIs working correctly")
        sys.exit(0)
    else:
        print("\n❌ Some API validation tests FAILED - Review API implementation")
        sys.exit(1)


if __name__ == "__main__":
    main()
