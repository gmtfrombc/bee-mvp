# 🤖 BEE MVP - Automated Development Workflows

**Created:** January 6, 2025  
**Purpose:** Complete reference for local development and production testing automation  
**Scope:** Environment management, testing pipelines, and deployment workflows  

---

## 📋 **Quick Reference**

| Command | Purpose | Environment | When to Use |
|---------|---------|-------------|-------------|
| `./supa` | Start local Supabase backend | Local | Daily development |
| `./bee` | Start Flutter app (local mode) | Local | Daily development |
| `./bee-prod` | Test app with production backend | Production | Quick production verification |
| `./test-deploy` | Full deployment pipeline | Local → Production | Feature complete/major releases |

---

## 🏗️ **Development Strategy**

### **Phase 1: Local Development** 🏠
- **Goal:** Rapid iteration, safe testing, feature development
- **Data:** Test users, seed data, isolated from production
- **Speed:** Fast startup, immediate feedback

### **Phase 2: Production Testing** 🌐
- **Goal:** Verify real-world functionality, integration testing
- **Data:** Real users, live data, production environment
- **Safety:** Automated backup/restore, clear warnings

---

## 🔧 **Environment Configuration**

### **Local Development** (`app/.env`)
```bash
ENVIRONMENT=development
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
FLUTTER_ENV=development
AI_API_KEY=sk-proj-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### **Production Configuration** (temporary, auto-managed)
```bash
ENVIRONMENT=production
SUPABASE_URL=https://okptsizouuanwnpqjfui.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
FLUTTER_ENV=production
```

---

## 🚀 **Workflow Commands**

### **1. `./supa` - Local Backend Startup**

**What it does:**
- ✅ Checks and starts Docker (if needed)
- ✅ Kills existing Supabase processes
- ✅ Starts local Supabase server
- ✅ Uses `app/.env` for configuration
- ✅ Serves at `http://127.0.0.1:54321`

**When to use:**
- Starting daily development session
- Need local database for testing
- Developing new features requiring backend

**Example:**
```bash
./supa
# Output:
# 🐝 Starting BEE-MVP Supabase Environment...
# ✅ Docker is already running
# 🚀 Starting Supabase functions server...
# 🌐 Server will be available at: http://127.0.0.1:54321
```

---

### **2. `./bee` - Local App Development**

**What it does:**
- ✅ Reads `app/.env` (local configuration)
- ✅ Starts Flutter app with local backend
- ✅ Connects to `http://127.0.0.1:54321`
- ✅ Uses test users and seed data

**When to use:**
- Daily development work
- Testing new features
- UI/UX iteration
- Recovery plan implementation

**Example:**
```bash
./bee
# Output:
# 🚀 Starting BEE Momentum Meter in development mode...
# ✅ Environment configured, launching app...
# [Flutter startup logs...]
```

---

### **3. `./bee-prod` - Production App Testing**

**What it does:**
- ✅ Backs up current `app/.env`
- ✅ Temporarily switches to production config
- ✅ Starts Flutter app with production backend
- ✅ Shows warnings about real data usage
- ✅ Automatically restores local config on exit

**When to use:**
- Quick production verification
- Testing with real users/data
- Verifying feature works end-to-end
- Post-deployment validation

**Safety features:**
- 💾 Automatic backup/restore of local config
- ⚠️ Clear warnings about production data
- 🔄 Cleanup on script exit (Ctrl+C safe)

**Example:**
```bash
./bee-prod
# Output:
# 🌐 BEE-MVP: Switching to PRODUCTION for testing...
# 💾 Backed up current .env to .env.backup
# ✅ Switched to production configuration
# ⚠️  This will use REAL production data and users!
```

---

### **4. `./test-deploy` - Complete Deployment Pipeline**

**What it does:**
- ✅ **Step 1:** Runs local tests (Flutter + custom)
- ✅ **Step 2:** Deploys functions to production
- ✅ **Step 3:** Verifies production API endpoints
- ✅ **Step 4:** Optionally starts production app testing

**When to use:**
- Feature development complete
- Major releases
- Recovery plan milestone completion
- Full integration testing

**Pipeline stages:**
1. **Local Testing** - Ensures code quality
2. **Production Deployment** - Updates live functions
3. **API Verification** - Tests production endpoints
4. **App Testing** - Optional full end-to-end test

**Example:**
```bash
./test-deploy
# Output:
# 🧪 BEE-MVP: Complete Development → Production Testing Pipeline
# 1️⃣ Running Local Tests...
# ✅ Local tests passed
# 2️⃣ Deploying to Production...
# ✅ Production deployment complete
# 3️⃣ Production Verification...
# ✅ Production verification passed
# 🎯 Start production app testing now? (y/N):
```

