const http = require('https');
const sqlite3 = require('sqlite3').verbose();

// First get a valid token by signing one directly using the same secret
const jwt = require('jsonwebtoken');
require('dotenv').config();
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_for_development_only_12345';

const db = new sqlite3.Database('database.sqlite');
db.get("SELECT * FROM users WHERE role='faculty' LIMIT 1", (err, user) => {
  if (err || !user) {
    console.log("Error or no user");
    return;
  }
  const token = jwt.sign({ id: user.id, role: user.role, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
  
  const options = {
    hostname: 'qr-attendance-api-wvvs.onrender.com',
    path: '/timetable/' + user.id,
    method: 'GET',
    headers: {
      'Authorization': 'Bearer ' + token
    }
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => console.log('Response:', res.statusCode, data));
  });
  req.end();
});
