const express = require('express');
const jwt = require('jsonwebtoken');
const winston = require('winston');

const app = express();
const PORT = process.env.PORT || 8080;
const JWT_SECRET = process.env.JWT_SECRET || 'devsecops-lab-secret';

// In-memory database (simple arrays)
let users = [];
let products = [
  { id: 1, name: 'DevSecOps Book', description: 'Complete guide to DevSecOps practices', price: 49.99, category: 'Books' },
  { id: 2, name: 'Security Scanner', description: 'Automated vulnerability scanner', price: 199.99, category: 'Tools' }
];
let nextUserId = 1;

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

// Basic middleware
app.use(express.json({ limit: '10mb' }));

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }
  
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.2.0',
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    vulnerabilities: 'INTENTIONAL - FOR TESTING ONLY'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'DevSecOps Lab Sample Application',
    version: '1.2.0',
    status: 'VULNERABLE VERSION - FOR TESTING ONLY',
    endpoints: {
      health: '/health',
      register: 'POST /api/register',
      login: 'POST /api/login',
      products: 'GET /api/products',
      search: 'GET /api/search-vuln?query=term',
      debug: 'GET /api/debug/*',
      admin: 'GET /api/admin/users'
    }
  });
});

// VULNERABLE: Registration with plain text passwords
app.post('/api/register', (req, res) => {
  const { username, email, password } = req.body;
  
  if (!username || !email || !password) {
    return res.status(400).json({ error: 'Username, email, and password required' });
  }
  
  // Check if user exists
  if (users.find(u => u.username === username || u.email === email)) {
    return res.status(400).json({ error: 'User already exists' });
  }
  
  // VULNERABILITY: Plain text password storage
  const user = {
    id: nextUserId++,
    username,
    email,
    password, // VULNERABILITY: No hashing!
    role: 'user',
    created_at: new Date().toISOString()
  };
  
  users.push(user);
  logger.info(`New user registered: ${username}`);
  res.status(201).json({ 
    message: 'User created', 
    userId: user.id,
    warning: 'VULNERABILITY: Password stored in plain text!'
  });
});

// VULNERABLE: Login with plain text comparison
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }
  
  const user = users.find(u => u.username === username);
  if (!user || user.password !== password) { // VULNERABILITY: Plain text comparison
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  const token = jwt.sign(
    { userId: user.id, username: user.username, role: user.role },
    JWT_SECRET,
    { expiresIn: '24h' }
  );
  
  logger.info(`User logged in: ${username}`);
  res.json({ 
    token, 
    user: { id: user.id, username: user.username, role: user.role },
    warning: 'VULNERABILITY: Plain text password authentication!'
  });
});

// Products endpoint (requires auth)
app.get('/api/products', authenticateToken, (req, res) => {
  res.json(products);
});

// VULNERABLE: SQL Injection simulation
app.get('/api/search-vuln', authenticateToken, (req, res) => {
  const { query } = req.query;
  
  if (!query) {
    return res.status(400).json({ error: 'Search query required' });
  }
  
  // VULNERABILITY: Simulated SQL injection
  const simulatedSQL = `SELECT * FROM products WHERE name LIKE '%${query}%'`;
  logger.warn(`VULNERABLE SQL QUERY: ${simulatedSQL}`);
  
  // Simulate SQL injection success
  if (query.includes("' OR 1=1") || query.includes("' OR '1'='1")) {
    res.json({
      message: "🚨 SQL Injection successful!",
      query: query,
      sql: simulatedSQL,
      results: products,
      vulnerability: "SQL Injection detected - this would expose all data",
      impact: "CRITICAL - Full database compromise possible"
    });
  } else {
    const results = products.filter(p => 
      p.name.toLowerCase().includes(query.toLowerCase())
    );
    res.json({ results, query, sql: simulatedSQL });
  }
});

// VULNERABLE: XSS in user profile
app.get('/api/profile/:username', authenticateToken, (req, res) => {
  const { username } = req.params;
  const user = users.find(u => u.username === username);
  
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  // VULNERABILITY: XSS - unescaped user input
  const welcomeMessage = `<h1>Welcome ${user.username}!</h1><p>Email: ${user.email}</p>`;
  
  res.json({
    profile: welcomeMessage, // VULNERABILITY: Raw HTML in JSON
    user: user,
    vulnerability: "XSS vulnerability - HTML not escaped"
  });
});

// VULNERABLE: JWT secret disclosure
app.get('/api/debug/jwt-secret', (req, res) => {
  res.json({
    secret: JWT_SECRET,
    algorithm: 'HS256',
    vulnerability: 'CRITICAL: JWT secret exposed!',
    impact: 'Attacker can forge any JWT token',
    exploit: 'Use this secret to create admin tokens'
  });
});

// VULNERABLE: Server info disclosure
app.get('/api/debug/server-info', (req, res) => {
  res.json({
    nodeVersion: process.version,
    platform: process.platform,
    arch: process.arch,
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage(),
    env: process.env,
    cwd: process.cwd(),
    pid: process.pid,
    users: users, // VULNERABILITY: All user data exposed!
    vulnerability: "CRITICAL: Complete server and user data disclosure"
  });
});

// VULNERABLE: Admin backdoor (no authentication)
app.get('/api/admin/users', (req, res) => {
  // VULNERABILITY: No authentication required for admin endpoint
  res.json({
    message: "Admin backdoor - no authentication required!",
    users: users,
    totalUsers: users.length,
    vulnerability: "CRITICAL: Admin functionality without authentication"
  });
});

// Error handling
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    details: err.message, // VULNERABILITY: Error details disclosure
    stack: err.stack // VULNERABILITY: Stack trace disclosure
  });
});

app.listen(PORT, () => {
  console.log(`🚀 DevSecOps Lab - VULNERABLE APP running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log('');
  console.log('⚠️  INTENTIONAL VULNERABILITIES LOADED:');
  console.log('🚨 Plain Text Passwords: POST /api/register');
  console.log('🚨 SQL Injection: GET /api/search-vuln?query=\' OR 1=1 --');
  console.log('🚨 Secret Disclosure: GET /api/debug/jwt-secret');
  console.log('🚨 Info Disclosure: GET /api/debug/server-info');
  console.log('🚨 Admin Backdoor: GET /api/admin/users');
  console.log('🚨 XSS Vulnerability: GET /api/profile/:username');
  console.log('');
  console.log('🔒 FOR SECURITY TESTING ONLY - DO NOT USE IN PRODUCTION!');
});

module.exports = app;




