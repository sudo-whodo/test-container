# Makefile for FastAPI Test Container
# Provides targets for building, running, and managing the test API

CONTAINER_NAME := test-api
IMAGE_NAME := localhost/test-api:latest
PORT := 8080

# Multi-architecture build variables
PLATFORMS := linux/amd64,linux/arm64
REGISTRY := localhost
IMAGE_BASE := test-api

.PHONY: help build run stop clean logs status test all build-multi build-arm build-x86

# Default target
all: build run

help: ## Show this help message
	@echo "FastAPI Test Container Management"
	@echo "================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make build     # Build the container image"
	@echo "  make run       # Run the container"
	@echo "  make test      # Test the API endpoints"
	@echo "  make stop      # Stop the container"
	@echo "  make clean     # Stop and remove container"

build: ## Build the FastAPI test container image
	@echo "🐳 Building FastAPI test container..."
	podman build -t $(IMAGE_NAME) .
	@echo "✅ Container image built successfully!"

run: ## Run the FastAPI test container
	@echo "🧹 Stopping and removing existing container if it exists..."
	-podman stop $(CONTAINER_NAME) 2>/dev/null
	-podman rm $(CONTAINER_NAME) 2>/dev/null
	@echo "🚀 Starting FastAPI test container..."
	podman run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):$(PORT) \
		$(IMAGE_NAME)
	@echo "⏳ Waiting for container to start..."
	@sleep 3
	@echo "✅ FastAPI test container is running!"
	@echo "🌐 API available at: http://localhost:$(PORT)"

stop: ## Stop the FastAPI test container
	@echo "🛑 Stopping FastAPI test container..."
	-podman stop $(CONTAINER_NAME)
	@echo "✅ Container stopped!"

clean: stop ## Stop and remove the FastAPI test container
	@echo "🧹 Removing FastAPI test container..."
	-podman rm $(CONTAINER_NAME)
	@echo "✅ Container removed!"

logs: ## Show container logs
	@echo "📋 Container logs:"
	podman logs $(CONTAINER_NAME)

status: ## Show container status and available endpoints
	@echo "🔍 Container status:"
	podman ps --filter name=$(CONTAINER_NAME)
	@echo ""
	@echo "🌐 Available endpoints:"
	@echo "   - http://localhost:$(PORT)/"
	@echo "   - http://localhost:$(PORT)/health"
	@echo "   - http://localhost:$(PORT)/status"
	@echo "   - http://localhost:$(PORT)/api/v1/health"
	@echo "   - http://localhost:$(PORT)/metrics"

test: ## Test the API endpoints
	@echo "🧪 Testing FastAPI endpoints..."
	@echo ""
	@echo "Testing root endpoint:"
	@curl -s http://localhost:$(PORT)/ | python3 -m json.tool || echo "❌ Root endpoint failed"
	@echo ""
	@echo "Testing health endpoint:"
	@curl -s http://localhost:$(PORT)/health | python3 -m json.tool || echo "❌ Health endpoint failed"
	@echo ""
	@echo "Testing status endpoint:"
	@curl -s http://localhost:$(PORT)/status | python3 -m json.tool || echo "❌ Status endpoint failed"
	@echo ""
	@echo "Testing API v1 health endpoint:"
	@curl -s http://localhost:$(PORT)/api/v1/health | python3 -m json.tool || echo "❌ API v1 health endpoint failed"
	@echo ""
	@echo "Testing metrics endpoint:"
	@curl -s http://localhost:$(PORT)/metrics || echo "❌ Metrics endpoint failed"
	@echo ""
	@echo "✅ API endpoint testing complete!"

restart: clean build run ## Clean, rebuild, and restart the container

dev: ## Run in development mode (build and run with logs)
	@make build
	@make run
	@echo "📋 Following logs (Ctrl+C to stop):"
	@make logs

# Container management targets
ps: ## List running containers
	podman ps

images: ## List container images
	podman images | grep test-api || echo "No test-api images found"

shell: ## Open shell in running container
	podman exec -it $(CONTAINER_NAME) /bin/bash

# Cleanup targets
clean-images: ## Remove container images
	@echo "🧹 Removing test-api images..."
	-podman rmi $(IMAGE_NAME)
	@echo "✅ Images removed!"

