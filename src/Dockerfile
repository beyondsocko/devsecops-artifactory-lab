# Multi-stage production Dockerfile
FROM node:18-alpine AS builder

LABEL stage="builder"
LABEL description="DevSecOps Lab - Build Stage"

WORKDIR /app

# Copy package files from src directory
COPY src/package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy source code from src directory
COPY src/ .

# Production stage
FROM node:18-alpine AS production

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

# Install security updates
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init curl && \
    rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

WORKDIR /app
RUN chown -R nodejs:nodejs /app

USER nodejs

# Copy package files from src directory
COPY --chown=nodejs:nodejs src/package*.json ./
RUN npm install --only=production && npm cache clean --force

# Copy application code from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/server.js ./

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
