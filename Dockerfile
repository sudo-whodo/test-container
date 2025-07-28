FROM python:3.13-slim

# Container metadata
LABEL org.opencontainers.image.title="Test Container API"
LABEL org.opencontainers.image.description="A multi-architecture Python Flask API for testing containerized applications with automated dependency management"
LABEL org.opencontainers.image.version="latest"
LABEL org.opencontainers.image.authors="sudo-whodo <your-email@example.com>"
LABEL org.opencontainers.image.vendor="sudo-whodo"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/sudo-whodo/test-container"
LABEL org.opencontainers.image.source="https://github.com/sudo-whodo/test-container"
LABEL org.opencontainers.image.documentation="https://github.com/sudo-whodo/test-container/blob/main/README.md"
LABEL org.opencontainers.image.created=""
LABEL org.opencontainers.image.revision=""

# Additional custom labels
LABEL maintainer="sudo-whodo"
LABEL project="test-container"
LABEL component="api"
LABEL environment="production"
LABEL architecture="multi-arch"
LABEL python.version="3.13"
LABEL framework="flask"

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/app.py .

# Expose port 8080
EXPOSE 8080

# Set environment variable for port
ENV PORT=8080

# Run the application
CMD ["python", "app.py"]