clean-all: clean clean-images ## Remove container and images

# Quick test target for pytest integration
pytest-setup: build run ## Setup container for pytest testing
	@echo "⏳ Waiting for API to be ready..."
	@sleep 5
	@echo "🧪 Container ready for pytest testing!"
	@echo "Run: cd .. && pytest test_http_endpoints.py -v -s"

# Conventional commits and release targets
commit-help: ## Show conventional commit examples
	@echo "📝 Conventional Commit Examples"
	@echo "=============================="
	@echo ""
	@echo "Features (minor version bump):"
	@echo "  git commit -m 'feat: add new API endpoint'"
	@echo "  git commit -m 'feat(api): add user authentication'"
	@echo ""
	@echo "Bug fixes (patch version bump):"
	@echo "  git commit -m 'fix: resolve container startup issue'"
	@echo "  git commit -m 'fix(docker): correct port binding'"
	@echo ""
	@echo "Breaking changes (major version bump):"
	@echo "  git commit -m 'feat!: migrate to new API version'"
	@echo ""
	@echo "No version bump:"
	@echo "  git commit -m 'docs: update README'"
	@echo "  git commit -m 'chore: update dependencies'"
	@echo "  git commit -m 'ci: add new workflow'"
	@echo ""
	@echo "See CONTRIBUTING.md for full details"

check-commits: ## Check recent commits for conventional format
	@echo "🔍 Recent commits:"
	@git log --oneline -10 --pretty=format:"%C(yellow)%h%C(reset) %s %C(dim)(%cr)%C(reset)"
	@echo ""
	@echo ""
	@echo "💡 Use 'make commit-help' for conventional commit examples"

release-info: ## Show current version and release information
	@echo "📦 Release Information"
	@echo "====================="
	@echo ""
	@echo "Current version:"
	@git describe --tags --abbrev=0 2>/dev/null || echo "  No releases yet"
	@echo ""
	@echo "Recent tags:"
	@git tag -l --sort=-version:refname | head -5 || echo "  No tags found"
	@echo ""
	@echo "Commits since last release:"
	@LAST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null); \
	if [ -n "$$LAST_TAG" ]; then \
		git log $$LAST_TAG..HEAD --oneline --pretty=format:"  %s"; \
	else \
		echo "  All commits (no previous release)"; \
		git log --oneline --pretty=format:"  %s"; \
	fi
	@echo ""

pr-labels-help: ## Show available PR labels for version control
	@echo "🏷️  PR Labels for Version Control"
	@echo "================================="
	@echo ""
	@echo "Version Bump Labels:"
	@echo "  major, breaking-change  → Major version bump (1.0.0 → 2.0.0)"
	@echo "  minor, feature          → Minor version bump (1.0.0 → 1.1.0)"
	@echo "  patch, bugfix, fix      → Patch version bump (1.0.0 → 1.0.1)"
	@echo "  no-release, skip-release → No version bump"
	@echo ""
	@echo "Usage:"
	@echo "  1. Create PR with any commit messages"
	@echo "  2. Add appropriate label to PR"
	@echo "  3. Merge PR to main"
	@echo "  4. Automatic RC release based on label"
	@echo ""
	@echo "Priority Order:"
	@echo "  1. Conventional commits (if present)"
	@echo "  2. PR labels (fallback)"
	@echo "  3. PR title format (secondary fallback)"
	@echo "  4. Default to patch (final fallback)"

