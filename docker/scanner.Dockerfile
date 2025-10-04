# =============================================================================
# DevSecOps Security Scanner Container
# =============================================================================
# Contains Trivy, Grype, Syft, and OPA for security scanning
# =============================================================================

FROM ubuntu:22.04

# Metadata
LABEL maintainer="DevSecOps Lab"
LABEL description="Security scanner with Trivy, Grype, Syft, and OPA"
LABEL version="1.0.0"

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    jq \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI for image scanning
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Trivy
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y trivy \
    && rm -rf /var/lib/apt/lists/*

# Install Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Install Syft
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install OPA
RUN curl -L -o opa https://openpolicyagent.org/downloads/v0.57.0/opa_linux_amd64_static \
    && chmod +x opa \
    && mv opa /usr/local/bin/

# Create app directory and subdirectories
WORKDIR /app
RUN mkdir -p /app/scripts /app/scan-results /app/reports /app/logs /app/policies

# Copy the entrypoint script
COPY docker/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set environment variables
ENV PATH="/app/scripts:${PATH}"
ENV TRIVY_CACHE_DIR=/app/.trivy
ENV GRYPE_DB_CACHE_DIR=/app/.grype

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD trivy --version >/dev/null 2>&1

# Use the entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]