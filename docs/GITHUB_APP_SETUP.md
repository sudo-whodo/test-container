# GitHub App Setup for Automated Releases

This document explains the GitHub App configuration for automated releases in this repository.

## Overview

We've configured this repository to use a GitHub App instead of the default `GITHUB_TOKEN` for automated releases. This provides the necessary permissions to create releases, tags, and push changes back to the repository.

## What Was Changed

### 1. Release Workflow (`.github/workflows/release.yml`)

**Added GitHub App Token Generation:**
```yaml
- name: Generate GitHub App Token
  id: app-token
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}
```

**Updated Token Usage:**
- Replaced all `${{ secrets.GITHUB_TOKEN }}` references with `${{ steps.app-token.outputs.token }}`
- Updated checkout action to use app token
- Updated semantic-release to use app token
- Updated GitHub release creation to use app token

### 2. Required Repository Secrets

The following secrets must be configured in your repository settings:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `APP_ID` | GitHub App ID | `123456` |
| `APP_PRIVATE_KEY` | GitHub App Private Key | `-----BEGIN RSA PRIVATE KEY-----...` |

## GitHub App Configuration

### Required Permissions

Your GitHub App should have these **Repository permissions**:

- **Contents**: `Read and write` (create tags, update files)
- **Metadata**: `Read` (access repository info)
- **Pull requests**: `Write` (update PR status, create comments)
- **Issues**: `Write` (create release comments)
- **Actions**: `Read` (access workflow information)

### Installation

- Install the app on your repository (or organization)
- The app only needs access to repositories where you want automated releases

## How It Works

### Security Model

1. **Token Scoping**: Each workflow run generates a token scoped only to the current repository
2. **Minimal Permissions**: The app only has the permissions it needs for releases
3. **Repository Isolation**: The app cannot access other repositories from this workflow

### Workflow Process

1. **Token Generation**: First step generates a repository-scoped token
2. **Checkout**: Uses app token to checkout code with full history
3. **Semantic Release**: Uses app token to create releases and push tags
4. **GitHub Releases**: Uses app token to create GitHub releases

## Benefits Over Default GITHUB_TOKEN

| Feature | Default GITHUB_TOKEN | GitHub App Token |
|---------|---------------------|------------------|
| Create releases | ❌ Limited | ✅ Full access |
| Push tags | ❌ Limited | ✅ Full access |
| Update repository | ❌ Limited | ✅ Full access |
| Security | ⚠️ Broad permissions | ✅ Minimal permissions |
| Cross-repo access | ❌ Possible | ✅ Isolated |

## Troubleshooting

### Common Issues

1. **"Resource not accessible by integration"**
   - Check app permissions (Contents: Write, Pull requests: Write)
   - Verify app is installed on the repository

2. **"Bad credentials"**
   - Verify `APP_ID` is correct (just the number)
   - Verify `APP_PRIVATE_KEY` includes the full PEM content with headers

3. **Token generation fails**
   - Check that secrets are properly set in repository settings
   - Verify the app is installed and has access to the repository

### Verification Steps

1. **Check App Installation:**
   ```bash
   # Go to your repository → Settings → Integrations
   # Verify your app is listed and has access
   ```

2. **Test Token Generation:**
   ```yaml
   - name: Test App Token
     run: |
       echo "Token generated successfully"
       echo "Token length: ${#GITHUB_TOKEN}"
     env:
       GITHUB_TOKEN: ${{ steps.app-token.outputs.token }}
   ```

## Reusing the App

This same GitHub App can be used across multiple repositories:

1. **Install the app** on additional repositories
2. **Copy the workflow files** to other repositories
3. **Add the same secrets** (`APP_ID` and `APP_PRIVATE_KEY`) to each repository

Each repository will be completely isolated - workflows in one repository cannot affect another.

## Dependabot Auto-Merge

The GitHub App is also configured to automatically approve and merge Dependabot PRs based on safety criteria:

### Auto-Merge Rules

**Automatically Merged:**
- ✅ Patch version updates (1.0.0 → 1.0.1)
- ✅ Minor version updates (1.0.0 → 1.1.0)
- ✅ Security updates (any version)
- ✅ Test dependencies (any version)

**Auto-Approved Only (Manual Merge Required):**
- ⚠️ Major version updates (1.0.0 → 2.0.0)
- ⚠️ Non-standard version formats

### Workflow: `.github/workflows/dependabot-auto-merge.yml`

1. **Analyzes** Dependabot PRs for safety
2. **Waits** for CI checks to complete
3. **Approves** safe dependency updates
4. **Merges** low-risk updates automatically
5. **Comments** with detailed reasoning

### Safety Features

- Only runs on Dependabot PRs
- Waits for all CI checks to pass
- Uses squash merge to maintain clean history
- Provides detailed comments explaining actions
- Blocks merge if any tests fail

## Next Steps

1. ✅ GitHub App created and configured
2. ✅ Repository secrets added
3. ✅ Workflow updated to use app token
4. ✅ Dependabot auto-merge configured
5. 🔄 Test the release workflow
6. 🔄 Test Dependabot auto-merge
7. 🔄 Monitor for any permission issues

## Testing

To test the setup:

1. **Create a test PR** with appropriate labels (`patch`, `minor`, or `major`)
2. **Merge the PR** to trigger the release-candidate workflow
3. **Check the workflow logs** for successful token generation and release creation
4. **Verify the release** was created in GitHub releases

The workflow should now have the necessary permissions to create releases automatically!
