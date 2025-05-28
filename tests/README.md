# BEE Engagement Events - Testing Suite

**Module:** Core Engagement  
**Milestone:** 1 · Data Backbone  
**Task:** 5 - Testing & Validation

This directory contains comprehensive tests for the engagement events logging system, covering database security, performance, and API validation.

## 📋 Test Overview

### Task 5.1: Mock Data Generation ✅
- **File:** `supabase/migrations/seed_engagement_events.sql`
- **Purpose:** Generate realistic test data with multiple event types and users
- **Coverage:** ~48 events across 3 test users with varied JSONB payloads

### Task 5.2: RLS Audit Tests ✅
- **File:** `tests/db/test_rls_audit.py`
- **Purpose:** Verify complete cross-user data isolation
- **Coverage:** Zero cross-user leakage verification, concurrent session testing

### Task 5.3: Performance Testing ✅
- **File:** `tests/db/test_performance.py`
- **Purpose:** Measure database performance and Realtime latency
- **Coverage:** Concurrent inserts, index effectiveness, large dataset queries

### Task 5.4: API Validation Tests ✅
- **File:** `tests/api/test_api_validation.py`
- **Purpose:** Test REST/GraphQL APIs, authentication, and error handling
- **Coverage:** CRUD operations, unauthorized access, rate limiting

## 🚀 Quick Start

### Prerequisites

1. **Install Dependencies:**
   ```bash
   pip install -r tests/requirements.txt
   ```

2. **Environment Setup:**
   ```bash
   # Required for database tests
   export DB_HOST=localhost
   export DB_PORT=54322
   export DB_NAME=postgres
   export DB_USER=postgres
   export DB_PASSWORD=postgres
   
   # Optional for API tests
   export SUPABASE_URL=http://localhost:54321
   export SUPABASE_ANON_KEY=your_anon_key
   export USER_JWT_TOKEN=your_user_jwt
   export SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

3. **Database Setup:**
   ```bash
   # Apply migrations
   supabase db reset
   
   # Load test data
   psql -h localhost -p 54322 -U postgres -d postgres -f supabase/migrations/seed_engagement_events.sql
   ```

### Run All Tests

```bash
# Run complete test suite
python tests/run_all_tests.py

# Run with options
python tests/run_all_tests.py --skip-performance --skip-api
```

### Run Individual Test Suites

```bash
# RLS Audit Tests
python tests/db/test_rls_audit.py

# Performance Tests  
python tests/db/test_performance.py

# API Validation Tests
python tests/api/test_api_validation.py
```

## 📊 Test Details

### RLS Audit Tests (`test_rls_audit.py`)

**Purpose:** Ensure HIPAA-compliant data isolation

**Tests:**
1. **Table & RLS Check** - Verify engagement_events table exists with RLS enabled
2. **User Isolation** - Confirm users can only see their own events
3. **Anonymous Access** - Verify anonymous users have no access
4. **Insert Isolation** - Test users can only insert their own events
5. **Service Role Access** - Verify service role bypasses RLS appropriately
6. **Concurrent Sessions** - Test RLS under concurrent user access

**Success Criteria:**
- Zero cross-user data leakage
- All RLS policies enforced correctly
- Service role access works for bulk operations

### Performance Tests (`test_performance.py`)

**Purpose:** Validate system performance under load

**Tests:**
1. **Single Insert Performance** - Target: <50ms average
2. **Concurrent Inserts** - 100+ concurrent inserts, >50 inserts/sec
3. **Index Effectiveness** - Verify EXPLAIN ANALYZE shows index usage
4. **Large Dataset Queries** - Test with 1000+ events, <500ms queries
5. **Realtime Latency** - Simulate <500ms notification latency

**Success Criteria:**
- Meet all performance targets from PRD
- Indexes used effectively for common queries
- System scales under concurrent load

### API Validation Tests (`test_api_validation.py`)

**Purpose:** Validate REST and GraphQL API behavior

**Tests:**
1. **REST CRUD Operations** - Test all HTTP methods with authentication
2. **GraphQL Operations** - Test queries and mutations
3. **Unauthorized Access** - Verify proper error responses (401/403)
4. **Service Role Access** - Test bulk operations and RLS bypass
5. **Data Validation** - Test constraint enforcement and error handling
6. **Rate Limiting** - Test API behavior under rapid requests
7. **Response Formats** - Validate JSON structure and data types

**Success Criteria:**
- All CRUD operations work correctly
- Proper authentication and authorization
- Consistent API response formats

## 📈 Test Reports

Each test suite generates detailed JSON reports:

- **RLS Audit:** `tests/db/rls_audit_report_YYYYMMDD_HHMMSS.json`
- **Performance:** `tests/db/performance_report_YYYYMMDD_HHMMSS.json`  
- **API Validation:** `tests/api/api_validation_report_YYYYMMDD_HHMMSS.json`

## 🔧 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Check if Supabase is running
   supabase status
   
   # Start local development
   supabase start
   ```

2. **Missing Test Data**
   ```bash
   # Reload seed data
   psql -h localhost -p 54322 -U postgres -d postgres -f supabase/migrations/seed_engagement_events.sql
   ```

3. **API Tests Failing**
   ```bash
   # Check environment variables
   echo $SUPABASE_URL
   echo $SUPABASE_ANON_KEY
   
   # Generate user JWT token for testing
   # (Use Supabase dashboard or auth endpoint)
   ```

4. **Permission Errors**
   ```bash
   # Make scripts executable
   chmod +x tests/db/test_rls_audit.py
   chmod +x tests/db/test_performance.py
   chmod +x tests/api/test_api_validation.py
   ```

### Environment Variables Reference

| Variable | Required | Purpose | Default |
|----------|----------|---------|---------|
| `DB_HOST` | Yes | Database host | `localhost` |
| `DB_PORT` | Yes | Database port | `54322` |
| `DB_NAME` | Yes | Database name | `postgres` |
| `DB_USER` | Yes | Database user | `postgres` |
| `DB_PASSWORD` | Yes | Database password | `postgres` |
| `SUPABASE_URL` | No | Supabase project URL | `http://localhost:54321` |
| `SUPABASE_ANON_KEY` | No | Anonymous API key | Required for API tests |
| `USER_JWT_TOKEN` | No | User JWT for testing | Required for user API tests |
| `SUPABASE_SERVICE_ROLE_KEY` | No | Service role key | Required for service role tests |

## 🎯 Success Metrics

Task 5 is complete when all tests pass:

- ✅ **RLS Audit:** Zero cross-user leakage confirmed
- ✅ **Performance:** <500ms Realtime latency, >50 inserts/sec throughput  
- ✅ **API Validation:** All CRUD operations working with proper auth

## 📚 Related Documentation

- **PRD:** `docs/1_milestone_1/prd-engagement-events-logging.md`
- **Tasks:** `docs/1_milestone_1/tasks-prd-engagement-events-logging.md`
- **Prompts:** `docs/1_milestone_1/prompts-engagement-events.md`
- **Migration:** `supabase/migrations/20241201000000_engagement_events.sql`

---

**Status:** ✅ Complete  
**Next:** Proceed to Task 6 (Documentation & Deployment) 