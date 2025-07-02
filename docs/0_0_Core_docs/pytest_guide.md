# Pytest Guide for BEE Project

## Overview

**Yes, you should absolutely be using pytest!** Your project is at the perfect stage to leverage pytest's powerful features. You're already using it in several places, but there's significant room for improvement.

## Current Status ✅

Your project **already has pytest** set up and working:
- ✅ 32 comprehensive unit tests in `test_momentum_calculation_unit_tests.py`
- ✅ Functionality testing handled via Flutter service tests (intervention logic tested natively)
- ✅ Performance and integration tests
- ✅ Proper test structure and organization
- ✅ All dependencies installed and working

## Why Pytest is Perfect for Your Project

### 1. **Project Size is Ideal**
- You have **15+ Python files** with complex logic
- **Multiple test categories**: API, database, performance, integration
- **Growing codebase** that needs reliable testing
- **Not too small** - you have real complexity to test

### 2. **Current Benefits You're Getting**
```bash
# You already have 32 passing tests!
$ python -m pytest tests/api/test_momentum_calculation_unit_tests.py -v
# ✅ 32 passed in 0.09s
```

### 3. **Advanced Features You Can Leverage**

## Pytest Features You Should Use More

### 1. **Test Discovery and Organization**
```bash
# Run all tests
pytest

# Run specific test categories
pytest -m unit          # Only unit tests
pytest -m integration   # Only integration tests
pytest -m performance   # Only performance tests

# Run tests by pattern
pytest -k "momentum"    # All tests with "momentum" in name
pytest tests/api/       # All API tests
```

### 2. **Fixtures for Better Test Setup**
```python
@pytest.fixture
def sample_user_id():
    return "550e8400-e29b-41d4-a716-446655440000"

@pytest.fixture
def mock_database():
    # Setup mock database
    yield mock_db
    # Cleanup after test
```

### 3. **Parametrized Tests for Multiple Scenarios**
```python
@pytest.mark.parametrize("score,expected_state", [
    (85, "Rising"),
    (60, "Steady"), 
    (30, "NeedsCare"),
])
def test_momentum_classification(score, expected_state):
    assert classify_momentum(score) == expected_state
```

### 4. **Async Testing (You're Already Using This!)**
```python
@pytest.mark.asyncio
async def test_async_momentum_calculation():
    result = await calculate_momentum_async(user_id)
    assert result["success"] is True
```

### 5. **Performance Benchmarking**
```python
@pytest.mark.performance
def test_calculation_performance(benchmark):
    result = benchmark(calculate_momentum_score, test_data)
    assert result > 0
```

## Recommended Pytest Setup for Your Project

### 1. **Install Additional Plugins**
```bash
pip install pytest-asyncio pytest-benchmark pytest-cov pytest-html pytest-xdist
```

### 2. **Enhanced pytest.ini Configuration**
```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*

markers =
    unit: Unit tests
    integration: Integration tests  
    performance: Performance tests
    api: API tests
    db: Database tests
    slow: Slow tests that can be skipped

addopts = 
    -v
    --tb=short
    --strict-markers
    --color=yes

asyncio_mode = auto
```

### 3. **Test Organization Structure**
```
tests/
├── api/                    # API tests
│   ├── test_momentum_*.py
│   └── test_intervention_*.py
├── db/                     # Database tests  
│   ├── test_rls_*.py
│   └── test_performance_*.py
├── unit/                   # Pure unit tests
├── integration/            # Integration tests
└── conftest.py            # Shared fixtures
```

## Advanced Pytest Commands for Your Project

### 1. **Coverage Analysis**
```bash
# Run tests with coverage
pytest --cov=functions --cov-report=html --cov-report=term

# Coverage for specific modules
pytest --cov=functions/momentum-score-calculator --cov-report=term-missing
```

### 2. **Parallel Test Execution**
```bash
# Run tests in parallel (faster CI)
pytest -n auto  # Use all CPU cores
pytest -n 4     # Use 4 processes
```

### 3. **Test Selection and Filtering**
```bash
# Run only fast tests
pytest -m "not slow"

# Run only API tests
pytest -m api

# Run specific test file
pytest tests/api/test_momentum_calculation_unit_tests.py

# Run tests matching pattern
pytest -k "momentum and not performance"
```

### 4. **Debugging and Development**
```bash
# Stop on first failure
pytest -x

# Drop into debugger on failure
pytest --pdb

# Show local variables in tracebacks
pytest -l

# Verbose output with timing
pytest -v --durations=10
```

### 5. **HTML Reports**
```bash
# Generate HTML test report
pytest --html=reports/test_report.html --self-contained-html
```

## Integration with Your CI/CD

### 1. **GitHub Actions Integration**
Your `.github/workflows/ci.yml` already includes pytest! You can enhance it:

```yaml
- name: Run Python tests with pytest
  run: |
    pytest tests/ \
      --cov=functions \
      --cov-report=xml \
      --cov-report=term \
      --html=reports/pytest_report.html \
      --junitxml=reports/junit.xml \
      -v
```

### 2. **Test Categories for CI**
```bash
# Fast tests for PR checks
pytest -m "unit and not slow" --maxfail=1

# Full test suite for main branch
pytest --cov=functions --cov-fail-under=80
```

## Specific Improvements for Your Project

### 1. **Better Test Organization**
Move your current test runner scripts to use pytest:

```python
# Instead of custom test runners, use pytest directly
# tests/api/run_momentum_unit_tests.py -> Use pytest with markers
```

### 2. **Shared Fixtures**
Create `tests/conftest.py`:
```python
@pytest.fixture
def test_user_id():
    return "550e8400-e29b-41d4-a716-446655440000"

@pytest.fixture  
def supabase_client():
    return create_client(TEST_URL, TEST_KEY)
```

### 3. **Environment-Specific Testing**
```python
@pytest.mark.skipif(not os.getenv("SUPABASE_URL"), reason="No Supabase URL")
def test_live_api():
    # Test against real API
    pass
```

## Performance Benefits You'll Get

### 1. **Faster Test Execution**
- **Parallel execution**: `-n auto` can cut test time by 50-75%
- **Smart test selection**: Only run tests affected by changes
- **Efficient fixtures**: Shared setup/teardown

### 2. **Better Developer Experience**
- **Clear test output**: See exactly what's failing
- **Fast feedback**: Run subset of tests during development
- **Debugging support**: Drop into debugger on failures

### 3. **CI/CD Optimization**
- **Fail fast**: Stop on first failure in PR checks
- **Test categorization**: Run different test suites for different triggers
- **Coverage tracking**: Ensure code quality standards

## Example Commands for Your Daily Workflow

```bash
# During development - run fast tests
pytest -m "unit and not slow" -x

# Before committing - run all tests for changed files
pytest tests/api/ -v

# Performance testing
pytest -m performance --benchmark-only

# Full test suite with coverage
pytest --cov=functions --cov-report=term-missing

# Generate reports for review
pytest --html=reports/test_report.html --cov=functions --cov-report=html
```

## Conclusion

**Your project is absolutely ready for pytest!** You're already using it effectively, but you can get much more value by:

1. ✅ **Leveraging markers** for test categorization
2. ✅ **Using fixtures** for better test setup
3. ✅ **Adding coverage analysis** to ensure quality
4. ✅ **Implementing parallel execution** for faster CI
5. ✅ **Creating HTML reports** for better visibility

The investment in better pytest usage will pay off immediately with:
- **Faster development cycles**
- **More reliable code**
- **Better CI/CD pipeline**
- **Easier debugging and maintenance**

Your project has reached the complexity where pytest's advanced features become essential rather than optional! 