analyze-prs: ## Analyze recent merged PRs for version impact
	@echo "🔍 Analyzing Recent Merged PRs"
	@echo "=============================="
	@echo ""
	@LAST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null || echo ""); \
	if [ -n "$$LAST_TAG" ]; then \
		echo "Since last release ($$LAST_TAG):"; \
		COMMIT_RANGE="$$LAST_TAG..HEAD"; \
	else \
		echo "All merged PRs (no previous release):"; \
		COMMIT_RANGE="HEAD"; \
	fi; \
	echo ""; \
	git log $$COMMIT_RANGE --merges --pretty=format:"%h %s" | grep "Merge pull request" | while read line; do \
		PR_NUM=$$(echo "$$line" | grep -oE '#[0-9]+' | sed 's/#//'); \
		if [ -n "$$PR_NUM" ]; then \
			echo "PR #$$PR_NUM:"; \
			echo "  Commit: $$line"; \
			if command -v gh >/dev/null 2>&1; then \
				PR_LABELS=$$(gh pr view $$PR_NUM --json labels --jq '.labels[].name' 2>/dev/null | tr '\n' ' ' || echo "No labels"); \
				PR_TITLE=$$(gh pr view $$PR_NUM --json title --jq '.title' 2>/dev/null || echo "Unknown title"); \
				echo "  Labels: $$PR_LABELS"; \
				echo "  Title: $$PR_TITLE"; \
				if echo "$$PR_LABELS" | grep -qE "(major|breaking-change)"; then \
					echo "  → MAJOR version bump"; \
				elif echo "$$PR_LABELS" | grep -qE "(minor|feature)"; then \
					echo "  → MINOR version bump"; \
				elif echo "$$PR_LABELS" | grep -qE "(patch|bugfix|fix)"; then \
					echo "  → PATCH version bump"; \
				elif echo "$$PR_LABELS" | grep -qE "(no-release|skip-release)"; then \
					echo "  → NO release"; \
				else \
					echo "  → DEFAULT (patch) version bump"; \
				fi; \
			else \
				echo "  (Install 'gh' CLI to see labels and titles)"; \
			fi; \
			echo ""; \
		fi; \
	done

version-preview: ## Preview next version based on recent changes
	@echo "🔮 Version Preview"
	@echo "=================="
	@echo ""
	@CURRENT_VERSION=$$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0"); \
	echo "Current version: $$CURRENT_VERSION"; \
	echo ""; \
	echo "Analyzing changes for next version..."; \
	echo ""; \
	HAS_MAJOR=false; \
	HAS_MINOR=false; \
	HAS_PATCH=false; \
	LAST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null || echo ""); \
	if [ -n "$$LAST_TAG" ]; then \
		COMMIT_RANGE="$$LAST_TAG..HEAD"; \
	else \
		COMMIT_RANGE="HEAD"; \
	fi; \
	git log $$COMMIT_RANGE --merges --pretty=format:"%s" | grep "Merge pull request" | while read line; do \
		PR_NUM=$$(echo "$$line" | grep -oE '#[0-9]+' | sed 's/#//'); \
		if [ -n "$$PR_NUM" ] && command -v gh >/dev/null 2>&1; then \
			PR_LABELS=$$(gh pr view $$PR_NUM --json labels --jq '.labels[].name' 2>/dev/null | tr '\n' ' ' || echo ""); \
			if echo "$$PR_LABELS" | grep -qE "(major|breaking-change)"; then \
				HAS_MAJOR=true; \
			elif echo "$$PR_LABELS" | grep -qE "(minor|feature)"; then \
				HAS_MINOR=true; \
			elif echo "$$PR_LABELS" | grep -qE "(patch|bugfix|fix)"; then \
				HAS_PATCH=true; \
			elif ! echo "$$PR_LABELS" | grep -qE "(no-release|skip-release)"; then \
				HAS_PATCH=true; \
			fi; \
		fi; \
	done; \
	IFS='.' read -r MAJOR MINOR PATCH <<< "$$CURRENT_VERSION"; \
	if [ "$$HAS_MAJOR" = true ]; then \
		MAJOR=$$((MAJOR + 1)); \
		MINOR=0; \
		PATCH=0; \
		echo "Next version: v$$MAJOR.$$MINOR.$$PATCH (MAJOR bump)"; \
	elif [ "$$HAS_MINOR" = true ]; then \
		MINOR=$$((MINOR + 1)); \
		PATCH=0; \
		echo "Next version: v$$MAJOR.$$MINOR.$$PATCH (MINOR bump)"; \
	elif [ "$$HAS_PATCH" = true ]; then \
		PATCH=$$((PATCH + 1)); \
		echo "Next version: v$$MAJOR.$$MINOR.$$PATCH (PATCH bump)"; \
	else \
		echo "Next version: v$$MAJOR.$$MINOR.$$PATCH (NO changes)"; \
	fi

