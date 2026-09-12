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
  console.log('1. Registering test user...');
  const email = `test-${Date.now()}@test.com`;
  const password = 'password123';
  
  await request('POST', '/api/users', {
    name: 'Test Student',
    email,
    password,
    role: 'student',
    rollNo: 'TEST01'
  });

  console.log('2. Phone A logging in...');
  const deviceA = crypto.randomUUID();
  const loginA = await request('POST', '/login', { email, password, deviceId: deviceA });
  console.log('Phone A Login status:', loginA.status);
  const tokenA = loginA.data.token;
  const userId = loginA.data.id;

  console.log('3. Phone A connecting to SSE...');
  const sseReq = http.request(new URL(`/notifications/stream?userId=${userId}&token=${tokenA}`, BASE_URL), {
    method: 'GET',
    headers: { 'Accept': 'text/event-stream' }
  }, (res) => {
    console.log('SSE Connected! Status:', res.statusCode);
    res.on('data', chunk => {
      console.log('SSE Message received:', chunk.toString().trim());
    });
  });
  sseReq.end();

  await new Promise(r => setTimeout(r, 2000));

  console.log('4. Phone B logging in...');
  const deviceB = crypto.randomUUID();
  const loginB = await request('POST', '/login', { email, password, deviceId: deviceB });
  console.log('Phone B Login status:', loginB.status);
  
  await new Promise(r => setTimeout(r, 3000));
  console.log('Test complete. Exiting.');
  process.exit(0);
}

runTest().catch(console.error);
