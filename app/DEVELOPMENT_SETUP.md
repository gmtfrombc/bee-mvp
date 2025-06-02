# Development Environment Setup

## 🚨 URGENT: Environment Configuration Required

Your local development environment is currently using placeholder values that will cause connection failures.

## Current Issue
The `.env` file contains placeholder values:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key-here
```

## Quick Fix Required

### Step 1: Get Your Real Supabase Credentials
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your BEE-MVP project
3. Go to Settings > API
4. Copy the following values:
   - **Project URL** (looks like: `https://abcdefg.supabase.co`)
   - **anon/public key** (long string starting with `eyJ...`)

### Step 2: Update Your .env File
Replace the placeholder values in `app/.env` with your real values:

```bash
# Update app/.env with your real values:
ENVIRONMENT=development
SUPABASE_URL=https://YOUR_REAL_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=YOUR_REAL_ANON_KEY_HERE
FIREBASE_PROJECT_ID=bee-mvp-3ab43
APP_VERSION=1.0.0
```

### Step 3: Verify Connection
Run the app and check that you no longer see the error:
```
Failed host lookup: 'your-project.supabase.co'
```

## Security Note
- ✅ The `.env` file is git-ignored for security
- ✅ Never commit real credentials to version control
- ✅ The CI/CD uses safe placeholder values for builds

## Firebase Configuration
The Firebase configuration is properly set up with CI-safe placeholder values that allow compilation without real Firebase services. 