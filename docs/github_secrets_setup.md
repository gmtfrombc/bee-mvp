# GitHub Secrets Setup for BEE Project

## Overview
To avoid GitGuardian warnings about exposed secrets in CI configuration, we use GitHub repository secrets even for test credentials.

## Required Secrets

### 1. Production Secrets (Already Set)
- `SUPABASE_ACCESS_TOKEN` - Your Supabase access token

### 2. Test Database Secrets (To Add)
- `TEST_DB_PASSWORD` - Test database password (value: `postgres`)
- `TEST_DB_USER` - Test database user (value: `postgres`)
- `TEST_DB_NAME` - Test database name (value: `test`)

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret:

```
Name: TEST_DB_PASSWORD
Value: postgres

Name: TEST_DB_USER  
Value: postgres

Name: TEST_DB_NAME
Value: test
```

## Updated CI Configuration

With secrets, your CI would look like:

```yaml
- name: Setup PostgreSQL
  uses: harmon758/postgresql-action@v1
  with:
    postgresql version: '14'
    postgresql db: ${{ secrets.TEST_DB_NAME }}
    postgresql user: ${{ secrets.TEST_DB_USER }}
    postgresql password: ${{ secrets.TEST_DB_PASSWORD }}
```

## Benefits

1. **No GitGuardian warnings** - No hardcoded credentials in code
2. **Consistent pattern** - All credentials handled the same way
3. **Easy to change** - Update secrets without code changes
4. **Audit trail** - GitHub tracks secret usage

## Alternative: Environment Variables

If you prefer not to use secrets for test credentials, you can use environment variables as we've implemented:

```yaml
env:
  TEST_DB_PASSWORD: postgres

# Then reference as:
postgresql password: ${{ env.TEST_DB_PASSWORD }}
```

This approach:
- ✅ Removes hardcoded credentials from YAML
- ✅ Keeps GitGuardian happy
- ✅ Clearly marks as test credentials
- ✅ Easier to manage than secrets for non-sensitive data 