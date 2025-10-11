# Multi-stage production Dockerfile
FROM ubuntu:22.04 AS builder

LABEL stage="builder"
LABEL description="DevSecOps Lab - Build Stage"

# Install Node.js 18
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files (build context is src directory)
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy source code (build context is src directory)
COPY . .

# Production stage
FROM ubuntu:22.04 AS production

# Install Node.js 18
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Comprehensive metadata labels
LABEL maintainer="DevSecOps Lab"
LABEL description="Sample Node.js application for security testing"
LABEL version="1.2.0"
LABEL security.scan.required="true"

# Build arguments for metadata
ARG BUILD_NUMBER=unknown
ARG VCS_REVISION=unknown
ARG BUILD_TIMESTAMP=unknown

LABEL build.number="$BUILD_NUMBER"
LABEL build.vcs.revision="$VCS_REVISION"
LABEL build.timestamp="$BUILD_TIMESTAMP"

# Install additional security packages (Node.js already installed above)
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends dumb-init && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create non-root user with home directory
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs -m -s /bin/bash nodejs

WORKDIR /app
RUN chown -R nodejs:nodejs /app

USER nodejs

# Copy application files from builder stage (before installing deps)
COPY --from=builder --chown=nodejs:nodejs /app/server.js ./
COPY --from=builder --chown=nodejs:nodejs /app/app.js ./

# Copy package files and install production dependencies
COPY --chown=nodejs:nodejs package*.json ./
RUN npm install --only=production && npm cache clean --force

# Create directories
RUN mkdir -p logs && chmod 755 logs

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENV NODE_ENV=production
ENV PORT=8080

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
