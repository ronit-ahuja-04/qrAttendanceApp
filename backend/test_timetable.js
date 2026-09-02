const http = require('http');

const options = {
  hostname: 'qr-attendance-api-wvvs.onrender.com',
  path: '/timetable/f1',
  method: 'GET',
};

const req = http.request(options, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => console.log('Response:', res.statusCode, data));
});
req.end();
