const http = require('http');
const os = require('os');

const server = http.createServer((req, res) => {
  const response = {
    message: 'DevSecOps Lab Application',
    version: '1.0.0',
    hostname: os.hostname(),
    timestamp: new Date().toISOString(),
    build: process.env.BUILD_NUMBER || 'unknown',
    revision: process.env.VCS_REVISION || 'unknown'
  };
  
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(response, null, 2));
});

server.listen(8080, () => {
  console.log('DevSecOps Lab App running on port 8080');
});
