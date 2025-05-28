#!/usr/bin/env python3
"""
Test Runner: Momentum Calculation Unit Tests
Epic: 1.1 · Momentum Meter
Task: T1.1.2.10 · Write unit tests for calculation logic and API endpoints

Executes comprehensive unit tests and generates coverage reports to achieve
90%+ test coverage on momentum calculation logic and API endpoints.

Usage:
    python tests/api/run_momentum_unit_tests.py
    python tests/api/run_momentum_unit_tests.py --coverage
    python tests/api/run_momentum_unit_tests.py --performance-only
    python tests/api/run_momentum_unit_tests.py --generate-report

Created: 2024-12-17
Author: BEE Development Team
"""

import sys
import argparse
import subprocess
import json
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, Any

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Test configuration
TEST_CONFIG = {
    "test_files": [
        "tests/api/test_momentum_calculation_unit_tests.py",
        "tests/api/test_momentum_score_calculator.py",
        "tests/api/test_data_validation_error_handling.py",
    ],
    "coverage_threshold": 90,
    "performance_threshold_ms": 500,
    "output_dir": "tests/reports",
    "report_timestamp": datetime.now().strftime("%Y%m%d_%H%M%S"),
}


class MomentumTestRunner:
    """Test runner for momentum calculation unit tests"""

    def __init__(self):
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "test_files": [],
            "coverage": {},
            "performance": {},
            "summary": {},
        }
        self.ensure_output_directory()

    def ensure_output_directory(self):
        """Ensure output directory exists"""
        output_dir = Path(TEST_CONFIG["output_dir"])
        output_dir.mkdir(parents=True, exist_ok=True)

    def run_unit_tests(
        self, coverage: bool = False, performance_only: bool = False
    ) -> bool:
        """Run unit tests with optional coverage analysis"""
        print("=" * 80)
        print("MOMENTUM CALCULATION UNIT TESTS")
        print("=" * 80)
        print(f"Timestamp: {self.results['timestamp']}")
        print(f"Coverage analysis: {'Enabled' if coverage else 'Disabled'}")
        print(f"Performance only: {'Yes' if performance_only else 'No'}")
        print()

        success = True

        for test_file in TEST_CONFIG["test_files"]:
            if performance_only and "performance" not in test_file:
                continue

            print(f"Running tests in {test_file}...")
            file_success = self.run_test_file(test_file, coverage)
            success = success and file_success
            print()

        return success

    def run_test_file(self, test_file: str, coverage: bool = False) -> bool:
        """Run tests in a specific file"""
        start_time = time.time()

        try:
            # Build pytest command
            cmd = ["python", "-m", "pytest", test_file, "-v"]

            if coverage:
                cmd.extend(
                    ["--cov=functions/momentum-score-calculator", "--cov-report=json"]
                )

            # Run tests
            result = subprocess.run(
                cmd, capture_output=True, text=True, cwd=project_root
            )

            end_time = time.time()
            execution_time = (end_time - start_time) * 1000

            # Parse results
            test_result = {
                "file": test_file,
                "success": result.returncode == 0,
                "execution_time_ms": execution_time,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "return_code": result.returncode,
            }

            self.results["test_files"].append(test_result)

            # Print summary
            if test_result["success"]:
                print(f"  ✅ PASSED ({execution_time:.1f}ms)")
            else:
                print(f"  ❌ FAILED ({execution_time:.1f}ms)")
                print(f"  Error: {result.stderr}")

            return test_result["success"]

        except Exception as e:
            print(f"  ❌ ERROR: {str(e)}")
            return False

    def analyze_coverage(self) -> Dict[str, Any]:
        """Analyze test coverage from coverage reports"""
        print("Analyzing test coverage...")

        coverage_file = project_root / "coverage.json"
        if not coverage_file.exists():
            print("  ⚠️  Coverage report not found")
            return {}

        try:
            with open(coverage_file, "r") as f:
                coverage_data = json.load(f)

            # Extract coverage metrics
            total_coverage = coverage_data.get("totals", {}).get("percent_covered", 0)

            coverage_summary = {
                "total_coverage_percent": total_coverage,
                "meets_threshold": total_coverage >= TEST_CONFIG["coverage_threshold"],
                "threshold": TEST_CONFIG["coverage_threshold"],
                "files": {},
            }

            # Analyze per-file coverage
            for file_path, file_data in coverage_data.get("files", {}).items():
                if "momentum" in file_path.lower():
                    coverage_summary["files"][file_path] = {
                        "coverage_percent": file_data.get("summary", {}).get(
                            "percent_covered", 0
                        ),
                        "lines_covered": file_data.get("summary", {}).get(
                            "covered_lines", 0
                        ),
                        "lines_total": file_data.get("summary", {}).get(
                            "num_statements", 0
                        ),
                    }

            self.results["coverage"] = coverage_summary

            print(f"  Total coverage: {total_coverage:.1f}%")
            print(f"  Threshold: {TEST_CONFIG['coverage_threshold']}%")
            print(
                f"  Status: {'✅ PASSED' if coverage_summary['meets_threshold'] else '❌ FAILED'}"
            )

            return coverage_summary

        except Exception as e:
            print(f"  ❌ Error analyzing coverage: {str(e)}")
            return {}

    def analyze_performance(self) -> Dict[str, Any]:
        """Analyze performance test results"""
        print("Analyzing performance metrics...")

        performance_summary = {
            "average_execution_time_ms": 0,
            "max_execution_time_ms": 0,
            "meets_threshold": True,
            "threshold_ms": TEST_CONFIG["performance_threshold_ms"],
            "slow_tests": [],
        }

        execution_times = []
        for test_result in self.results["test_files"]:
            execution_time = test_result["execution_time_ms"]
            execution_times.append(execution_time)

            if execution_time > TEST_CONFIG["performance_threshold_ms"]:
                performance_summary["slow_tests"].append(
                    {"file": test_result["file"], "execution_time_ms": execution_time}
                )
                performance_summary["meets_threshold"] = False

        if execution_times:
            performance_summary["average_execution_time_ms"] = sum(
                execution_times
            ) / len(execution_times)
            performance_summary["max_execution_time_ms"] = max(execution_times)

        self.results["performance"] = performance_summary

        print(
            f"  Average execution time: {performance_summary['average_execution_time_ms']:.1f}ms"
        )
        print(
            f"  Max execution time: {performance_summary['max_execution_time_ms']:.1f}ms"
        )
        print(f"  Threshold: {TEST_CONFIG['performance_threshold_ms']}ms")
        print(
            f"  Status: {'✅ PASSED' if performance_summary['meets_threshold'] else '❌ FAILED'}"
        )

        if performance_summary["slow_tests"]:
            print(f"  Slow tests: {len(performance_summary['slow_tests'])}")

        return performance_summary

    def generate_summary(self) -> Dict[str, Any]:
        """Generate test execution summary"""
        total_tests = len(self.results["test_files"])
        passed_tests = sum(1 for test in self.results["test_files"] if test["success"])

        summary = {
            "total_test_files": total_tests,
            "passed_test_files": passed_tests,
            "failed_test_files": total_tests - passed_tests,
            "success_rate_percent": (
                (passed_tests / total_tests * 100) if total_tests > 0 else 0
            ),
            "overall_success": passed_tests == total_tests,
            "coverage_success": self.results.get("coverage", {}).get(
                "meets_threshold", False
            ),
            "performance_success": self.results.get("performance", {}).get(
                "meets_threshold", True
            ),
        }

        summary["all_criteria_met"] = (
            summary["overall_success"]
            and summary["coverage_success"]
            and summary["performance_success"]
        )

        self.results["summary"] = summary
        return summary

    def print_summary(self):
        """Print test execution summary"""
        summary = self.results["summary"]

        print("=" * 80)
        print("TEST EXECUTION SUMMARY")
        print("=" * 80)

        print(
            f"Test Files: {summary['passed_test_files']}/{summary['total_test_files']} passed"
        )
        print(f"Success Rate: {summary['success_rate_percent']:.1f}%")

        if "coverage" in self.results:
            coverage = self.results["coverage"]
            print(
                f"Coverage: {coverage.get('total_coverage_percent', 0):.1f}% (threshold: {coverage.get('threshold', 0)}%)"
            )

        if "performance" in self.results:
            performance = self.results["performance"]
            print(
                f"Performance: {performance['average_execution_time_ms']:.1f}ms avg (threshold: {performance['threshold_ms']}ms)"
            )

        print()
        print("Criteria Status:")
        print(
            f"  ✅ Test Execution: {'PASSED' if summary['overall_success'] else 'FAILED'}"
        )
        print(
            f"  ✅ Coverage (90%+): {'PASSED' if summary['coverage_success'] else 'FAILED'}"
        )
        print(
            f"  ✅ Performance: {'PASSED' if summary['performance_success'] else 'FAILED'}"
        )

        print()
        overall_status = (
            "✅ ALL CRITERIA MET"
            if summary["all_criteria_met"]
            else "❌ SOME CRITERIA FAILED"
        )
        print(f"Overall Status: {overall_status}")

        if summary["all_criteria_met"]:
            print("\n🎉 Task T1.1.2.10 requirements satisfied!")
            print("   - 90%+ test coverage achieved")
            print("   - All unit tests passing")
            print("   - Performance requirements met")

    def save_report(self) -> str:
        """Save detailed test report"""
        report_filename = (
            f"momentum_unit_tests_report_{TEST_CONFIG['report_timestamp']}.json"
        )
        report_path = Path(TEST_CONFIG["output_dir"]) / report_filename

        try:
            with open(report_path, "w") as f:
                json.dump(self.results, f, indent=2)

            print(f"\nDetailed report saved: {report_path}")
            return str(report_path)

        except Exception as e:
            print(f"Error saving report: {str(e)}")
            return ""

    def run_full_test_suite(self, args) -> bool:
        """Run complete test suite with all analyses"""
        # Run unit tests
        self.run_unit_tests(
            coverage=args.coverage, performance_only=args.performance_only
        )

        print()

        # Analyze coverage if requested
        if args.coverage and not args.performance_only:
            self.analyze_coverage()
            print()

        # Analyze performance
        self.analyze_performance()
        print()

        # Generate and print summary
        self.generate_summary()
        self.print_summary()

        # Save report if requested
        if args.generate_report:
            self.save_report()

        return self.results["summary"]["all_criteria_met"]


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Run momentum calculation unit tests with coverage analysis"
    )

    parser.add_argument(
        "--coverage", action="store_true", help="Enable coverage analysis"
    )

    parser.add_argument(
        "--performance-only", action="store_true", help="Run only performance tests"
    )

    parser.add_argument(
        "--generate-report", action="store_true", help="Generate detailed JSON report"
    )

    args = parser.parse_args()

    # Create and run test suite
    runner = MomentumTestRunner()
    success = runner.run_full_test_suite(args)

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