---

## 📊 **Development Workflows**

### **Daily Development Cycle**
```bash
# Morning startup
./supa          # Terminal 1: Start backend
./bee           # Terminal 2: Start app

# Development loop
# 1. Code changes
# 2. Hot reload in Flutter
# 3. Test features
# 4. Iterate

# End of day
# Ctrl+C both terminals
```

### **Feature Completion Workflow**
```bash
# After feature development
./test-deploy   # Complete pipeline

# If tests pass:
# ✅ Feature deployed to production
# ✅ Ready for user testing

# If tests fail:
# 🔄 Back to ./bee for fixes
```

### **Recovery Plan Development**
```bash
# For Epic 1.3 tasks (T1.3.2.6 - T1.3.2.8)
./supa          # Local backend
./bee           # Local app testing

# When task complete:
./test-deploy   # Deploy to production
./bee-prod      # Verify with real data
```

---

## 🎯 **Environment Decision Matrix**

| Scenario | Command | Reason |
|----------|---------|---------|
| **New feature development** | `./supa` + `./bee` | Safe iteration with test data |
| **UI/UX changes** | `./supa` + `./bee` | Fast feedback loop |
| **API integration testing** | `./supa` + `./bee` | Controlled environment |
| **Ready for user testing** | `./test-deploy` | Full deployment pipeline |
| **Quick production check** | `./bee-prod` | Fast verification |
| **Bug investigation** | `./bee-prod` | Test with real data |
| **Demo preparation** | `./bee-prod` | Use production data |

---

## 🛡️ **Safety Features**

### **Automatic Backups**
- `bee-prod` always backs up your local config
- Restoration happens automatically on script exit
- Safe to Ctrl+C at any time

### **Clear Environment Indicators**
- Each script shows which environment you're using
- Production warnings before using real data
- Environment variables clearly labeled

### **Fail-Safe Mechanisms**
- Scripts exit on any error (`set -e`)
- Docker startup verification
- Production API verification before app testing

### **Data Protection**
- Local and production data completely isolated
- No accidental production writes during development
- Test users separate from real users

---

## 🔍 **Troubleshooting**

### **Common Issues**

**"Docker not running" error:**
```bash
# The supa script will automatically start Docker
# Wait for startup message: "✅ Docker is ready!"
```

**"Function failed to boot" error:**
```bash
# Check function logs in terminal running ./supa
# Usually indicates missing environment variables
```

**Production connection issues:**
```bash
# Verify production deployment:
supabase functions list

# Check function logs:
supabase functions logs ai-coaching-engine
```

**Environment confusion:**
```bash
# Check current environment:
cat app/.env

# Reset to local development:
# Delete app/.env.backup if it exists
# Ensure app/.env points to localhost
```

---

## 📈 **Performance Tips**

### **Development Speed**
- Keep `./supa` running in background terminal
- Use Flutter hot reload for UI changes
- Local database is much faster than production

### **Production Testing**
- Use `./bee-prod` sparingly (uses real API quota)
- Run `./test-deploy` only for significant changes
- Local tests catch most issues before production

### **Resource Management**
- Docker Desktop can be heavy - close other apps if needed
- Flutter app uses device/simulator resources
- Production API calls count against quotas

---

## 🎯 **Recovery Plan Integration**

### **Current Status (T1.3.2.5 Complete)**
- ✅ Real engagement data integration deployed
- ✅ Both local and production synchronized
- ✅ Ready for T1.3.2.6 development

### **Next Tasks Workflow**
```bash
# T1.3.2.6: Coaching effectiveness measurement
./supa + ./bee    # Develop locally
./test-deploy     # Deploy when ready

# T1.3.2.7: Frequency optimization  
./supa + ./bee    # Develop locally
./test-deploy     # Deploy when ready

# T1.3.2.8: Cross-patient patterns
./supa + ./bee    # Develop locally
./test-deploy     # Deploy when ready
```

---

## 📚 **Quick Start Guide**

### **First Time Setup**
1. ✅ Ensure Docker Desktop is installed
2. ✅ Verify `app/.env` exists with local config
3. ✅ Make all scripts executable: `chmod +x supa bee bee-prod test-deploy`

### **Daily Development**
```bash
./supa    # Start backend (keep running)
./bee     # Start app (new terminal)
```

### **Feature Complete**
```bash
./test-deploy    # Full pipeline
```

### **Quick Production Test**
```bash
./bee-prod       # Temporary production mode
```

---

**📞 Support:** Refer to recovery plan documents in `docs/1_3_Epic_Adaptive_Coach/`  
**🔄 Updates:** This document is updated as workflows evolve  
**🎯 Goal:** Seamless development → production workflow for BEE MVP 