# Python linting targets
lint: ## Run Pylint on all Python files
	@echo "🔍 Running Pylint"
	@echo "================="
	@echo ""
	@if command -v pylint >/dev/null 2>&1; then \
		PYTHON_FILES=$$(find . -name "*.py" \
			-not -path "./.git/*" \
			-not -path "./.venv/*" \
			-not -path "./venv/*" \
			-not -path "./__pycache__/*" \
			-not -path "./.pytest_cache/*" \
			-not -path "./build/*" \
			-not -path "./dist/*" \
			-not -path "./*.egg-info/*"); \
		if [ -n "$$PYTHON_FILES" ]; then \
			echo "Found Python files:"; \
			echo "$$PYTHON_FILES" | sed 's/^/  /'; \
			echo ""; \
			echo "Running Pylint with config: .config/.pylintrc"; \
			pylint --rcfile=.config/.pylintrc $$PYTHON_FILES; \
		else \
			echo "No Python files found to lint"; \
		fi; \
	else \
		echo "❌ Pylint not installed. Install with: pip install pylint"; \
		exit 1; \
	fi

lint-install: ## Install Pylint for local development
	@echo "📦 Installing Pylint"
	@echo "===================="
	@pip install pylint
	@echo "✅ Pylint installed successfully!"
	@echo ""
	@echo "Usage:"
	@echo "  make lint          # Run linter on all Python files"
	@echo "  make lint-fix      # Show fixable issues"
	@echo "  make lint-report   # Generate detailed report"

lint-report: ## Generate detailed Pylint report
	@echo "📊 Generating Pylint Report"
	@echo "==========================="
	@echo ""
	@if command -v pylint >/dev/null 2>&1; then \
		PYTHON_FILES=$$(find . -name "*.py" \
			-not -path "./.git/*" \
			-not -path "./.venv/*" \
			-not -path "./venv/*" \
			-not -path "./__pycache__/*" \
			-not -path "./.pytest_cache/*" \
			-not -path "./build/*" \
			-not -path "./dist/*" \
			-not -path "./*.egg-info/*"); \
		if [ -n "$$PYTHON_FILES" ]; then \
			echo "Generating detailed report..."; \
			pylint --rcfile=.config/.pylintrc --reports=yes $$PYTHON_FILES > pylint-report.txt 2>&1 || true; \
			echo "Report saved to: pylint-report.txt"; \
			echo ""; \
			echo "Summary:"; \
			if grep -q "Your code has been rated at" pylint-report.txt; then \
				grep "Your code has been rated at" pylint-report.txt; \
			fi; \
			echo ""; \
			echo "Issue counts:"; \
			echo "  Errors: $$(grep -c "E[0-9][0-9][0-9][0-9]:" pylint-report.txt || echo "0")"; \
			echo "  Warnings: $$(grep -c "W[0-9][0-9][0-9][0-9]:" pylint-report.txt || echo "0")"; \
			echo "  Conventions: $$(grep -c "C[0-9][0-9][0-9][0-9]:" pylint-report.txt || echo "0")"; \
			echo "  Refactor: $$(grep -c "R[0-9][0-9][0-9][0-9]:" pylint-report.txt || echo "0")"; \
		else \
			echo "No Python files found to lint"; \
		fi; \
	else \
		echo "❌ Pylint not installed. Run: make lint-install"; \
		exit 1; \
	fi

lint-config: ## Show current Pylint configuration
	@echo "⚙️  Pylint Configuration"
	@echo "========================"
	@echo ""
	@echo "Config file: .config/.pylintrc"
	@echo ""
	@if [ -f .config/.pylintrc ]; then \
		echo "Key settings:"; \
		echo ""; \
		echo "Max line length:"; \
		grep "max-line-length" .config/.pylintrc || echo "  Not specified"; \
		echo ""; \
		echo "Disabled checks:"; \
		grep -A 10 "disable=" .config/.pylintrc | head -15 || echo "  None specified"; \
		echo ""; \
		echo "Good variable names:"; \
		grep "good-names" .config/.pylintrc || echo "  Using defaults"; \
	else \
		echo "❌ Config file not found: .config/.pylintrc"; \
	fi

