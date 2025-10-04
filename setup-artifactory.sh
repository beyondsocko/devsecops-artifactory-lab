#!/bin/bash
set -e

echo "🚀 Setting up JFrog Artifactory OSS..."

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  artifactory:
    image: releases-docker.jfrog.io/jfrog/artifactory-oss:latest
    container_name: artifactory-oss
    ports:
      - "8081:8081"
      - "8082:8082"
    volumes:
      - ./artifactory-data:/var/opt/jfrog/artifactory
    environment:
      - JF_SHARED_DATABASE_TYPE=derby
      - JF_SHARED_SECURITY_JOINKEY=devsecops-lab-key-2024
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8082/artifactory/api/system/ping"]
      interval: 30s
      timeout: 10s
      retries: 5
EOF

echo "✅ docker-compose.yml created"

# Start Artifactory
echo "🚀 Starting Artifactory OSS..."
docker-compose up -d

echo "⏳ Waiting for Artifactory to start (this takes about 2-3 minutes)..."
sleep 120

# Test connectivity
echo "🔍 Testing connectivity..."
if curl -s http://localhost:8082/artifactory/api/system/ping | grep -q "OK"; then
    echo "✅ Artifactory is running successfully!"
    echo ""
    echo "🌐 Access URL: http://localhost:8082"
    echo "👤 Default login: admin/password"
    echo "📝 Next steps:"
    echo "   1. Open http://localhost:8082 in your browser"
    echo "   2. Login with admin/password"
    echo "   3. Complete the setup wizard"
    echo "   4. Generate an access token"
    echo "   5. Update your .env file"
else
    echo "❌ Artifactory failed to start properly"
    echo "📋 Check logs with: docker-compose logs artifactory"
    exit 1
fi
