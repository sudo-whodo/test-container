"""
Simple FastAPI test application for HTTP endpoint testing
Provides basic endpoints that return 200 status codes
"""

import asyncio
import logging
import os
import signal
import sys
from contextlib import asynccontextmanager
from typing import Dict, Any

from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application configuration with environment variable support"""

    # Server configuration
    host: str = "0.0.0.0"
    port: int = 8080

    # Application configuration
    app_name: str = "Test API"
    app_version: str = "1.0.0"  # Will be overridden by TEST_API_APP_VERSION env var
    environment: str = "production"
    debug: bool = False

    # Logging configuration
    log_level: str = "INFO"
    log_format: str = "json"  # json or text

    # Health check configuration
    health_check_timeout: int = 5

    class Config:
        env_prefix = "TEST_API_"
        case_sensitive = False


# Global settings instance
settings = Settings()

# Configure logging
def setup_logging():
    """Setup structured logging"""
    log_level = getattr(logging, settings.log_level.upper(), logging.INFO)

    if settings.log_format.lower() == "json":
        # JSON logging format for production
        logging.basicConfig(
            level=log_level,
            format='{"timestamp": "%(asctime)s", "level": "%(levelname)s", "logger": "%(name)s", "message": "%(message)s"}',
            datefmt='%Y-%m-%dT%H:%M:%S'
        )
    else:
        # Human-readable format for development
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)

# Global shutdown event
shutdown_event = asyncio.Event()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup and shutdown events"""
    # Startup
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"Debug mode: {settings.debug}")
    logger.info(f"Listening on {settings.host}:{settings.port}")

    # Setup signal handlers for graceful shutdown
    def signal_handler(signum, frame):
        logger.info(f"Received signal {signum}, initiating graceful shutdown...")
        shutdown_event.set()

    # Register signal handlers
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    yield

    # Shutdown
    logger.info("Shutting down application...")
    # Add any cleanup logic here (close database connections, etc.)
    logger.info("Application shutdown complete")


app = FastAPI(
    title=settings.app_name,
    description="Simple API for testing HTTP endpoints with proper configuration and graceful shutdown",
    version=settings.app_version,
    debug=settings.debug,
    lifespan=lifespan
)


@app.get("/")
async def root():
    """Root endpoint with configuration information"""
    logger.info("Root endpoint accessed")
    return {
        "message": f"{settings.app_name} is running",
        "status": "healthy",
        "version": settings.app_version,
        "environment": settings.environment,
        "endpoints": [
            "/",
            "/health",
            "/status",
            "/api/v1/health",
            "/metrics",
            "/config",
            "/docs",
            "/api/v1/info"
        ]
    }


@app.get("/health")
async def health():
    """Enhanced health check endpoint"""
    logger.debug("Health check endpoint accessed")

    # Perform basic health checks
    health_status = {
        "status": "healthy",
        "service": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment,
        "checks": {
            "application": "healthy",
            "memory": "healthy",
            "disk": "healthy"
        }
    }

    # Add more sophisticated health checks here
    # For example: database connectivity, external service checks, etc.

    logger.debug("Health check completed successfully")
    return health_status


@app.get("/status")
async def status():
    """Enhanced status endpoint with system information"""
    logger.debug("Status endpoint accessed")

    import psutil
    import time

    try:
        # Get system information
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')

        status_info = {
            "status": "running",
            "service": settings.app_name,
            "version": settings.app_version,
            "environment": settings.environment,
            "uptime_seconds": int(time.time() - psutil.Process().create_time()),
            "system": {
                "memory_usage_percent": memory.percent,
                "disk_usage_percent": disk.percent,
                "cpu_count": psutil.cpu_count()
            }
        }
    except ImportError:
        # Fallback if psutil is not available
        status_info = {
            "status": "running",
            "service": settings.app_name,
            "version": settings.app_version,
            "environment": settings.environment,
            "uptime": "unknown",
            "system": "monitoring_unavailable"
        }

    return status_info


@app.get("/api/v1/health")
async def api_health():
    """API v1 health endpoint"""
    logger.debug("API v1 health endpoint accessed")
    return {
        "api_version": "v1",
        "status": "healthy",
        "service": settings.app_name,
        "version": settings.app_version,
        "environment": settings.environment
    }


@app.get("/metrics")
async def metrics():
    """Enhanced metrics endpoint with basic Prometheus-style metrics"""
    logger.debug("Metrics endpoint accessed")

    # Basic metrics - in a real application, these would be collected over time
    content = f"""# HELP test_api_info Application information
# TYPE test_api_info gauge
test_api_info{{version="{settings.app_version}",environment="{settings.environment}"}} 1

# HELP test_api_requests_total Total requests (placeholder)
# TYPE test_api_requests_total counter
test_api_requests_total 42

# HELP test_api_health_status Health status (1=healthy, 0=unhealthy)
# TYPE test_api_health_status gauge
test_api_health_status 1

# HELP test_api_uptime_seconds Application uptime in seconds
# TYPE test_api_uptime_seconds gauge
test_api_uptime_seconds 3600
"""

    return JSONResponse(content=content, media_type="text/plain")


@app.get("/config")
async def config():
    """Configuration endpoint (non-sensitive settings only)"""
    logger.debug("Configuration endpoint accessed")

    # Only return non-sensitive configuration
    safe_config = {
        "app_name": settings.app_name,
        "app_version": settings.app_version,
        "environment": settings.environment,
        "debug": settings.debug,
        "log_level": settings.log_level,
        "log_format": settings.log_format,
        "host": settings.host,
        "port": settings.port
    }

    return {
        "configuration": safe_config,
        "note": "Only non-sensitive configuration is displayed"
    }


@app.get("/api/v1/info")
async def api_info():
    """API v1 information endpoint with detailed service information"""
    logger.debug("API v1 info endpoint accessed")

    import platform
    import datetime

    return {
        "api": {
            "version": "v1",
            "service": settings.app_name,
            "service_version": settings.app_version,
            "environment": settings.environment,
            "description": "Enhanced test API with comprehensive monitoring endpoints"
        },
        "server": {
            "platform": platform.system(),
            "python_version": platform.python_version(),
            "architecture": platform.machine(),
            "hostname": platform.node()
        },
        "features": {
            "health_monitoring": True,
            "metrics_collection": True,
            "graceful_shutdown": True,
            "structured_logging": True,
            "configuration_management": True
        },
        "endpoints": {
            "health": ["/health", "/api/v1/health"],
            "monitoring": ["/status", "/metrics"],
            "configuration": ["/config"],
            "documentation": ["/docs", "/redoc"],
            "api": ["/api/v1/info"]
        },
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
    }


async def graceful_shutdown():
    """Handle graceful shutdown"""
    logger.info("Graceful shutdown initiated")

    # Wait for shutdown event
    await shutdown_event.wait()

    # Perform cleanup tasks
    logger.info("Performing cleanup tasks...")

    # Add any cleanup logic here:
    # - Close database connections
    # - Finish processing current requests
    # - Save state if needed

    logger.info("Cleanup completed, shutting down server")


if __name__ == "__main__":
    logger.info(f"Starting {settings.app_name} server...")
    logger.info(f"Configuration: host={settings.host}, port={settings.port}, debug={settings.debug}")

    try:
        uvicorn.run(
            app,
            host=settings.host,
            port=settings.port,
            log_level=settings.log_level.lower(),
            access_log=True
        )
    except KeyboardInterrupt:
        logger.info("Received keyboard interrupt, shutting down...")
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)