lint-help: ## Show Pylint help and available options
	@echo "🔍 Pylint Help"
	@echo "=============="
	@echo ""
	@echo "Available linting targets:"
	@echo "  make lint          # Run Pylint on all Python files"
	@echo "  make lint-install  # Install Pylint"
	@echo "  make lint-report   # Generate detailed report"
	@echo "  make lint-config   # Show current configuration"
	@echo "  make lint-help     # Show this help"
	@echo ""
	@echo "Configuration:"
	@echo "  Config file: .config/.pylintrc"
	@echo "  Customize settings by editing the config file"
	@echo ""
	@echo "CI/CD Integration:"
	@echo "  Linting runs automatically on:"
	@echo "  - Pull requests to main branch"
	@echo "  - Pushes to any branch"
	@echo "  - Manual workflow dispatch"

# Multi-architecture build targets
build-multi: ## Build multi-architecture image (AMD64 + ARM64)
	@echo "🏗️  Building multi-architecture container image..."
	@echo "Platforms: $(PLATFORMS)"
	@echo ""
	@if command -v podman >/dev/null 2>&1; then \
		echo "Using Podman for multi-arch build..."; \
		podman build \
			--platform $(PLATFORMS) \
			--manifest $(REGISTRY)/$(IMAGE_BASE):latest \
			.; \
		echo "✅ Multi-architecture manifest created!"; \
		echo "📋 Manifest details:"; \
		podman manifest inspect $(REGISTRY)/$(IMAGE_BASE):latest; \
	elif command -v docker >/dev/null 2>&1; then \
		echo "Using Docker buildx for multi-arch build..."; \
		docker buildx create --use --name multiarch-builder 2>/dev/null || true; \
		docker buildx build \
			--platform $(PLATFORMS) \
			--tag $(REGISTRY)/$(IMAGE_BASE):latest \
			--load \
			.; \
		echo "✅ Multi-architecture image built!"; \
	else \
		echo "❌ Neither podman nor docker found. Install one to build multi-arch images."; \
		exit 1; \
	fi

build-arm: ## Build ARM64 image specifically
	@echo "🦾 Building ARM64 container image..."
	@if command -v podman >/dev/null 2>&1; then \
		podman build --platform linux/arm64 -t $(REGISTRY)/$(IMAGE_BASE):arm64 .; \
		echo "✅ ARM64 image built: $(REGISTRY)/$(IMAGE_BASE):arm64"; \
	elif command -v docker >/dev/null 2>&1; then \
		docker buildx build --platform linux/arm64 -t $(REGISTRY)/$(IMAGE_BASE):arm64 --load .; \
		echo "✅ ARM64 image built: $(REGISTRY)/$(IMAGE_BASE):arm64"; \
	else \
		echo "❌ Neither podman nor docker found."; \
		exit 1; \
	fi

build-x86: ## Build AMD64/x86_64 image specifically
	@echo "💻 Building AMD64 container image..."
	@if command -v podman >/dev/null 2>&1; then \
		podman build --platform linux/amd64 -t $(REGISTRY)/$(IMAGE_BASE):amd64 .; \
		echo "✅ AMD64 image built: $(REGISTRY)/$(IMAGE_BASE):amd64"; \
	elif command -v docker >/dev/null 2>&1; then \
		docker buildx build --platform linux/amd64 -t $(REGISTRY)/$(IMAGE_BASE):amd64 --load .; \
		echo "✅ AMD64 image built: $(REGISTRY)/$(IMAGE_BASE):amd64"; \
	else \
		echo "❌ Neither podman nor docker found."; \
		exit 1; \
	fi

build-push-multi: ## Build and push multi-architecture image to registry
	@echo "🚀 Building and pushing multi-architecture image..."
	@echo "⚠️  Make sure you're logged into your registry first!"
	@echo ""
	@read -p "Registry (e.g., docker.io/username, ghcr.io/username): " PUSH_REGISTRY; \
	if [ -z "$$PUSH_REGISTRY" ]; then \
		echo "❌ Registry cannot be empty"; \
		exit 1; \
	fi; \
	echo "Building and pushing to: $$PUSH_REGISTRY/$(IMAGE_BASE):latest"; \
	if command -v podman >/dev/null 2>&1; then \
		podman build \
			--platform $(PLATFORMS) \
			--manifest $$PUSH_REGISTRY/$(IMAGE_BASE):latest \
			.; \
		podman manifest push $$PUSH_REGISTRY/$(IMAGE_BASE):latest; \
		echo "✅ Multi-architecture image pushed to $$PUSH_REGISTRY/$(IMAGE_BASE):latest"; \
	elif command -v docker >/dev/null 2>&1; then \
		docker buildx create --use --name multiarch-builder 2>/dev/null || true; \
		docker buildx build \
			--platform $(PLATFORMS) \
			--tag $$PUSH_REGISTRY/$(IMAGE_BASE):latest \
			--push \
			.; \
		echo "✅ Multi-architecture image pushed to $$PUSH_REGISTRY/$(IMAGE_BASE):latest"; \
	else \
		echo "❌ Neither podman nor docker found."; \
		exit 1; \
	fi

