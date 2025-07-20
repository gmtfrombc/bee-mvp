# Founder Walk-Through QA – Document 0

> Version 1.0 · **Phase 0 – Stability & Hygiene**\
> Prepared for: Solo-founder (iPhone-only)\
> Prepared by: AI Pair-Programmer\
> Last updated: <!-- yyyy-mm-dd will be filled by commit hook -->

---

## 1 Purpose

Provide a repeatable, checklist-style Quality Assurance (QA) procedure so a
non-technical founder can manually validate the **current MVP build** on an
_iPhone_. This walk-through targets the four epics slated for Phase 0:

| # | Epic | Description                                   |
| - | ---- | --------------------------------------------- |
| 1 | 1.6  | Registration & Authentication                 |
| 2 | 1.11 | Onboarding Intake Surveys                     |
| 3 | 1.5  | Weekly **Action Steps**                       |
| 4 | 1.7  | Health Signals – Perceived Energy Score (PES) |

The document covers:

- Preconditions & test account reset workflow
- Step-by-step test scripts per epic
- Clear **acceptance criteria** / expected results
- SQL snippets to verify data in Supabase
- Pass / Fail recording tables

---

## 2 Pre-Test Checklist

| Item               | Details                                                         | Done |
| ------------------ | --------------------------------------------------------------- | ---- |
| App build          | Install latest TestFlight build (build number ≥ current sprint) | ☐    |
| Network            | Stable Wi-Fi or cellular                                        | ☐    |
| Supabase dashboard | Access to `app.supabase.com → <project>` with **SQL editor**    | ☐    |
| Service role key   | _Not required_; all SQL run via dashboard                       | ☐    |
| Screen recording   | iOS screen-record ON for bug capture (optional)                 | ☐    |

### 2.1 Environment Reset (repeatable onboarding)

Because the app skips onboarding when `profiles.onboarding_complete = TRUE`, we
must delete the user between runs. Do this **before** each new test cycle.

1. Open Supabase → SQL Editor
2. Replace `<EMAIL>` in the block below and **Run**:

```sql
-- 🔄 Full user reset (Auth + profile + domain data)
-- 1) Grab the user_id for the email
SELECT id INTO TEMP t_uid FROM auth.users WHERE email = '<EMAIL>' LIMIT 1;

-- 2) Delete domain rows (CASCADE safe)
DELETE FROM public.action_steps       WHERE user_id IN (SELECT * FROM t_uid);
DELETE FROM public.onboarding_responses WHERE user_id IN (SELECT * FROM t_uid);
DELETE FROM public.pes_entries        WHERE user_id IN (SELECT * FROM t_uid);
DELETE FROM public.profiles           WHERE user_id IN (SELECT * FROM t_uid);

-- 3) Finally delete the auth record
DELETE FROM auth.users WHERE id IN (SELECT * FROM t_uid);
```

3. Confirm **0 rows** remain:
   `SELECT * FROM auth.users WHERE email = '<EMAIL>';`
4. Launch the app – it should open to **Registration**.

---

## 3 Test Scripts & Acceptance Criteria

For each epic use the template:

> ① **Feature** ② **Test Steps** ③ **Expected Result** ④ **Result (Pass/Fail &
> notes)**

### 3.1 Epic 1.6 – Registration & Auth

| # | Feature / Scenario    | How to Test                                                                                       | Acceptance Criteria                                                                   | Result |
| - | --------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ------ |
| 1 | Register new user     | a. Launch app → **Register** <br/>b. Enter valid email & 12-char password <br/>c. Tap **Sign Up** | • No validation errors <br/>• App auto-logs in and navigates to **Onboarding** screen | ☐      |
| 2 | Duplicate email guard | Repeat **Register** with same email                                                               | • UI shows “Email already in use”                                                     | ☐      |
| 3 | Login existing user   | From **Login** screen use valid credentials                                                       | • Successful navigation to Home (if onboarding_complete = TRUE)                       | ☐      |
| 4 | Bad password          | Enter wrong password                                                                              | • Error banner “Invalid login credentials”                                            | ☐      |

**Data Verification** (run after scenario 1):

```sql
-- Verify profile row exists & onboarding incomplete
SELECT u.id, p.onboarding_complete
FROM auth.users u
JOIN public.profiles p ON p.user_id = u.id
WHERE u.email = '<EMAIL>';  -- Expect onboarding_complete = false
```

---

### 3.2 Epic 1.11 – Onboarding Intake

| # | Scenario                      | How to Test                                 | Acceptance Criteria                                                      | Result |
| - | ----------------------------- | ------------------------------------------- | ------------------------------------------------------------------------ | ------ |
| 1 | Survey navigation             | Complete each page using typical answers    | • **Next** & **Back** buttons function <br/>• Progress indicator updates | ☐      |
| 2 | Mandatory question validation | Leave a required field blank → tap **Next** | • Inline validation preventing advance                                   | ☐      |
| 3 | Submission                    | Finish survey → tap **Submit**              | • Spinner ≤ 2 s <br/>• You land on **Home** screen                       | ☐      |

**Data Verification**:

```sql
-- Answers JSON stored & profile flag flipped
SELECT r.answers, p.onboarding_complete
FROM auth.users u
JOIN public.onboarding_responses r ON r.user_id = u.id
JOIN public.profiles p            ON p.user_id = u.id
WHERE u.email = '<EMAIL>';        -- Expect onboarding_complete = true
```

---

### 3.3 Epic 1.5 – Weekly Action Steps

| # | Scenario           | How to Test                                                                                                                        | Acceptance Criteria                                                               | Result |
| - | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------ |
| 1 | Create action step | In **Action Steps** tab → **Add Step**. <br/>Choose category “Nutrition”, description “Add veggies”, frequency “5 days” → **Save** | • Step appears in list with correct text <br/>• Week progress bar = 0 % initially | ☐      |
| 2 | Edit step          | Tap step → **Edit**, change frequency to “7 days” → **Save**                                                                       | • List updates; no duplicate created                                              | ☐      |
| 3 | Delete step        | Swipe left → **Delete**                                                                                                            | • Step removed from list                                                          | ☐      |

**Data Verification** (after creation):

```sql
SELECT description, frequency
FROM public.action_steps
WHERE user_id = (SELECT id FROM auth.users WHERE email = '<EMAIL>')
  AND week_start = date_trunc('week', now());
```

---

### 3.4 Epic 1.7 – Health Signals (Perceived Energy Score)

| # | Scenario            | How to Test                                                                | Acceptance Criteria                                                    | Result |
| - | ------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ------ |
| 1 | Add PES entry       | Home → **Log Energy** button. <br/>Pick score “4 / 5” for today → **Save** | • Confirmation toast “Logged” <br/>• Gauge / chart updates immediately | ☐      |
| 2 | Duplicate day guard | Try logging a second PES for same day                                      | • UI error: “You already logged today”                                 | ☐      |

**Data Verification**:

```sql
SELECT date, score
FROM public.pes_entries
WHERE user_id = (SELECT id FROM auth.users WHERE email = '<EMAIL>')
  AND date = current_date;   -- Expect one row with score = 4
```

---

## 4 Bug Reporting Matrix

Use the table below to capture issues. Create a new row per defect.

| ID | Screen | Steps to Reproduce | Expected | Actual | Screenshot | Severity |
| -- | ------ | ------------------ | -------- | ------ | ---------- | -------- |

---

## 5 Sign-Off

After executing all tests:

- All **Result** cells should read **Pass**.
- Attach the Bug Reporting Matrix if any **Fail** cases exist.
- Sign & date:

> _Tester_: _________________________\
> _Date_: ___________________________
