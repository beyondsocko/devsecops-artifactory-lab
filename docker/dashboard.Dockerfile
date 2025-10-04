# =============================================================================
# DevSecOps Lab Dashboard Container
# =============================================================================
# Web dashboard for viewing documentation, reports, and lab status
# =============================================================================

FROM nginx:alpine

# Metadata
LABEL maintainer="DevSecOps Lab"
LABEL description="Web dashboard for DevSecOps lab documentation and reports"
LABEL version="1.0.0"

# Install additional packages
RUN apk add --no-cache \
    curl \
    jq \
    bash

# Create dashboard structure
RUN mkdir -p /usr/share/nginx/html/{docs,reports,logs,api}

# Create custom nginx configuration
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Enable directory browsing for reports and logs
    location /reports/ {
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }

    location /logs/ {
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }

    # API proxy to Nexus
    location /api/nexus/ {
        proxy_pass http://nexus:8081/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

# Create dashboard HTML
RUN cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevSecOps Lab Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #202B52 0%, #3F486B 100%);
            color: #FFFFFF;
            min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .header h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .header p { font-size: 1.1rem; opacity: 0.9; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { 
            background: rgba(255, 255, 255, 0.1); 
            border-radius: 12px; 
            padding: 25px; 
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .card h3 { margin-bottom: 15px; color: #FFFFFF; }
        .card a { 
            color: #87CEEB; 
            text-decoration: none; 
            display: block; 
            margin: 8px 0;
            padding: 8px 12px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 6px;
            transition: background 0.3s;
        }
        .card a:hover { background: rgba(255, 255, 255, 0.2); }
        .status { 
            background: #4CAF50; 
            color: white; 
            padding: 4px 12px; 
            border-radius: 20px; 
            font-size: 0.9rem;
            display: inline-block;
            margin-bottom: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ DevSecOps Lab Dashboard</h1>
            <p>Complete Security-First CI/CD Pipeline</p>
            <div class="status">✅ Lab Active</div>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>📋 Documentation</h3>
                <a href="docs/README.html">📖 Main Documentation</a>
                <a href="docs/architecture.html">🏗️ Architecture Guide</a>
                <a href="docs/api-reference.html">📚 API Reference</a>
                <a href="docs/troubleshooting.html">🔧 Troubleshooting</a>
            </div>
            
            <div class="card">
                <h3>🔍 Security Reports</h3>
                <a href="reports/">📊 All Reports</a>
                <a href="reports/security/">🛡️ Security Scans</a>
                <a href="reports/policy/">⚖️ Policy Decisions</a>
                <a href="reports/sbom/">📦 Software BOMs</a>
            </div>
            
            <div class="card">
                <h3>📝 Audit Logs</h3>
                <a href="logs/">📋 All Logs</a>
                <a href="logs/audit/">🔍 Audit Trail</a>
                <a href="logs/scan/">🔎 Scan Logs</a>
                <a href="logs/integration/">🔗 Integration Logs</a>
            </div>
            
            <div class="card">
                <h3>🔧 Lab Services</h3>
                <a href="http://localhost:8081" target="_blank">🏛️ Nexus Repository</a>
                <a href="http://localhost:3000" target="_blank">🌐 Sample Application</a>
                <a href="api/nexus/service/rest/v1/status" target="_blank">📡 Nexus API Status</a>
            </div>
            
            <div class="card">
                <h3>🧪 Quick Actions</h3>
                <a href="#" onclick="runScan()">🔍 Run Security Scan</a>
                <a href="#" onclick="checkGate()">⚖️ Test Policy Gate</a>
                <a href="#" onclick="viewStatus()">📊 View Lab Status</a>
                <a href="#" onclick="downloadReports()">📥 Download Reports</a>
            </div>
            
            <div class="card">
                <h3>📖 Quick Start</h3>
                <p style="margin-bottom: 15px; line-height: 1.5;">
                    Your DevSecOps lab is ready! Use the links above to explore 
                    documentation, view security reports, and access lab services.
                </p>
                <a href="docs/README.html">🚀 Get Started Guide</a>
            </div>
        </div>
    </div>
    
    <script>
        function runScan() {
            alert('Use: docker-compose exec security-scanner /app/scripts/security/scan.sh alpine:latest');
        }
        function checkGate() {
            alert('Use: docker-compose exec security-scanner /app/scripts/security/policy-gate.sh');
        }
        function viewStatus() {
            window.open('/logs/lab-status.json', '_blank');
        }
        function downloadReports() {
            window.open('/reports/', '_blank');
        }
    </script>
</body>
</html>
EOF

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port
EXPOSE 80