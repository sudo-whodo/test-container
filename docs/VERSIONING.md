# Versioning System

This project uses a **hybrid versioning system** that accommodates both teams that use conventional commits and those that don't.

## Quick Start

### Option 1: Conventional Commits (Recommended)
```bash
git commit -m "feat: add new feature"
git commit -m "fix: resolve bug"
git commit -m "feat!: breaking change"
```

### Option 2: PR Labels (Fallback)
```bash
# Regular commit messages
git commit -m "add new feature"

# Add labels to PR before merging:
# - 'feature' or 'minor' for new features
# - 'fix' or 'patch' for bug fixes
# - 'major' or 'breaking-change' for breaking changes
# - 'no-release' to skip versioning
```

## How It Works

### Priority Order
1. **Conventional Commits** (Primary) - If any commits follow conventional format
2. **PR Labels** (Fallback) - If no conventional commits found
3. **PR Titles** (Secondary Fallback) - Check PR titles for conventional format
4. **Default Patch** (Final Fallback) - Any other changes default to patch

### Version Bumps
- **Major** (1.0.0 → 2.0.0): Breaking changes
- **Minor** (1.0.0 → 1.1.0): New features
- **Patch** (1.0.0 → 1.0.1): Bug fixes

### Release Process
1. **Push to main** → Automatic Release Candidate (RC)
2. **Manual trigger** → Production Release

## Available PR Labels

| Label | Aliases | Version Bump | Example |
|-------|---------|--------------|---------|
| `major` | `breaking-change` | Major | 1.0.0 → 2.0.0 |
| `minor` | `feature` | Minor | 1.0.0 → 1.1.0 |
| `patch` | `bugfix`, `fix` | Patch | 1.0.0 → 1.0.1 |
| `no-release` | `skip-release` | None | No version change |

## Automatic PR Analysis

When you create a PR, the system automatically:
- ✅ Analyzes labels and title for version impact
- 💬 Posts a comment showing detected version bump
- 🔄 Updates comment when labels change
- 📚 Provides guidance on available labels

## Helpful Commands

```bash
# Show conventional commit examples
make commit-help

# Show PR label options
make pr-labels-help

# Analyze recent merged PRs
make analyze-prs

# Preview next version
make version-preview

# Check current release info
make release-info
```

## Examples

### Mixed Team Workflow

**Developer A** (uses conventional commits):
```bash
git commit -m "feat: add user authentication"
# → Will trigger minor version bump
```

**Developer B** (uses PR labels):
```bash
git commit -m "add user authentication feature"
# → Adds 'feature' label to PR
# → Will trigger minor version bump when merged
```

**Result**: Both approaches work seamlessly together!

### Version Determination Logic

```
Merged PRs since last release:
├── PR #123: "feat: add API endpoint" (conventional commit)
├── PR #124: "update docs" + [no-release] label
├── PR #125: "fix bug" + [patch] label
└── PR #126: "new feature" + [feature] label

Result: Minor version bump (highest priority change)
```

## Troubleshooting

**Q: My PR didn't trigger a release**
- Check if PR has `no-release` or `skip-release` label
- Verify tests are passing
- Check if commits are documentation/chore only

**Q: Wrong version bump detected**
- Add correct label to PR before merging
- Use conventional commit format for automatic detection
- Check CONTRIBUTING.md for detailed examples

**Q: Want to skip a release**
- Add `no-release` or `skip-release` label to PR
- Or use commit message with `[skip ci]`

For more details, see [CONTRIBUTING.md](CONTRIBUTING.md).
