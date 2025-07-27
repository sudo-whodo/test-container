"""
Simple FastAPI test application for HTTP endpoint testing
Provides basic endpoints that return 200 status codes
"""

from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
import os

app = FastAPI(
    title="Test API",
    description="Simple API for testing HTTP endpoints",
    version="1.0.0"
)

@app.get("/")
async def root():
    """Root endpoint"""
    return {
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

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "test-api",
        "version": "1.0.0"
    }

@app.get("/status")
async def status():
    """Status endpoint"""
    return {
        "status": "running",
        "uptime": "unknown",
        "service": "test-api"
    }

@app.get("/api/v1/health")
async def api_health():
    """API v1 health endpoint"""
    return {
        "api_version": "v1",
        "status": "healthy",
        "service": "test-api"
    }

@app.get("/metrics")
async def metrics():
    """Metrics endpoint (Prometheus-style)"""
    return JSONResponse(
        content="# HELP test_api_requests_total Total requests\n# TYPE test_api_requests_total counter\ntest_api_requests_total 42\n",
        media_type="text/plain"
    )

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
