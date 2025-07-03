# Security Policy - BEE Momentum Meter

## 🚨 Current Security Status

**LAST AUDIT:** January 2025\
**CRITICAL ISSUES FOUND:** ✅ Resolved (13 exposed secrets removed)

## Supported Versions

We maintain the latest `main` branch. Previous versions are not supported for
security fixes.

## Reporting a Vulnerability

If you discover a security issue **please DO NOT open a public GitHub issue**.
Instead:

- Send an email to `security@bee-mvp.io`
- Or reach out to @gmtfr directly with details
- We will acknowledge your report within 24h and provide a fix timeline

## 🔐 Secrets Management - 2025 Best Practices

### ✅ **RECOMMENDED APPROACH (Current)**

**1. Development Setup:**

```bash
# Create app/.env file (never committed)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Run development server
./run_dev.sh
```

**2. Production/CI Setup:**

```bash
# Use --dart-define flags (secure)
flutter build apk \
  --dart-define="SUPABASE_URL=$PROD_URL" \
  --dart-define="SUPABASE_ANON_KEY=$PROD_KEY"
```

### 🏗️ **Architecture Overview**

- **Local Development:** `.env` files (gitignored)
- **CI/CD:** GitHub Secrets → `--dart-define` flags
- **Production:** Build-time injection via `--dart-define`
- **Client Code:** `AppSecrets` class with safe defaults

### 📁 **File Structure**

```
app/
├── .env                    # ❌ Never commit (local only)
├── .env.example           # ✅ Safe template (TODO: create)
├── lib/core/config/
│   ├── app_secrets.dart   # ✅ Centralized secrets management  
│   └── environment.dart   # ✅ Fallback compatibility
└── firebase_options.dart  # ✅ Placeholder values only
```

## 🛡️ **Security Controls**

### **1. GitLeaks Integration**

```bash
# Pre-commit scanning (automatic)
git commit -m "Your changes"
# → GitLeaks scans staged changes

# Manual scanning
gitleaks detect --source . --config .gitleaks.toml
```

### **2. Pre-commit Hooks**

```bash
# Setup (one-time)
git config core.hooksPath .githooks

# Automatic protection
- Blocks .env files from commits
- Scans for secrets with GitLeaks
- Shows clear error messages
```

### **3. GitHub Actions Security**

```yaml
# Secrets are stored in GitHub Settings → Secrets
env:
   SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

### **4. CI/CD Pipeline**

- ✅ Uses GitHub Secrets (not committed values)
- ✅ Firebase uses placeholder configurations
- ✅ All sensitive operations use `--dart-define`

## 📋 **Developer Checklist**

### **Before First Run:**

- [ ] Copy `.secrets.example` to `~/.bee_secrets/supabase.env` and fill in real
      values (never commit)
- [ ] Copy `app/.env.example` to `app/.env` (when available)
- [ ] Ensure `gitleaks` binary is installed locally (pre-commit hook now fails
      if missing)
- [ ] Verify `git config core.hooksPath .githooks`
- [ ] Test: `gitleaks detect --source app/`

### **Before Each Commit:**

- [ ] Remove any debugging credentials
- [ ] Run `gitleaks detect --staged`
- [ ] Verify no `.env` files in `git status`
- [ ] Check pre-commit hooks are working

### **Before Production Deploy:**

- [ ] All secrets use `--dart-define` flags
- [ ] Firebase config contains only placeholders
- [ ] GitHub Secrets are up to date
- [ ] Test build without local `.env` files

## 🔄 **Rotating Compromised Keys**

### **Immediate Response (if secrets leaked):**

1. **Generate new keys:**
   ```bash
   # Supabase: Dashboard → Settings → API → "Generate new anon key"
   # Firebase: Console → Project Settings → Service Accounts → "Generate new key"
   ```

2. **Update all locations:**
   ```bash
   # Local development
   vim app/.env

   # GitHub Secrets
   gh secret set SUPABASE_ACCESS_TOKEN

   # Production deployment
   # Update your deployment scripts with new --dart-define values
   ```

3. **Invalidate old keys:**
   - Supabase: Delete old key from dashboard
   - Firebase: Revoke old service account

4. **Force-push to all environments** to ensure immediate key rotation

## 🚫 **Security Anti-Patterns to Avoid**

### ❌ **NEVER DO:**

```dart
// DON'T hardcode secrets
const String apiKey = "real_secret_key_here";

// DON'T commit .env files
git add app/.env  // ← This will be blocked

// DON'T use service role keys in client apps
const serviceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";

// DON'T put secrets in documentation
curl -H "Authorization: Bearer sk_live_real_key"
```

### ✅ **DO INSTEAD:**

```dart
// Use centralized secrets management
import '../config/app_secrets.dart';

final apiKey = AppSecrets.supabaseAnonKey;

// Use placeholder examples in docs
curl -H "Authorization: Bearer YOUR_API_KEY"

// Use build-time injection
flutter run --dart-define="API_KEY=$API_KEY"
```

## 🏢 **GitHub Repository Security**

### **Required Settings:**

- [ ] **2-factor authentication** for all collaborators
- [ ] **Branch protection** with mandatory reviews
- [ ] **Secret scanning & push protection** enabled
- [ ] **Dependency scanning** enabled (Dependabot)
- [ ] **Code scanning** enabled (CodeQL)

### **Periodic Tasks:**

```bash
# Audit tokens quarterly
gh secret list
gh auth status

# Check repository security tab
# Review dependency alerts
# Update security policies
```

## 📊 **Security Monitoring**

### **Continuous Monitoring:**

- GitLeaks scans on every commit
- GitHub Advanced Security alerts
- Dependabot vulnerability notifications
- Regular secret rotation (quarterly)

### **Security Metrics:**

- Secrets exposure incidents: **0 target**
- Failed GitLeaks scans: **< 5% of commits**
- Security patches applied: **< 7 days**
- 2FA coverage: **100% team members**

## 🆘 **Incident Response**

### **If Secrets Are Exposed:**

1. **Immediate:** Revoke compromised credentials
2. **Within 1 hour:** Generate and deploy new credentials
3. **Within 24 hours:** Complete security review
4. **Within 48 hours:** Post-mortem and process improvements

### **Emergency Contacts:**

- Security Lead: @gmtfr
- Email: security@bee-mvp.io
- Escalation: GitHub security advisory

---

**Last Updated:** January 2025\
**Next Review:** April 2025

> 💡 **Remember:** Security is everyone's responsibility. When in doubt, ask for
> a security review before committing.
