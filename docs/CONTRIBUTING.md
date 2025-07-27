# Contributing to Test Container

## Conventional Commits

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation.

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature (triggers minor version bump)
- **fix**: A bug fix (triggers patch version bump)
- **perf**: A code change that improves performance (triggers patch version bump)
- **refactor**: A code change that neither fixes a bug nor adds a feature (triggers patch version bump)
- **revert**: Reverts a previous commit (triggers patch version bump)
- **docs**: Documentation only changes (no version bump)
- **style**: Changes that do not affect the meaning of the code (no version bump)
- **test**: Adding missing tests or correcting existing tests (no version bump)
- **build**: Changes that affect the build system or external dependencies (no version bump)
- **ci**: Changes to CI configuration files and scripts (no version bump)
- **chore**: Other changes that don't modify src or test files (no version bump)

### Breaking Changes

Add `BREAKING CHANGE:` in the footer or `!` after the type to trigger a major version bump:

```
feat!: remove deprecated API endpoint

BREAKING CHANGE: The /old-api endpoint has been removed. Use /api/v1 instead.
```

### Examples

#### Features
```bash
git commit -m "feat: add health check endpoint"
git commit -m "feat(api): add user authentication"
git commit -m "feat!: migrate to FastAPI 2.0"
```

#### Bug Fixes
```bash
git commit -m "fix: resolve memory leak in container startup"
git commit -m "fix(docker): correct port binding issue"
```

#### Documentation
```bash
git commit -m "docs: update API documentation"
git commit -m "docs(readme): add installation instructions"
```

#### Chores
```bash
git commit -m "chore: update dependencies"
git commit -m "chore(deps): bump fastapi to 0.104.1"
```

#### CI/CD
```bash
git commit -m "ci: add automated testing workflow"
git commit -m "ci(release): configure semantic versioning"
```

### Scopes (Optional)

Common scopes for this project:
- `api`: API-related changes
- `docker`: Docker/containerization changes
- `tests`: Test-related changes
- `deps`: Dependency updates
- `config`: Configuration changes
- `docs`: Documentation changes

### Release Process

This project uses a **hybrid versioning system** with a two-stage release process: **Release Candidates (RC)** and **Production Releases**.

#### Version Determination (Hybrid Approach)

The system uses **multiple methods** to determine version bumps, with fallbacks for teams that don't use conventional commits:

1. **Conventional Commits** (Primary): Standard semantic versioning from commit messages
2. **PR Labels** (Fallback): Version bumps determined by pull request labels
3. **PR Titles** (Secondary Fallback): Conventional commit format in PR titles
4. **Default Patch** (Final Fallback): Any other changes default to patch version

#### PR Labels for Version Control

When conventional commits aren't used, you can control versioning with PR labels:

- **`major`** or **`breaking-change`**: Major version bump (1.0.0 → 2.0.0)
- **`minor`** or **`feature`**: Minor version bump (1.0.0 → 1.1.0)
- **`patch`**, **`bugfix`**, or **`fix`**: Patch version bump (1.0.0 → 1.0.1)
- **`no-release`** or **`skip-release`**: No version bump

#### Automatic PR Analysis

When you create a PR, the system automatically:
- Analyzes PR labels and title for version impact
- Posts a comment showing the detected version bump
- Updates the comment when labels change
- Provides guidance on available labels

#### Release Candidates (Automatic)

When you push to `main`, the release workflow automatically:
- **Runs all tests** - Release only happens if tests pass
- **Tries conventional commits first** - Uses semantic-release if commits are properly formatted
- **Falls back to PR analysis** - Analyzes merged PR labels if conventional commits don't work
- **Calculates version bump** - Uses the highest priority change (major > minor > patch)
- Creates a release candidate (RC) if there are relevant changes
- Tags the release as `vX.Y.Z-rc`
- Builds Docker images with RC tags (`X.Y.Z-rc`, `latest-rc`)
- Creates a GitHub pre-release for testing

#### Production Releases (Manual)

Production releases are triggered manually via GitHub Actions:
- Go to **Actions** → **Release** → **Run workflow**
- This creates the final production release
- Tags the release as `vX.Y.Z` (without `-rc`)
- Builds Docker images with production tags (`X.Y.Z`, `latest`)
- Generates final changelog and GitHub release

#### Version Bumping Priority

1. **Conventional Commits**: If any commits follow conventional format, semantic-release handles versioning
2. **PR Labels**: If no conventional commits, analyzes labels on merged PRs since last release
3. **PR Titles**: If no labels, checks PR titles for conventional format
4. **Default**: Any other changes default to patch version bump

#### Release Workflow Examples

**Example 1: Using Conventional Commits**
```bash
git commit -m "feat: add user authentication"
git push origin main
# → Automatic minor version RC created
```

**Example 2: Using PR Labels**
```bash
# Create PR with regular commit messages
git commit -m "add user auth feature"
# Add 'feature' label to PR before merging
# → Automatic minor version RC created when merged
```

**Example 3: Mixed Approach**
- Some developers use conventional commits
- Others rely on PR labels
- System handles both automatically with conventional commits taking priority

### Tips

- Use the imperative mood: "add feature" not "added feature"
- Keep the first line under 50 characters
- Reference issues and pull requests when applicable
- Use the body to explain what and why, not how

### Tools

You can use tools like [commitizen](https://github.com/commitizen/cz-cli) to help format commits:

```bash
npm install -g commitizen cz-conventional-changelog
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc
```

Then use `git cz` instead of `git commit` for guided commit creation.
