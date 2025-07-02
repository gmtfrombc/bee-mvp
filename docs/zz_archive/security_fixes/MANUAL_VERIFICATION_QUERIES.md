# Manual Production Verification Queries

Since the Supabase Security Advisor may be cached, please run these queries
manually in **Supabase Studio SQL Editor** to verify the fixes are applied in
production:

## 1. Check RLS Status on Tables

```sql
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('system_logs', 'realtime_event_metrics', 'momentum_error_logs')
AND schemaname = 'public'
ORDER BY tablename;
```

**Expected Result:** All 3 tables should show `rls_enabled = t`

## 2. Check View Security Properties

```sql
SELECT 
    schemaname,
    viewname,
    viewowner,
    CASE 
        WHEN definition LIKE '%SECURITY DEFINER%' THEN 'HAS SECURITY DEFINER ⚠️'
        ELSE 'Clean ✅'
    END as security_status
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname IN ('coach_intervention_queue', 'momentum_dashboard', 'recent_user_momentum', 'intervention_candidates')
ORDER BY viewname;
```

**Expected Result:** All 4 views should show `security_status = 'Clean ✅'`

## 3. Check for ANY Remaining SECURITY DEFINER Views

```sql
SELECT 
    schemaname,
    viewname,
    'SECURITY DEFINER FOUND' as issue
FROM pg_views 
WHERE schemaname = 'public' 
AND definition LIKE '%SECURITY DEFINER%'
ORDER BY viewname;
```

**Expected Result:** No rows should be returned (empty result set)

## 4. Verify View Options (PostgreSQL 11+)

```sql
SELECT 
    schemaname,
    viewname,
    (options).option_name,
    (options).option_value
FROM (
    SELECT 
        schemaname,
        viewname,
        unnest(reloptions) as options
    FROM pg_views v
    JOIN pg_class c ON c.relname = v.viewname
    WHERE schemaname = 'public' 
    AND viewname IN ('coach_intervention_queue', 'momentum_dashboard', 'recent_user_momentum', 'intervention_candidates')
) x
WHERE (options).option_name = 'security_invoker';
```

**Expected Result:** Should show `security_invoker = true` for all 4 views

## 5. Check Migration History

```sql
SELECT version, name, statements
FROM supabase_migrations.schema_migrations 
WHERE version >= '20250120000000'
ORDER BY version;
```

**Expected Result:** Should show our 3 security fix migrations applied

---

## ✅ If All Queries Return Expected Results:

The security fixes are **definitely applied in production**. The Supabase
Security Advisor is showing **cached/stale results**.

**Timeline for Security Advisor Update:** 2-6 hours typically

## ⚠️ If Any Query Shows Unexpected Results:

There may be a sync issue between local and production. Please share the results
and we'll investigate further.

## 🎯 Next Steps:

1. **Run these queries in Supabase Studio**
2. **Compare results with expected outcomes**
3. **Wait for Security Advisor cache to refresh (2-6 hours)**
4. **Re-run Security Advisor scan manually if possible**
