const http = require('https');
const crypto = require('crypto');

const BASE_URL = 'https://qr-attendance-api-wvvs.onrender.com';

async function request(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
      }
    };
    if (token) options.headers['Authorization'] = `Bearer ${token}`;

    const req = http.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, data: data ? JSON.parse(data) : null }));
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTest() {
  console.log("Trying to login to any test user to see what happens...");
  // Let's just create a completely random email and password.
  // Wait, I can't register without admin token.
  // But wait! If the user's DB has test users... I don't know the credentials.
  
  // What if I just check the SSE stream?
  const userId = "test_user_id";
  const sseReq = http.request(new URL(`/notifications/stream?userId=${userId}`, BASE_URL), {
    method: 'GET',
    headers: { 'Accept': 'text/event-stream' }
  }, (res) => {
    console.log('SSE Connected! Status:', res.statusCode);
    res.on('data', chunk => {
      console.log('SSE Message received:', chunk.toString().trim());
    });
  });
  sseReq.end();

  setTimeout(() => {
    console.log("Exiting test.");
    process.exit(0);
  }, 16000); // wait for 1 ping
}

runTest().catch(console.error);
