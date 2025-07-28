# FastAPI Test Container

[![linting: pylint](https://img.shields.io/badge/linting-pylint-yellowgreen)](https://github.com/pylint-dev/pylint)

A simple FastAPI application for testing HTTP endpoint connectivity. This container provides basic REST endpoints that return 200 status codes, perfect for testing load balancers, health checks, and HTTP endpoint monitoring.

## 🚀 Quick Start

### Using Make (Recommended)

```bash
# Build and run the container
make all

# Or step by step
make build    # Build the container image
make run      # Run the container
make test     # Test all endpoints
make status   # Check container status
```

### Manual Commands

```bash
# Build the container
podman build -t localhost/test-api:latest .

# Run the container
podman run -d --name test-api -p 8080:8080 localhost/test-api:latest

# Test the API
curl http://localhost:8080/health
```

## 📋 Available Endpoints

The API provides the following endpoints, all returning HTTP 200:

| Endpoint | Description | Response Type |
|----------|-------------|---------------|
| `/` | Root endpoint with API info | JSON |
| `/health` | Basic health check | JSON |
| `/status` | Service status | JSON |
| `/api/v1/health` | API v1 health check | JSON |
| `/metrics` | Prometheus-style metrics | Plain text |

## 🛠️ Make Targets

| Target | Description |
|--------|-------------|
| `make help` | Show all available targets |
| `make build` | Build the container image |
| `make run` | Run the container (stops existing first) |
| `make stop` | Stop the running container |
| `make clean` | Stop and remove the container |
| `make logs` | Show container logs |
| `make status` | Show container status and endpoints |
| `make test` | Test all API endpoints with curl |
| `make restart` | Clean, rebuild, and restart |
| `make dev` | Run in development mode with logs |
| `make pytest-setup` | Setup for pytest HTTP endpoint testing |
| `make lint` | Run Pylint on all Python files |
| `make lint-report` | Generate detailed Pylint report |

## 🔍 Code Quality

This project uses [Pylint](https://github.com/pylint-dev/pylint) for code quality and style checking:

```bash
# Run linting locally
make lint

# Install Pylint for development
make lint-install

# Generate detailed report
make lint-report

# View linting configuration
make lint-config
```

### Automated Linting

- **Pull Requests**: Automatic linting on all PRs with detailed comments
- **Push Events**: Linting runs on pushes to any branch
- **Configuration**: Stored in `.config/.pylintrc`
- **CI Integration**: Results posted as PR comments with pass/fail status

## 🧪 Testing with pytest

This container is designed to work with the HTTP endpoint tests:

```bash
# Setup the test container
cd tests/working/test_api
make pytest-setup

# Run the HTTP endpoint tests
cd ..
pytest test_http_endpoints.py -v -s
```

## 📊 Example Responses

### Root Endpoint (`/`)
```json
{
  "message": "Test API is running",
  "status": "healthy",
  "endpoints": [
    "/",
    "/health",
    "/status",
    "/api/v1/health",
    "/metrics"
  ]
}
```

### Health Endpoint (`/health`)
```json
{
  "status": "healthy",
  "service": "test-api",
  "version": "1.0.0"
}
```

### Metrics Endpoint (`/metrics`)
```
# HELP test_api_requests_total Total requests
# TYPE test_api_requests_total counter
test_api_requests_total 42
```

## 🔧 Configuration

The container can be configured with environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Port the API listens on |

Example with custom port:
```bash
podman run -d --name test-api -p 9090:9090 -e PORT=9090 localhost/test-api:latest
```

## 🐳 Container Management

### View running containers
```bash
make ps
# or
podman ps
```

### View container logs
```bash
make logs
# or
podman logs test-api
```

### Access container shell
```bash
make shell
# or
podman exec -it test-api /bin/bash
```

### Clean up everything
```bash
make clean-all  # Removes container and images
```

## 🔍 Troubleshooting

### Container won't start
```bash
# Check if port is already in use
lsof -i :8080

# Check container logs
make logs
```

### API not responding
```bash
# Check container status
make status

# Test with curl
curl -v http://localhost:8080/health
```

### Build issues
```bash
# Clean everything and rebuild
make clean-all
make build
```

## 🎯 Use Cases

This test API is perfect for:

- **Load Balancer Testing**: Test backend connectivity
- **Health Check Monitoring**: Verify monitoring systems
- **HTTP Endpoint Testing**: Validate HTTP client code
- **Container Orchestration**: Test deployment pipelines
- **Network Connectivity**: Verify network routing

## 📁 Files

- `app.py` - FastAPI application code
- `requirements.txt` - Python dependencies
- `Dockerfile` - Container build instructions
- `Makefile` - Build and management commands
- `README.md` - This documentation

## 🔗 Integration

This test API integrates with:

- **pytest HTTP tests** (`../test_http_endpoints.py`)
- **Load balancer tests** (`../test_loadbalancer.py`)
- **Container monitoring** (systemd, docker, podman)
- **Network port testing** (firewall, connectivity)

## 📋 Release Notes

For detailed information about recent improvements and changes, see [RELEASE_NOTES.md](RELEASE_NOTES.md).

## 📚 Documentation

For additional documentation, please refer to the `docs/` directory:

- **[Contributing Guidelines](docs/CONTRIBUTING.md)** - How to contribute to the project
- **[GitHub App Setup](docs/GITHUB_APP_SETUP.md)** - Setting up GitHub App for automation
- **[Versioning Guide](docs/VERSIONING.md)** - Understanding our versioning strategy
