FROM python:3.13-slim

# Build arguments
ARG VERSION=1.0.0
ARG BUILD_DATE
ARG REVISION

# Container metadata
LABEL org.opencontainers.image.title="Test Container API"
LABEL org.opencontainers.image.description="A multi-architecture Python FastAPI for testing containerized applications with automated dependency management"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL org.opencontainers.image.authors="sudo-whodo <your-email@example.com>"
LABEL org.opencontainers.image.vendor="sudo-whodo"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/sudo-whodo/test-container"
LABEL org.opencontainers.image.source="https://github.com/sudo-whodo/test-container"
LABEL org.opencontainers.image.documentation="https://github.com/sudo-whodo/test-container/blob/main/README.md"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${REVISION}"

# Additional custom labels
LABEL maintainer="sudo-whodo"
LABEL project="test-container"
LABEL component="api"
LABEL environment="production"
LABEL architecture="multi-arch"
LABEL python.version="3.13"
LABEL framework="fastapi"

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/app.py .

# Change ownership of the app directory to the non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 8080
EXPOSE 8080

# Set environment variables
ENV PORT=8080
ENV TEST_API_APP_VERSION=${VERSION}
ENV TEST_API_ENVIRONMENT=production

# Run the application
CMD ["python", "app.py"]
