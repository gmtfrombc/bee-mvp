# Supabase CLI Version Management

## Overview

We pin the Supabase CLI to a specific version to prevent breaking changes from
causing unexpected failures in our CI/CD pipeline. This ensures consistent
behavior across all environments.

## Current Setup

- **Pinned Version**: `2.30.4`
- **GitHub Workflow**: `.github/workflows/migrations-deploy.yml`
- **Local CI Script**: `scripts/run_ci_locally.sh`
- **Update Script**: `scripts/update_supabase_version.sh`

## Why We Pin Versions

1. **Stability**: Prevents breaking changes from newer CLI versions
2. **Consistency**: Ensures local CI matches remote CI behavior
3. **Predictability**: Avoids surprise failures in production deployments
4. **Debugging**: Makes it easier to reproduce issues across environments

## Version Compatibility Checks

Both the GitHub workflow and local CI script include version compatibility
checks:

- **GitHub**: Warns if the actual version doesn't match the pinned version
- **Local**: Prompts user to continue or abort if version mismatch is detected

## Updating the Pinned Version

### Automated Update (Recommended)

Use the provided script to update all files consistently:

```bash
./scripts/update_supabase_version.sh 2.31.0
```

This script:

1. Validates the version format
2. Updates the GitHub workflow file
3. Updates the local CI script
4. Provides next steps for testing and deployment

### Manual Update

If you need to update manually:

1. **GitHub Workflow** (`.github/workflows/migrations-deploy.yml`):
   ```yaml
   - name: Setup Supabase CLI
     uses: supabase/setup-cli@v1
     with:
         version: 2.31.0 # Update this line

   - name: Verify Supabase CLI version compatibility
     run: |
         EXPECTED_VERSION="2.31.0"  # Update this line
   ```

2. **Local CI Script** (`scripts/run_ci_locally.sh`):
   ```bash
   EXPECTED_VERSION="2.31.0"  # Update this line
   ```

## Testing Version Updates

Before deploying a version update:

1. **Test Locally**:
   ```bash
   # Update your local CLI first
   brew upgrade supabase

   # Test the local CI
   ./scripts/run_ci_locally.sh -j deploy --env ACT=false --env SKIP_TERRAFORM=true
   ```

2. **Test in CI**:
   - Create a feature branch
   - Push the version update
   - Monitor the GitHub Actions workflow

3. **Verify Functionality**:
   - Check that migrations still work
   - Verify authentication still functions
   - Ensure no new errors appear

## Monitoring for New Versions

Stay informed about new Supabase CLI releases:

- **GitHub Releases**: https://github.com/supabase/cli/releases
- **Changelog**: Check release notes for breaking changes
- **Documentation**: Review CLI docs for new features/changes

## Troubleshooting

### Version Mismatch Errors

If you see version mismatch warnings:

1. **In GitHub Actions**:
   - Check the workflow logs
   - Update the pinned version if needed
   - Re-run the workflow

2. **In Local CI**:
   - Update your local CLI: `brew upgrade supabase`
   - Or use the specific version: `npm install supabase@1.83.7`
   - Re-run the local CI

### CLI Command Changes

If CLI commands change between versions:

1. Review the release notes
2. Update any affected scripts
3. Test thoroughly in development
4. Update documentation as needed

## Best Practices

1. **Regular Updates**: Review and update the pinned version monthly
2. **Test Thoroughly**: Always test version updates in development first
3. **Monitor Releases**: Subscribe to Supabase CLI release notifications
4. **Document Changes**: Note any breaking changes in commit messages
5. **Gradual Rollout**: Update development environments before production

## Emergency Rollback

If a version update causes issues:

1. **Immediate Fix**:
   ```bash
   ./scripts/update_supabase_version.sh 1.83.7  # Rollback to known good version
   git add . && git commit -m "ci: rollback Supabase CLI to v1.83.7"
   git push origin main
   ```

2. **Investigate**: Determine what caused the issue
3. **Plan Fix**: Address the root cause before trying the update again

## Related Files

- `.github/workflows/migrations-deploy.yml` - GitHub Actions workflow
- `scripts/run_ci_locally.sh` - Local CI script
- `scripts/update_supabase_version.sh` - Version update automation
- `docs/0_0_Core_docs/supabase_cli_version_management.md` - This documentation