inspect-multi: ## Inspect multi-architecture manifest
	@echo "🔍 Inspecting multi-architecture manifest..."
	@if command -v podman >/dev/null 2>&1; then \
		podman manifest inspect $(REGISTRY)/$(IMAGE_BASE):latest 2>/dev/null || \
		echo "❌ No multi-arch manifest found. Run 'make build-multi' first."; \
	elif command -v docker >/dev/null 2>&1; then \
		docker buildx imagetools inspect $(REGISTRY)/$(IMAGE_BASE):latest 2>/dev/null || \
		echo "❌ No multi-arch image found. Run 'make build-multi' first."; \
	else \
		echo "❌ Neither podman nor docker found."; \
		exit 1; \
	fi

multi-help: ## Show multi-architecture build help
	@echo "🏗️  Multi-Architecture Build Help"
	@echo "=================================="
	@echo ""
	@echo "Available multi-arch targets:"
	@echo "  make build-multi      # Build for AMD64 + ARM64"
	@echo "  make build-arm        # Build ARM64 only"
	@echo "  make build-x86        # Build AMD64 only"
	@echo "  make build-push-multi # Build and push to registry"
	@echo "  make inspect-multi    # Inspect multi-arch manifest"
	@echo "  make multi-help       # Show this help"
	@echo ""
	@echo "Supported platforms: $(PLATFORMS)"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - Podman 4.0+ OR Docker with buildx"
	@echo "  - QEMU for cross-platform emulation"
	@echo ""
	@echo "Examples:"
	@echo "  # Build for both architectures locally"
	@echo "  make build-multi"
	@echo ""
	@echo "  # Build and push to Docker Hub"
	@echo "  docker login"
	@echo "  make build-push-multi"
	@echo ""
	@echo "  # Build and push to GitHub Container Registry"
	@echo "  echo \$$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"
	@echo "  make build-push-multi"
	@echo ""
	@echo "  # Test ARM64 image on x86 machine"
	@echo "  make build-arm"
	@echo "  podman run --platform linux/arm64 $(REGISTRY)/$(IMAGE_BASE):arm64"

setup-qemu: ## Setup QEMU for cross-platform builds
	@echo "⚙️  Setting up QEMU for cross-platform builds..."
	@if command -v docker >/dev/null 2>&1; then \
		echo "Setting up Docker buildx with QEMU..."; \
		docker run --rm --privileged multiarch/qemu-user-static --reset -p yes; \
		docker buildx create --use --name multiarch-builder --driver docker-container 2>/dev/null || true; \
		docker buildx inspect --bootstrap; \
		echo "✅ Docker buildx with QEMU configured!"; \
	elif command -v podman >/dev/null 2>&1; then \
		echo "Setting up Podman with QEMU..."; \
		if command -v qemu-user-static >/dev/null 2>&1; then \
			echo "✅ QEMU already available"; \
		else \
			echo "Installing QEMU user static..."; \
			if command -v apt-get >/dev/null 2>&1; then \
				sudo apt-get update && sudo apt-get install -y qemu-user-static; \
			elif command -v yum >/dev/null 2>&1; then \
				sudo yum install -y qemu-user-static; \
			elif command -v brew >/dev/null 2>&1; then \
				brew install qemu; \
			else \
				echo "❌ Please install qemu-user-static manually"; \
				exit 1; \
			fi; \
		fi; \
		echo "✅ Podman with QEMU configured!"; \
	else \
		echo "❌ Neither podman nor docker found."; \
		exit 1; \
	fi
